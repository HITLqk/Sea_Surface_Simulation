function [raw,summary,reference,assessment] = run_thesis_two_group_validation(cfg)
%RUN_THESIS_TWO_GROUP_VALIDATION Clean Elfouhaily versus modified-Lie test.
%   The only displayed groups are Linear Elfouhaily and an
%   Elfouhaily-closed Modified Lie model.

arguments
    cfg (1,1) struct = default_thesis_two_group_config()
end
validate_config(cfg);
if ~isfolder(cfg.outputDirectory)
    mkdir(cfg.outputDirectory);
end

reference = two_group_mss_references(cfg.windSpeeds,cfg);
[closure,closureCalibration] = calibrate_elfouhaily_closure(cfg,reference);
cfg.elfouhailyClosure = closure;
groups = ["Linear Elfouhaily","Elfouhaily-Constrained Modified Lie"];
nRows = numel(cfg.windSpeeds)*numel(cfg.realizationSeeds)*numel(groups);
U10 = zeros(nRows,1);
Seed = zeros(nRows,1);
Group = strings(nRows,1);
MssAlong = zeros(nRows,1);
MssCross = zeros(nRows,1);
MssTotal = zeros(nRows,1);
Gamma = zeros(nRows,1);
PrimaryMss = zeros(nRows,1);
ShortWaveMss = zeros(nRows,1);
PreClosureMssTotal = nan(nRows,1);
PreClosureGamma = nan(nRows,1);
row = 0;
example = struct();

for windIndex = 1:numel(cfg.windSpeeds)
    windSpeed = cfg.windSpeeds(windIndex);
    for seedIndex = 1:numel(cfg.realizationSeeds)
        seed = cfg.realizationSeeds(seedIndex);
        result = synthesize_two_group_realization(windSpeed,seed,cfg);
        row = add_row(row,windSpeed,seed,groups(1),result.linear, ...
            result.primaryLinear.total,result.shortWave.total,[]);
        row = add_row(row,windSpeed,seed,groups(2),result.breaking, ...
            result.primaryBreaking.total,result.shortWaveBreaking.total, ...
            result.breakingRaw);
        if seedIndex == 1 && (windSpeed == 5 || windSpeed == 10)
            example.(sprintf('U%d',windSpeed)) = result;
        end
    end
end

raw = table(U10,Seed,Group,MssAlong,MssCross,MssTotal,Gamma, ...
    PrimaryMss,ShortWaveMss,PreClosureMssTotal,PreClosureGamma);
summary = summarize_results(raw,groups,cfg.windSpeeds);
assessment = assess_results(summary,reference,groups);

figMss = plot_mss(summary,reference,groups,cfg);
figGamma = plot_gamma(summary,reference,groups,cfg);
figExamples = plot_examples(example,cfg);
exportgraphics(figMss,fullfile(cfg.outputDirectory,'01_two_group_mss.png'), ...
    'Resolution',cfg.exportResolution);
exportgraphics(figGamma,fullfile(cfg.outputDirectory,'02_two_group_anisotropy.png'), ...
    'Resolution',cfg.exportResolution);
exportgraphics(figExamples,fullfile(cfg.outputDirectory,'03_surface_examples.png'), ...
    'Resolution',cfg.exportResolution);
close(figMss); close(figGamma); close(figExamples);

writetable(raw,fullfile(cfg.outputDirectory,'two_group_raw.csv'));
writetable(summary,fullfile(cfg.outputDirectory,'two_group_summary.csv'));
writetable(reference,fullfile(cfg.outputDirectory,'two_group_reference.csv'));
writetable(assessment,fullfile(cfg.outputDirectory,'two_group_assessment.csv'));
writetable(closureCalibration,fullfile(cfg.outputDirectory, ...
    'elfouhaily_closure_calibration.csv'));
save(fullfile(cfg.outputDirectory,'two_group_validation.mat'), ...
    'raw','summary','reference','assessment','closureCalibration', ...
    'cfg','example','-v7.3');
disp(assessment);

    function nextRow = add_row(currentRow,wind,seedValue,groupName,mss, ...
            primary,shortWave,preClosure)
        nextRow = currentRow+1;
        U10(nextRow) = wind;
        Seed(nextRow) = seedValue;
        Group(nextRow) = groupName;
        MssAlong(nextRow) = mss.along;
        MssCross(nextRow) = mss.cross;
        MssTotal(nextRow) = mss.total;
        Gamma(nextRow) = mss.gamma;
        PrimaryMss(nextRow) = primary;
        ShortWaveMss(nextRow) = shortWave;
        if ~isempty(preClosure)
            PreClosureMssTotal(nextRow) = preClosure.total;
            PreClosureGamma(nextRow) = preClosure.gamma;
        end
    end
end

function [closure,calibration] = calibrate_elfouhaily_closure(cfg,reference)
calibrationCfg = cfg;
calibrationCfg.enableElfouhailyClosure = false;
nWinds = numel(cfg.windSpeeds);
RawAlongMedian = zeros(nWinds,1);
RawCrossMedian = zeros(nWinds,1);
for windIndex = 1:nWinds
    windSpeed = cfg.windSpeeds(windIndex);
    rawAlong = zeros(numel(cfg.closureCalibrationSeeds),1);
    rawCross = zeros(numel(cfg.closureCalibrationSeeds),1);
    for seedIndex = 1:numel(cfg.closureCalibrationSeeds)
        result = synthesize_two_group_realization(windSpeed, ...
            cfg.closureCalibrationSeeds(seedIndex),calibrationCfg);
        rawAlong(seedIndex) = result.breakingRaw.along;
        rawCross(seedIndex) = result.breakingRaw.cross;
    end
    RawAlongMedian(windIndex) = median(rawAlong);
    RawCrossMedian(windIndex) = median(rawCross);
end

logWind = log(cfg.windSpeeds(:));
logWindCenter = mean(logWind);
logWindScale = std(logWind);
x = (logWind-logWindCenter)/logWindScale;
alongObservedLogScale = log(reference.ElfouhailyAlong./RawAlongMedian);
crossObservedLogScale = log(reference.ElfouhailyCross./RawCrossMedian);
degree = cfg.closurePolynomialDegree;
alongCoefficients = polyfit(x,alongObservedLogScale,degree);
crossCoefficients = polyfit(x,crossObservedLogScale,degree);
FittedAlongScale = exp(polyval(alongCoefficients,x));
FittedCrossScale = exp(polyval(crossCoefficients,x));
FittedAlongScale = min(max(FittedAlongScale,cfg.closureScaleBounds(1)), ...
    cfg.closureScaleBounds(2));
FittedCrossScale = min(max(FittedCrossScale,cfg.closureScaleBounds(1)), ...
    cfg.closureScaleBounds(2));

closure.logWindCenter = logWindCenter;
closure.logWindScale = logWindScale;
closure.alongLogScaleCoefficients = alongCoefficients;
closure.crossLogScaleCoefficients = crossCoefficients;

U10 = cfg.windSpeeds(:);
TargetAlong = reference.ElfouhailyAlong;
TargetCross = reference.ElfouhailyCross;
PredictedAlong = RawAlongMedian.*FittedAlongScale;
PredictedCross = RawCrossMedian.*FittedCrossScale;
RawGamma = sqrt(RawCrossMedian./RawAlongMedian);
PredictedGamma = sqrt(PredictedCross./PredictedAlong);
TargetGamma = reference.ElfouhailyGamma;
calibration = table(U10,RawAlongMedian,RawCrossMedian,RawGamma, ...
    TargetAlong,TargetCross,TargetGamma,FittedAlongScale,FittedCrossScale, ...
    PredictedAlong,PredictedCross,PredictedGamma);
end

function summary = summarize_results(raw,groups,winds)
n = numel(groups)*numel(winds);
Group = strings(n,1); U10 = zeros(n,1);
AlongMedian = zeros(n,1); CrossMedian = zeros(n,1);
TotalMedian = zeros(n,1); TotalQ05 = zeros(n,1); TotalQ25 = zeros(n,1);
TotalQ75 = zeros(n,1); TotalQ95 = zeros(n,1); GammaMedian = zeros(n,1);
PreClosureTotalMedian = nan(n,1); PreClosureGammaMedian = nan(n,1);
row = 0;
for groupIndex = 1:numel(groups)
    for windIndex = 1:numel(winds)
        row = row+1;
        selected = raw.Group == groups(groupIndex) & raw.U10 == winds(windIndex);
        Group(row) = groups(groupIndex); U10(row) = winds(windIndex);
        AlongMedian(row) = median(raw.MssAlong(selected));
        CrossMedian(row) = median(raw.MssCross(selected));
        q = local_quantile(raw.MssTotal(selected),[0.05 0.25 0.5 0.75 0.95]);
        TotalQ05(row)=q(1); TotalQ25(row)=q(2); TotalMedian(row)=q(3);
        TotalQ75(row)=q(4); TotalQ95(row)=q(5);
        GammaMedian(row) = median(raw.Gamma(selected));
        preClosureTotal = raw.PreClosureMssTotal(selected);
        preClosureGamma = raw.PreClosureGamma(selected);
        if any(isfinite(preClosureTotal))
            PreClosureTotalMedian(row) = median(preClosureTotal(isfinite(preClosureTotal)));
            PreClosureGammaMedian(row) = median(preClosureGamma(isfinite(preClosureGamma)));
        end
    end
end
summary = table(Group,U10,AlongMedian,CrossMedian,TotalMedian,TotalQ05, ...
    TotalQ25,TotalQ75,TotalQ95,GammaMedian,PreClosureTotalMedian, ...
    PreClosureGammaMedian);
end

function assessment = assess_results(summary,reference,groups)
Group = groups(:);
RMSE_CoxMunk = zeros(numel(groups),1);
RMSE_Guerin = zeros(numel(groups),1);
RMSE_TGRS_Hu = zeros(numel(groups),1);
RMSE_Elfouhaily = zeros(numel(groups),1);
MeanAbsGammaError_TGRS = zeros(numel(groups),1);
for index = 1:numel(groups)
    selected = summary.Group == groups(index);
    groupSummary = sortrows(summary(selected,:),'U10');
    total = groupSummary.TotalMedian;
    RMSE_CoxMunk(index) = sqrt(mean((total-reference.CoxMunkTotal).^2));
    valid = isfinite(reference.GuerinTotal);
    RMSE_Guerin(index) = sqrt(mean((total(valid)-reference.GuerinTotal(valid)).^2));
    RMSE_TGRS_Hu(index) = sqrt(mean((total-reference.TgrsHuTotal).^2));
    RMSE_Elfouhaily(index) = sqrt(mean((total-reference.ElfouhailyTotal).^2));
    MeanAbsGammaError_TGRS(index) = mean(abs( ...
        groupSummary.GammaMedian-reference.TgrsGamma));
end
assessment = table(Group,RMSE_CoxMunk,RMSE_Guerin,RMSE_TGRS_Hu, ...
    RMSE_Elfouhaily,MeanAbsGammaError_TGRS);
end

function fig = plot_mss(summary,reference,groups,cfg)
fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[100 100 1260 480]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
colors = lines(numel(groups));
for index = 1:numel(groups)
    ax = nexttile; hold(ax,'on');
    selected = sortrows(summary(summary.Group == groups(index),:),'U10');
    fill(ax,[selected.U10;flipud(selected.U10)], ...
        [selected.TotalQ05;flipud(selected.TotalQ95)],colors(index,:), ...
        'FaceAlpha',0.12,'EdgeColor','none','DisplayName','5%-95%');
    fill(ax,[selected.U10;flipud(selected.U10)], ...
        [selected.TotalQ25;flipud(selected.TotalQ75)],colors(index,:), ...
        'FaceAlpha',0.28,'EdgeColor','none','DisplayName','IQR');
    plot(ax,selected.U10,selected.TotalMedian,'o-', ...
        'Color',colors(index,:),'LineWidth',1.8,'DisplayName','Simulation median');
    if any(isfinite(selected.PreClosureTotalMedian))
        plot(ax,selected.U10,selected.PreClosureTotalMedian,'x--', ...
            'Color',[0.45 0.45 0.45],'LineWidth',1.3, ...
            'DisplayName','Raw Modified Lie (pre-closure)');
    end
    plot(ax,reference.U10,reference.ElfouhailyTotal,'k:','LineWidth',1.6, ...
        'DisplayName','Elfouhaily integral');
    plot(ax,reference.U10,reference.CoxMunkTotal,'k--','LineWidth',1.5, ...
        'DisplayName','Cox-Munk');
    plot(ax,reference.U10,reference.TgrsHuTotal,'Color',[0.8 0.2 0.1], ...
        'LineStyle','-.','LineWidth',1.5,'DisplayName','TGRS/Hu');
    plot(ax,reference.U10,reference.GuerinTotal,'s','Color',[0.1 0.35 0.8], ...
        'MarkerFaceColor','none','DisplayName','Guerin IASI');
    title(ax,groups(index)); xlabel(ax,'U_{10} (m/s)'); ylabel(ax,'Total MSS');
    grid(ax,'on'); box(ax,'on'); xlim(ax,[1 10]);
    legend(ax,'Location','northwest');
end
linkaxes(findall(fig,'Type','axes'),'xy');
end

function fig = plot_gamma(summary,reference,groups,cfg)
fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[120 120 1260 480]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
colors = lines(numel(groups));
for index = 1:numel(groups)
    ax = nexttile; hold(ax,'on');
    selected = sortrows(summary(summary.Group == groups(index),:),'U10');
    plot(ax,selected.U10,selected.GammaMedian,'o-', ...
        'Color',colors(index,:),'LineWidth',1.8,'DisplayName','Simulation');
    if any(isfinite(selected.PreClosureGammaMedian))
        plot(ax,selected.U10,selected.PreClosureGammaMedian,'x--', ...
            'Color',[0.45 0.45 0.45],'LineWidth',1.3, ...
            'DisplayName','Raw Modified Lie (pre-closure)');
    end
    plot(ax,reference.U10,reference.ElfouhailyGamma,'k:','LineWidth',1.6, ...
        'DisplayName','Elfouhaily integral');
    plot(ax,reference.U10,reference.GuerinGamma,'s','Color',[0.1 0.35 0.8], ...
        'MarkerFaceColor','none','DisplayName','Guerin IASI');
    yline(ax,0.864,'-.','TGRS mean 0.864','Color',[0.8 0.2 0.1], ...
        'LineWidth',1.5,'LabelHorizontalAlignment','left', ...
        'HandleVisibility','off');
    yline(ax,0.84,'--','TGRS simulated 0.84','Color',[0.45 0.2 0.6], ...
        'LineWidth',1.2,'LabelHorizontalAlignment','left', ...
        'HandleVisibility','off');
    title(ax,groups(index)); xlabel(ax,'U_{10} (m/s)');
    ylabel(ax,'Anisotropy \gamma'); grid(ax,'on'); box(ax,'on'); xlim(ax,[1 10]);
    legend(ax,'Location','best');
end
linkaxes(findall(fig,'Type','axes'),'xy');
end

function fig = plot_examples(example,cfg)
fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[140 80 1480 800]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
winds = [5 10];
for windIndex = 1:numel(winds)
    result = example.(sprintf('U%d',winds(windIndex)));
    surfaces = {result.linearSurface,result.breakingSurface};
    names = {'Linear Elfouhaily','Elfouhaily-Constrained Modified Lie'};
    commonLimit = max(abs([surfaces{1}(:);surfaces{2}(:)]));
    coordinates = (0:size(surfaces{1},1)-1)*result.primarySpacing;
    for groupIndex = 1:2
        ax = nexttile; imagesc(ax,coordinates,coordinates,surfaces{groupIndex});
        axis(ax,'image'); axis(ax,'xy'); clim(ax,[-commonLimit commonLimit]);
        colormap(ax,parula); colorbar(ax);
        title(ax,sprintf('%s, U_{10}=%d m/s',names{groupIndex},winds(windIndex)));
        xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    end
    ax = nexttile; hold(ax,'on');
    centerRow = floor(size(surfaces{1},1)/2)+1;
    plot(ax,coordinates,surfaces{1}(centerRow,:),'LineWidth',1.4, ...
        'DisplayName','Linear');
    plot(ax,coordinates,surfaces{2}(centerRow,:),'LineWidth',1.4, ...
        'DisplayName','Modified Lie');
    title(ax,sprintf('Paired center section, U_{10}=%d m/s',winds(windIndex)));
    xlabel(ax,'x (m)'); ylabel(ax,'Elevation (m)'); grid(ax,'on'); box(ax,'on');
    legend(ax,'Location','best');
end
end

function q = local_quantile(values,p)
values = sort(values(:));
positions = 1+(numel(values)-1)*p;
lower = floor(positions); upper = ceil(positions);
weight = positions-lower;
q = values(lower).*(1-weight)+values(upper).*weight;
end

function validate_config(cfg)
assert(isequal(cfg.windSpeeds(:),(1:10)'), ...
    'This experiment is fixed to the requested 1:1:10 m/s wind grid.');
assert(all(cfg.realizationSeeds == floor(cfg.realizationSeeds)), ...
    'Realization seeds must be integers.');
assert(all(cfg.closureCalibrationSeeds == floor(cfg.closureCalibrationSeeds)), ...
    'Closure calibration seeds must be integers.');
assert(isempty(intersect(cfg.realizationSeeds,cfg.closureCalibrationSeeds)), ...
    'Calibration and validation seeds must be independent.');
assert(cfg.primaryPeakSamples >= 10, ...
    'The primary grid must satisfy the thesis dk <= kp/10 condition.');
assert(cfg.lieOutputPeakMultiple <= cfg.primaryMaximumPeakMultiple, ...
    'The Lie output band must be contained in the primary grid band.');
assert(cfg.maximumOpticalWavenumber > 370, ...
    'The optical cutoff must include the Elfouhaily short-wave peak.');
assert(cfg.closurePolynomialDegree >= 1 && cfg.closurePolynomialDegree <= 3, ...
    'Use a low-order closure polynomial (degree 1 to 3).');
assert(numel(cfg.closureScaleBounds) == 2 && ...
    cfg.closureScaleBounds(1) > 0 && ...
    cfg.closureScaleBounds(2) > cfg.closureScaleBounds(1), ...
    'closureScaleBounds must be a positive increasing pair.');
end
