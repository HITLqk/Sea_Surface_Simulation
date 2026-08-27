function cfg = default_modern_mss_validation_config(mode)
%DEFAULT_MODERN_MSS_VALIDATION_CONFIG Literature-matched MSS experiments.

arguments
    mode (1,1) string {mustBeMember(mode,["guerin","davis"])} = "guerin"
end

thisDirectory = fileparts(mfilename('fullpath'));
nonlinearDirectory = fullfile(fileparts(thisDirectory),'NonLiner');
if ~isfolder(nonlinearDirectory)
    nonlinearDirectory = ...
        'E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\NonLiner';
end

cfg.mode = mode;
cfg.source.nonlinearDirectory = nonlinearDirectory;
cfg.randomSeeds = 20260801:20260820;
cfg.sea.inverseWaveAge = 0.84;
cfg.sea.windDirectionDeg = 0.0;
cfg.slope.minimumNormalZ = 0.02;
cfg.numerics.minimumPeakWaves = 1.0;
cfg.numerics.enforcePeakResolution = true;

cfg.curl.enabled = mode == "guerin";
cfg.curl.heightSigmaThreshold = 1.25;
cfg.curl.smoothingLength = 0.20;
cfg.curl.refineRadius = 0.25;
cfg.curl.edgeMargin = 4.0;
cfg.curl.propagationDirectionDeg = NaN;
cfg.curl.crestLength = 6.0;
cfg.curl.amplitudeCurl = 0.20;
cfg.curl.curlMultiplier = 0.55;
cfg.curl.pivotDepth = 0.95;
cfg.curl.forwardGain = 1.15;
cfg.curl.verticalAngleRatio = 0.28;
cfg.curl.maskAngleFraction = 0.08;

cfg.output.figureVisible = 'on';
cfg.output.saveMat = true;

if mode == "guerin"
    cfg.windSpeeds = 3:0.5:15;
    cfg.groups = ["Linear","G0_Nonlinear", ...
        "G1_Upward","G1_Background"];
    cfg.domain = struct('Lx',256.0,'Ly',256.0,'dx',0.25,'dy',0.25);
    cfg.synthesis.minimumWavenumber = 0.0;
    cfg.synthesis.maximumWavenumber = inf;
    cfg.lie.nonlinearInputCutoff = 6.0;
    cfg.lie.nonlinearOutputCutoff = 12.0;
    cfg.output.directory = fullfile(thisDirectory,'output_modern_guerin');
else
    cfg.windSpeeds = [3:2:15 20:5:50];
    cfg.groups = ["Linear","G0_Nonlinear"];
    davisDomainLength = 2*pi/0.01;
    davisGridSpacing = davisDomainLength/1024;
    cfg.domain = struct('Lx',davisDomainLength, ...
        'Ly',davisDomainLength,'dx',davisGridSpacing, ...
        'dy',davisGridSpacing);
    cfg.synthesis.minimumWavenumber = 0.01;
    cfg.synthesis.maximumWavenumber = 1.0;
    cfg.lie.nonlinearInputCutoff = 0.5;
    cfg.lie.nonlinearOutputCutoff = 1.0;
    cfg.numerics.enforcePeakResolution = false;
    cfg.output.directory = fullfile(thisDirectory,'output_modern_davis');
end
end
