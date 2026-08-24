clear; close all; clc;

cfg = default_localized_curl_config();
surfaceData = generate_localized_elfouhaily_curl_patch(cfg);

assert(all(isfinite(surfaceData.vertices), 'all'), ...
    'The generated mesh contains NaN or Inf values.');
assert(surfaceData.metrics.maxOutsidePatchDisplacement < 1e-12, ...
    'The localized deformation leaks outside its compact support.');

if ~exist(cfg.output.outputDirectory, 'dir')
    mkdir(cfg.output.outputDirectory);
end

fprintf('Localized breaking patch generated.\n');
fprintf('  projected footprint area : %.3f m^2\n', ...
    surfaceData.metrics.projectedFootprintArea);
fprintf('  baseline patch area      : %.3f m^2\n', ...
    surfaceData.metrics.baselinePatchSurfaceArea);
fprintf('  curled patch area        : %.3f m^2\n', ...
    surfaceData.metrics.curledPatchSurfaceArea);
fprintf('  curled/baseline ratio    : %.3f\n', ...
    surfaceData.metrics.surfaceAreaRatio);
fprintf('  maximum elevation change : %.3f m\n', ...
    surfaceData.metrics.maxElevationIncrement);
fprintf('  detected crest location   : (%.3f, %.3f, %.3f) m\n', ...
    surfaceData.crestDetection.x, surfaceData.crestDetection.y, ...
    surfaceData.crestDetection.z);
fprintf('  curl centre offset        : %.3f m before crest\n', ...
    surfaceData.curlCenterOffset);
fprintf('  maximum outside movement : %.3e m\n', ...
    surfaceData.metrics.maxOutsidePatchDisplacement);

fig = figure('Visible',cfg.output.figureVisible);
tl = tiledlayout(fig, 2, 3, 'Padding','compact', 'TileSpacing','compact');

nexttile;
surf(surfaceData.X0, surfaceData.Y0, surfaceData.Z0, ...
    'EdgeColor','none');
hold on;
plot3(surfaceData.crestDetection.x, surfaceData.crestDetection.y, ...
    surfaceData.crestDetection.z, 'kp', 'MarkerSize',11, ...
    'MarkerFaceColor','w', 'LineWidth',1.4);
curlIndex = nearest_xy(surfaceData.X0, surfaceData.Y0, ...
    surfaceData.curlCenterXY);
plot3(surfaceData.X0(curlIndex), surfaceData.Y0(curlIndex), ...
    surfaceData.Z0(curlIndex), 'ko', 'MarkerSize',8, ...
    'MarkerFaceColor',[1.0 0.75 0.1], 'LineWidth',1.2);
axis equal tight; view(42,28); grid on; colormap(turbo);
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Detected crest (*) and pre-crest curl centre (o)');

nexttile;
trisurf(surfaceData.faces, surfaceData.vertices(:,1), ...
    surfaceData.vertices(:,2), surfaceData.vertices(:,3), ...
    surfaceData.vertices(:,3), 'EdgeColor','none');
hold on;
crestVertex = surfaceData.vertices(surfaceData.crestDetection.linearIndex,:);
plot3(crestVertex(1), crestVertex(2), crestVertex(3), 'kp', ...
    'MarkerSize',11, 'MarkerFaceColor','w', 'LineWidth',1.4);
curlVertex = surfaceData.vertices(curlIndex,:);
plot3(curlVertex(1), curlVertex(2), curlVertex(3), 'ko', ...
    'MarkerSize',8, 'MarkerFaceColor',[1.0 0.75 0.1], 'LineWidth',1.2);
axis equal tight; view(42,28); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Sea with one localized curled breaking patch');

nexttile;
imagesc(surfaceData.X0(1,:), surfaceData.Y0(:,1), ...
    surfaceData.breakingMask);
set(gca,'YDir','normal'); axis equal tight; colormap(gca,gray);
xlabel('x (m)'); ylabel('y (m)');
title('Finite breaking-event mask');

nexttile;
patchVertices = surfaceData.vertices(surfaceData.breakingMask(:),:);
pad = get_patch_value(cfg.patch, 'transitionLength', 0) + 0.25;
trisurf(surfaceData.faces, surfaceData.vertices(:,1), ...
    surfaceData.vertices(:,2), surfaceData.vertices(:,3), ...
    surfaceData.support(:), 'EdgeColor','none');
xlim([min(patchVertices(:,1))-pad, max(patchVertices(:,1))+pad]);
ylim([min(patchVertices(:,2))-pad, max(patchVertices(:,2))+pad]);
zlim([min(patchVertices(:,3))-0.25, max(patchVertices(:,3))+0.15]);
axis vis3d; view(112,20); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Patch close view: oblique');
cb = colorbar; cb.Label.String = 'Breaking support weight';

nexttile;
trisurf(surfaceData.faces, surfaceData.vertices(:,1), ...
    surfaceData.vertices(:,2), surfaceData.vertices(:,3), ...
    surfaceData.support(:), 'EdgeColor','none');
xlim([min(patchVertices(:,1))-pad, max(patchVertices(:,1))+pad]);
ylim([min(patchVertices(:,2))-pad, max(patchVertices(:,2))+pad]);
zlim([min(patchVertices(:,3))-0.25, max(patchVertices(:,3))+0.15]);
axis vis3d; view(cfg.patch.propagationDirectionDeg-90, 7); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Patch close view: along crest');

nexttile;
centerStrip = abs(surfaceData.localV) <= 0.55*max(cfg.domain.dx,cfg.domain.dy);
[uBase, order] = sort(surfaceData.localU(centerStrip));
zBase = surfaceData.Z0(centerStrip);
uCurl = surfaceData.localUFinal(centerStrip);
zCurl = surfaceData.Z(centerStrip);
plot(uBase, zBase(order), 'Color',[0.25 0.25 0.25], 'LineWidth',1.2); hold on;
plot(uCurl(order), zCurl(order), 'r-', 'LineWidth',1.8);
grid on; axis equal;
plotHalfWidth = cfg.patch.crossWaveWidth/2 + ...
    get_patch_value(cfg.patch, 'transitionLength', 0) + 0.25;
xlim([-plotHalfWidth plotHalfWidth]);
xlabel('Propagation coordinate u (m)'); ylabel('z (m)');
legend('Background','Curled surface','Location','best');
title('Central propagation-direction section');

title(tl, sprintf(['Localized patch: %.2f m crest, %.2f m width, ', ...
    '%.0f deg maximum curl'], ...
    cfg.patch.crestLength, cfg.patch.crossWaveWidth, cfg.patch.maxCurlDeg));

if cfg.output.saveMat
    % Compatibility aliases for the existing Echo_Caculate.m interface.
    X_cut = surfaceData.X;
    Y_cut = surfaceData.Y;
    Z_cut = surfaceData.Z;
    x_points = X_cut(:);
    y_points = Y_cut(:);
    z_points = Z_cut(:);
    tri = surfaceData.faces;
    breakingFacetMask = surfaceData.breakingFacetMask;
    save(fullfile(cfg.output.outputDirectory, ...
        'localized_elfouhaily_curl_surface.mat'), 'surfaceData', ...
        'X_cut','Y_cut','Z_cut','x_points','y_points','z_points', ...
        'tri','breakingFacetMask','-v7.3');
end
if cfg.output.saveFigure
    exportgraphics(fig, fullfile(cfg.output.outputDirectory, ...
        'localized_elfouhaily_curl_preview.png'), 'Resolution',180);
end

function index = nearest_xy(X, Y, xy)
[~,index] = min((X(:)-xy(1)).^2 + (Y(:)-xy(2)).^2);
end

function value = get_patch_value(patch, name, fallback)
if isfield(patch,name) && ~isempty(patch.(name))
    value = patch.(name);
else
    value = fallback;
end
end

