function cfg = default_angle_asymmetry_validation_config()
%DEFAULT_ANGLE_ASYMMETRY_VALIDATION_CONFIG Paired morphology validation.

elseDirectory = fileparts(mfilename('fullpath'));
cfg.curlDirectory = fullfile(elseDirectory,'..','..','Curl');
cfg.outputDirectory = fullfile(elseDirectory,'output');
cfg.figureVisible = 'off';

cfg.monteCarlo.randomSeed = 20260902;
cfg.monteCarlo.nPerGroup = 100;
cfg.monteCarlo.maximumPairAttempts = 600;
cfg.monteCarlo.bootstrapCount = 2000;

cfg.reference.frontFaceAngleDeg = [65 70];
cfg.reference.asymmetryAuxiliary = [1.60 2.35];

cfg.extraction.centerlineHalfWidthCells = 0.55;
cfg.extraction.crestSearchFractionLambda = 0.15;
cfg.extraction.activeCurlFraction = 0.08;
cfg.extraction.frontForwardFraction = 0.35;
cfg.extraction.frontVerticalFraction = [0.15 0.85];
cfg.extraction.minimumPoints = 3;

cfg.groups.names = ["G0 No-breaking","G1 Shallow-curl","G2 Conditioned"];
cfg.groups.original = parameter_ranges( ...
    [0.17 0.23],[0.45 0.65],[0.80 1.10],[1.00 1.30],[0.20 0.40]);
cfg.groups.proposed = parameter_ranges( ...
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
