function [rawResults,summaryResults,coxMunk] = run_surface_mss_diagnostic(cfg)
%RUN_SURFACE_MSS_DIAGNOSTIC Diagnose sampled nonlinear and curled surfaces.
%   The experiment uses paired random phases for all groups at each U10 and
%   reports confidence intervals across independent realizations.

arguments
    cfg (1,1) struct = default_cox_munk_validation_config()
end

assert(isfolder(cfg.source.nonlinearDirectory), ...
    'NonLiner source directory does not exist: %s', ...
    cfg.source.nonlinearDirectory);
addpath(cfg.source.nonlinearDirectory);
assert(exist('generate_nonlinear_lie_elfouhaily_surface','file') == 2, ...
    'The NonLiner generator is not available on the MATLAB path.');

if cfg.numerics.enforceNativeGrid
    tolerance = 100*eps(cfg.numerics.nativeGridSpacing);
    assert(abs(cfg.domain.dx-cfg.numerics.nativeGridSpacing) <= tolerance && ...
        abs(cfg.domain.dy-cfg.numerics.nativeGridSpacing) <= tolerance, ...
        ['NonLiner uses a Nyquist-relative nonlinear cutoff. Keep dx=dy=%.3f m ', ...
        'for Cox-Munk comparison, or redesign the generator with a fixed ', ...
        'physical cutoff before changing resolution.'], ...
        cfg.numerics.nativeGridSpacing);
end

if cfg.numerics.enforcePeakResolution
    peakWavelengths = 2*pi*cfg.windSpeeds.^2/ ...
        (9.81*cfg.sea.inverseWaveAge^2);
    availableLength = min(cfg.domain.Lx,cfg.domain.Ly);
    requiredLength = cfg.numerics.minimumPeakWaves*peakWavelengths;
    unresolvedIndex = find(requiredLength > availableLength,1,'last');
    if ~isempty(unresolvedIndex)
        error(['The domain does not resolve the spectral peak for every ', ...
            'wind speed. U10 %.1f m/s has a peak wavelength of %.1f m, ', ...
            'but the available domain length is %.1f m. Reduce the wind ', ...
            'range or enlarge the domain.'], ...
            cfg.windSpeeds(unresolvedIndex), ...
            peakWavelengths(unresolvedIndex),availableLength);
    end
end

if ~exist(cfg.output.directory,'dir')
    mkdir(cfg.output.directory);
end

groups = ["Linear","G0_Nonlinear","G1_Upward","G1_Background"];
nWind = numel(cfg.windSpeeds);
nSeed = numel(cfg.randomSeeds);
nRows = nWind*nSeed*numel(groups);

U10 = zeros(nRows,1);
Seed = zeros(nRows,1);
Group = strings(nRows,1);
MssAlong = zeros(nRows,1);
MssCross = zeros(nRows,1);
MssTotal = zeros(nRows,1);
MeanSlopeAlong = zeros(nRows,1);
MeanSlopeCross = zeros(nRows,1);
OverturnedAreaFraction = zeros(nRows,1);
OverturningVertexCount = zeros(nRows,1);
rowIndex = 0;

fprintf('Cox-Munk validation: %d wind speeds x %d seeds.\n',nWind,nSeed);
for windIndex = 1:nWind
    windSpeed = cfg.windSpeeds(windIndex);
    for seedIndex = 1:nSeed
        seed = cfg.randomSeeds(seedIndex);

        nonlinearCfg = default_nonlinear_lie_config();
        nonlinearCfg.randomSeed = seed;
        nonlinearCfg.domain = cfg.domain;
        nonlinearCfg.sea.U10 = windSpeed;
        nonlinearCfg.sea.inverseWaveAge = cfg.sea.inverseWaveAge;
        nonlinearCfg.sea.windDirectionDeg = cfg.sea.windDirectionDeg;
        nonlinearCfg.output.saveSurfaceMat = false;
        nonlinearCfg.output.figureVisible = 'off';
        surfaceData = generate_nonlinear_lie_elfouhaily_surface(nonlinearCfg);

        linearStats = calculate_parametric_surface_mss( ...
            surfaceData.X0,surfaceData.Y0,surfaceData.ZLinear, ...
            cfg.sea.windDirectionDeg, ...
            MinimumNormalZ=cfg.slope.minimumNormalZ);
        nonlinearStats = calculate_parametric_surface_mss( ...
            surfaceData.X,surfaceData.Y,surfaceData.Z, ...
            cfg.sea.windDirectionDeg, ...
            MinimumNormalZ=cfg.slope.minimumNormalZ);

        if cfg.curl.enabled
            curled = apply_ideal_curl_to_surface(surfaceData,cfg.curl);
            curledStats = calculate_parametric_surface_mss( ...
                curled.X,curled.Y,curled.Z,cfg.sea.windDirectionDeg, ...
                MinimumNormalZ=cfg.slope.minimumNormalZ);
            backgroundStats = calculate_parametric_surface_mss( ...
                curled.X,curled.Y,curled.Z,cfg.sea.windDirectionDeg, ...
                ExcludedVertexMask=curled.curlMask, ...
                MinimumNormalZ=cfg.slope.minimumNormalZ);
            overturningCount = nnz(curled.overturningMask);
        else
            curledStats = nonlinearStats;
            backgroundStats = nonlinearStats;
            overturningCount = 0;
        end

        groupStats = {linearStats,nonlinearStats,curledStats,backgroundStats};
        for groupIndex = 1:numel(groups)
            rowIndex = rowIndex+1;
            stats = groupStats{groupIndex};
            U10(rowIndex) = windSpeed;
            Seed(rowIndex) = seed;
            Group(rowIndex) = groups(groupIndex);
            MssAlong(rowIndex) = stats.mssAlong;
            MssCross(rowIndex) = stats.mssCross;
            MssTotal(rowIndex) = stats.mssTotal;
            MeanSlopeAlong(rowIndex) = stats.meanSlopeAlong;
            MeanSlopeCross(rowIndex) = stats.meanSlopeCross;
            OverturnedAreaFraction(rowIndex) = ...
                stats.overturnedSurfaceAreaFraction;
            if startsWith(groups(groupIndex),"G1")
                OverturningVertexCount(rowIndex) = overturningCount;
            end
        end

        fprintf('  U10=%4.1f m/s, seed=%d (%d/%d)\n',windSpeed,seed, ...
            (windIndex-1)*nSeed+seedIndex,nWind*nSeed);
    end
end

rawResults = table(U10,Seed,Group,MssAlong,MssCross,MssTotal, ...
    MeanSlopeAlong,MeanSlopeCross,OverturnedAreaFraction, ...
    OverturningVertexCount);
coxMunk = make_cox_munk_table(cfg.windSpeeds,cfg.coxMunk.totalUncertainty);
summaryResults = summarize_results(rawResults,coxMunk,groups);

writetable(rawResults,fullfile(cfg.output.directory,'cox_munk_raw_results.csv'));
writetable(summaryResults,fullfile(cfg.output.directory, ...
    'cox_munk_summary_results.csv'));
writetable(coxMunk,fullfile(cfg.output.directory,'cox_munk_reference.csv'));

figureHandle = plot_validation(summaryResults,coxMunk,cfg);
exportgraphics(figureHandle,fullfile(cfg.output.directory, ...
    'cox_munk_validation.png'),'Resolution',220);
if cfg.output.saveMat
    save(fullfile(cfg.output.directory,'cox_munk_validation.mat'), ...
        'rawResults','summaryResults','coxMunk','cfg','-v7.3');
end
end

function reference = make_cox_munk_table(windSpeeds,totalUncertainty)
U10 = windSpeeds(:);
MssAlong = 3.16e-3*U10;
MssCross = 0.003+1.92e-3*U10;
MssTotal = MssAlong+MssCross;
MssTotalLower = max(MssTotal-totalUncertainty,0);
MssTotalUpper = MssTotal+totalUncertainty;
reference = table(U10,MssAlong,MssCross,MssTotal, ...
    MssTotalLower,MssTotalUpper);
end

function summary = summarize_results(raw,reference,groups)
nRows = numel(groups)*height(reference);
U10 = zeros(nRows,1);
Group = strings(nRows,1);
MssAlongMean = zeros(nRows,1);
MssAlongCi95 = zeros(nRows,1);
MssCrossMean = zeros(nRows,1);
MssCrossCi95 = zeros(nRows,1);
MssTotalMean = zeros(nRows,1);
MssTotalCi95 = zeros(nRows,1);
RelativeTotalError = zeros(nRows,1);
OverturnedAreaFractionMean = zeros(nRows,1);

rowIndex = 0;
for windIndex = 1:height(reference)
    for groupIndex = 1:numel(groups)
        rowIndex = rowIndex+1;
        selected = raw.U10 == reference.U10(windIndex) & ...
            raw.Group == groups(groupIndex);
        n = nnz(selected);
        U10(rowIndex) = reference.U10(windIndex);
        Group(rowIndex) = groups(groupIndex);
        [MssAlongMean(rowIndex),MssAlongCi95(rowIndex)] = ...
            mean_ci95(raw.MssAlong(selected),n);
        [MssCrossMean(rowIndex),MssCrossCi95(rowIndex)] = ...
            mean_ci95(raw.MssCross(selected),n);
        [MssTotalMean(rowIndex),MssTotalCi95(rowIndex)] = ...
            mean_ci95(raw.MssTotal(selected),n);
        RelativeTotalError(rowIndex) = abs(MssTotalMean(rowIndex)-...
            reference.MssTotal(windIndex))/reference.MssTotal(windIndex);
        OverturnedAreaFractionMean(rowIndex) = mean( ...
            raw.OverturnedAreaFraction(selected));
    end
end

summary = table(U10,Group,MssAlongMean,MssAlongCi95, ...
    MssCrossMean,MssCrossCi95,MssTotalMean,MssTotalCi95, ...
    RelativeTotalError,OverturnedAreaFractionMean);
end

function [sampleMean,ci95] = mean_ci95(values,n)
sampleMean = mean(values);
if n > 1
    ci95 = 1.96*std(values,0)/sqrt(n);
else
    ci95 = 0;
end
end

function fig = plot_validation(summary,reference,cfg)
fig = figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[80 80 1180 820]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

ax1 = nexttile(layout);
hold(ax1,'on');
fill(ax1,[reference.U10;flipud(reference.U10)], ...
    [reference.MssTotalLower;flipud(reference.MssTotalUpper)], ...
    [0.85 0.85 0.85],'EdgeColor','none','DisplayName','Cox-Munk band');
plot(ax1,reference.U10,reference.MssTotal,'k--','LineWidth',1.6, ...
    'DisplayName','Cox-Munk');
plot_groups(ax1,summary,'MssTotalMean','MssTotalCi95');
xlabel(ax1,'U_{10} (m/s)'); ylabel(ax1,'Total MSS');
title(ax1,'Total Mean Square Slope'); grid(ax1,'on'); legend(ax1,'Location','northwest');

ax2 = nexttile(layout);
hold(ax2,'on');
plot(ax2,reference.U10,reference.MssAlong,'k--','LineWidth',1.6, ...
    'DisplayName','Cox-Munk');
plot_groups(ax2,summary,'MssAlongMean','MssAlongCi95');
xlabel(ax2,'U_{10} (m/s)'); ylabel(ax2,'Along-wind MSS');
title(ax2,'Along-wind Component'); grid(ax2,'on');

ax3 = nexttile(layout);
hold(ax3,'on');
plot(ax3,reference.U10,reference.MssCross,'k--','LineWidth',1.6, ...
    'DisplayName','Cox-Munk');
plot_groups(ax3,summary,'MssCrossMean','MssCrossCi95');
xlabel(ax3,'U_{10} (m/s)'); ylabel(ax3,'Cross-wind MSS');
title(ax3,'Cross-wind Component'); grid(ax3,'on');

ax4 = nexttile(layout);
hold(ax4,'on');
groups = unique(summary.Group,'stable');
for groupIndex = 1:numel(groups)
    selected = summary.Group == groups(groupIndex);
    plot(ax4,summary.U10(selected),100*summary.RelativeTotalError(selected), ...
        '-o','LineWidth',1.4,'DisplayName',strrep(groups(groupIndex),'_',' '));
end
xlabel(ax4,'U_{10} (m/s)'); ylabel(ax4,'Relative error (%)');
title(ax4,'Error Relative to Cox-Munk'); grid(ax4,'on');

allAxes = findall(fig,'Type','axes');
set(allAxes,'FontName','Times New Roman','FontSize',11,'LineWidth',0.8);
end

function plot_groups(ax,summary,meanVariable,ciVariable)
groups = unique(summary.Group,'stable');
colors = lines(numel(groups));
for groupIndex = 1:numel(groups)
    selected = summary.Group == groups(groupIndex);
    errorbar(ax,summary.U10(selected),summary.(meanVariable)(selected), ...
        summary.(ciVariable)(selected),'-o','Color',colors(groupIndex,:), ...
        'LineWidth',1.4,'MarkerSize',5, ...
        'DisplayName',strrep(groups(groupIndex),'_',' '));
end
end
