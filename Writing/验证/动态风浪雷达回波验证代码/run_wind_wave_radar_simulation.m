%% RUN_WIND_WAVE_RADAR_SIMULATION
% Generate Linear/Proposed dynamic seas and complex radar echoes.

clear;
clc;
close all;

cfg = wind_wave_simulation_config();
simulate_wind_wave_paired_echo(cfg);

fprintf('\nWind-wave radar simulation complete. Results: %s\n', ...
    cfg.paths.outputDir);
