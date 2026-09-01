function cfg = wind_wave_validation_config()
%WIND_WAVE_VALIDATION_CONFIG Wind-wave three-group validation settings.

thisDir = fileparts(mfilename('fullpath'));
cfg.paths.rootDir = thisDir;
radarEchoDir = fileparts(thisDir);
cfg.paths.dataDir = fullfile(radarEchoDir, 'data');
cfg.paths.simulationOutputDir = fullfile(thisDir, 'simulation_output');
cfg.paths.outputDir = fullfile(thisDir, 'validation_output');
cfg.paths.measuredFile = fullfile(cfg.paths.dataDir, ...
    '20210106155330_01_staring.mat');
cfg.paths.measuredVariable = 'amplitude_complex_T2';
cfg.paths.linearFile = fullfile(cfg.paths.simulationOutputDir, ...
    'linear_radar_echo.mat');
cfg.paths.proposedFile = fullfile(cfg.paths.simulationOutputDir, ...
    'proposed_radar_echo.mat');

% Distribution-shape analysis uses one global RMS per group. Per-range RMS
% removal is disabled because it suppresses physically meaningful spatial
% texture. Raw simulated echoes are retained for absolute Linear/Proposed
% comparisons; measured ADC units are not treated as absolutely calibrated.
cfg.preprocessing.removeRangeEnvelope = false;
cfg.preprocessing.applyTheoreticalRangeCompensation = true;
cfg.preprocessing.maximumFitSamples = 300000;
cfg.preprocessing.randomSeed = 20260831;

% A fixed homogeneous gate prevents the deterministic R^-4 envelope from
% masquerading as compound-Gaussian heavy-tail behaviour.
cfg.analysis.fitRangeLimitsM = [2500, 3000];

cfg.rti.dynamicRangeDb = [-35, 15];
cfg.rti.maximumDisplayPulses = 1600;
cfg.rti.maximumDisplayRangeBins = 1200;

cfg.fitting.models = {'Rayleigh','Weibull','Log-normal','K'};
cfg.fitting.histogramBinCount = 100;
cfg.fitting.curvePointCount = 350;
cfg.fitting.quantilePointCount = 2000;
cfg.fitting.tailProbabilityRange = [1e-4, 1e-1];
cfg.fitting.optimizationDisplay = 'off';
cfg.fitting.rayleighLimitNu = 20;
cfg.fitting.rayleighLikeWeibullTolerance = 0.10;

cfg.output.savePdf = true;
end
