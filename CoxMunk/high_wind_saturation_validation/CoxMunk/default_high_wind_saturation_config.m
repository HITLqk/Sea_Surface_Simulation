function cfg = default_high_wind_saturation_config()
%DEFAULT_HIGH_WIND_SATURATION_CONFIG Hurricane MSS validation settings.

thisDirectory = fileparts(mfilename('fullpath'));
cfg.source.nonlinearDirectory = fullfile(fileparts(thisDirectory),'NonLiner');
cfg.windSpeeds = 15:2.5:50;
cfg.calibrationWindSpeeds = 15:5:50;
cfg.validationWindSpeeds = 17.5:5:47.5;
cfg.randomSeeds = 20260801:20260808;
cfg.groups = ["Linear Elfouhaily","Raw Modified Lie", ...
    "Saturation-Constrained Modified Lie"];

cfg.sea.inverseWaveAge = 0.84;
cfg.sea.windDirectionDeg = 0;
cfg.sea.minimumWavenumber = 0.01;
cfg.sea.maximumWavenumber = 1.0;

domainLength = 2*pi/cfg.sea.minimumWavenumber;
cfg.domain.Lx = domainLength;
cfg.domain.Ly = domainLength;
cfg.domain.dx = domainLength/512;
cfg.domain.dy = domainLength/512;

cfg.lie.nonlinearInputCutoff = 0.5;
cfg.lie.nonlinearOutputCutoff = 1.0;
cfg.rawConstraint.maximumRelativeMssIncrease = 0.05;
cfg.saturationConstraint.maximumRelativeMssIncrease = 0.015;
cfg.constraintBisectionIterations = 14;
cfg.minimumNormalZ = 0.02;

cfg.saturation.wavenumberExponent = 2.0;
cfg.saturation.maximumMu = 30;
cfg.saturation.maximumGain = 1.05;
cfg.output.figureVisible = 'off';
cfg.output.saveMat = true;
cfg.output.directory = fullfile(thisDirectory,'output_high_wind');
end
