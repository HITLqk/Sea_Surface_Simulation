function curled = apply_ideal_curl_to_surface(surfaceData,curlCfg)
%APPLY_IDEAL_CURL_TO_SURFACE Apply the existing Curl transform to G0.
%   The input is the nonlinear surface itself; no independent background
%   sea is regenerated. This makes G0/G1 a paired comparison.

X0 = surfaceData.X;
Y0 = surfaceData.Y;
Z0 = surfaceData.Z;
baseX = surfaceData.X0;
baseY = surfaceData.Y0;

dx = median(diff(baseX(1,:)));
dy = median(diff(baseY(:,1)));
sigmaCells = curlCfg.smoothingLength/max(0.5*(dx+dy),eps);
Zsmooth = gaussian_smooth(Z0,sigmaCells);

threshold = mean(Zsmooth,'all')+...
    curlCfg.heightSigmaThreshold*std(Zsmooth,0,'all');
validPosition = baseX >= curlCfg.edgeMargin & ...
    baseX <= max(baseX,[],'all')-curlCfg.edgeMargin & ...
    baseY >= curlCfg.edgeMargin & ...
    baseY <= max(baseY,[],'all')-curlCfg.edgeMargin;
candidates = validPosition & Zsmooth >= threshold;
assert(any(candidates,'all'), ...
    'No crest exceeds the configured curl height threshold.');

score = Zsmooth;
score(~candidates) = -Inf;
[~,coarseIndex] = max(score(:));
refine = validPosition & hypot(baseX-baseX(coarseIndex), ...
    baseY-baseY(coarseIndex)) <= curlCfg.refineRadius;
refineIndices = find(refine);
[~,localIndex] = max(Z0(refineIndices));
crestIndex = refineIndices(localIndex);

if isnan(curlCfg.propagationDirectionDeg)
    directionDeg = surfaceData.cfg.sea.windDirectionDeg;
else
    directionDeg = curlCfg.propagationDirectionDeg;
end
direction = deg2rad(directionDeg);
crestX = X0(crestIndex);
crestY = Y0(crestIndex);
crestZ = Z0(crestIndex);
u = cos(direction).*(X0-crestX)+sin(direction).*(Y0-crestY);
v = -sin(direction).*(X0-crestX)+cos(direction).*(Y0-crestY);

zPivot = crestZ-curlCfg.pivotDepth;
normalizedZ = Z0-zPivot;
curlRate = exp(-abs(u)/curlCfg.amplitudeCurl);
crestWeight = compact_cosine(v/(0.5*curlCfg.crestLength));
theta = curlCfg.curlMultiplier.*curlRate.*crestWeight;
verticalTheta = curlCfg.verticalAngleRatio.*theta;

uFinal = u.*cos(theta)+...
    curlCfg.forwardGain.*normalizedZ.*sin(theta);
zFinal = zPivot-u.*sin(verticalTheta)+...
    normalizedZ.*cos(verticalTheta);
X = crestX+cos(direction).*uFinal-sin(direction).*v;
Y = crestY+sin(direction).*uFinal+cos(direction).*v;

curlMask = theta >= curlCfg.maskAngleFraction*curlCfg.curlMultiplier;
[duDx,duDy] = gradient(uFinal,dx,dy);
propagationJacobian = cos(direction).*duDx+sin(direction).*duDy;

curled.X = X;
curled.Y = Y;
curled.Z = zFinal;
curled.curlMask = curlMask;
curled.crestWeight = crestWeight;
curled.propagationJacobian = propagationJacobian;
curled.overturningMask = crestWeight > 0 & propagationJacobian < 0;
curled.detection.x = crestX;
curled.detection.y = crestY;
curled.detection.z = crestZ;
curled.detection.heightThreshold = threshold;
curled.metrics.curlVertexCount = nnz(curlMask);
curled.metrics.overturningVertexCount = nnz(curled.overturningMask);
curled.metrics.minimumPropagationJacobian = min( ...
    propagationJacobian(crestWeight > 0));
end

function Zsmooth = gaussian_smooth(Z,sigmaCells)
if sigmaCells <= 0
    Zsmooth = Z;
    return;
end
radius = max(1,ceil(3*sigmaCells));
q = -radius:radius;
kernel = exp(-0.5*(q/sigmaCells).^2);
kernel = kernel/sum(kernel);
Zsmooth = conv2(kernel,kernel,Z,'same');
end

function weight = compact_cosine(q)
weight = zeros(size(q));
inside = abs(q) < 1;
weight(inside) = 0.5*(1+cos(pi*q(inside)));
end
