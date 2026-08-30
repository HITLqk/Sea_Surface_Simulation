function cfg = default_breaker_morphology_validation_config()
%DEFAULT_BREAKER_MORPHOLOGY_VALIDATION_CONFIG Minimal GRSL validation setup.

patternsDirectory = fileparts(mfilename('fullpath'));
cfg.curlDirectory = fullfile(patternsDirectory,'..','Curl');
cfg.outputDirectory = fullfile(patternsDirectory,'output');
cfg.figureVisible = 'off';

% Use the same representative pre-impact curl as the existing Curl demo.
cfg.curlOverrides.amplitudeCurl = 0.21;
cfg.curlOverrides.forwardGain = 1.05;
cfg.curlOverrides.verticalAngleRatio = 1.59;
cfg.curlOverrides.pivotDepth = 0.915;
cfg.curlOverrides.curlMultiplier = 1.16;

% Erinin et al. (JFM 2023), weak-to-strong experimental envelope.
cfg.reference.frontFaceAngleDeg = [65.0 70.0];
cfg.reference.rxOverLambda = [0.049 0.069];
cfg.reference.ryOverLambda = [0.045 0.059];

% The default wavelength is the Elfouhaily spectral-peak wavelength.
% Set mode='fixed' and fixedWavelength to use a measured local wavelength.
cfg.normalization.mode = 'spectralPeak';
cfg.normalization.fixedWavelength = 1.1806;

cfg.extraction.centerlineHalfWidthCells = 0.55;
cfg.extraction.activeCurlFraction = 0.08;
cfg.extraction.frontForwardFraction = 0.35;
cfg.extraction.frontVerticalFraction = [0.15 0.85];

cfg.monteCarlo.randomSeed = 20260901;
cfg.monteCarlo.nPerGroup = 100;
cfg.monteCarlo.original = parameter_ranges( ...
    [0.17 0.23],[0.45 0.65],[0.80 1.10],[1.00 1.30],[0.20 0.40]);
cfg.monteCarlo.corrected = parameter_ranges( ...
    [0.19 0.23],[1.12 1.20],[0.85 0.98],[0.98 1.12],[1.54 1.64]);
end

function ranges = parameter_ranges(amplitudeCurl,curlMultiplier, ...
    pivotDepth,forwardGain,verticalAngleRatio)
ranges.amplitudeCurl = amplitudeCurl;
ranges.curlMultiplier = curlMultiplier;
ranges.pivotDepth = pivotDepth;
ranges.forwardGain = forwardGain;
ranges.verticalAngleRatio = verticalAngleRatio;
end
