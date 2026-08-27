# Modern MSS validation

## Low-to-moderate wind: Guerin 2023

```matlab
cfg = default_modern_mss_validation_config("guerin");
[raw,summary,reference,assessment,figures] = ...
    run_modern_nonlinear_mss_validation(cfg);
```

The default experiment uses `U10=3:0.5:15 m/s`, 20 paired random
realizations per wind speed, a `256 m x 256 m` domain, and `0.25 m`
spacing. It compares along-wind and cross-wind MSS against the IASI values
reported in Table 1 of Guerin et al. (2023) and the height-corrected
Cox-Munk relations.

Primary figures are realization scatter plots and quantile box plots. CSV
files retain every realization and the median, interquartile range, and
5%-95% interval.

## Hurricane wind: Davis 2025

```matlab
cfg = default_modern_mss_validation_config("davis");
[raw,summary,reference,assessment,figures] = ...
    run_modern_nonlinear_mss_validation(cfg);
```

This mode synthesizes only `k=0.01-1 rad/m`, matching the reported Davis
fit:

```text
mss = 0.0250*tanh(0.0476*U10)-0.0020
```

The domain length is exactly `2*pi/0.01`, and the 1024-by-1024 grid
resolves the 1 rad/m upper limit with about ten samples per shortest wave.
The default wind grid includes the low-wind transition and the 25, 30, 35,
45, and 50 m/s hurricane regimes. High-wind mode initially evaluates only
`Linear` and `G0_Nonlinear`; the current single inserted curl is not a
wind-dependent breaking-rate model and is therefore excluded from the
Davis comparison.

## Smoke tests

Use fewer winds and seeds without changing the physical grid:

```matlab
cfg = default_modern_mss_validation_config("guerin");
cfg.windSpeeds = [3 10 15];
cfg.randomSeeds = 20260801:20260802;
cfg.output.figureVisible = 'off';
cfg.output.directory = fullfile(pwd,'output_modern_guerin_smoke');
run_modern_nonlinear_mss_validation(cfg);
```

Do not reduce the Davis domain length or increase its grid spacing for a
paper result, because that changes the validated wavenumber support or
the numerical slope response.
