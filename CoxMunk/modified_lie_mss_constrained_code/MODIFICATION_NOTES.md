# Elfouhaily statistical closure: implementation notes

## Removed circular constraint

The previous implementation formed a component-wise fusion of Cox-Munk, Guerin, and TGRS/Hu and contracted every realization toward that target. That made the same observations both calibration targets and validation references. It also produced the decreasing nonlinear anisotropy curve seen in the earlier figure.

## New closure

- The only closure target is the numerical integral of the same directional Elfouhaily spectrum used to generate the linear group.
- Calibration seeds `101:112` and validation seeds `1:20` are disjoint.
- Degree-two functions of normalized `log(U10)` model the along- and cross-wind log scale factors.
- One deterministic scale pair is used for all validation realizations at a given wind speed, preserving Monte Carlo scatter.
- Positive angular spectral dressing realizes the scale pair while preserving Fourier phase and nonlinear crest geometry.
- Cox-Munk, Guerin, and TGRS/Hu are external comparisons only.

This is an Elfouhaily-style statistical closure in methodology: smooth global wind-dependent parameterization fitted to ensemble spectral moments. It is not a claim that these fitted coefficients are part of the original 1997 model.

## Full-run results

The fitted along-wind scales decrease from `0.98049` at `1 m/s` to `0.97069` at `10 m/s`; cross-wind scales decrease from `1.00050` to `0.97539`. None is near the safety bounds `[0.50, 1.50]`, so the closure is a modest correction.

On held-out validation seeds, nonlinear anisotropy changes from the raw range `0.7682-0.8381` to `0.7760-0.8405`. The corrected curve follows the increasing Elfouhaily trend and no longer shows the old `0.95` low-wind artifact.

| Group | RMSE Elfouhaily | RMSE Cox-Munk | RMSE Guerin | RMSE TGRS/Hu |
|---|---:|---:|---:|---:|
| Linear Elfouhaily | 0.000753 | 0.005602 | 0.005228 | 0.003827 |
| Constrained Modified Lie | 0.000195 | 0.005072 | 0.004354 | 0.003173 |

The result does not coincide with Cox-Munk, Guerin, or TGRS/Hu. Those residuals are expected and are precisely what the external validation quantifies.
