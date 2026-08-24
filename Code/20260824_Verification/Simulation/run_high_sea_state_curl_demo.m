clear; close all; clc;

cfg = default_localized_curl_config();

% Use a larger domain and an independent realization so that the higher
% sea state changes the resolved wavelengths and morphology, not only Hs.
cfg.randomSeed = 20260824;
cfg.domain.Lx = 36.0;
cfg.domain.Ly = 36.0;
cfg.domain.dx = 0.06;
cfg.domain.dy = 0.06;
cfg.sea.U10 = 12.0;
cfg.sea.inverseWaveAge = 2.0;
cfg.sea.windDirectionDeg = 15.0;
cfg.sea.targetHs = 0.90;

% Scale the localized geometry with the larger, younger wind waves while
% retaining a low rotation angle and a broad transition region.
cfg.patch.crestSearchSmoothingLength = 0.40;
cfg.patch.crestRefineRadius = 0.50;
cfg.patch.propagationDirectionDeg = 15.0;
cfg.patch.crestLength = 7.0;
cfg.patch.crossWaveWidth = 3.60;
cfg.patch.transitionLength = 2.40;
cfg.patch.crestHeight = 0.080;
cfg.patch.evolutionHeight = 0.050;
cfg.patch.evolutionLean = 0.080;
cfg.patch.curlCenterOffset = -0.55;
cfg.patch.maxCurlDeg = 20.0;
cfg.patch.pivotDepth = 0.100;
cfg.patch.forwardLean = 0.040;

cfg.output.outputDirectory = fullfile(fileparts(mfilename('fullpath')), ...
    'output', 'high_sea_state');
if ~exist(cfg.output.outputDirectory, 'dir')
    mkdir(cfg.output.outputDirectory);
end

surfaceData = generate_localized_elfouhaily_curl_patch(cfg);

assert(all(isfinite(surfaceData.vertices), 'all'), ...
    'The generated mesh contains NaN or Inf values.');
assert(surfaceData.metrics.maxOutsidePatchDisplacement < 1e-12, ...
    'The localized deformation leaks outside its compact support.');

fprintf('High sea-state curled surface generated.\n');
fprintf('  U10                      : %.2f m/s\n', cfg.sea.U10);
fprintf('  target Hs                : %.2f m\n', cfg.sea.targetHs);
fprintf('  inverse wave age         : %.2f\n', cfg.sea.inverseWaveAge);
fprintf('  domain                   : %.1f x %.1f m\n', ...
    cfg.domain.Lx, cfg.domain.Ly);
fprintf('  detected crest elevation: %.3f m\n', ...
    surfaceData.crestDetection.z);
fprintf('  maximum elevation change: %.3f m\n', ...
    surfaceData.metrics.maxElevationIncrement);

figSurface = new_figure(cfg.output.figureVisible, [100 100 1120 760]);
trisurf(surfaceData.faces, surfaceData.vertices(:,1), ...
    surfaceData.vertices(:,2), surfaceData.vertices(:,3), ...
    surfaceData.vertices(:,3), 'EdgeColor','none', ...
    'FaceColor','interp');
axis tight;
pbaspect([1.25 1 0.34]);
view(42,25);
grid on;
box on;
colormap(turbo);
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('High Sea-state Surface with a Localized Curled Breaking Wave');
cb = colorbar;
cb.Label.String = 'Elevation (m)';

figSection = new_figure(cfg.output.figureVisible, [140 140 920 680]);
centerStrip = abs(surfaceData.localV) <= ...
    0.55*max(cfg.domain.dx,cfg.domain.dy);
[uBase, order] = sort(surfaceData.localU(centerStrip));
zBase = surfaceData.Z0(centerStrip);
uCurl = surfaceData.localUFinal(centerStrip);
zCurl = surfaceData.Z(centerStrip);
plot(uBase, zBase(order), 'Color',[0.25 0.25 0.25], ...
    'LineWidth',1.2); hold on;
plot(uCurl(order), zCurl(order), 'r-', 'LineWidth',1.8);
grid on;
plotHalfWidth = cfg.patch.crossWaveWidth/2 + ...
    cfg.patch.transitionLength + 0.25;
xlim([-plotHalfWidth plotHalfWidth]);
sectionWindow = abs(uBase) <= plotHalfWidth;
sectionElevation = [zBase(order(sectionWindow)); ...
    zCurl(order(sectionWindow))];
sectionRange = max(sectionElevation) - min(sectionElevation);
sectionMargin = max(0.04, 0.15*sectionRange);
ylim([min(sectionElevation)-sectionMargin, ...
    max(sectionElevation)+sectionMargin]);
xlabel('Propagation coordinate u (m)'); ylabel('z (m)');
legend('Background','Curled surface','Location','best');
title('High Sea-state Central Propagation-direction Section');

exportgraphics(figSurface, fullfile(cfg.output.outputDirectory, ...
    'high_sea_state_curled_surface.png'), 'Resolution',240);
exportgraphics(figSection, fullfile(cfg.output.outputDirectory, ...
    'high_sea_state_section_comparison.png'), 'Resolution',180);

function fig = new_figure(visibility, position)
fig = figure('Visible',visibility, 'Color','w', 'Position',position);
set(gca, 'FontName','Times New Roman', 'FontSize',12, ...
    'LineWidth',0.8, 'Layer','top');
end

