%% RUN_WIND_WAVE_VALIDATION
% Compare Linear, Proposed wind-wave and Measured sea-clutter echoes.

clear;
clc;
close all;

cfg = wind_wave_validation_config();
compare_wind_wave_validation(cfg);

fprintf('\nWind-wave validation complete. Results: %s\n', ...
    cfg.paths.outputDir);
