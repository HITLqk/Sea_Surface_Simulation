function [rawResults,summaryResults,reference,assessment,figures] = ...
    run_modern_nonlinear_mss_validation(cfg)
%RUN_MODERN_NONLINEAR_MSS_VALIDATION Literature-matched sea-slope test.
%   Each point is one independently synthesized sea realization. Guerin
%   mode uses the 3:0.5:15 m/s IASI grid. Davis mode synthesizes only the
%   k=[0.01,1] rad/m band used by the 2025 buoy parameterization.

arguments
    cfg (1,1) struct = default_modern_mss_validation_config("guerin")
end

validate_experiment(cfg);
addpath(cfg.source.nonlinearDirectory);
assert(exist('generate_nonlinear_lie_elfouhaily_surface','file') == 2, ...
    'NonLiner generator is not available: %s',cfg.source.nonlinearDirectory);

if ~exist(cfg.output.directory,'dir')
    mkdir(cfg.output.directory);
end

nWind = numel(cfg.windSpeeds);
nSeed = numel(cfg.randomSeeds);
nGroup = numel(cfg.groups);
nRows = nWind*nSeed*nGroup;
U10 = zeros(nRows,1);
Seed = zeros(nRows,1);
Group = strings(nRows,1);
MssAlong = zeros(nRows,1);
MssCross = zeros(nRows,1);
MssTotal = zeros(nRows,1);
OverturnedAreaFraction = zeros(nRows,1);
CurlVertexFraction = zeros(nRows,1);
row = 0;

fprintf('Modern MSS validation (%s): %d winds x %d seeds x %d groups.\n', ...
    cfg.mode,nWind,nSeed,nGroup);
for windIndex = 1:nWind
    windSpeed = cfg.windSpeeds(windIndex);
    for seedIndex = 1:nSeed
        seed = cfg.randomSeeds(seedIndex);
        nonlinearCfg = make_nonlinear_config(cfg,windSpeed,seed);
        surfaceData = generate_nonlinear_lie_elfouhaily_surface(nonlinearCfg);

        available = struct();
        available.Linear = calculate_parametric_surface_mss( ...
            surfaceData.X0,surfaceData.Y0,surfaceData.ZLinear, ...
            cfg.sea.windDirectionDeg, ...
            MinimumNormalZ=cfg.slope.minimumNormalZ);
        available.G0_Nonlinear = calculate_parametric_surface_mss( ...
            surfaceData.X,surfaceData.Y,surfaceData.Z, ...
            cfg.sea.windDirectionDeg, ...
            MinimumNormalZ=cfg.slope.minimumNormalZ);
        curlFraction = 0;

        if any(startsWith(cfg.groups,"G1"))
            assert(cfg.curl.enabled, ...
                'G1 groups require cfg.curl.enabled=true.');
            curled = apply_ideal_curl_to_surface(surfaceData,cfg.curl);
            available.G1_Upward = calculate_parametric_surface_mss( ...
                curled.X,curled.Y,curled.Z,cfg.sea.windDirectionDeg, ...
                MinimumNormalZ=cfg.slope.minimumNormalZ);
            available.G1_Background = calculate_parametric_surface_mss( ...
                curled.X,curled.Y,curled.Z,cfg.sea.windDirectionDeg, ...
                ExcludedVertexMask=curled.curlMask, ...
                MinimumNormalZ=cfg.slope.minimumNormalZ);
            curlFraction = nnz(curled.curlMask)/numel(curled.curlMask);
        end

        for groupIndex = 1:nGroup
            group = cfg.groups(groupIndex);
            stats = available.(char(group));
            row = row+1;
            U10(row) = windSpeed;
            Seed(row) = seed;
            Group(row) = group;
            MssAlong(row) = stats.mssAlong;
            MssCross(row) = stats.mssCross;
            MssTotal(row) = stats.mssTotal;
            OverturnedAreaFraction(row) = stats.overturnedSurfaceAreaFraction;
            if startsWith(group,"G1")
                CurlVertexFraction(row) = curlFraction;
            end
        end
        fprintf('  U10=%5.1f m/s, realization %d/%d\n',windSpeed, ...
            (windIndex-1)*nSeed+seedIndex,nWind*nSeed);
    end
end

rawResults = table(U10,Seed,Group,MssAlong,MssCross,MssTotal, ...
    OverturnedAreaFraction,CurlVertexFraction);
summaryResults = summarize_samples(rawResults,cfg.groups);
reference = make_reference(cfg);
assessment = assess_results(summaryResults,reference,cfg);

writetable(rawResults,fullfile(cfg.output.directory,'modern_mss_raw.csv'));
writetable(summaryResults,fullfile(cfg.output.directory, ...
    'modern_mss_summary.csv'));
writetable(reference,fullfile(cfg.output.directory, ...
    'modern_mss_reference.csv'));
writetable(assessment,fullfile(cfg.output.directory, ...
    'modern_mss_assessment.csv'));

figures = plot_experiment(rawResults,reference,cfg);
if cfg.output.saveMat
    save(fullfile(cfg.output.directory,'modern_mss_validation.mat'), ...
        'rawResults','summaryResults','reference','assessment','cfg','-v7.3');
end
end

function nonlinearCfg = make_nonlinear_config(cfg,windSpeed,seed)
nonlinearCfg = default_nonlinear_lie_config();
nonlinearCfg.randomSeed = seed;
nonlinearCfg.domain = cfg.domain;
nonlinearCfg.sea.U10 = windSpeed;
nonlinearCfg.sea.inverseWaveAge = cfg.sea.inverseWaveAge;
nonlinearCfg.sea.windDirectionDeg = cfg.sea.windDirectionDeg;
nonlinearCfg.sea.minimumWavenumber = cfg.synthesis.minimumWavenumber;
nonlinearCfg.sea.maximumWavenumber = cfg.synthesis.maximumWavenumber;
nonlinearCfg.lie.nonlinearInputCutoff = cfg.lie.nonlinearInputCutoff;
nonlinearCfg.lie.nonlinearOutputCutoff = cfg.lie.nonlinearOutputCutoff;
nonlinearCfg.output.figureVisible = 'off';
nonlinearCfg.output.saveSurfaceMat = false;
end

function reference = make_reference(cfg)
if cfg.mode == "guerin"
    complete = guerin_2023_mss_reference();
    [found,index] = ismember(cfg.windSpeeds(:),complete.U10);
    assert(all(found),'Guerin mode requires wind speeds from Table 1.');
    reference = complete(index,:);
else
    reference = davis_2025_mss_reference(cfg.windSpeeds);
end
end

function summary = summarize_samples(raw,groups)
nRows = numel(unique(raw.U10))*numel(groups);
U10 = zeros(nRows,1);
Group = strings(nRows,1);
variables = {'MssAlong','MssCross','MssTotal'};
statistics = {'Mean','Median','Q05','Q25','Q75','Q95'};
values = struct();
for variableIndex = 1:numel(variables)
    for statisticIndex = 1:numel(statistics)
        values.([variables{variableIndex} statistics{statisticIndex}]) = ...
            zeros(nRows,1);
    end
end
SampleCount = zeros(nRows,1);
row = 0;
windSpeeds = unique(raw.U10,'sorted');
for windIndex = 1:numel(windSpeeds)
    for groupIndex = 1:numel(groups)
        row = row+1;
        selected = raw.U10 == windSpeeds(windIndex) & ...
            raw.Group == groups(groupIndex);
        U10(row) = windSpeeds(windIndex);
        Group(row) = groups(groupIndex);
        SampleCount(row) = nnz(selected);
        for variableIndex = 1:numel(variables)
            sample = raw.(variables{variableIndex})(selected);
            values.([variables{variableIndex} 'Mean'])(row) = mean(sample);
            q = sample_quantiles(sample,[0.05 0.25 0.50 0.75 0.95]);
            values.([variables{variableIndex} 'Median'])(row) = q(3);
            values.([variables{variableIndex} 'Q05'])(row) = q(1);
            values.([variables{variableIndex} 'Q25'])(row) = q(2);
            values.([variables{variableIndex} 'Q75'])(row) = q(4);
            values.([variables{variableIndex} 'Q95'])(row) = q(5);
        end
    end
end
summary = table(U10,Group,SampleCount);
names = fieldnames(values);
for index = 1:numel(names)
    summary.(names{index}) = values.(names{index});
end
end

function assessment = assess_results(summary,reference,cfg)
Group = cfg.groups(:);
RMSE_Total = zeros(numel(Group),1);
MAE_Total = zeros(numel(Group),1);
RMSE_Along = nan(numel(Group),1);
RMSE_Cross = nan(numel(Group),1);
for groupIndex = 1:numel(Group)
    selected = summary.Group == Group(groupIndex);
    [~,order] = sort(summary.U10(selected));
    total = summary.MssTotalMedian(selected);
    total = total(order);
    if cfg.mode == "guerin"
        target = reference.MssTotal;
        along = summary.MssAlongMedian(selected);
        crosswind = summary.MssCrossMedian(selected);
        RMSE_Along(groupIndex) = sqrt(mean((along(order)-reference.MssAlong).^2));
        RMSE_Cross(groupIndex) = sqrt(mean((crosswind(order)-reference.MssCross).^2));
    else
        target = reference.MssBandLimited;
    end
    RMSE_Total(groupIndex) = sqrt(mean((total-target).^2));
    MAE_Total(groupIndex) = mean(abs(total-target));
end
assessment = table(Group,RMSE_Total,MAE_Total,RMSE_Along,RMSE_Cross);
end

function figures = plot_experiment(raw,reference,cfg)
if cfg.mode == "guerin"
    figures.scatter = plot_guerin_scatter(raw,reference,cfg);
else
    figures.scatter = plot_davis_scatter(raw,reference,cfg);
end
figures.box = plot_total_boxes(raw,reference,cfg);
exportgraphics(figures.scatter,fullfile(cfg.output.directory, ...
    sprintf('%s_mss_scatter.png',cfg.mode)),'Resolution',240);
exportgraphics(figures.box,fullfile(cfg.output.directory, ...
    sprintf('%s_mss_boxplot.png',cfg.mode)),'Resolution',240);
end

function fig = plot_guerin_scatter(raw,reference,cfg)
fig = figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[60 60 1240 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for groupIndex = 1:numel(cfg.groups)
    ax = nexttile(layout); hold(ax,'on');
    selected = raw.Group == cfg.groups(groupIndex);
    jitter = deterministic_jitter(raw.Seed(selected),0.10);
    scatter(ax,raw.U10(selected)+jitter,raw.MssAlong(selected),13, ...
        [0.90 0.16 0.12],'filled','MarkerFaceAlpha',0.24, ...
        'MarkerEdgeAlpha',0.12,'DisplayName','Along-wind realizations');
    scatter(ax,raw.U10(selected)-jitter,raw.MssCross(selected),13, ...
        [0.10 0.28 0.86],'filled','MarkerFaceAlpha',0.24, ...
        'MarkerEdgeAlpha',0.12,'DisplayName','Cross-wind realizations');
    plot(ax,reference.U10,reference.CoxMunkAlong,'--', ...
        'Color',[0.85 0.12 0.10],'LineWidth',1.4, ...
        'DisplayName','Cox-Munk along');
    plot(ax,reference.U10,reference.CoxMunkCross,'--', ...
        'Color',[0.08 0.20 0.75],'LineWidth',1.4, ...
        'DisplayName','Cox-Munk cross');
    scatter(ax,reference.U10,reference.MssAlong,32,'s', ...
        'MarkerEdgeColor',[0.85 0.12 0.10],'LineWidth',1.2, ...
        'DisplayName','Guerin IASI along');
    scatter(ax,reference.U10,reference.MssCross,32,'s', ...
        'MarkerEdgeColor',[0.08 0.20 0.75],'LineWidth',1.2, ...
        'DisplayName','Guerin IASI cross');
    format_axes(ax,cfg.groups(groupIndex),'Directional MSS');
    xlim(ax,[2.7 15.3]);
    if groupIndex == 1
        legend(ax,'Location','northwest','FontSize',8);
    end
end
xlabel(layout,'10-m wind speed U_{10} (m/s)');
ylabel(layout,'Mean square slope');
end

function fig = plot_davis_scatter(raw,reference,cfg)
fig = figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[80 80 1120 470]);
layout = tiledlayout(fig,1,numel(cfg.groups), ...
    'TileSpacing','compact','Padding','compact');
for groupIndex = 1:numel(cfg.groups)
    ax = nexttile(layout); hold(ax,'on');
    selected = raw.Group == cfg.groups(groupIndex);
    jitter = deterministic_jitter(raw.Seed(selected),0.55);
    scatter(ax,raw.U10(selected)+jitter,raw.MssTotal(selected),16, ...
        [0.05 0.48 0.30],'filled','MarkerFaceAlpha',0.28, ...
        'MarkerEdgeAlpha',0.12,'DisplayName','Sea realizations');
    plot(ax,reference.U10,reference.MssBandLimited,'k-', ...
        'LineWidth',2.0,'DisplayName','Davis 2025 fit');
    plot(ax,reference.U10,reference.MssAligned,'--', ...
        'Color',[0.85 0.22 0.12],'LineWidth',1.3, ...
        'DisplayName','Davis aligned');
    plot(ax,reference.U10,reference.MssCrossing,'--', ...
        'Color',[0.18 0.30 0.78],'LineWidth',1.3, ...
        'DisplayName','Davis crossing');
    yline(ax,0.12,':','Color',[0.35 0.35 0.35], ...
        'LineWidth',1.2,'DisplayName','Plant upper limit');
    format_axes(ax,cfg.groups(groupIndex),'k = 0.01-1 rad/m');
    xlim(ax,[0 52]);
    if groupIndex == 1
        legend(ax,'Location','southeast','FontSize',8);
    end
end
xlabel(layout,'10-m wind speed U_{10} (m/s)');
ylabel(layout,'Band-limited mean square slope');
end

function fig = plot_total_boxes(raw,reference,cfg)
nGroup = numel(cfg.groups);
fig = figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[60 60 1320,max(360,300*ceil(nGroup/2))]);
layout = tiledlayout(fig,ceil(nGroup/2),min(2,nGroup), ...
    'TileSpacing','compact','Padding','compact');
windSpeeds = unique(raw.U10,'sorted');
if numel(windSpeeds) > 15
    boxWidth = 0.28;
else
    boxWidth = 0.8;
end
for groupIndex = 1:nGroup
    ax = nexttile(layout); hold(ax,'on');
    for windIndex = 1:numel(windSpeeds)
        sample = raw.MssTotal(raw.Group == cfg.groups(groupIndex) & ...
            raw.U10 == windSpeeds(windIndex));
        draw_quantile_box(ax,windSpeeds(windIndex),sample,boxWidth, ...
            [0.22 0.50 0.72]);
    end
    if cfg.mode == "guerin"
        scatter(ax,reference.U10,reference.MssTotal,24,'s', ...
            'MarkerEdgeColor',[0.85 0.12 0.10], ...
            'DisplayName','Guerin total');
        plot(ax,reference.U10,reference.CoxMunkTotal,'k--', ...
            'LineWidth',1.4,'DisplayName','Cox-Munk total');
        xlim(ax,[2.7 15.3]);
    else
        plot(ax,reference.U10,reference.MssBandLimited,'k-', ...
            'LineWidth',1.8,'DisplayName','Davis 2025 fit');
        xlim(ax,[0 52]);
    end
    format_axes(ax,cfg.groups(groupIndex),'Median, IQR, and 5%-95%');
    if groupIndex == 1
        legend(ax,'Location','northwest','FontSize',8);
    end
end
xlabel(layout,'10-m wind speed U_{10} (m/s)');
ylabel(layout,'Total mean square slope');
end

function draw_quantile_box(ax,x,sample,width,color)
q = sample_quantiles(sample,[0.05 0.25 0.50 0.75 0.95]);
line(ax,[x x],[q(1) q(5)],'Color',color,'LineWidth',0.9, ...
    'HandleVisibility','off');
patch(ax,x+width*[-0.5 0.5 0.5 -0.5], ...
    [q(2) q(2) q(4) q(4)],color,'FaceAlpha',0.22, ...
    'EdgeColor',color,'LineWidth',0.8,'HandleVisibility','off');
line(ax,x+width*[-0.5 0.5],[q(3) q(3)],'Color',color, ...
    'LineWidth',1.5,'HandleVisibility','off');
end

function q = sample_quantiles(sample,probabilities)
sample = sort(sample(:));
n = numel(sample);
assert(n > 0,'Cannot calculate quantiles of an empty sample.');
positions = 1+(n-1)*probabilities;
lower = floor(positions);
upper = ceil(positions);
fraction = positions-lower;
q = sample(lower).*(1-fraction(:))+sample(upper).*fraction(:);
q = q(:)';
end

function jitter = deterministic_jitter(seeds,amplitude)
centered = mod(double(seeds(:))*0.61803398875,1)-0.5;
jitter = 2*amplitude*centered;
end

function format_axes(ax,group,subtitleText)
title(ax,sprintf('%s: %s',strrep(char(group),'_',' '),subtitleText), ...
    'FontWeight','normal');
grid(ax,'on'); box(ax,'on');
set(ax,'FontName','Times New Roman','FontSize',10,'Layer','top');
end

function validate_experiment(cfg)
assert(isfolder(cfg.source.nonlinearDirectory), ...
    'NonLiner directory does not exist: %s',cfg.source.nonlinearDirectory);
assert(~isempty(cfg.windSpeeds) && all(cfg.windSpeeds > 0), ...
    'Wind speeds must be positive.');
assert(~isempty(cfg.randomSeeds),'At least one random seed is required.');
assert(all(ismember(cfg.groups,["Linear","G0_Nonlinear", ...
    "G1_Upward","G1_Background"])), 'Unknown validation group.');
Nx = round(cfg.domain.Lx/cfg.domain.dx);
Ny = round(cfg.domain.Ly/cfg.domain.dy);
assert(mod(Nx,2) == 0 && mod(Ny,2) == 0, ...
    'Validation grids require even sample counts.');
dk = max(2*pi/cfg.domain.Lx,2*pi/cfg.domain.Ly);
nyquist = min(pi/cfg.domain.dx,pi/cfg.domain.dy);
assert(cfg.synthesis.minimumWavenumber == 0 || ...
    dk <= cfg.synthesis.minimumWavenumber*(1+1e-10), ...
    'Domain is too short to resolve the requested minimum wavenumber.');
assert(isinf(cfg.synthesis.maximumWavenumber) || ...
    cfg.synthesis.maximumWavenumber <= nyquist, ...
    'Grid does not resolve the requested maximum wavenumber.');
assert(cfg.lie.nonlinearOutputCutoff <= nyquist, ...
    'Grid does not resolve the nonlinear output cutoff.');
if cfg.numerics.enforcePeakResolution
    peakWavelength = 2*pi*cfg.windSpeeds.^2/ ...
        (9.81*cfg.sea.inverseWaveAge^2);
    assert(all(cfg.numerics.minimumPeakWaves*peakWavelength <= ...
        min(cfg.domain.Lx,cfg.domain.Ly)), ...
        'Domain does not contain the spectral peak at every wind speed.');
end
end
