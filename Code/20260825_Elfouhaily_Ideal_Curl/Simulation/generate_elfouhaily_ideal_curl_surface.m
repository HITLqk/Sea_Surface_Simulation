function surfaceData = generate_elfouhaily_ideal_curl_surface(cfg)
%GENERATE_ELFOUHAILY_IDEAL_CURL_SURFACE Curl a height-selected 2-D sea crest.
%   The local (u,z) rotation follows the operation in
%   Ideal_Curl_Wave_Echo.m. Unlike that script, every crestwise position
%   keeps its own Elfouhaily elevation and receives a finite smooth weight.

arguments
    cfg (1,1) struct = default_elfouhaily_ideal_curl_config()
end

rng(cfg.randomSeed, 'twister');

Nx = round(cfg.domain.Lx/cfg.domain.dx);
Ny = round(cfg.domain.Ly/cfg.domain.dy);
x = (0:Nx-1)*cfg.domain.Lx/Nx;
y = (0:Ny-1)*cfg.domain.Ly/Ny;
[X0,Y0] = meshgrid(x,y);

Z0 = synthesize_elfouhaily_surface(Nx,Ny,cfg.domain.Lx, ...
    cfg.domain.Ly,cfg.sea);
detection = detect_high_crest(X0,Y0,Z0,cfg);

psi = deg2rad(cfg.curl.propagationDirectionDeg);
u = cos(psi).*(X0-detection.x) + sin(psi).*(Y0-detection.y);
v = -sin(psi).*(X0-detection.x) + cos(psi).*(Y0-detection.y);

% Original ideal-curl operation in a local coordinate system.
zPivot = detection.z-cfg.curl.pivotDepth;
nU = cfg.curl.scaleU.*u;
nZ = cfg.curl.scaleZ.*(Z0-zPivot);
curlRate = exp(-abs(nU)/cfg.curl.amplitudeCurl);
crestWeight = compact_cosine(v/(0.5*cfg.curl.crestLength));
thetaCurl = cfg.curl.curlMultiplier.*curlRate.*crestWeight;

rotU = nU.*cos(thetaCurl) + nZ.*sin(thetaCurl);
rotZ = -nU.*sin(thetaCurl) + nZ.*cos(thetaCurl);

uFinal = rotU;
Z = zPivot+rotZ;
X = detection.x + cos(psi).*uFinal - sin(psi).*v;
Y = detection.y + sin(psi).*uFinal + cos(psi).*v;

[duFinalDx,duFinalDy] = gradient(uFinal, ...
    cfg.domain.Lx/Nx,cfg.domain.Ly/Ny);
propagationJacobian = cos(psi).*duFinalDx + ...
    sin(psi).*duFinalDy;
overturningMask = crestWeight > 0 & propagationJacobian < 0;

curlMask = thetaCurl >= ...
    cfg.curl.maskAngleFraction*cfg.curl.curlMultiplier;
faces = structured_triangles(Nx,Ny);
curlFacetMask = any(reshape(curlMask(faces),size(faces)),2);

surfaceData = struct();
surfaceData.X0 = X0;
surfaceData.Y0 = Y0;
surfaceData.Z0 = Z0;
surfaceData.X = X;
surfaceData.Y = Y;
surfaceData.Z = Z;
surfaceData.localU = u;
surfaceData.localV = v;
surfaceData.localUFinal = uFinal;
surfaceData.thetaCurl = thetaCurl;
surfaceData.crestWeight = crestWeight;
surfaceData.curlMask = curlMask;
surfaceData.propagationJacobian = propagationJacobian;
surfaceData.overturningMask = overturningMask;
surfaceData.faces = faces;
surfaceData.curlFacetMask = curlFacetMask;
surfaceData.verticesBaseline = [X0(:),Y0(:),Z0(:)];
surfaceData.vertices = [X(:),Y(:),Z(:)];
surfaceData.detection = detection;
surfaceData.cfg = cfg;
surfaceData.metrics.maxElevationChange = max(abs(Z(:)-Z0(:)));
surfaceData.metrics.maxHorizontalDisplacement = max(hypot( ...
    X(:)-X0(:),Y(:)-Y0(:)));
surfaceData.metrics.curlPointCount = nnz(curlMask);
surfaceData.metrics.curlProjectedArea = nnz(curlMask)* ...
    (cfg.domain.Lx/Nx)*(cfg.domain.Ly/Ny);
surfaceData.metrics.minimumPropagationJacobian = min( ...
    propagationJacobian(crestWeight > 0));
surfaceData.metrics.overturningPointCount = nnz(overturningMask);
outside = crestWeight == 0;
surfaceData.metrics.maxOutsideCrestDisplacement = max([ ...
    abs(X(outside)-X0(outside)); abs(Y(outside)-Y0(outside)); ...
    abs(Z(outside)-Z0(outside))]);
crestLine = abs(u) <= max(cfg.domain.dx,cfg.domain.dy) & ...
    crestWeight > 0;
surfaceData.metrics.crestwiseBackgroundStd = std( ...
    Z0(crestLine),0,'all');
end

function detection = detect_high_crest(X,Y,Z,cfg)
dx = cfg.domain.Lx/size(X,2);
dy = cfg.domain.Ly/size(Y,1);
sigmaCells = cfg.detection.smoothingLength/max(0.5*(dx+dy),eps);
Zsmooth = gaussian_smooth(Z,sigmaCells);

threshold = mean(Zsmooth,'all') + ...
    cfg.detection.heightSigmaThreshold*std(Zsmooth,0,'all');
margin = cfg.detection.edgeMargin;
valid = X >= margin & X <= cfg.domain.Lx-margin & ...
    Y >= margin & Y <= cfg.domain.Ly-margin;
candidates = valid & Zsmooth >= threshold;
assert(any(candidates,'all'), ...
    'No crest exceeds the configured elevation threshold.');

score = Zsmooth;
score(~candidates) = -Inf;
[~,coarseIndex] = max(score(:));

refine = valid & hypot(X-X(coarseIndex),Y-Y(coarseIndex)) <= ...
    cfg.detection.refineRadius;
indices = find(refine);
[~,localIndex] = max(Z(indices));
index = indices(localIndex);

detection.linearIndex = index;
detection.x = X(index);
detection.y = Y(index);
detection.z = Z(index);
detection.smoothedElevation = Zsmooth(index);
detection.heightThreshold = threshold;
detection.coarseIndex = coarseIndex;
detection.candidateCount = nnz(candidates);
end

function Z = synthesize_elfouhaily_surface(Nx,Ny,Lx,Ly,sea)
g = 9.81;
km = 370.0;
cm = 0.23;
Omega = sea.inverseWaveAge;
uStar = sqrt(1e-3*(0.8+0.065*sea.U10))*sea.U10;
k0 = g/sea.U10^2;
kp = k0*Omega^2;
cp = sqrt(g/kp);

if Omega <= 1
    gamma = 1.7;
else
    gamma = 1.7+6*log10(Omega);
end
alphaP = 6e-3*sqrt(Omega);
alphaM = 0.01*(1+log(max(uStar/cm,eps)));

dkx = 2*pi/Lx;
dky = 2*pi/Ly;
kx = ifftshift((-floor(Nx/2):ceil(Nx/2)-1)*dkx);
ky = ifftshift((-floor(Ny/2):ceil(Ny/2)-1)*dky);
[KX,KY] = meshgrid(kx,ky);
K = hypot(KX,KY);
Ksafe = max(K,eps);

c = sqrt(g./Ksafe.*(1+(Ksafe/km).^2));
Lpm = exp(-1.25*(kp./Ksafe).^2);
Gamma = exp(-(sqrt(Ksafe/kp)-1).^2/(2*0.08^2));
Fp = Lpm.*gamma.^Gamma.*exp(-Omega/sqrt(10).* ...
    (sqrt(Ksafe/kp)-1));
Bl = 0.5*alphaP.*(cp./c).*Fp;
Fm = exp(-0.25*(Ksafe/km-1).^2);
Bh = 0.5*alphaM.*(cm./c).*Fm;
S = (Bl+Bh)./Ksafe.^3;

windDirection = deg2rad(sea.windDirectionDeg);
phi = atan2(KY,KX)-windDirection;
spread = 2/pi.*cos(phi).^2;
Psi = max(S.*spread./Ksafe,0);
Psi(K == 0) = 0;

white = (randn(Ny,Nx)+1i*randn(Ny,Nx))/sqrt(2);
negX = [1,Nx:-1:2];
negY = [1,Ny:-1:2];
white = (white+conj(white(negY,negX)))/sqrt(2);
H = sqrt(Psi*dkx*dky).*white;
Z = real(ifft2(H)*Nx*Ny);
Z = Z-mean(Z,'all');

if sea.targetHs > 0
    Z = Z*sea.targetHs/max(4*std(Z,0,'all'),eps);
end
end

function Zs = gaussian_smooth(Z,sigmaCells)
if sigmaCells <= 0
    Zs = Z;
    return;
end
radius = max(1,ceil(3*sigmaCells));
q = -radius:radius;
kernel = exp(-0.5*(q/sigmaCells).^2);
kernel = kernel/sum(kernel);
Zs = conv2(kernel,kernel,Z,'same');
end

function w = compact_cosine(q)
w = zeros(size(q));
inside = abs(q) < 1;
w(inside) = 0.5*(1+cos(pi*q(inside)));
end

function faces = structured_triangles(Nx,Ny)
[i,j] = meshgrid(1:Nx-1,1:Ny-1);
v00 = sub2ind([Ny,Nx],j(:),i(:));
v10 = sub2ind([Ny,Nx],j(:),i(:)+1);
v01 = sub2ind([Ny,Nx],j(:)+1,i(:));
v11 = sub2ind([Ny,Nx],j(:)+1,i(:)+1);
faces = [v00,v10,v11; v00,v11,v01];
end

