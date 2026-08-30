function metrics = extract_front_angle_asymmetry(surfaceData,cfg)
%EXTRACT_FRONT_ANGLE_ASYMMETRY Measure angle and zero-crossing asymmetry.

[u0,u,z0,z] = center_profile(surfaceData,cfg);
sea = surfaceData.cfg.sea;
lambdaPeak = 2*pi/(9.81/sea.U10^2*sea.inverseWaveAge^2);

crestSearch = abs(u0) <= ...
    cfg.extraction.crestSearchFractionLambda*lambdaPeak;
assert(any(crestSearch),'The crest search window is empty.');
indices = find(crestSearch);
[~,localCrest] = max(z(indices));
crestIndex = indices(localCrest);

% The generated Elfouhaily field is zero-mean. Estimate the mean water
% level from the full undeformed surface to avoid local crest-window bias.
meanWaterLevel = mean(surfaceData.Z0,'all');
frontCross = first_crossing(z-meanWaterLevel,crestIndex,+1,u);
rearCross = first_crossing(z-meanWaterLevel,crestIndex,-1,u);

crestU = u(crestIndex);
crestZ = z(crestIndex);
crestHeight = crestZ-meanWaterLevel;
frontLength = abs(frontCross.u-crestU);
rearLength = abs(crestU-rearCross.u);
minimumLength = 2*surfaceData.cfg.domain.dx;
assert(crestHeight > 0,'The selected crest is below the mean water level.');
assert(frontLength >= minimumLength && rearLength >= minimumLength, ...
    'A zero-crossing length is below two grid intervals.');

epsilonFront = crestHeight/frontLength;
epsilonRear = crestHeight/rearLength;
asymmetry = epsilonFront/epsilonRear;

% Use the same undeformed-coordinate support for all groups. This lets the
% no-breaking control and curled groups use one operational angle rule.
amplitudeCurl = surfaceData.cfg.curl.amplitudeCurl;
supportWeight = exp(-abs(u0)/max(amplitudeCurl,eps));
active = supportWeight >= cfg.extraction.activeCurlFraction;
uActive = u(active);
zActive = z(active);
uSpan = max(uActive)-min(uActive);
zSpan = max(zActive)-min(zActive);
uLimit = max(uActive)-cfg.extraction.frontForwardFraction*uSpan;
zLimits = min(zActive)+cfg.extraction.frontVerticalFraction*zSpan;
frontFace = active & u >= uLimit & z >= zLimits(1) & z <= zLimits(2);

du = gradient(u,u0);
dz = gradient(z,u0);
descending = du.*dz < 0;
if nnz(frontFace & descending) >= cfg.extraction.minimumPoints
    frontFace = frontFace & descending;
end
assert(nnz(frontFace) >= cfg.extraction.minimumPoints, ...
    'Front-face extraction produced too few points.');

fitPoints = [u(frontFace),z(frontFace)];
centered = fitPoints-mean(fitPoints,1);
[~,~,vectors] = svd(centered,0);
direction = vectors(:,1);
frontFaceAngleDeg = atan2d(abs(direction(2)),abs(direction(1)));

metrics.frontFaceAngleDeg = frontFaceAngleDeg;
metrics.epsilonFront = epsilonFront;
metrics.epsilonRear = epsilonRear;
metrics.asymmetry = asymmetry;
metrics.crestHeight = crestHeight;
metrics.frontLength = frontLength;
metrics.rearLength = rearLength;
metrics.meanWaterLevel = meanWaterLevel;
metrics.frontAnglePass = frontFaceAngleDeg >= ...
    cfg.reference.frontFaceAngleDeg(1) && frontFaceAngleDeg <= ...
    cfg.reference.frontFaceAngleDeg(2);
metrics.frontSteeper = asymmetry > 1;
metrics.profile.u0 = u0;
metrics.profile.u = u;
metrics.profile.z0 = z0;
metrics.profile.z = z;
metrics.profile.frontFace = frontFace;
metrics.landmarks.crest = [crestU crestZ];
metrics.landmarks.frontCrossing = [frontCross.u meanWaterLevel];
metrics.landmarks.rearCrossing = [rearCross.u meanWaterLevel];
end

function [u0,u,z0,z] = center_profile(surfaceData,cfg)
dx = surfaceData.cfg.domain.Lx/size(surfaceData.X,2);
dy = surfaceData.cfg.domain.Ly/size(surfaceData.Y,1);
halfWidth = cfg.extraction.centerlineHalfWidthCells*max(dx,dy);
selected = abs(surfaceData.localV) <= halfWidth;
u0 = surfaceData.localU(selected);
u = surfaceData.localUFinal(selected);
z0 = surfaceData.Z0(selected);
z = surfaceData.Z(selected);
[u0,order] = sort(u0);
u = u(order); z0 = z0(order); z = z(order);
[u0,~,group] = unique(round(u0/max(dx,eps))*max(dx,eps),'stable');
u = accumarray(group,u,[],@mean);
z0 = accumarray(group,z0,[],@mean);
z = accumarray(group,z,[],@mean);
end

function crossing = first_crossing(level,crestIndex,direction,u)
if direction > 0
    candidate = crestIndex:numel(level)-1;
else
    candidate = crestIndex:-1:2;
end
found = false;
for k = candidate
    next = k+direction;
    if level(k) == 0 || level(k)*level(next) <= 0
        fraction = level(k)/(level(k)-level(next)+eps);
        crossing.u = u(k)+fraction*(u(next)-u(k));
        crossing.indices = [k next];
        found = true;
        break;
    end
end
assert(found,'No adjacent mean-water-level crossing was found.');
end
