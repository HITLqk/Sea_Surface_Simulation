function pair = calculate_local_paired_scattering(surfaceData, cfg)
%CALCULATE_LOCAL_PAIRED_SCATTERING Evaluate G0/G1 on one fixed local patch.

faces = double(surfaceData.faces);
uFace = mean(surfaceData.localU(faces), 2);
vFace = mean(surfaceData.localV(faces), 2);
inWindow = abs(uFace) <= 0.5*cfg.window.propagationLength & ...
    abs(vFace) <= 0.5*cfg.window.crestwiseLength;
localFaces = faces(inWindow, :);

assert(~isempty(localFaces), 'The configured local window contains no faces.');

propagationDirectionDeg = get_propagation_direction(surfaceData.cfg);
psi = deg2rad(propagationDirectionDeg + cfg.radar.lookAzimuthOffsetDeg);
gamma = deg2rad(cfg.radar.grazingAngleDeg);
unitToRadar = [cos(gamma)*cos(psi), cos(gamma)*sin(psi), sin(gamma)];

pre = facet_rcs_proxy(surfaceData.verticesBaseline, localFaces, unitToRadar);
curl = facet_rcs_proxy(surfaceData.vertices, localFaces, unitToRadar);

fixedWindowArea = cfg.window.propagationLength*cfg.window.crestwiseLength;
preRcs = sum(pre.rcsLinear);
distributedCurlRcs = sum(curl.rcsLinear);

chi = surfaceData.cfg.curl.curlMultiplier/ ...
    cfg.chi.maximumCurlMultiplier;
jacobianSeverity = max(0, -surfaceData.metrics.minimumPropagationJacobian);
breakerActivity = chi*(1 + ...
    cfg.scattering.jacobianSeverityWeight*jacobianSeverity);
nonBraggRcs = cfg.scattering.nonBraggPowerCoefficient* ...
    preRcs*breakerActivity;
curlRcs = distributedCurlRcs + nonBraggRcs;

pair = struct();
pair.preRcsLinear = preRcs;
pair.curlRcsLinear = curlRcs;
pair.distributedCurlRcsLinear = distributedCurlRcs;
pair.nonBraggRcsLinear = nonBraggRcs;
pair.breakerActivity = breakerActivity;
pair.jacobianSeverity = jacobianSeverity;
pair.preRcs_dBsm = linear_to_db(preRcs);
pair.curlRcs_dBsm = linear_to_db(curlRcs);
pair.Gb_dB = linear_to_db(curlRcs/preRcs);
pair.preLocalNrcsLinear = preRcs/fixedWindowArea;
pair.curlLocalNrcsLinear = curlRcs/fixedWindowArea;
pair.windowArea = fixedWindowArea;
pair.faceCount = size(localFaces, 1);
pair.preVisibleFraction = mean(pre.visible);
pair.curlVisibleFraction = mean(curl.visible);
pair.pre = pre;
pair.curl = curl;
pair.mapU = uFace(inWindow);
pair.mapV = vFace(inWindow);
end

function directionDeg = get_propagation_direction(generatorCfg)
% Support both the current generator interface and older saved surfaces.
if isfield(generatorCfg, 'detection') && ...
        isfield(generatorCfg.detection, 'propagationDirectionDeg')
    directionDeg = generatorCfg.detection.propagationDirectionDeg;
elseif isfield(generatorCfg, 'curl') && ...
        isfield(generatorCfg.curl, 'propagationDirectionDeg')
    directionDeg = generatorCfg.curl.propagationDirectionDeg;
else
    error('NRCS:MissingPropagationDirection', ...
        ['Generator configuration must define detection.', ...
        'propagationDirectionDeg.']);
end
end

function facet = facet_rcs_proxy(vertices, faces, unitToRadar)
p1 = vertices(faces(:,1), :);
p2 = vertices(faces(:,2), :);
p3 = vertices(faces(:,3), :);

areaVector = cross(p2-p1, p3-p1, 2);
twiceArea = vecnorm(areaVector, 2, 2);
assert(all(twiceArea > 0), 'Degenerate triangle found in the local patch.');

normal = areaVector./twiceArea;
flip = normal(:,3) < 0;
normal(flip,:) = -normal(flip,:);
area = 0.5*twiceArea;
cosIncidence = normal*unitToRadar(:);
visible = cosIncidence > 0;

rcsLinear = zeros(size(area));
rcsLinear(visible) = area(visible).*cosIncidence(visible).^2;

facet = struct();
facet.centres = (p1+p2+p3)/3;
facet.area = area;
facet.normal = normal;
facet.cosIncidence = cosIncidence;
facet.visible = visible;
facet.rcsLinear = rcsLinear;
facet.rcs_dBsm = linear_to_db(rcsLinear);
end

function value = linear_to_db(value)
value = 10*log10(max(value, realmin('double')));
end
