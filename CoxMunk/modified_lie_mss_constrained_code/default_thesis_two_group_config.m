function cfg = default_thesis_two_group_config()
%DEFAULT_THESIS_TWO_GROUP_CONFIG Configuration for the clean two-group test.

cfg.windSpeeds = (1:10)';
cfg.realizationSeeds = (1:20)';
cfg.inverseWaveAge = 0.84;
cfg.windDirectionDeg = 0;

% The primary-wave grid uses dk = kp/12, satisfying the thesis condition
% dk <= kp/10. Its nonlinear input/output bands prevent quadratic aliasing.
cfg.primaryGridSize = 256;
cfg.primaryPeakSamples = 12;
cfg.primaryMaximumPeakMultiple = 8;
cfg.lieInputPeakMultiple = 4;
cfg.lieOutputPeakMultiple = 8;

% Independent octave tiles represent the short-wave contribution without
% requiring one prohibitively large millimetre-resolution domain.
cfg.shortWaveTileSize = 64;
cfg.shortWaveModesBelowBand = 8;
cfg.maximumOpticalWavenumber = pi*1000;

% Dimensionless strength of the second-order Lie/Creamer correction.  U10 is
% deliberately NOT multiplied into the quadratic term (that is dimensionally
% inconsistent); wind dependence already enters through the input spectrum.
cfg.modifiedLieScale = 1.0;

% Elfouhaily-style statistical closure. Independent seeds estimate the
% ensemble bias introduced by the Lie transform. Low-order smooth functions
% of log(U10) are then applied to every validation realization. Cox-Munk,
% Guerin and TGRS are not used to obtain these coefficients.
cfg.enableElfouhailyClosure = true;
cfg.closureCalibrationSeeds = (101:112)';
cfg.closurePolynomialDegree = 2;
cfg.closureScaleBounds = [0.50 1.50];

cfg.outputDirectory = fullfile(fileparts(mfilename('fullpath')),'output');
cfg.figureVisible = 'off';
cfg.exportResolution = 200;
end
