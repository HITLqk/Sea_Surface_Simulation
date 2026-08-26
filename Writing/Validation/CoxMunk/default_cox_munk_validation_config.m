function cfg = default_cox_munk_validation_config()
%DEFAULT_COX_MUNK_VALIDATION_CONFIG Batch-validation settings.

thisDirectory = fileparts(mfilename('fullpath'));

siblingNonlinearDirectory = fullfile(fileparts(thisDirectory),'NonLiner');
if isfolder(siblingNonlinearDirectory)
    cfg.source.nonlinearDirectory = siblingNonlinearDirectory;
else
    cfg.source.nonlinearDirectory = ...
        'E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\NonLiner';
end

% Multiple independent realizations are required for confidence intervals.
cfg.windSpeeds = [3 5 7 10];
cfg.randomSeeds = 20260801:20260820;

% Keep the native NonLiner grid. Its anti-alias cutoff is specified as a
% fraction of Nyquist, so changing dx also changes the physical nonlinear
% bandwidth and is not a neutral resolution refinement.
cfg.domain.Lx = 128.0;
cfg.domain.Ly = 128.0;
cfg.domain.dx = 0.25;
cfg.domain.dy = 0.25;
cfg.numerics.nativeGridSpacing = 0.25;
cfg.numerics.enforceNativeGrid = true;
cfg.sea.inverseWaveAge = 0.84;
cfg.sea.windDirectionDeg = 0.0;

% These are the parameters used by the current successful Curl demo.
% One controlled curl is inserted per realization. This checks whether the
% local geometric operation destroys global MSS; it is not a breaking-rate
% model and must not be interpreted as one.
cfg.curl.enabled = true;
cfg.curl.heightSigmaThreshold = 1.25;
cfg.curl.smoothingLength = 0.20;
cfg.curl.refineRadius = 0.25;
cfg.curl.edgeMargin = 4.0;
cfg.curl.propagationDirectionDeg = NaN; % NaN follows wind direction.
cfg.curl.crestLength = 6.0;
cfg.curl.amplitudeCurl = 0.20;
cfg.curl.curlMultiplier = 0.55;
cfg.curl.pivotDepth = 0.95;
cfg.curl.forwardGain = 1.15;
cfg.curl.verticalAngleRatio = 0.28;
cfg.curl.maskAngleFraction = 0.08;

% Cox-Munk clean-sea component relations and the uncertainty band retained
% by the current manuscript code.
cfg.coxMunk.totalUncertainty = 0.0055;

% Nearly vertical and overturned facets are not representable by the
% single-valued Cox-Munk slope variable. They are counted separately.
cfg.slope.minimumNormalZ = 0.02;

cfg.output.directory = fullfile(thisDirectory,'output');
cfg.output.figureVisible = 'on';
cfg.output.saveMat = true;
end
