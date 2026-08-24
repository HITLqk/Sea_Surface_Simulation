clear; close all; clc;

cfg = default_localized_curl_config();
cfg.output.saveMat = false;
cfg.output.saveFigure = false;
surfaceData = generate_localized_elfouhaily_curl_patch(cfg);

if ~exist(cfg.output.outputDirectory, 'dir')
    mkdir(cfg.output.outputDirectory);
end

fig = figure('Visible',cfg.output.figureVisible, 'Color','w', ...
    'Position',[100 100 1120 760]);
surf(surfaceData.X, surfaceData.Y, surfaceData.Z, surfaceData.Z, ...
    'EdgeColor','none', 'FaceColor','interp');
axis tight;
pbaspect([1.25 1 0.32]);
view(42,25);
grid on;
box on;
colormap(turbo);

xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');
title('Nonlinear Sea Surface with a Localized Curled Breaking Wave');
cb = colorbar;
cb.Label.String = 'Elevation (m)';

set(gca, 'FontName','Times New Roman', 'FontSize',12, ...
    'LineWidth',0.8, 'Layer','top');
set(fig, 'Renderer','opengl');

outputPath = fullfile(cfg.output.outputDirectory, ...
    'curled_sea_surface_only.png');
exportgraphics(fig, outputPath, 'Resolution',240);
fprintf('Curled sea figure saved to:\n  %s\n', outputPath);


