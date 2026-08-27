function cfg = default_thesis_two_group_config()
%DEFAULT_THESIS_TWO_GROUP_CONFIG Configuration for the paired validation.

cfg.windSpeeds = (1:10)';                    % 10-m wind speed, m/s
cfg.realizationSeeds = (1:20)';
cfg.inverseWaveAge = 0.84;                   % fully developed lower limit
cfg.windDirectionDeg = 0;

% The Wu neutral drag law is independent of the MSS references and is not
% calibrated to Cox-Munk.
cfg.dragCoefficientMode = "wu";             % "wu" or "fixed_legacy"
cfg.legacyDragCoefficient = 0.00144;
cfg.warnOnShortWaveClamp = true;

% The primary grid satisfies dk <= kp/10. Quadratic products use a 2:1
% input/output bandwidth to avoid circular aliasing.
cfg.primaryGridSize = 256;
cfg.primaryPeakSamples = 12;
cfg.primaryMaximumPeakMultiple = 8;
cfg.lieInputPeakMultiple = 4;
cfg.lieOutputPeakMultiple = 8;

% Independent octave tiles represent optical-scale slopes.
cfg.shortWaveTileSize = 64;
cfg.shortWaveModesBelowBand = 8;
cfg.maximumOpticalWavenumber = pi*1000;      % rad/m, lambda_min = 2 mm
cfg.slopePdfSamplesPerRealization = 4096;

% "current" is the old dimensionally inconsistent implementation retained
% only for the requested diagnostic comparison.
cfg.windFactorMode = "direction_only";      % current|direction_only|none
cfg.modifiedLieScale = 1.0;                  % formal second-order coefficient

% Diagnostic iterative spectral undressing, not a rigorous inversion.
cfg.enableSpectralUndressing = false;
cfg.undressingIterations = 3;
cfg.undressingSeeds = (101:103)';
cfg.undressingRadialBins = 36;
cfg.undressingSmoothingWindow = 5;
cfg.undressingCorrectionLimits = [0.75 1.25];

cfg.spectralDiagnosticWinds = [3 5 10]';
cfg.spectralDiagnosticSeeds = (1:5)';
cfg.spectralRadialBins = 42;
cfg.spectralRatioMssFloorFraction = 1e-4; % Ignore MSS-negligible radial bins.
cfg.windFactorDiagnosticWinds = [3 5 7 10]';
cfg.windFactorDiagnosticSeeds = (1:5)';
cfg.windFactorModes = ["current","direction_only","none"];
cfg.slopePdfWinds = [5 10]';
cfg.opticalCutoffSweep = [100 200 370 1000 2000 pi*1000]'; % rad/m
cfg.cutoffCumulativePoints = 220;

cfg.numericalRelativeTolerance = 1e-10;
% Previous committed run, retained only for before/after reporting.
cfg.previousBaseline.linearElfouhailyRmse = 0.00077468;
cfg.previousBaseline.modifiedElfouhailyRmse = 0.0039167;
cfg.previousBaseline.modifiedU10TotalMss = 0.06767958;
cfg.previousBaseline.modifiedU10Gamma = 0.79291021;
cfg.outputDirectory = fullfile(fileparts(mfilename('fullpath')),'output');
cfg.figureVisible = 'off';
cfg.exportResolution = 200;
end
