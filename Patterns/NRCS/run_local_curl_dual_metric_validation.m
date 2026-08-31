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
digitized = load_digitized_reference(cfg.output.referenceCsv);
fig = plot_results(raw, summary, reference, digitized, cfg);

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
fprintf('  literature Gb   : median %.3f dB, range [%.3f, %.3f] dB\n', ...
    median(reference.Gb_dB), min(reference.Gb_dB), max(reference.Gb_dB));
fprintf('  median difference: %.3f dB (model minus literature)\n', ...
    median(raw.Gb_dB)-median(reference.Gb_dB));
fprintf('  result directory: %s\n', cfg.output.directory);
if isempty(reference)
    fprintf(['  literature CSV  : not populated; current figures validate ', ...
        'the paired model response only.\n']);
end

results = struct('raw', raw, 'summary', summary, ...
    'reference', reference, 'digitized', digitized, ...
    'cfg', cfg, 'figure', fig);
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
candidate = readtable(csvFile, 'TextType', 'string', 'Delimiter', ',');
required = {'Source','Chi','Gb_dB'};
if ~all(ismember(required, candidate.Properties.VariableNames))
    warning('Reference CSV is missing Source, Chi, or Gb_dB.');
    return
end
valid = isfinite(candidate.Chi) & isfinite(candidate.Gb_dB);
reference = candidate(valid,:);
end

function digitized = load_digitized_reference(referenceCsv)
digitizedFile = fullfile(fileparts(referenceCsv), 'digitized', ...
    'Kim_Johnson_2002_Fig8a_HH.csv');
assert(exist(digitizedFile, 'file') == 2, ...
    'Missing audited digitized reference: %s', digitizedFile);
digitized = readtable(digitizedFile, 'TextType', 'string', 'Delimiter', ',');
end

function fig = plot_results(raw, summary, reference, digitized, cfg)
fig = figure('Visible', cfg.output.figureVisible, 'Color', 'w', ...
    'Position', [80 80 1250 500]);
tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
yl = [-33 -10];
patch([8.5 16.5 16.5 8.5], [yl(1) yl(1) yl(2) yl(2)], ...
    [0.94 0.88 0.80], 'EdgeColor', 'none', 'FaceAlpha', 0.55, ...
    'DisplayName', 'Breaking stages (waves 9-16)');
hCurve = plot(digitized.Wave, digitized.DominantPath_dB, 'ko-', ...
    'LineWidth', 1.5, 'MarkerFaceColor', 'w', ...
    'DisplayName', 'Digitized dominant-path magnitude');
preReference = median(digitized.DominantPath_dB(1:8));
hPre = yline(preReference, '--', 'Color', [0.25 0.45 0.68], ...
    'LineWidth', 1.5, 'DisplayName', ...
    sprintf('Prebreaking median: %.2f dB', preReference));
xlim([1 16]); ylim(yl); xticks([1 4 8 9 12 16]);
xlabel('LONGTANK wave stage');
ylabel('Maximum image magnitude (dB)');
title('(a) Literature Reference Extraction'); grid on;
lgd = legend([hCurve,hPre], 'Location','southeast');
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
style_axes(gca);

nexttile;
hSamples = scatter(raw.Chi, raw.Gb_dB, 25, [0.22 0.46 0.72], 'filled', ...
    'MarkerFaceAlpha', 0.45, 'DisplayName', 'Model samples'); hold on;
validBins = summary.Count > 0;
hModel = errorbar(summary.MedianChi(validBins), summary.MedianGb_dB(validBins), ...
    summary.MedianGb_dB(validBins)-summary.Q25Gb_dB(validBins), ...
    summary.Q75Gb_dB(validBins)-summary.MedianGb_dB(validBins), ...
    'ko-', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', ...
    'DisplayName', 'Model median and IQR');
assert(~isempty(reference), 'Literature reference table is empty.');
uncertainty = ones(height(reference),1);
if ismember('Uncertainty_dB', reference.Properties.VariableNames)
    uncertainty = reference.Uncertainty_dB;
end
hReference = errorbar(reference.Chi, reference.Gb_dB, uncertainty, ...
    's--', 'Color', [0.74 0.23 0.17], 'LineWidth', 1.5, ...
    'MarkerFaceColor', [1.0 0.88 0.84], ...
    'DisplayName', 'Kim and Johnson Fig. 8(a), digitized');
lgd = legend([hSamples,hModel,hReference], 'Location','southwest');
set(lgd, 'Color', 'w', 'TextColor', 'k', ...
    'EdgeColor', [0.65 0.65 0.65]);
xlabel('Normalized progression / model control'); ylabel('G_b (dB)');
title('(b) Model-to-Literature Comparison'); grid on;
style_axes(gca);

heading = sgtitle(sprintf(['Local curl scattering validation | ', ...
    'literature-derived reference and %d paired simulations'], ...
    height(raw)));
heading.Color = 'k';
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
