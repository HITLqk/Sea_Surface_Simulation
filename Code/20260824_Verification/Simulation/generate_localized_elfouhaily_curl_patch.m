function surfaceData = generate_localized_elfouhaily_curl_patch(cfg)
%GENERATE_LOCALIZED_ELFOUHAILY_CURL_PATCH Create a finite breaking patch.
%   surfaceData = generate_localized_elfouhaily_curl_patch(cfg) first
%   synthesizes an Elfouhaily sea and then applies a compactly supported
%   crest elevation and curl deformation. The baseline and curled meshes
%   share vertex indices and faces, which supports paired radar calculations.

arguments
    cfg (1,1) struct = default_localized_curl_config()
end

rng(cfg.randomSeed, 'twister');

Nx = round(cfg.domain.Lx / cfg.domain.dx);
Ny = round(cfg.domain.Ly / cfg.domain.dy);
x = (0:Nx-1) * cfg.domain.Lx / Nx;
y = (0:Ny-1) * cfg.domain.Ly / Ny;
[X0, Y0] = meshgrid(x, y);

Z0 = synthesize_elfouhaily_surface(Nx, Ny, cfg.domain.Lx, ...
    cfg.domain.Ly, cfg.sea);

psi = deg2rad(cfg.patch.propagationDirectionDeg);
crestDetection = locate_breaking_crest(X0, Y0, Z0, cfg);
xc = crestDetection.x;
yc = crestDetection.y;
u =  cos(psi) .* (X0-xc) + sin(psi) .* (Y0-yc);
v = -sin(psi) .* (X0-xc) + cos(psi) .* (Y0-yc);

halfLength = cfg.patch.crestLength / 2;
halfWidth = cfg.patch.crossWaveWidth / 2;
transitionLength = get_optional(cfg.patch, 'transitionLength', 0);
halfTransitionWidth = halfWidth + transitionLength;

% Mild along-crest variation creates a finite, natural-looking footprint.
vPhase = pi * v / halfLength;
uCenter = cfg.patch.centerlineMeander .* sin(1.6*vPhase) .* ...
    compact_cosine(v / halfLength);
widthScale = 1 + cfg.patch.edgeIrregularity .* ...
    (0.65*sin(2.3*vPhase) + 0.35*sin(4.7*vPhase + 0.8));
uRelative = u - uCenter;

wv = compact_cosine(v / halfLength);
wuCore = compact_cosine(uRelative ./ (halfWidth .* widthScale));
wuTransition = compact_cosine(uRelative ./ ...
    (halfTransitionWidth .* widthScale));
coreSupport = wuCore .* wv;
support = wuTransition .* wv;

% A low, asymmetric crest correction follows the resolved wave instead of
% creating a separate tall bump.
sigmaRear = 0.95 * halfWidth;
sigmaFront = 0.75 * halfWidth;
sigmaU = sigmaRear .* ones(size(uRelative));
sigmaU(uRelative >= 0) = sigmaFront;
crestProfile = exp(-0.5 * (uRelative ./ sigmaU).^2);
crestEnvelope = cfg.patch.crestHeight .* crestProfile .* support;

% The broad evolution band starts changing the non-curled shoulder before
% the rotation core and returns continuously to the paired background.
evolutionSigma = max(0.72*halfTransitionWidth, eps);
evolutionProfile = exp(-0.5 * (uRelative/evolutionSigma).^2);
evolutionEnvelope = get_optional(cfg.patch, 'evolutionHeight', 0) .* ...
    evolutionProfile .* support;
Zpre = Z0 + crestEnvelope + evolutionEnvelope;
uPre = u + get_optional(cfg.patch, 'evolutionLean', 0) .* ...
    evolutionProfile .* support;

% Start rotating on the approaching shoulder, shortly before the detected
% crest. The long support band blends the rotated core into the evolving
% but non-curled neighbouring surface.
curlCenterOffset = get_optional(cfg.patch, 'curlCenterOffset', 0);
curlCore = exp(-0.5 * ((uRelative-curlCenterOffset) / ...
    (0.62*halfWidth)).^2) .* wv;
theta = deg2rad(cfg.patch.maxCurlDeg) .* curlCore;
uPivot = uCenter + curlCenterOffset + cfg.patch.forwardLean;
zPivot = Z0 - cfg.patch.pivotDepth;
du = uPre - uPivot;
dz = Zpre - zPivot;
uRot = uPivot + du .* cos(theta) + dz .* sin(theta);
zRot = zPivot - du .* sin(theta) + dz .* cos(theta);

uFinal = uPre + support .* (uRot-uPre);
Z = Zpre + support .* (zRot-Zpre);
X = xc + cos(psi).*uFinal - sin(psi).*v;
Y = yc + sin(psi).*uFinal + cos(psi).*v;

breakingMask = coreSupport >= cfg.patch.maskThreshold;
[duFinalDx, duFinalDy] = gradient(uFinal, ...
    cfg.domain.Lx/Nx, cfg.domain.Ly/Ny);
localPropagationJacobian = cos(psi).*duFinalDx + ...
    sin(psi).*duFinalDy;
overturningMask = breakingMask & localPropagationJacobian < 0;
faces = structured_triangles(Nx, Ny);
facetMask = any(reshape(breakingMask(faces), size(faces)), 2);

baselineVertices = [X0(:), Y0(:), Z0(:)];
vertices = [X(:), Y(:), Z(:)];
baselineArea = triangle_area_sum(baselineVertices, faces(facetMask,:));
curledArea = triangle_area_sum(vertices, faces(facetMask,:));

surfaceData = struct();
surfaceData.X0 = X0;
surfaceData.Y0 = Y0;
surfaceData.Z0 = Z0;
surfaceData.X = X;
surfaceData.Y = Y;
surfaceData.Z = Z;
surfaceData.breakingMask = breakingMask;
surfaceData.overturningMask = overturningMask;
surfaceData.localPropagationJacobian = localPropagationJacobian;
surfaceData.support = support;
surfaceData.coreSupport = coreSupport;
surfaceData.localU = u;
surfaceData.localV = v;
surfaceData.localUFinal = uFinal;
surfaceData.faces = faces;
surfaceData.breakingFacetMask = facetMask;
surfaceData.verticesBaseline = baselineVertices;
surfaceData.vertices = vertices;
surfaceData.eventId = ones(size(X), 'uint8') .* uint8(breakingMask);
resolvedCfg = cfg;
resolvedCfg.patch.centerXY = [xc, yc];
surfaceData.cfg = resolvedCfg;
surfaceData.requestedCfg = cfg;
surfaceData.crestDetection = crestDetection;
surfaceData.curlCenterOffset = curlCenterOffset;
surfaceData.curlCenterXY = [xc + cos(psi)*curlCenterOffset, ...
    yc + sin(psi)*curlCenterOffset];
surfaceData.metrics.projectedFootprintArea = nnz(breakingMask) * ...
    (cfg.domain.Lx/Nx) * (cfg.domain.Ly/Ny);
surfaceData.metrics.baselinePatchSurfaceArea = baselineArea;
surfaceData.metrics.curledPatchSurfaceArea = curledArea;
surfaceData.metrics.surfaceAreaRatio = curledArea / baselineArea;
surfaceData.metrics.maxElevationIncrement = max(Z(:)-Z0(:));
surfaceData.metrics.maxHorizontalDisplacement = max(hypot(X(:)-X0(:), Y(:)-Y0(:)));
surfaceData.metrics.breakerCenterToCrestDistance = hypot( ...
    xc-crestDetection.x, yc-crestDetection.y);
effectiveCurl = theta .* support;
[~, maximumCurlIndex] = max(effectiveCurl(:));
surfaceData.metrics.maxCurlToCrestDistance = hypot( ...
    X0(maximumCurlIndex)-crestDetection.x, ...
    Y0(maximumCurlIndex)-crestDetection.y);
surfaceData.metrics.minimumLocalPropagationJacobian = min( ...
    localPropagationJacobian(breakingMask));
surfaceData.metrics.overturningPointCount = nnz(overturningMask);
surfaceData.metrics.overturningProjectedArea = nnz(overturningMask) * ...
    (cfg.domain.Lx/Nx) * (cfg.domain.Ly/Ny);
outside = support == 0;
surfaceData.metrics.maxOutsidePatchDisplacement = max([ ...
    abs(X(outside)-X0(outside)); abs(Y(outside)-Y0(outside)); ...
    abs(Z(outside)-Z0(outside))]);
end

function detection = locate_breaking_crest(X, Y, Z, cfg)
% Locate a resolved crest while keeping the complete breaking patch inside.
mode = 'manual';
if isfield(cfg.patch, 'centerMode') && ~isempty(cfg.patch.centerMode)
    mode = lower(char(cfg.patch.centerMode));
end

if strcmp(mode, 'manual')
    [~, index] = min((X(:)-cfg.patch.centerXY(1)).^2 + ...
        (Y(:)-cfg.patch.centerXY(2)).^2);
    detection = make_detection(index, X, Y, Z, Z, mode, 0);
    return;
end
assert(strcmp(mode, 'highest_crest'), ...
    'Unknown patch centerMode: %s.', cfg.patch.centerMode);

dx = cfg.domain.Lx / size(X,2);
dy = cfg.domain.Ly / size(X,1);
transitionLength = get_optional(cfg.patch, 'transitionLength', 0);
effectiveWidth = cfg.patch.crossWaveWidth + 2*transitionLength;
patchRadius = 0.5 * hypot(cfg.patch.crestLength, effectiveWidth);
extraClearance = get_optional(cfg.patch, 'edgeClearance', 0);
clearance = patchRadius + extraClearance + 2*max(dx,dy);
valid = X >= clearance & X <= cfg.domain.Lx-clearance & ...
    Y >= clearance & Y <= cfg.domain.Ly-clearance;
assert(any(valid, 'all'), ...
    'The domain is too small to place the complete breaking patch.');

smoothLength = get_optional(cfg.patch, ...
    'crestSearchSmoothingLength', 0);
sigmaCells = smoothLength / max(0.5*(dx+dy), eps);
Zscore = gaussian_smooth(Z, sigmaCells);
score = Zscore;
score(~valid) = -Inf;
[~, coarseIndex] = max(score(:));

refineRadius = get_optional(cfg.patch, 'crestRefineRadius', 0);
if refineRadius > 0
    refine = valid & hypot(X-X(coarseIndex), Y-Y(coarseIndex)) <= refineRadius;
    candidates = find(refine);
    [~, localIndex] = max(Z(candidates));
    index = candidates(localIndex);
else
    index = coarseIndex;
end
detection = make_detection(index, X, Y, Z, Zscore, mode, clearance);
detection.coarseIndex = coarseIndex;
detection.coarseXY = [X(coarseIndex), Y(coarseIndex)];
end

function detection = make_detection(index, X, Y, Z, Zscore, mode, clearance)
detection.mode = mode;
detection.linearIndex = index;
detection.x = X(index);
detection.y = Y(index);
detection.z = Z(index);
detection.smoothedElevation = Zscore(index);
detection.edgeClearance = clearance;
end

function value = get_optional(s, name, fallback)
if isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = fallback;
end
end

function Zs = gaussian_smooth(Z, sigmaCells)
if sigmaCells <= 0
    Zs = Z;
    return;
end
radius = max(1, ceil(3*sigmaCells));
q = -radius:radius;
kernel = exp(-0.5*(q/sigmaCells).^2);
kernel = kernel / sum(kernel);
Zs = conv2(kernel, kernel, Z, 'same');
end

function Z = synthesize_elfouhaily_surface(Nx, Ny, Lx, Ly, sea)
% Omnidirectional Elfouhaily spectrum with the commonly used cos^2 spreading.
g = 9.81;
km = 370.0;
cm = 0.23;
Omega = sea.inverseWaveAge;
uStar = sqrt(1e-3*(0.8 + 0.065*sea.U10)) * sea.U10;
k0 = g / sea.U10^2;
kp = k0 * Omega^2;
cp = sqrt(g/kp);
if Omega <= 1
    gamma = 1.7;
else
    gamma = 1.7 + 6*log10(Omega);
end
alphaP = 6e-3 * sqrt(Omega);
alphaM = 0.01 * (1 + log(max(uStar/cm, eps)));

dkx = 2*pi/Lx;
dky = 2*pi/Ly;
kx = ifftshift((-floor(Nx/2):ceil(Nx/2)-1) * dkx);
ky = ifftshift((-floor(Ny/2):ceil(Ny/2)-1) * dky);
[KX, KY] = meshgrid(kx, ky);
K = hypot(KX, KY);
Ksafe = max(K, eps);

c = sqrt(g./Ksafe .* (1 + (Ksafe/km).^2));
Lpm = exp(-1.25*(kp./Ksafe).^2);
Gamma = exp(-(sqrt(Ksafe/kp)-1).^2 / (2*0.08^2));
Fp = Lpm .* gamma.^Gamma .* exp(-Omega/sqrt(10) .* (sqrt(Ksafe/kp)-1));
Bl = 0.5*alphaP .* (cp./c) .* Fp;
Fm = exp(-0.25*(Ksafe/km-1).^2);
Bh = 0.5*alphaM .* (cm./c) .* Fm;
S = (Bl + Bh) ./ Ksafe.^3;

windDirection = deg2rad(sea.windDirectionDeg);
phi = atan2(KY, KX) - windDirection;
spread = 2/pi .* cos(phi).^2;
Psi = max(S .* spread ./ Ksafe, 0);
Psi(K == 0) = 0;

white = (randn(Ny,Nx) + 1i*randn(Ny,Nx)) / sqrt(2);
negX = [1, Nx:-1:2];
negY = [1, Ny:-1:2];
white = (white + conj(white(negY,negX))) / sqrt(2);
H = sqrt(Psi * dkx * dky) .* white;
Z = real(ifft2(H) * Nx * Ny);
Z = Z - mean(Z, 'all');

if sea.targetHs > 0
    currentHs = 4*std(Z, 0, 'all');
    Z = Z * sea.targetHs / max(currentHs, eps);
end
end

function w = compact_cosine(q)
w = zeros(size(q));
inside = abs(q) < 1;
w(inside) = 0.5 * (1 + cos(pi*q(inside)));
end

function faces = structured_triangles(Nx, Ny)
[i, j] = meshgrid(1:Nx-1, 1:Ny-1);
v00 = sub2ind([Ny,Nx], j(:), i(:));
v10 = sub2ind([Ny,Nx], j(:), i(:)+1);
v01 = sub2ind([Ny,Nx], j(:)+1, i(:));
v11 = sub2ind([Ny,Nx], j(:)+1, i(:)+1);
faces = [v00, v10, v11; v00, v11, v01];
end

function area = triangle_area_sum(vertices, faces)
e1 = vertices(faces(:,2),:) - vertices(faces(:,1),:);
e2 = vertices(faces(:,3),:) - vertices(faces(:,1),:);
area = sum(0.5 * vecnorm(cross(e1,e2,2), 2, 2));
end

