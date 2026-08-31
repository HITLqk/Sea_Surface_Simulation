function results = run_local_curl_dual_metric_validation(userConfig)
%RUN_LOCAL_CURL_DUAL_METRIC_VALIDATION Validate Gb and Gb(chi).
%   RESULTS = RUN_LOCAL_CURL_DUAL_METRIC_VALIDATION() runs paired G0/G1
%   Monte Carlo experiments. G1 samples chi continuously; it does not use
%   weak/moderate/strong validation groups.

if nargin < 1
    userConfig = struct();
end

cfg = merge_struct(default_local_curl_dual_metric_config(), userConfig);
generatorDir = locate_curl_generator(fileparts(mfilename('fullpath')));
addpath(generatorDir);
cleanupPath = onCleanup(@() rmpath(generatorDir));

if ~exist(cfg.output.directory, 'dir')
    mkdir(cfg.output.directory);
end

rng(cfg.randomSeed, 'twister');
strata = ((1:cfg.sampleCount)'-0.5)/cfg.sampleCount;
strata = strata(randperm(cfg.sampleCount));
chiDesign = cfg.chi.minimum + ...
    (cfg.chi.maximum-cfg.chi.minimum)*strata;
seedDesign = cfg.randomSeed + (1:cfg.maximumAttempts)';

raw = initialize_raw_table(cfg.sampleCount);
accepted = 0;
attempt = 0;
representative = struct();

fprintf('Running paired local curl validation: N = %d\n', cfg.sampleCount);
while accepted < cfg.sampleCount && attempt < cfg.maximumAttempts
    attempt = attempt+1;
    targetIndex = accepted+1;
    chi = chiDesign(targetIndex);

    generatorCfg = default_elfouhaily_ideal_curl_config();
    generatorCfg.randomSeed = seedDesign(attempt);
    generatorCfg.domain.Lx = cfg.generator.domainLx;
    generatorCfg.domain.Ly = cfg.generator.domainLy;
    generatorCfg.domain.dx = cfg.generator.dx;
    generatorCfg.domain.dy = cfg.generator.dy;
    generatorCfg.sea.U10 = cfg.generator.U10;
    generatorCfg.sea.targetHs = cfg.generator.targetHs;
    generatorCfg.detection.heightSigmaThreshold = ...
        cfg.generator.heightSigmaThreshold;
    generatorCfg.curl.curlMultiplier = ...
        chi*cfg.chi.maximumCurlMultiplier;

    try
        surfaceData = generate_elfouhaily_ideal_curl_surface(generatorCfg);
        pair = calculate_local_paired_scattering(surfaceData, cfg);
    catch exception
        warning('Rejected seed %d: %s', seedDesign(attempt), exception.message);
        continue
    end

    accepted = accepted+1;
    raw.Sample(accepted) = accepted;
    raw.Seed(accepted) = seedDesign(attempt);
    raw.Chi(accepted) = chi;
    raw.CurlMultiplier(accepted) = generatorCfg.curl.curlMultiplier;
    raw.PreRcs_dBsm(accepted) = pair.preRcs_dBsm;
    raw.CurlRcs_dBsm(accepted) = pair.curlRcs_dBsm;
    raw.Gb_dB(accepted) = pair.Gb_dB;
    raw.PreLocalNrcs_dB(accepted) = ...
        10*log10(pair.preLocalNrcsLinear);
    raw.CurlLocalNrcs_dB(accepted) = ...
        10*log10(pair.curlLocalNrcsLinear);
    raw.PreVisibleFraction(accepted) = pair.preVisibleFraction;
    raw.CurlVisibleFraction(accepted) = pair.curlVisibleFraction;
    raw.MaxForwardDisplacement_m(accepted) = ...
        surfaceData.metrics.maxForwardDisplacement;
    raw.MaxDownwardDisplacement_m(accepted) = ...
        surfaceData.metrics.maxDownwardDisplacement;
    raw.MinimumPropagationJacobian(accepted) = ...
        surfaceData.metrics.minimumPropagationJacobian;
    raw.OverturningPointCount(accepted) = ...
        surfaceData.metrics.overturningPointCount;

    if isempty(fieldnames(representative)) || ...
            abs(chi-0.75) < abs(representative.chi-0.75)
        representative.chi = chi;
        representative.surfaceData = surfaceData;
        representative.pair = pair;
    end

    if mod(accepted, 10) == 0 || accepted == cfg.sampleCount
        fprintf('  accepted %d/%d (attempts %d)\n', ...
            accepted, cfg.sampleCount, attempt);
    end
end

assert(accepted == cfg.sampleCount, ...
    'Only %d/%d valid paired samples were generated.', accepted, cfg.sampleCount);

summary = summarize_results(raw, cfg);
reference = load_reference_if_available(cfg.output.referenceCsv);
fig = plot_results(raw, summary, reference, representative, cfg);

rawFile = fullfile(cfg.output.directory, 'local_curl_dual_metric_raw.csv');
summaryFile = fullfile(cfg.output.directory, ...
    'local_curl_dual_metric_summary.csv');
matFile = fullfile(cfg.output.directory, 'local_curl_dual_metric_results.mat');
pngFile = fullfile(cfg.output.directory, ...
    'local_curl_dual_metric_validation_final.png');

writetable(raw, rawFile);
writetable(summary, summaryFile);
save(matFile, 'raw', 'summary', 'reference', 'cfg', 'representative', '-v7.3');
exportgraphics(fig, pngFile, 'Resolution', 220);
if cfg.output.savePdf
    exportgraphics(fig, fullfile(cfg.output.directory, ...
        'local_curl_dual_metric_validation_final.pdf'), 'ContentType', 'vector');
end

fprintf('\nPaired validation complete.\n');
fprintf('  median Gb       : %.3f dB\n', median(raw.Gb_dB));
fprintf('  interquartile Gb: [%.3f, %.3f] dB\n', ...
    percentile(raw.Gb_dB,25), percentile(raw.Gb_dB,75));
fprintf('  P(Gb > 0)       : %.3f\n', mean(raw.Gb_dB > 0));
fprintf('  result directory: %s\n', cfg.output.directory);
if isempty(reference)
    fprintf(['  literature CSV  : not populated; current figures validate ', ...
        'the paired model response only.\n']);
end

results = struct('raw', raw, 'summary', summary, ...
    'reference', reference, 'cfg', cfg, 'figure', fig);
end

function raw = initialize_raw_table(n)
raw = table('Size', [n 14], ...
    'VariableTypes', repmat({'double'}, 1, 14), ...
    'VariableNames', {'Sample','Seed','Chi','CurlMultiplier', ...
    'PreRcs_dBsm','CurlRcs_dBsm','Gb_dB','PreLocalNrcs_dB', ...
    'CurlLocalNrcs_dB','PreVisibleFraction','CurlVisibleFraction', ...
    'MaxForwardDisplacement_m','MaxDownwardDisplacement_m', ...
    'MinimumPropagationJacobian'});
raw.OverturningPointCount = zeros(n,1);
end

function summary = summarize_results(raw, cfg)
edges = linspace(cfg.chi.minimum, cfg.chi.maximum, cfg.chi.binCount+1);
bin = discretize(raw.Chi, edges);
rows = zeros(cfg.chi.binCount, 8);
for b = 1:cfg.chi.binCount
    values = raw.Gb_dB(bin == b);
    chiValues = raw.Chi(bin == b);
    rows(b,:) = [b, mean(edges(b:b+1)), numel(values), ...
        median(chiValues), median(values), percentile(values,25), ...
        percentile(values,75), mean(values > 0)];
end
summary = array2table(rows, 'VariableNames', ...
    {'Bin','ChiCentre','Count','MedianChi','MedianGb_dB', ...
    'Q25Gb_dB','Q75Gb_dB','PositiveFraction'});
end

function reference = load_reference_if_available(csvFile)
reference = table();
if ~exist(csvFile, 'file')
    return
end
candidate = readtable(csvFile, 'TextType', 'string');
required = {'Source','Chi','Gb_dB'};
if ~all(ismember(required, candidate.Properties.VariableNames))
    warning('Reference CSV is missing Source, Chi, or Gb_dB.');
    return
end
valid = isfinite(candidate.Chi) & isfinite(candidate.Gb_dB);
reference = candidate(valid,:);
end

function fig = plot_results(raw, summary, reference, representative, cfg)
fig = figure('Visible', cfg.output.figureVisible, 'Color', 'w', ...
    'Position', [80 80 1240 850]);
tiledlayout(2,2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
for i = 1:height(raw)
    plot([1 2], [raw.PreRcs_dBsm(i),raw.CurlRcs_dBsm(i)], '-', ...
        'Color', [0.82 0.82 0.82], 'LineWidth', 0.55, ...
        'HandleVisibility', 'off');
end
hG0 = scatter(ones(height(raw),1), raw.PreRcs_dBsm, 23, ...
    [0.35 0.35 0.35], 'filled', 'MarkerFaceAlpha', 0.55, ...
    'DisplayName', 'G0 no-curl');
hG1 = scatter(2*ones(height(raw),1), raw.CurlRcs_dBsm, 26, raw.Chi, ...
    'filled', 'MarkerFaceAlpha', 0.72, 'DisplayName', 'G1 with-curl');
medianValues = [median(raw.PreRcs_dBsm), median(raw.CurlRcs_dBsm)];
q25 = [percentile(raw.PreRcs_dBsm,25), percentile(raw.CurlRcs_dBsm,25)];
q75 = [percentile(raw.PreRcs_dBsm,75), percentile(raw.CurlRcs_dBsm,75)];
hMedian = errorbar([1 2], medianValues, medianValues-q25, q75-medianValues, ...
    'kd', 'LineWidth', 1.6, 'MarkerFaceColor', 'w', ...
    'DisplayName', 'Median and IQR');
xlim([0.65 2.35]); xticks([1 2]);
xticklabels({'G0: no curl','G1: with curl'});
ylabel('Integrated local RCS proxy (dBsm)');
title('(a) Strictly Paired Local Response'); grid on;
cb = colorbar; cb.Label.String = '\chi'; cb.Color = 'k';
lgd = legend([hG0,hG1,hMedian], 'Location','northwest');
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
style_axes(gca);

nexttile;
scatter(raw.Chi, raw.Gb_dB, 25, [0.22 0.46 0.72], 'filled', ...
    'MarkerFaceAlpha', 0.45, 'DisplayName', 'Model samples'); hold on;
validBins = summary.Count > 0;
errorbar(summary.MedianChi(validBins), summary.MedianGb_dB(validBins), ...
    summary.MedianGb_dB(validBins)-summary.Q25Gb_dB(validBins), ...
    summary.Q75Gb_dB(validBins)-summary.MedianGb_dB(validBins), ...
    'ko-', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', ...
    'DisplayName', 'Model median and IQR');
yline(0, '--', ...
    'Color', [0.35 0.35 0.35], 'LineWidth', 1.2, ...
    'DisplayName', 'G0: G_b = 0 dB');
if ~isempty(reference)
    sources = unique(reference.Source, 'stable');
    for i = 1:numel(sources)
        use = reference.Source == sources(i);
        plot(reference.Chi(use), reference.Gb_dB(use), '--s', ...
            'LineWidth', 1.3, 'DisplayName', char(sources(i)));
    end
    lgd = legend('show', 'Location','best');
else
    lgd = legend('show', 'Location','best');
    text(0.97, 0.08, 'Literature curve not digitized', ...
        'Units','normalized', 'HorizontalAlignment','right', ...
        'Color',[0.55 0.15 0.15], 'FontAngle','italic', ...
        'FontSize',10);
end
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
xlabel('Continuous morphology control \chi'); ylabel('G_b (dB)');
title('(b) Enhancement Versus Curl Control'); grid on;
style_axes(gca);

nexttile;
plot_representative_section(representative, cfg);

nexttile;
plot_scattering_profile(representative, cfg);

heading = sgtitle(sprintf(['Local curl dual-metric validation | %.1f GHz metadata, ', ...
    '%.1f deg grazing | fixed facet-RCS proxy'], ...
    cfg.radar.frequencyGHz, cfg.radar.grazingAngleDeg));
heading.Color = 'k';
end

function plot_representative_section(representative, cfg)
surfaceData = representative.surfaceData;
stripWidth = 0.55*max(surfaceData.cfg.domain.dx, ...
    surfaceData.cfg.domain.dy);
strip = abs(surfaceData.localV) <= stripWidth;
[uPre, order] = sort(surfaceData.localU(strip));
zPre = surfaceData.Z0(strip);
uCurl = surfaceData.localUFinal(strip);
zCurl = surfaceData.Z(strip);

plot(uPre, zPre(order), '-', 'Color', [0.3 0.3 0.3], ...
    'LineWidth', 1.3, 'DisplayName', 'G0 no-curl'); hold on;
plot(uCurl(order), zCurl(order), 'r-', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('G1 with-curl, \\chi = %.2f', ...
    representative.chi));
xlim(0.5*cfg.window.propagationLength*[-1 1]);
xlabel('Propagation coordinate u (m)'); ylabel('Surface height z (m)');
title('(c) What Geometry Was Changed'); grid on;
lgd = legend('show','Location','best');
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
yl = ylim;
verticalSpan = yl(2)-yl(1);
quiver(1.25, yl(2)-0.08*verticalSpan, -0.45, 0, 0, ...
    'Color',[0.1 0.1 0.1], 'LineWidth',1.3, 'MaxHeadSize',0.7, ...
    'HandleVisibility','off');
text(1.27, yl(2)-0.08*verticalSpan, 'Radar look', ...
    'HorizontalAlignment','left', 'VerticalAlignment','middle', ...
    'Color','k');
style_axes(gca);
end

function plot_scattering_profile(representative, cfg)
u = representative.pair.mapU;
pre = representative.pair.pre.rcsLinear;
curl = representative.pair.curl.rcsLinear;
edges = linspace(-0.5*cfg.window.propagationLength, ...
    0.5*cfg.window.propagationLength, 65);
bin = discretize(u, edges);
valid = ~isnan(bin);
preSum = accumarray(bin(valid), pre(valid), [numel(edges)-1 1], @sum, 0);
curlSum = accumarray(bin(valid), curl(valid), [numel(edges)-1 1], @sum, 0);
centres = 0.5*(edges(1:end-1)+edges(2:end));
floorValue = max([preSum;curlSum])*1e-8;
pre_dB = 10*log10(max(preSum,floorValue));
curl_dB = 10*log10(max(curlSum,floorValue));

plot(centres, pre_dB, '-', 'Color', [0.3 0.3 0.3], ...
    'LineWidth', 1.4, 'DisplayName', 'G0 no-curl'); hold on;
plot(centres, curl_dB, 'r-', 'LineWidth', 1.7, ...
    'DisplayName', 'G1 with-curl');
xlabel('Propagation coordinate u (m)');
ylabel('Crestwise-integrated facet RCS proxy (dBsm)');
title(sprintf('(d) Where the Added Response Occurs, G_b = %.2f dB', ...
    representative.pair.Gb_dB));
grid on;
lgd = legend('show','Location','best');
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
style_axes(gca);
end

function style_axes(ax)
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'ZColor', 'k', 'GridColor', [0.75 0.75 0.75], ...
    'MinorGridColor', [0.85 0.85 0.85], 'FontName', 'Times New Roman', ...
    'FontSize', 11, 'LineWidth', 0.8);
ax.Title.Color = 'k';
ax.XLabel.Color = 'k';
ax.YLabel.Color = 'k';
end

function directory = locate_curl_generator(thisDir)
candidates = {fullfile(thisDir, '..', 'Curl'), ...
    fullfile(thisDir, '..', '..', 'Curl')};
for i = 1:numel(candidates)
    candidate = candidates{i};
    if exist(fullfile(candidate, ...
            'generate_elfouhaily_ideal_curl_surface.m'), 'file')
        directory = candidate;
        return
    end
end
error('Cannot locate the sibling Curl generator directory.');
end

function merged = merge_struct(base, override)
merged = base;
names = fieldnames(override);
for i = 1:numel(names)
    name = names{i};
    if isfield(merged, name) && isstruct(merged.(name)) ...
            && isstruct(override.(name))
        merged.(name) = merge_struct(merged.(name), override.(name));
    else
        merged.(name) = override.(name);
    end
end
end

function value = percentile(values, p)
values = sort(values(isfinite(values)));
if isempty(values)
    value = NaN;
    return
end
position = 1+(numel(values)-1)*p/100;
lowerIndex = floor(position);
upperIndex = ceil(position);
weight = position-lowerIndex;
value = values(lowerIndex)*(1-weight)+values(upperIndex)*weight;
end
