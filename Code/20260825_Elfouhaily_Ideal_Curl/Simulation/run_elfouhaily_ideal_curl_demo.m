clear; close all; clc;

cfg = default_elfouhaily_ideal_curl_config();
surfaceData = generate_elfouhaily_ideal_curl_surface(cfg);
assert(surfaceData.metrics.overturningPointCount > 0, ...
    'The selected crest is deformed but does not geometrically curl.');
assert(surfaceData.metrics.maxOutsideCrestDisplacement < 1e-12, ...
    'The curl deformation leaks outside the finite crest window.');
assert(surfaceData.metrics.crestwiseBackgroundStd > 0, ...
    'The curled patch has collapsed to a crestwise-constant extrusion.');

if ~exist(cfg.output.outputDirectory,'dir')
    mkdir(cfg.output.outputDirectory);
end

fprintf('2-D Elfouhaily ideal curl generated.\n');
fprintf('  height threshold         : %.4f m\n', ...
    surfaceData.detection.heightThreshold);
fprintf('  selected crest           : (%.3f, %.3f, %.3f) m\n', ...
    surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z);
fprintf('  above-threshold candidates: %d\n', ...
    surfaceData.detection.candidateCount);
fprintf('  curl points              : %d\n', ...
    surfaceData.metrics.curlPointCount);
fprintf('  minimum du_final/du      : %.4f\n', ...
    surfaceData.metrics.minimumPropagationJacobian);
fprintf('  overturning points       : %d\n', ...
    surfaceData.metrics.overturningPointCount);
fprintf('  crestwise background std : %.5f m\n', ...
    surfaceData.metrics.crestwiseBackgroundStd);
fprintf('  outside-window movement  : %.3e m\n', ...
    surfaceData.metrics.maxOutsideCrestDisplacement);

figBackground = new_figure(cfg.output.figureVisible,[80 80 1040 720]);
surf(surfaceData.X0,surfaceData.Y0,surfaceData.Z0, ...
    surfaceData.Z0,'EdgeColor','none');
hold on;
plot3(surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z,'kp','MarkerFaceColor','w', ...
    'MarkerSize',12,'LineWidth',1.4);
axis tight; pbaspect([1 1 0.28]); view(44,26); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Elfouhaily Sea and Height-selected Crest');
colormap(turbo); colorbar;

figCurl = new_figure(cfg.output.figureVisible,[110 110 1040 720]);
surf(surfaceData.X,surfaceData.Y,surfaceData.Z, ...
    surfaceData.Z,'EdgeColor','none');
axis tight; pbaspect([1 1 0.28]); view(44,26); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Ideal Curl Applied to the 2-D Elfouhaily Sea');
colormap(turbo); colorbar;

strip = abs(surfaceData.localV) <= ...
    0.55*max(cfg.domain.dx,cfg.domain.dy);
[uBase,order] = sort(surfaceData.localU(strip));
zBase = surfaceData.Z0(strip);
uCurl = surfaceData.localUFinal(strip);
zCurl = surfaceData.Z(strip);

figSection = new_figure(cfg.output.figureVisible,[140 140 920 620]);
plot(uBase,zBase(order),'Color',[0.25 0.25 0.25], ...
    'LineWidth',1.2); hold on;
plot(uCurl(order),zCurl(order),'r-','LineWidth',1.9);
xlim([-1.4 1.4]); grid on;
xlabel('Propagation coordinate u (m)'); ylabel('z (m)');
legend('Elfouhaily background','Ideal-curled surface', ...
    'Location','best');
title('Height-selected Crest Section');

figCloseup = new_figure(cfg.output.figureVisible,[170 170 1040 720]);
surf(surfaceData.X,surfaceData.Y,surfaceData.Z, ...
    surfaceData.Z,'EdgeColor','none');
patchX = surfaceData.X(surfaceData.curlMask);
patchY = surfaceData.Y(surfaceData.curlMask);
patchZ = surfaceData.Z(surfaceData.curlMask);
xlim([min(patchX)-0.35,max(patchX)+0.35]);
ylim([min(patchY)-0.35,max(patchY)+0.35]);
zlim([min(patchZ)-0.06,max(patchZ)+0.06]);
axis vis3d; view(105,18); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Local 3-D Ideal Curl on the Elfouhaily Crest');
colormap(turbo); colorbar;

exportgraphics(figBackground,fullfile(cfg.output.outputDirectory, ...
    '01_elfouhaily_height_selected_crest.png'),'Resolution',180);
exportgraphics(figCurl,fullfile(cfg.output.outputDirectory, ...
    '02_elfouhaily_ideal_curled_surface.png'),'Resolution',180);
exportgraphics(figSection,fullfile(cfg.output.outputDirectory, ...
    '03_elfouhaily_ideal_curl_section.png'),'Resolution',200);
exportgraphics(figCloseup,fullfile(cfg.output.outputDirectory, ...
    '04_elfouhaily_ideal_curl_closeup.png'),'Resolution',220);

function fig = new_figure(visibility,position)
fig = figure('Visible',visibility,'Color','w','Position',position);
set(gca,'FontName','Times New Roman','FontSize',12, ...
    'LineWidth',0.8,'Layer','top');
end

