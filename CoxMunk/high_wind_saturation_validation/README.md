# High-sea-state saturation validation

This is a separate extension of the previous Modified-Lie implementation. It does not overwrite the low-wind experiment.

## Groups

1. `Linear Elfouhaily`: unmodified band-limited Elfouhaily baseline.
2. `Raw Modified Lie`: previous Modified-Lie geometry with a 5% resolved-MSS safety limit.
3. `Saturation-Constrained Modified Lie`: Modified Lie after a high-wind spectral-tail closure.

All comparisons use `k=0.01-1 rad/m`, matching Davis et al. (2025), and scan `U10=15:2.5:50 m/s`. Eight paired realizations are generated at every wind speed.

## Saturation closure

The spectrum is modified by

```text
Psi_sat(k,U) = G(U) exp[-mu(U)(k/k_max)^p] Psi_Elf(k,U),  p=2.
```

`mu(U)` limits high-wavenumber slope energy as breaking dissipation becomes dominant. `G(U)` is one except where the unmodified finite-band Elfouhaily energy falls below the asymptotic high-wind level; its configured upper bound is `1.05`, and the fitted maximum is `1.0243` at `50 m/s`.

Closure parameters are fitted at `15,20,...,50 m/s`. Interleaved winds `17.5,22.5,...,47.5 m/s` are held out from parameter estimation and used to test smooth interpolation.

## Result

| Group | Held-out RMSE |
|---|---:|
| Linear Elfouhaily | 0.0021104 |
| Raw Modified Lie | 0.0030357 |
| Saturation-constrained Modified Lie | 0.00010785 |

The corrected median MSS increases from `0.013295` at `15 m/s` to `0.022611` at `50 m/s` and progressively flattens. Its fitted slope falls from `5.36e-4` over `15-25 m/s` to `7.48e-5` over `40-50 m/s`, a ratio of `0.140`. The held-out RMSE is about 94.9% lower than the linear Elfouhaily baseline.

This is an empirically constrained model. The interleaved holdout tests interpolation across wind speed, not independence from Davis 2025. A final independent validation requires hurricane observations not used to define this closure.

Run:

```matlab
cd('E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\CoxMunk\high_wind_saturation_validation\CoxMunk')
run_high_wind_saturation_validation
```
