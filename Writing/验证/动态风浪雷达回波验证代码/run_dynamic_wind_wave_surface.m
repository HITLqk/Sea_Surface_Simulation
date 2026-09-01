%% RUN_DYNAMIC_WIND_WAVE_SURFACE
% Generate the Linear baseline and Proposed nonlinear wind-wave sea only.

clear;
clc;
close all;

cfg = wind_wave_simulation_config();
cfg.paths.outputDir = fullfile(cfg.paths.simulationDir,'surface_output');
cfg.output.generateRadarEcho = false;
simulate_wind_wave_paired_echo(cfg);

fprintf('\nDynamic wind-wave sea complete. Results: %s\n', ...
    cfg.paths.outputDir);
