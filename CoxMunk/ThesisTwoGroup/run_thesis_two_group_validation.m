function [raw,summary,reference,assessment,diagnostics] = ...
    run_thesis_two_group_validation(cfg)
%RUN_THESIS_TWO_GROUP_VALIDATION Paired Elfouhaily/Lie validation suite.

arguments
    cfg (1,1) struct = default_thesis_two_group_config()
end
validate_config(cfg);
if ~isfolder(cfg.outputDirectory), mkdir(cfg.outputDirectory); end

groups = ["Linear Elfouhaily","Modified Lie Nonlinear"];
reference = two_group_mss_references(cfg.windSpeeds,cfg);
nRows = numel(cfg.windSpeeds)*numel(cfg.realizationSeeds)*2;
records = repmat(empty_record(),nRows,1);
row = 0;
examples = struct();
pdfData = struct();
clampedWinds = [];

for windIndex = 1:numel(cfg.windSpeeds)
    U10 = cfg.windSpeeds(windIndex);
    pdfKey = sprintf('U%d',U10);
    if ismember(U10,cfg.slopePdfWinds)
        pdfData.(pdfKey) = empty_pdf_data();
    end
    for seedIndex = 1:numel(cfg.realizationSeeds)
        seed = cfg.realizationSeeds(seedIndex);
        result = synthesize_two_group_realization(U10,seed,cfg);
        row = row+1;
        records(row) = make_record(result,U10,seed,groups(1),false);
        row = row+1;
        records(row) = make_record(result,U10,seed,groups(2),true);

        if result.diagnostics.shortWaveCoefficientClamped
            clampedWinds(end+1,1) = U10; %#ok<AGROW>
        end
        if seedIndex == 1 && ismember(U10,[5 10])
            examples.(pdfKey) = extract_surface_example(result);
        end
        if ismember(U10,cfg.slopePdfWinds)
            pdfData.(pdfKey) = append_pdf_data(pdfData.(pdfKey),result);
        end
        check_numerics(result,cfg,U10,seed);
    end
end
raw = struct2table(records);
summary = summarize_results(raw,groups,cfg.windSpeeds);
assessment = assess_results(summary,reference,groups);

spectralDiagnostics = run_spectral_diagnostics(cfg);
cutoffSensitivity = run_cutoff_sensitivity(cfg);
windFactorDiagnostics = run_wind_factor_diagnostics(cfg);
diagnostics.spectral = spectralDiagnostics;
diagnostics.cutoff = cutoffSensitivity;
diagnostics.windFactor = windFactorDiagnostics;
diagnostics.examples = examples;
diagnostics.pdf = pdfData;

plot_two_group_validation_outputs(summary,reference,diagnostics,cfg);
writetable(raw,fullfile(cfg.outputDirectory,'two_group_raw.csv'));
writetable(summary,fullfile(cfg.outputDirectory,'two_group_summary.csv'));
writetable(reference,fullfile(cfg.outputDirectory,'two_group_reference.csv'));
writetable(assessment,fullfile(cfg.outputDirectory,'two_group_assessment.csv'));
writetable(spectralDiagnostics, ...
    fullfile(cfg.outputDirectory,'spectral_diagnostics.csv'));
writetable(cutoffSensitivity, ...
    fullfile(cfg.outputDirectory,'cutoff_sensitivity.csv'));
writetable(windFactorDiagnostics, ...
    fullfile(cfg.outputDirectory,'wind_factor_diagnostics.csv'));
save(fullfile(cfg.outputDirectory,'two_group_validation.mat'), ...
    'raw','summary','reference','assessment','diagnostics','cfg','-v7.3');
write_two_group_validation_report(summary,reference,assessment, ...
    diagnostics,cfg);

if cfg.warnOnShortWaveClamp && ~isempty(clampedWinds)
    warning('Elfouhaily:ShortWaveCoefficientClamped', ...
        ['alpha_m was negative and clamped to zero at U10 = %s m/s. ', ...
        'The original short-wave parameterization is outside its reliable ', ...
        'low-wind range there.'],mat2str(unique(clampedWinds)'));
end
disp(assessment);
end

function record = empty_record()
record = struct('U10',0,'Seed',0,'Group',"",'MssAlong',0,'MssCross',0, ...
    'MssTotal',0,'Gamma',0,'PrimaryMssLinear',0,'PrimaryMssModified',0, ...
    'ShortWaveMss',0,'DeltaPrimaryMss',0,'DeltaTotalMss',0, ...
    'RelativeDeltaPrimaryMss',0,'RelativeDeltaTotalMss',0, ...
    'ElevationSkewness',0,'ElevationExcessKurtosis',0, ...
    'AlongSlopeSkewness',0,'AlongSlopeExcessKurtosis',0, ...
    'CrossSlopeSkewness',0,'CrossSlopeExcessKurtosis',0, ...
    'MssNumericalRelativeError',0,'HermitianResidual',0, ...
    'RieszEnergyRatio',0,'LiePreProjectionHermitianResidual',0, ...
    'DragCoefficient',0,'RawShortWaveCoefficient',0, ...
    'WindFactorMode',"",'DimensionalStatus',"");
end

function record = make_record(result,U10,seed,group,isModified)
record = empty_record();
record.U10 = U10; record.Seed = seed; record.Group = group;
if isModified
    mss = result.modifiedLie;
    stats = result.statistics.modifiedLie;
    record.MssNumericalRelativeError = ...
        result.diagnostics.modifiedMssRelativeError;
    record.HermitianResidual = result.diagnostics.modifiedHermitianResidual;
else
    mss = result.linear;
    stats = result.statistics.linear;
    record.MssNumericalRelativeError = result.diagnostics.linearMssRelativeError;
    record.HermitianResidual = result.diagnostics.linearHermitianResidual;
end
record.MssAlong = mss.along; record.MssCross = mss.cross;
record.MssTotal = mss.total; record.Gamma = mss.gamma;
record.PrimaryMssLinear = result.primaryLinear.total;
record.PrimaryMssModified = result.primaryModifiedLie.total;
record.ShortWaveMss = result.shortWave.total;
record.DeltaPrimaryMss = result.deltaPrimaryMss;
record.DeltaTotalMss = result.deltaTotalMss;
record.RelativeDeltaPrimaryMss = result.relativeDeltaPrimaryMss;
record.RelativeDeltaTotalMss = result.relativeDeltaTotalMss;
record.ElevationSkewness = stats.ElevationSkewness;
record.ElevationExcessKurtosis = stats.ElevationExcessKurtosis;
record.AlongSlopeSkewness = stats.AlongSlopeSkewness;
record.AlongSlopeExcessKurtosis = stats.AlongSlopeExcessKurtosis;
record.CrossSlopeSkewness = stats.CrossSlopeSkewness;
record.CrossSlopeExcessKurtosis = stats.CrossSlopeExcessKurtosis;
record.RieszEnergyRatio = result.diagnostics.lie.rieszEnergyRatio;
record.LiePreProjectionHermitianResidual = ...
    result.diagnostics.lie.preProjectionHermitianResidual;
record.DragCoefficient = result.diagnostics.dragCoefficient;
record.RawShortWaveCoefficient = result.diagnostics.rawShortWaveCoefficient;
record.WindFactorMode = result.diagnostics.lie.windFactorMode;
record.DimensionalStatus = result.diagnostics.lie.dimensionalStatus;
end

function pdf = empty_pdf_data()
pdf = struct('linearAlong',[],'linearCross',[],'modifiedAlong',[], ...
    'modifiedCross',[]);
end

function pdf = append_pdf_data(pdf,result)
linearAlong = result.slopeSamples.linearAlong(:);
linearCross = result.slopeSamples.linearCross(:);
modifiedAlong = result.slopeSamples.modifiedAlong(:);
modifiedCross = result.slopeSamples.modifiedCross(:);
pdf.linearAlong = [pdf.linearAlong;linearAlong];
pdf.linearCross = [pdf.linearCross;linearCross];
pdf.modifiedAlong = [pdf.modifiedAlong;modifiedAlong];
pdf.modifiedCross = [pdf.modifiedCross;modifiedCross];
end

function example = extract_surface_example(result)
example.linearSurface = result.linearSurface;
example.modifiedLieSurface = result.modifiedLieSurface;
example.primarySpacing = result.primarySpacing;
end

function summary = summarize_results(raw,groups,winds)
rows = repmat(empty_summary(),numel(groups)*numel(winds),1);
row = 0;
for group = groups
    for wind = reshape(winds,1,[])
        row = row+1;
        selected = raw.Group == group & raw.U10 == wind;
        rows(row) = make_summary(raw(selected,:),group,wind);
    end
end
summary = struct2table(rows);
end

function result = empty_summary()
result = struct('Group',"",'U10',0,'AlongMedian',0,'CrossMedian',0, ...
    'TotalMedian',0,'TotalQ05',0,'TotalQ25',0,'TotalQ75',0,'TotalQ95',0, ...
    'GammaMedian',0,'PrimaryMssLinearMedian',0, ...
    'PrimaryMssModifiedMedian',0,'ShortWaveMssMedian',0, ...
    'DeltaPrimaryMssMedian',0,'DeltaTotalMssMedian',0, ...
    'RelativeDeltaPrimaryMssMedian',0,'RelativeDeltaTotalMssMedian',0, ...
    'ElevationSkewnessMedian',0,'ElevationExcessKurtosisMedian',0, ...
    'AlongSlopeSkewnessMedian',0,'AlongSlopeExcessKurtosisMedian',0, ...
    'CrossSlopeSkewnessMedian',0,'CrossSlopeExcessKurtosisMedian',0, ...
    'MaximumMssNumericalRelativeError',0,'MaximumHermitianResidual',0, ...
    'RieszEnergyRatioMedian',0);
end

function result = make_summary(data,group,wind)
result = empty_summary(); result.Group = group; result.U10 = wind;
result.AlongMedian = median(data.MssAlong);
result.CrossMedian = median(data.MssCross);
q = local_quantile(data.MssTotal,[0.05 0.25 0.5 0.75 0.95]);
result.TotalQ05=q(1); result.TotalQ25=q(2); result.TotalMedian=q(3);
result.TotalQ75=q(4); result.TotalQ95=q(5);
result.GammaMedian = median(data.Gamma);
names = {'PrimaryMssLinear','PrimaryMssModified','ShortWaveMss', ...
    'DeltaPrimaryMss','DeltaTotalMss','RelativeDeltaPrimaryMss', ...
    'RelativeDeltaTotalMss','ElevationSkewness','ElevationExcessKurtosis', ...
    'AlongSlopeSkewness','AlongSlopeExcessKurtosis', ...
    'CrossSlopeSkewness','CrossSlopeExcessKurtosis'};
for index = 1:numel(names)
    result.([names{index},'Median']) = median(data.(names{index}));
end
result.MaximumMssNumericalRelativeError = max(data.MssNumericalRelativeError);
result.MaximumHermitianResidual = max(data.HermitianResidual);
result.RieszEnergyRatioMedian = median(data.RieszEnergyRatio);
end

function assessment = assess_results(summary,reference,groups)
Group = groups(:); n = numel(groups);
RMSE_CoxMunk = zeros(n,1); RMSE_Guerin = zeros(n,1);
RMSE_TGRS_Hu = zeros(n,1); RMSE_Elfouhaily = zeros(n,1);
MeanAbsGammaError_TGRS = zeros(n,1);
for index = 1:n
    data = sortrows(summary(summary.Group == groups(index),:),'U10');
    RMSE_CoxMunk(index) = rms_error(data.TotalMedian,reference.CoxMunkTotal);
    valid = isfinite(reference.GuerinTotal);
    RMSE_Guerin(index) = rms_error(data.TotalMedian(valid),reference.GuerinTotal(valid));
    RMSE_TGRS_Hu(index) = rms_error(data.TotalMedian,reference.TgrsHuTotal);
    RMSE_Elfouhaily(index) = rms_error(data.TotalMedian,reference.ElfouhailyTotal);
    MeanAbsGammaError_TGRS(index) = mean(abs(data.GammaMedian-reference.TgrsGamma));
end
assessment = table(Group,RMSE_CoxMunk,RMSE_Guerin,RMSE_TGRS_Hu, ...
    RMSE_Elfouhaily,MeanAbsGammaError_TGRS);
end

function tableOut = run_spectral_diagnostics(cfg)
rows = table();
for U10 = reshape(cfg.spectralDiagnosticWinds,1,[])
    accumulated = [];
    for seed = reshape(cfg.spectralDiagnosticSeeds,1,[])
        result = synthesize_two_group_realization(U10,seed,cfg);
        radial = radial_spectrum_diagnostics(result.Hlinear,result.Hmodified, ...
            result.K,result.peakWavenumber,cfg);
        if isempty(accumulated)
            accumulated = radial;
            fields = fieldnames(radial);
            for field = 2:numel(fields), accumulated.(fields{field}) = 0; end
        end
        fields = fieldnames(radial);
        for field = 2:numel(fields)
            accumulated.(fields{field}) = accumulated.(fields{field})+ ...
                radial.(fields{field});
        end
    end
    fields = fieldnames(accumulated);
    for field = 2:numel(fields)
        accumulated.(fields{field}) = accumulated.(fields{field})/ ...
            numel(cfg.spectralDiagnosticSeeds);
    end
    n = numel(accumulated.K);
    windTable = table(repmat(U10,n,1),accumulated.K, ...
        accumulated.LinearSpectrum,accumulated.ModifiedSpectrum, ...
        accumulated.LinearMssIntegrand,accumulated.ModifiedMssIntegrand, ...
        accumulated.DressingRatio,'VariableNames',{'U10','K', ...
        'LinearSpectrum','ModifiedSpectrum','LinearMssIntegrand', ...
        'ModifiedMssIntegrand','DressingRatio'});
    rows = [rows;windTable]; %#ok<AGROW>
end
tableOut = rows;
end

function tableOut = run_cutoff_sensitivity(cfg)
rows = cell(0,4);
for U10 = reshape(cfg.slopePdfWinds,1,[])
    [~,~,cumulative] = integrated_elfouhaily_mss(U10, ...
        cfg.maximumOpticalWavenumber,cfg);
    for kMaximum = reshape(cfg.opticalCutoffSweep,1,[])
        total = interp1(cumulative.K,cumulative.TotalMss,kMaximum, ...
            'linear','extrap');
        rows = [rows;{U10,"sweep",kMaximum,total}]; %#ok<AGROW>
    end
    cumulativeK = logspace(0,log10(cfg.maximumOpticalWavenumber), ...
        cfg.cutoffCumulativePoints)';
    cumulativeMss = interp1(cumulative.K,cumulative.TotalMss,cumulativeK, ...
        'linear','extrap');
    for index = 1:numel(cumulativeK)
        rows = [rows;{U10,"cumulative",cumulativeK(index), ...
            cumulativeMss(index)}]; %#ok<AGROW>
    end
end
tableOut = cell2table(rows,'VariableNames',{'U10','Series','Kmax','MssTotal'});
end

function tableOut = run_wind_factor_diagnostics(cfg)
rows = cell(0,6);
for mode = cfg.windFactorModes
    diagnosticCfg = cfg;
    diagnosticCfg.windFactorMode = mode;
    diagnosticCfg.enableSpectralUndressing = false;
    for U10 = reshape(cfg.windFactorDiagnosticWinds,1,[])
        total = zeros(numel(cfg.windFactorDiagnosticSeeds),1);
        delta = zeros(size(total)); gamma = zeros(size(total));
        deltaPrimary = zeros(size(total));
        for index = 1:numel(cfg.windFactorDiagnosticSeeds)
            result = synthesize_two_group_realization(U10, ...
                cfg.windFactorDiagnosticSeeds(index),diagnosticCfg);
            total(index) = result.modifiedLie.total;
            delta(index) = result.deltaTotalMss;
            gamma(index) = result.modifiedLie.gamma;
            deltaPrimary(index) = result.deltaPrimaryMss;
        end
        rows = [rows;{mode,U10,median(total),median(delta), ...
            median(deltaPrimary),median(gamma)}]; %#ok<AGROW>
    end
end
tableOut = cell2table(rows,'VariableNames',{'WindFactorMode','U10', ...
    'MssTotal','DeltaMss','DeltaPrimaryMss','Gamma'});
end

function check_numerics(result,cfg,U10,seed)
values = [result.diagnostics.linearMssRelativeError, ...
    result.diagnostics.modifiedMssRelativeError, ...
    result.diagnostics.maximumShortMssRelativeError, ...
    result.diagnostics.linearHermitianResidual, ...
    result.diagnostics.modifiedHermitianResidual, ...
    result.diagnostics.maximumShortHermitianResidual];
if any(values > cfg.numericalRelativeTolerance)
    warning('Validation:NumericalConsistency', ...
        'Numerical consistency exceeded %.1e at U10=%g, seed=%g (max %.3e).', ...
        cfg.numericalRelativeTolerance,U10,seed,max(values));
end
if abs(result.diagnostics.lie.rieszEnergyRatio-1) > 1e-10
    warning('Validation:RieszEnergy', ...
        'Riesz energy identity error at U10=%g, seed=%g: %.3e.', ...
        U10,seed,abs(result.diagnostics.lie.rieszEnergyRatio-1));
end
end

function q = local_quantile(values,p)
values = sort(values(:));
positions = 1+(numel(values)-1)*p;
lower = floor(positions); upper = ceil(positions); weight = positions-lower;
q = values(lower).*(1-weight)+values(upper).*weight;
end

function value = rms_error(a,b)
value = sqrt(mean((a-b).^2));
end

function validate_config(cfg)
assert(isequal(cfg.windSpeeds(:),(1:10)'), ...
    'The requested experiment uses U10=1:1:10 m/s.');
assert(cfg.primaryPeakSamples >= 10,'dk must be no greater than kp/10.');
assert(cfg.lieInputPeakMultiple*2 <= cfg.lieOutputPeakMultiple, ...
    'Quadratic output bandwidth must be at least twice the input bandwidth.');
assert(cfg.lieOutputPeakMultiple <= cfg.primaryMaximumPeakMultiple, ...
    'Lie output must remain inside the primary represented band.');
assert(cfg.maximumOpticalWavenumber >= max(cfg.opticalCutoffSweep), ...
    'maximumOpticalWavenumber must cover opticalCutoffSweep.');
assert(ismember(string(cfg.windFactorMode),cfg.windFactorModes), ...
    'Unknown windFactorMode.');
end
