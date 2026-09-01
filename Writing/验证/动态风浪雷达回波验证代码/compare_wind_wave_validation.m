function results = compare_wind_wave_validation(cfg)
%COMPARE_WIND_WAVE_VALIDATION Three-group wind-wave echo validation.
% Theoretical distributions are fitted after echo generation; none of them
% is used to synthesize Linear or Proposed data.

arguments
    cfg (1,1) struct = wind_wave_validation_config()
end

validate_inputs(cfg);
if ~isfolder(cfg.paths.outputDir)
    mkdir(cfg.paths.outputDir);
end

loadedLinear = load(cfg.paths.linearFile, 'linearEcho');
loadedProposed = load(cfg.paths.proposedFile, 'proposedEcho');
linearEcho = loadedLinear.linearEcho;
proposedEcho = loadedProposed.proposedEcho;
clear loadedLinear loadedProposed;

[measuredEcho, measuredMeta] = load_matching_measured_echo( ...
    cfg, linearEcho, proposedEcho);

numberOfPulses = min([size(linearEcho.echo,1), ...
    size(proposedEcho.echo,1), size(measuredEcho,1)]);
numberOfRanges = min([size(linearEcho.echo,2), ...
    size(proposedEcho.echo,2), size(measuredEcho,2)]);

linearRaw = single(linearEcho.echo(1:numberOfPulses,1:numberOfRanges));
proposedRaw = single(proposedEcho.echo(1:numberOfPulses,1:numberOfRanges));
measuredRaw = single(measuredEcho(1:numberOfPulses,1:numberOfRanges));
clear measuredEcho;

rangeMeters = double(linearEcho.rangeMeters(1:numberOfRanges));
slowTimeS = double(linearEcho.slowTimeS(1:numberOfPulses));
fitRangeMask = rangeMeters >= cfg.analysis.fitRangeLimitsM(1) ...
    & rangeMeters <= cfg.analysis.fitRangeLimitsM(2);
assert(nnz(fitRangeMask) >= 10, ...
    'The configured distribution-fit range gate contains too few bins.');

rng(cfg.preprocessing.randomSeed, 'twister');
absoluteTable = absolute_simulation_metrics( ...
    linearRaw(:,fitRangeMask),proposedRaw(:,fitRangeMask), ...
    cfg.preprocessing.maximumFitSamples,cfg.analysis.fitRangeLimitsM);
writetable(absoluteTable,fullfile(cfg.paths.outputDir, ...
    'absolute_linear_proposed_metrics.csv'));
plot_absolute_simulation_rti(linearRaw, proposedRaw, rangeMeters, ...
    slowTimeS, cfg);

linearStructural = apply_theoretical_range_compensation( ...
    linearRaw,rangeMeters,cfg);
proposedStructural = apply_theoretical_range_compensation( ...
    proposedRaw,rangeMeters,cfg);
measuredStructural = apply_theoretical_range_compensation( ...
    measuredRaw,rangeMeters,cfg);
[linear, linearPreprocessing] = preprocess_echo(linearStructural, cfg);
[proposed, proposedPreprocessing] = preprocess_echo(proposedStructural, cfg);
[measured, measuredPreprocessing] = preprocess_echo(measuredStructural, cfg);
clear linearStructural proposedStructural measuredStructural;
[temporalTable,correlationDiagnostics] = temporal_continuity_metrics( ...
    {linearRaw(:,fitRangeMask),proposedRaw(:,fitRangeMask), ...
    measuredRaw(:,fitRangeMask)}, ...
    {'Linear','Proposed','Measured'},slowTimeS,rangeMeters(fitRangeMask));
writetable(temporalTable,fullfile(cfg.paths.outputDir, ...
    'echo_temporal_continuity_metrics.csv'));
plot_correlation_diagnostics(correlationDiagnostics, ...
    {'Linear','Proposed','Measured'},cfg);
clear linearRaw proposedRaw measuredRaw;

groupNames = {'Linear','Proposed','Measured'};
echoGroups = {linear, proposed, measured};

plot_rti_comparison(echoGroups, groupNames, rangeMeters, slowTimeS, cfg);

rng(cfg.preprocessing.randomSeed, 'twister');
samples = cell(1,3);
for groupIndex = 1:3
    samples{groupIndex} = select_amplitude_samples( ...
        echoGroups{groupIndex}(:,fitRangeMask), ...
        cfg.preprocessing.maximumFitSamples);
end
clear linear proposed measured echoGroups;

plot_empirical_comparison(samples, groupNames, cfg);

allFits = cell(3, numel(cfg.fitting.models));
fitRows = cell(0,8);
for groupIndex = 1:3
    for modelIndex = 1:numel(cfg.fitting.models)
        fitResult = fit_amplitude_model(samples{groupIndex}, ...
            cfg.fitting.models{modelIndex}, cfg);
        allFits{groupIndex,modelIndex} = fitResult;
        fitRows(end+1,:) = { ...
            groupNames{groupIndex}, fitResult.model, ...
            parameter_text(fitResult), fitResult.KS, ...
            fitResult.pdfRmse, fitResult.logLikelihood, ...
            fitResult.AIC, fitResult.BIC}; %#ok<AGROW>
    end
end

fitTable = cell2table(fitRows, 'VariableNames', { ...
    'Group','Distribution','Parameters','KS','PDF_RMSE', ...
    'LogLikelihood','AIC','BIC'});
writetable(fitTable, fullfile(cfg.paths.outputDir, ...
    'distribution_fit_metrics.csv'));

plot_model_fits(samples, groupNames, allFits, cfg);

heavyTailTable = heavy_tail_diagnostics( ...
    samples, groupNames, allFits, cfg);
writetable(heavyTailTable,fullfile(cfg.paths.outputDir, ...
    'heavy_tail_diagnostics.csv'));

directTable = direct_measured_comparison(samples, groupNames, cfg);
writetable(directTable, fullfile(cfg.paths.outputDir, ...
    'simulation_vs_measured_metrics.csv'));

results.groupNames = groupNames;
results.rangeMeters = rangeMeters;
results.slowTimeS = slowTimeS;
results.fitRangeLimitsM = cfg.analysis.fitRangeLimitsM;
results.fitRangeMask = fitRangeMask;
results.measuredMeta = measuredMeta;
results.preprocessing.linear = linearPreprocessing;
results.preprocessing.proposed = proposedPreprocessing;
results.preprocessing.measured = measuredPreprocessing;
results.fitTable = fitTable;
results.directComparisonTable = directTable;
results.absoluteSimulationTable = absoluteTable;
results.temporalContinuityTable = temporalTable;
results.correlationDiagnostics = correlationDiagnostics;
results.heavyTailTable = heavyTailTable;
results.fits = allFits;
results.amplitudeSamples.linear = single(samples{1});
results.amplitudeSamples.proposed = single(samples{2});
results.amplitudeSamples.measured = single(samples{3});
results.cfg = cfg;
save(fullfile(cfg.paths.outputDir, 'rti_distribution_results.mat'), ...
    'results', '-v7.3');

fprintf('\nDistribution-fit metrics:\n');
disp(fitTable);
fprintf('\nDirect simulation-to-measured metrics:\n');
disp(directTable);
fprintf('\nAbsolute Linear/Proposed metrics (common simulation scale):\n');
disp(absoluteTable);
fprintf('\nHeavy-tail diagnostics after global RMS normalization:\n');
disp(heavyTailTable);
end

function validate_inputs(cfg)
required = {cfg.paths.measuredFile, cfg.paths.linearFile, ...
    cfg.paths.proposedFile};
for index = 1:numel(required)
    assert(isfile(required{index}), 'Required file not found: %s', required{index});
end
assert(cfg.preprocessing.maximumFitSamples >= 1000, ...
    'maximumFitSamples must be at least 1000.');
assert(diff(cfg.analysis.fitRangeLimitsM) > 0, ...
    'fitRangeLimitsM must be increasing.');
end

function [echo, meta] = load_matching_measured_echo(cfg, linear, proposed)
assert(strcmp(linear.orientation, 'pulse_by_range'), ...
    'Linear echo orientation must be pulse_by_range.');
assert(strcmp(proposed.orientation, 'pulse_by_range'), ...
    'Proposed echo orientation must be pulse_by_range.');

loaded = load(cfg.paths.measuredFile, cfg.paths.measuredVariable, ...
    'amplitude_complex_info');
rawEcho = loaded.(cfg.paths.measuredVariable);
info = double(loaded.amplitude_complex_info);
clear loaded;

if strcmp(cfg.paths.measuredVariable, 'amplitude_complex_T1')
    firstRangeM = info(1,11)*1000;
elseif strcmp(cfg.paths.measuredVariable, 'amplitude_complex_T2')
    firstRangeM = info(1,12)*1000;
else
    error('Measured variable must be amplitude_complex_T1 or T2.');
end
samplingRateHz = median(info(:,10),'omitnan')*1e6;
rangeSpacingM = linear.cfg.radar.c/(2*samplingRateHz);
allRangesM = firstRangeM+(0:size(rawEcho,2)-1)*rangeSpacingM;
targetRangesM = double(linear.rangeMeters(:).');

nearestIndex = round((targetRangesM-firstRangeM)/rangeSpacingM)+1;
assert(all(nearestIndex >= 1 & nearestIndex <= size(rawEcho,2)), ...
    'Simulation range interval is outside measured data.');
rangeMismatch = max(abs(allRangesM(nearestIndex)-targetRangesM));
assert(rangeMismatch <= 0.51*rangeSpacingM, ...
    'Simulation and measured range grids do not align.');

numberOfPulses = min([size(rawEcho,1), size(linear.echo,1), ...
    size(proposed.echo,1)]);
echo = rawEcho(1:numberOfPulses, nearestIndex);
clear rawEcho;

meta.sourceFile = cfg.paths.measuredFile;
meta.variable = cfg.paths.measuredVariable;
meta.numberOfPulses = numberOfPulses;
meta.rangeIndices = nearestIndex;
meta.rangeMeters = allRangesM(nearestIndex);
meta.rangeMismatchM = rangeMismatch;
meta.prfHz = median(info(:,26),'omitnan');
meta.bearingStartDeg = info(1,9);
meta.bearingEndDeg = info(numberOfPulses,9);
meta.stcCode = info(1,21);
meta.scanModeCode = info(1,22);
end

function [echo, diagnostics] = preprocess_echo(echo, cfg)
invalid = ~isfinite(real(echo)) | ~isfinite(imag(echo));
echo(invalid) = 0;

rangeRmsBefore = sqrt(mean(abs(echo).^2,1));
validRange = rangeRmsBefore > 0 & isfinite(rangeRmsBefore);
assert(any(validRange), 'Echo contains no valid range bins.');

if cfg.preprocessing.removeRangeEnvelope
    echo(:,validRange) = echo(:,validRange) ...
        ./ rangeRmsBefore(validRange);
end
echo(:,~validRange) = 0;

overallRms = sqrt(mean(abs(echo(:,validRange)).^2,'all'));
echo = echo/max(overallRms,realmin('single'));

diagnostics.invalidSampleCount = nnz(invalid);
diagnostics.validRangeFraction = mean(validRange);
diagnostics.rangeRmsBefore = rangeRmsBefore;
diagnostics.removedRangeEnvelope = cfg.preprocessing.removeRangeEnvelope;
diagnostics.finalRms = sqrt(mean(abs(echo(:,validRange)).^2,'all'));
end

function echo = apply_theoretical_range_compensation(echo,rangeMeters,cfg)
if ~cfg.preprocessing.applyTheoreticalRangeCompensation
    return;
end
referenceRangeM = sqrt(prod(cfg.analysis.fitRangeLimitsM));
amplitudeFactor = (rangeMeters/referenceRangeM).^2;
echo = echo.*single(amplitudeFactor);
end

function tableOut = absolute_simulation_metrics( ...
    linear,proposed,maximumCount,rangeLimitsM)
groups = {linear,proposed};
names = {'Linear','Proposed'};
sampleCount = min(numel(linear),maximumCount);
sampleIndex = randi(numel(linear),sampleCount,1);
rows = cell(2,10);
for index = 1:2
    amplitude = abs(groups{index});
    sample = double(amplitude(sampleIndex));
    rows(index,:) = {names{index},rangeLimitsM(1),rangeLimitsM(2), ...
        mean(double(amplitude).^2,'all'), ...
        empirical_quantile(sample,0.90), ...
        empirical_quantile(sample,0.95), ...
        empirical_quantile(sample,0.99), ...
        empirical_quantile(sample,0.999), ...
        max(amplitude,[],'all'),NaN};
end
linearP999 = rows{1,8};
rows{1,10} = 1;
rows{2,10} = rows{2,8}/max(linearP999,realmin('double'));
tableOut = cell2table(rows,'VariableNames',{ ...
    'Simulation','RangeStartM','RangeEndM','MeanPower', ...
    'AmplitudeP90','AmplitudeP95', ...
    'AmplitudeP99','AmplitudeP999','MaximumAmplitude', ...
    'P999RatioToLinear'});
end

function [tableOut,diagnostics] = temporal_continuity_metrics( ...
    groups,names,slowTimeS,rangeMeters)
rows = cell(numel(groups),7);
blockLength = 64;
dt = median(diff(slowTimeS));
maxTimeLag = min(size(groups{1},1)-1,max(1,round(0.5/dt)));
timeLagIndex = unique([0,round(logspace(0,log10(maxTimeLag),60))]);
rangeSpacingM = median(diff(rangeMeters));
maxRangeLag = min(size(groups{1},2)-1, ...
    max(1,round(50/rangeSpacingM)));
rangeLagIndex = unique([0,round(linspace(1,maxRangeLag,40))]);
diagnostics.timeLagS = timeLagIndex*dt;
diagnostics.rangeLagM = rangeLagIndex*rangeSpacingM;
diagnostics.intensityTimeCorrelation = ...
    nan(numel(groups),numel(timeLagIndex));
diagnostics.intensityRangeCorrelation = ...
    nan(numel(groups),numel(rangeLagIndex));
for index = 1:numel(groups)
    echo = groups{index};
    echo(~isfinite(real(echo)) | ~isfinite(imag(echo))) = 0;
    rangeRms = sqrt(mean(abs(echo).^2,1));
    valid = rangeRms > 0 & isfinite(rangeRms);
    echo = echo(:,valid)./rangeRms(valid);

    previous = echo(1:end-1,:);
    current = echo(2:end,:);
    complexCorrelation = abs(sum(current.*conj(previous),'all')) ...
        / max(sqrt(sum(abs(current).^2,'all') ...
        * sum(abs(previous).^2,'all')),eps);
    intensityCorrelation = centred_correlation( ...
        abs(previous).^2,abs(current).^2);

    intensityFull = abs(echo).^2;
    temporalFluctuation = intensityFull-mean(intensityFull,1);
    for lagIndex = 1:numel(timeLagIndex)
        lag = timeLagIndex(lagIndex);
        if lag == 0
            diagnostics.intensityTimeCorrelation(index,lagIndex) = 1;
        else
            diagnostics.intensityTimeCorrelation(index,lagIndex) = ...
                centred_correlation( ...
                temporalFluctuation(1:end-lag,:), ...
                temporalFluctuation(1+lag:end,:));
        end
    end

    rangeFluctuation = intensityFull./max(mean(intensityFull,1),eps);
    rangeFluctuation = rangeFluctuation-mean(rangeFluctuation,2);
    for lagIndex = 1:numel(rangeLagIndex)
        lag = rangeLagIndex(lagIndex);
        if lag == 0
            diagnostics.intensityRangeCorrelation(index,lagIndex) = 1;
        else
            diagnostics.intensityRangeCorrelation(index,lagIndex) = ...
                centred_correlation(rangeFluctuation(:,1:end-lag), ...
                rangeFluctuation(:,1+lag:end));
        end
    end

    numberOfBlocks = floor(size(echo,1)/blockLength);
    if numberOfBlocks >= 2
        intensity = abs(echo(1:numberOfBlocks*blockLength,:)).^2;
        blockPower = squeeze(mean(reshape(intensity,blockLength, ...
            numberOfBlocks,[]),1));
        blockCv = median(std(blockPower,0,1) ...
            ./ max(mean(blockPower,1),eps),'omitnan');
    else
        blockCv = NaN;
    end
    timeAcf = diagnostics.intensityTimeCorrelation(index,:);
    correlationAt100ms = interp1(diagnostics.timeLagS,timeAcf,0.1, ...
        'linear','extrap');
    integratedTime = trapz(diagnostics.timeLagS,max(timeAcf,0));
    rangeCorrelationAt5m = interp1(diagnostics.rangeLagM, ...
        diagnostics.intensityRangeCorrelation(index,:),5, ...
        'linear','extrap');
    rows(index,:) = {names{index},complexCorrelation, ...
        intensityCorrelation,blockCv,correlationAt100ms, ...
        integratedTime,rangeCorrelationAt5m};
end
tableOut = cell2table(rows,'VariableNames',{ ...
    'Group','Lag1ComplexCorrelation','Lag1IntensityCorrelation', ...
    'Median64PulseBlockPowerCV','IntensityCorrelationAt100ms', ...
    'IntegratedCorrelationTimeS','RangeCorrelationAt5m'});
end

function plot_correlation_diagnostics(diagnostics,names,cfg)
colours = lines(3);
fig = figure('Color','w','Position',[80 80 1320 520]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
nexttile(layout);
hold on;
for index = 1:3
    semilogx(max(diagnostics.timeLagS,1e-5), ...
        diagnostics.intensityTimeCorrelation(index,:), ...
        'LineWidth',1.6,'Color',colours(index,:));
end
hold off; grid on; ylim([-0.1,1]);
xlabel('Time lag (s)'); ylabel('Intensity autocorrelation');
title('Slow-time continuity'); legend(names,'Location','northeast');

nexttile(layout);
hold on;
for index = 1:3
    plot(diagnostics.rangeLagM, ...
        diagnostics.intensityRangeCorrelation(index,:), ...
        'LineWidth',1.6,'Color',colours(index,:));
end
hold off; grid on; ylim([-0.1,1]);
xlabel('Range lag (m)'); ylabel('Intensity autocorrelation');
title('Range continuity'); legend(names,'Location','northeast');
save_figure(fig,fullfile(cfg.paths.outputDir, ...
    'temporal_range_correlation_comparison'),cfg);
end

function value = centred_correlation(a,b)
a = double(a(:));
b = double(b(:));
a = a-mean(a);
b = b-mean(b);
value = (a.'*b)/max(norm(a)*norm(b),eps);
end

function sample = select_amplitude_samples(echo, maximumCount)
amplitude = abs(echo(:));
amplitude = amplitude(isfinite(amplitude) & amplitude > 0);
assert(numel(amplitude) >= 1000, 'Too few valid amplitudes for fitting.');
if numel(amplitude) > maximumCount
    index = randi(numel(amplitude), maximumCount, 1);
    amplitude = amplitude(index);
end
amplitude = double(amplitude);
amplitude = amplitude/sqrt(mean(amplitude.^2));
sample = amplitude(:);
end

function plot_absolute_simulation_rti(linear,proposed,rangeMeters,slowTimeS,cfg)
pulseStep = max(1,ceil(numel(slowTimeS)/cfg.rti.maximumDisplayPulses));
rangeStep = max(1,ceil(numel(rangeMeters)/cfg.rti.maximumDisplayRangeBins));
pulseIndex = 1:pulseStep:numel(slowTimeS);
rangeIndex = 1:rangeStep:numel(rangeMeters);
referenceRms = sqrt(mean(abs(linear).^2,'all'));
groups = {linear,proposed};
names = {'Linear','Proposed'};

fig = figure('Color','w','Position',[50 80 1320 560]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
for index = 1:2
    nexttile(layout);
    displayDb = 20*log10(max(abs(groups{index}( ...
        pulseIndex,rangeIndex))/referenceRms,realmin('single')));
    imagesc(rangeMeters(rangeIndex)/1000,slowTimeS(pulseIndex),displayDb);
    axis xy tight;
    clim(cfg.rti.dynamicRangeDb);
    xlabel('Range (km)');
    ylabel('Slow time (s)');
    title(names{index});
end
colormap(turbo(256));
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'Amplitude relative to Linear RMS (dB)';
title(layout,['Absolute simulation RTI: one common Linear reference; ' ...
    'no per-model normalization']);
save_figure(fig,fullfile(cfg.paths.outputDir, ...
    'rti_linear_proposed_absolute_common_reference'),cfg);
end

function plot_rti_comparison(groups, names, rangeMeters, slowTimeS, cfg)
pulseStep = max(1,ceil(numel(slowTimeS)/cfg.rti.maximumDisplayPulses));
rangeStep = max(1,ceil(numel(rangeMeters)/cfg.rti.maximumDisplayRangeBins));
pulseIndex = 1:pulseStep:numel(slowTimeS);
rangeIndex = 1:rangeStep:numel(rangeMeters);

fig = figure('Color','w','Position',[30 60 1740 560]);
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
for index = 1:3
    nexttile(layout);
    displayDb = 20*log10(max(abs(groups{index}( ...
        pulseIndex,rangeIndex)),realmin('single')));
    imagesc(rangeMeters(rangeIndex)/1000, slowTimeS(pulseIndex), displayDb);
    axis xy tight;
    clim(cfg.rti.dynamicRangeDb);
    xlabel('Range (km)');
    ylabel('Slow time (s)');
    title(names{index});
end
colormap(turbo(256));
cb = colorbar;
cb.Layout.Tile = 'east';
if cfg.preprocessing.applyTheoreticalRangeCompensation
    cb.Label.String = 'R^2-compensated, globally RMS-normalized amplitude (dB)';
    title(layout,['Structural RTI: theoretical R^2 amplitude compensation; ' ...
        'no empirical per-range normalization']);
else
    cb.Label.String = 'Globally RMS-normalized amplitude (dB)';
    title(layout,['Structural RTI: one global RMS per group; ' ...
        'no per-range normalization']);
end
save_figure(fig, fullfile(cfg.paths.outputDir, ...
    'rti_linear_proposed_measured'), cfg);
end

function plot_empirical_comparison(samples, names, cfg)
colours = lines(3);
upper = max(cellfun(@(x) empirical_quantile(x,0.9995),samples));
xGrid = linspace(0,upper,cfg.fitting.curvePointCount);
edges = linspace(0,upper,cfg.fitting.histogramBinCount+1);
centres = 0.5*(edges(1:end-1)+edges(2:end));

fig = figure('Color','w','Position',[80 80 1320 520]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
nexttile(layout);
hold on;
for index = 1:3
    density = histcounts(samples{index},edges,'Normalization','pdf');
    plot(centres,density,'LineWidth',1.6,'Color',colours(index,:));
end
hold off; grid on;
xlabel('RMS-normalized amplitude'); ylabel('PDF');
title('Empirical amplitude PDF'); legend(names,'Location','northeast');

nexttile(layout);
hold on;
for index = 1:3
    survival = 1-empirical_cdf_at(samples{index},xGrid);
    semilogy(xGrid,max(survival,1/numel(samples{index})), ...
        'LineWidth',1.6,'Color',colours(index,:));
end
hold off; grid on;
xlabel('RMS-normalized amplitude'); ylabel('CCDF');
title('Empirical amplitude tail'); legend(names,'Location','southwest');
ylim([1e-5,1]);
save_figure(fig, fullfile(cfg.paths.outputDir, ...
    'empirical_pdf_ccdf_comparison'), cfg);
end

function fitResult = fit_amplitude_model(sample, modelName, cfg)
x = max(double(sample(:)),1e-10);
switch lower(modelName)
    case 'rayleigh'
        sigma = sqrt(mean(x.^2)/2);
        parameters = sigma;
        parameterNames = {'sigma'};
        logPdf = rayleigh_logpdf(x,sigma);
        parameterCount = 1;
    case 'weibull'
        initial = log([1.5,mean(x)]);
        objective = @(v) bounded_weibull_nll(v,x);
        options = optimset('Display',cfg.fitting.optimizationDisplay, ...
            'MaxFunEvals',2500,'MaxIter',1200);
        solution = fminsearch(objective,initial,options);
        parameters = exp(solution);
        parameterNames = {'shape','scale'};
        logPdf = weibull_logpdf(x,parameters(1),parameters(2));
        parameterCount = 2;
    case 'log-normal'
        logX = log(x);
        mu = mean(logX);
        sigmaLog = std(logX,1);
        parameters = [mu,sigmaLog];
        parameterNames = {'muLog','sigmaLog'};
        logPdf = lognormal_logpdf(x,mu,sigmaLog);
        parameterCount = 2;
    case 'k'
        initial = log([2,mean(x.^2)]);
        objective = @(v) bounded_k_nll(v,x);
        options = optimset('Display',cfg.fitting.optimizationDisplay, ...
            'MaxFunEvals',4000,'MaxIter',1800);
        solution = fminsearch(objective,initial,options);
        parameters = exp(solution);
        parameterNames = {'nu','meanIntensity'};
        logPdf = k_amplitude_logpdf(x,parameters(1),parameters(2));
        parameterCount = 2;
    otherwise
        error('Unknown amplitude model: %s',modelName);
end

logLikelihood = sum(logPdf);
modelCdf = amplitude_model_cdf(modelName,x,parameters);
[sortedX,order] = sort(x);
sortedModelCdf = modelCdf(order);
n = numel(sortedX);
ksUpper = max(abs((1:n)'/n-sortedModelCdf));
ksLower = max(abs((0:n-1)'/n-sortedModelCdf));
KS = max(ksUpper,ksLower);

upper = empirical_quantile(x,0.9995);
edges = linspace(0,upper,cfg.fitting.histogramBinCount+1);
centres = 0.5*(edges(1:end-1)+edges(2:end));
empiricalPdf = histcounts(x,edges,'Normalization','pdf');
modelPdf = amplitude_model_pdf(modelName,centres,parameters);
pdfRmse = sqrt(mean((empiricalPdf-modelPdf).^2));

fitResult.model = modelName;
fitResult.parameterNames = parameterNames;
fitResult.parameters = parameters;
fitResult.logLikelihood = logLikelihood;
fitResult.KS = KS;
fitResult.pdfRmse = pdfRmse;
fitResult.AIC = 2*parameterCount-2*logLikelihood;
fitResult.BIC = parameterCount*log(n)-2*logLikelihood;
end

function plot_model_fits(samples, names, allFits, cfg)
modelColours = lines(numel(cfg.fitting.models));
fig = figure('Color','w','Position',[20 20 1680 1280]);
layout = tiledlayout(fig,3,3,'TileSpacing','compact','Padding','compact');
for groupIndex = 1:3
    upper = empirical_quantile(samples{groupIndex},0.9995);
    xGrid = linspace(1e-6,upper,cfg.fitting.curvePointCount);
    edges = linspace(0,upper,cfg.fitting.histogramBinCount+1);
    centres = 0.5*(edges(1:end-1)+edges(2:end));

    nexttile(layout);
    density = histcounts(samples{groupIndex},edges,'Normalization','pdf');
    plot(centres,density,'k','LineWidth',1.5); hold on;
    for modelIndex = 1:numel(cfg.fitting.models)
        fit = allFits{groupIndex,modelIndex};
        plot(xGrid,amplitude_model_pdf(fit.model,xGrid,fit.parameters), ...
            'LineWidth',1.2,'Color',modelColours(modelIndex,:));
    end
    hold off; grid on;
    xlabel('Amplitude'); ylabel('PDF'); title([names{groupIndex} ' PDF']);
    if groupIndex == 1
        legend([{'Empirical'},cfg.fitting.models], ...
            'Location','northeast','FontSize',8);
    end

    nexttile(layout);
    empiricalCdf = empirical_cdf_at(samples{groupIndex},xGrid);
    plot(xGrid,empiricalCdf,'k','LineWidth',1.5); hold on;
    for modelIndex = 1:numel(cfg.fitting.models)
        fit = allFits{groupIndex,modelIndex};
        plot(xGrid,amplitude_model_cdf(fit.model,xGrid,fit.parameters), ...
            'LineWidth',1.2,'Color',modelColours(modelIndex,:));
    end
    hold off; grid on;
    xlabel('Amplitude'); ylabel('CDF'); title([names{groupIndex} ' CDF']);

    nexttile(layout);
    semilogy(xGrid,max(1-empiricalCdf,1/numel(samples{groupIndex})), ...
        'k','LineWidth',1.5); hold on;
    for modelIndex = 1:numel(cfg.fitting.models)
        fit = allFits{groupIndex,modelIndex};
        modelCdf = amplitude_model_cdf(fit.model,xGrid,fit.parameters);
        semilogy(xGrid,max(1-modelCdf,1e-8), ...
            'LineWidth',1.2,'Color',modelColours(modelIndex,:));
    end
    hold off; grid on; ylim([1e-5,1]);
    xlabel('Amplitude'); ylabel('CCDF'); title([names{groupIndex} ' CCDF']);
end
title(layout,'Amplitude-distribution fits');
save_figure(fig,fullfile(cfg.paths.outputDir,'amplitude_distribution_fits'),cfg);
end

function tableOut = heavy_tail_diagnostics(samples,names,allFits,cfg)
weibullIndex = find(strcmpi(cfg.fitting.models,'Weibull'),1);
kIndex = find(strcmpi(cfg.fitting.models,'K'),1);
assert(~isempty(weibullIndex) && ~isempty(kIndex), ...
    'Heavy-tail diagnostics require Weibull and K fits.');
rows = cell(3,9);
for index = 1:3
    weibullShape = allFits{index,weibullIndex}.parameters(1);
    kNu = allFits{index,kIndex}.parameters(1);
    q99 = empirical_quantile(samples{index},0.99);
    q999 = empirical_quantile(samples{index},0.999);
    kAtRayleighLimit = kNu >= cfg.fitting.rayleighLimitNu;
    weibullRayleighLike = abs(weibullShape-2) <= ...
        cfg.fitting.rayleighLikeWeibullTolerance;
    heavyTailEvidence = ~kAtRayleighLimit ...
        && weibullShape < 2-cfg.fitting.rayleighLikeWeibullTolerance;
    rows(index,:) = {names{index},weibullShape,kNu, ...
        kAtRayleighLimit,weibullRayleighLike,heavyTailEvidence, ...
        q99,q999,mean(samples{index} > 2)};
end
tableOut = cell2table(rows,'VariableNames',{ ...
    'Group','WeibullShape','KShapeNu','KAtRayleighLimit', ...
    'WeibullRayleighLike','HeavyTailEvidence', ...
    'NormalizedAmplitudeP99', ...
    'NormalizedAmplitudeP999','ProbabilityAbove2RMS'});
end

function tableOut = direct_measured_comparison(samples,names,cfg)
measured = samples{3};
rows = cell(2,7);
threshold99 = empirical_quantile(measured,0.99);
for index = 1:2
    simulated = samples{index};
    ks = two_sample_ks(simulated,measured);
    wasserstein = wasserstein_distance(simulated,measured, ...
        cfg.fitting.quantilePointCount);
    [tailRmse,tailCount] = ccdf_tail_error(simulated,measured,cfg);
    q99Simulated = empirical_quantile(simulated,0.99);
    q99Measured = threshold99;
    q99RelativeError = (q99Simulated-q99Measured)/q99Measured;
    spikeProbability = mean(simulated > threshold99);
    spikeProbabilityError = spikeProbability-0.01;
    rows(index,:) = {names{index},ks,wasserstein,tailRmse,tailCount, ...
        q99RelativeError,spikeProbabilityError};
end
tableOut = cell2table(rows,'VariableNames',{ ...
    'Simulation','TwoSampleKS','Wasserstein','LogCCDF_RMSE', ...
    'TailGridCount','Q99_RelativeError','SpikeProbabilityError'});
end

function [rmse,count] = ccdf_tail_error(simulated,measured,cfg)
upper = empirical_quantile(measured,0.9999);
xGrid = linspace(empirical_quantile(measured,0.85),upper,400);
measuredCcdf = 1-empirical_cdf_at(measured,xGrid);
simulatedCcdf = 1-empirical_cdf_at(simulated,xGrid);
mask = measuredCcdf >= cfg.fitting.tailProbabilityRange(1) ...
    & measuredCcdf <= cfg.fitting.tailProbabilityRange(2);
count = nnz(mask);
if count == 0
    rmse = NaN;
else
    floorProbability = 1/max(numel(measured),numel(simulated));
    difference = log10(max(simulatedCcdf(mask),floorProbability)) ...
        - log10(max(measuredCcdf(mask),floorProbability));
    rmse = sqrt(mean(difference.^2));
end
end

function value = two_sample_ks(a,b)
grid = unique(sort([a(:);b(:)]));
Fa = empirical_cdf_at(a,grid);
Fb = empirical_cdf_at(b,grid);
value = max(abs(Fa-Fb));
end

function value = wasserstein_distance(a,b,numberOfPoints)
p = linspace(0.0005,0.9995,numberOfPoints);
qa = empirical_quantile(a,p);
qb = empirical_quantile(b,p);
value = mean(abs(qa-qb));
end

function text = parameter_text(fitResult)
parts = strings(1,numel(fitResult.parameters));
for index = 1:numel(parts)
    parts(index) = sprintf('%s=%.6g',fitResult.parameterNames{index}, ...
        fitResult.parameters(index));
end
text = strjoin(parts,'; ');
end

function nll = bounded_weibull_nll(v,x)
shape = exp(v(1)); scale = exp(v(2));
if shape < 0.05 || shape > 50 || scale < 0.01 || scale > 100
    nll = 1e100; return;
end
logPdf = weibull_logpdf(x,shape,scale);
if any(~isfinite(logPdf))
    nll = 1e100;
else
    nll = -sum(logPdf);
end
end

function nll = bounded_k_nll(v,x)
nu = exp(v(1)); meanIntensity = exp(v(2));
if nu < 0.05 || nu > 100 || meanIntensity < 0.01 || meanIntensity > 100
    nll = 1e100; return;
end
logPdf = k_amplitude_logpdf(x,nu,meanIntensity);
if any(~isfinite(logPdf))
    nll = 1e100;
else
    nll = -sum(logPdf);
end
end

function y = rayleigh_logpdf(x,sigma)
y = log(x)-2*log(sigma)-x.^2/(2*sigma^2);
end

function y = weibull_logpdf(x,shape,scale)
y = log(shape)-log(scale)+(shape-1).*(log(x)-log(scale)) ...
    -(x/scale).^shape;
end

function y = lognormal_logpdf(x,mu,sigma)
y = -log(x)-log(sigma)-0.5*log(2*pi) ...
    -0.5*((log(x)-mu)/sigma).^2;
end

function y = k_amplitude_logpdf(x,nu,meanIntensity)
b = sqrt(nu/meanIntensity);
z = max(2*b*x,1e-12);
scaledK = besselk(nu-1,z,1);
logK = log(max(scaledK,realmin('double')))-z;
y = log(4)+(nu+1)*log(b)+nu*log(x)-gammaln(nu)+logK;
end

function pdf = amplitude_model_pdf(model,x,parameters)
x = max(double(x),1e-12);
switch lower(model)
    case 'rayleigh'
        pdf = exp(rayleigh_logpdf(x,parameters(1)));
    case 'weibull'
        pdf = exp(weibull_logpdf(x,parameters(1),parameters(2)));
    case 'log-normal'
        pdf = exp(lognormal_logpdf(x,parameters(1),parameters(2)));
    case 'k'
        pdf = exp(k_amplitude_logpdf(x,parameters(1),parameters(2)));
end
pdf(~isfinite(pdf)) = 0;
end

function cdf = amplitude_model_cdf(model,x,parameters)
x = max(double(x),0);
switch lower(model)
    case 'rayleigh'
        cdf = 1-exp(-x.^2/(2*parameters(1)^2));
    case 'weibull'
        cdf = 1-exp(-(x/parameters(2)).^parameters(1));
    case 'log-normal'
        positiveX = max(x,realmin('double'));
        cdf = 0.5*(1+erf((log(positiveX)-parameters(1)) ...
            /(parameters(2)*sqrt(2))));
        cdf(x == 0) = 0;
    case 'k'
        nu = parameters(1); meanIntensity = parameters(2);
        b = sqrt(nu/meanIntensity);
        z = max(2*b*x,1e-12);
        scaledK = besselk(nu,z,1);
        logSurvival = log(2)-gammaln(nu) ...
            + nu*log(max(b*x,realmin('double'))) ...
            + log(max(scaledK,realmin('double')))-z;
        survival = exp(min(logSurvival,0));
        survival(x == 0) = 1;
        cdf = 1-survival;
end
cdf = min(max(real(cdf),0),1);
end

function cdf = empirical_cdf_at(sample,x)
sorted = sort(sample(:));
queryShape = size(x);
query = x(:);
[uniqueValues,~,groupIndex] = unique(sorted);
cumulativeCounts = cumsum(accumarray(groupIndex,1));

if isscalar(uniqueValues)
    indices = numel(sorted) * double(query >= uniqueValues);
else
    indices = interp1(uniqueValues,cumulativeCounts,query, ...
        'previous','extrap');
    indices(query < uniqueValues(1)) = 0;
    indices(query >= uniqueValues(end)) = numel(sorted);
end
cdf = reshape(indices/numel(sorted),queryShape);
end

function q = empirical_quantile(sample,p)
sorted = sort(sample(:));
pShape = size(p);
p = min(max(p(:),0),1);
position = 1+p*(numel(sorted)-1);
lower = floor(position);
upper = ceil(position);
weight = position-lower;
q = sorted(lower).*(1-weight)+sorted(upper).*weight;
q = reshape(q,pShape);
end

function save_figure(fig,basePath,cfg)
exportgraphics(fig,[basePath '.png'],'Resolution',200);
if cfg.output.savePdf
    exportgraphics(fig,[basePath '.pdf'],'ContentType','vector');
end
close(fig);
end
