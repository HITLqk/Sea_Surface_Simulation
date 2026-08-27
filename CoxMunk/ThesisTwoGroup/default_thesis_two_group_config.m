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

% Equation (2.31) is evaluated with an even wind projection so that the
% Fourier coefficients retain Hermitian symmetry and the surface is real.
cfg.modifiedLieScale = 1.0;

cfg.outputDirectory = fullfile(fileparts(mfilename('fullpath')),'output');
cfg.figureVisible = 'off';
cfg.exportResolution = 200;
end
