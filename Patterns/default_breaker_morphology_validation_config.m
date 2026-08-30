function cfg = default_breaker_morphology_validation_config()
%DEFAULT_BREAKER_MORPHOLOGY_VALIDATION_CONFIG Minimal GRSL validation setup.

patternsDirectory = fileparts(mfilename('fullpath'));
cfg.curlDirectory = fullfile(patternsDirectory,'..','Curl');
cfg.outputDirectory = fullfile(patternsDirectory,'output');
cfg.figureVisible = 'off';

% Use the same representative pre-impact curl as the existing Curl demo.
cfg.curlOverrides.forwardGain = 1.15;
cfg.curlOverrides.verticalAngleRatio = 0.28;
cfg.curlOverrides.pivotDepth = 0.95;
cfg.curlOverrides.curlMultiplier = 0.55;

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
end
