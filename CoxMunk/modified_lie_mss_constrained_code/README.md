# Two-group Elfouhaily and modified-Lie MSS validation

This implementation compares two paired groups on `U10 = 1:1:10 m/s`:

1. `Linear Elfouhaily`: a linear realization of the directional Elfouhaily spectrum.
2. `Elfouhaily-Constrained Modified Lie`: the same realization after the dimensionally consistent second-order Lie/Creamer transform and a global Elfouhaily statistical closure.

## Constraint versus validation

The closure is calibrated with seeds `101:112`, while reported validation uses held-out seeds `1:20`. For each wind speed, the calibration ensemble provides the median raw Modified-Lie along- and cross-wind MSS. Low-order polynomials in normalized `log(U10)` fit the two scale ratios between those medians and the integrated directional Elfouhaily spectrum. These deterministic wind-dependent scales are then applied to every held-out realization.

No validation realization is projected onto an empirical value. Cox-Munk, Guerin IASI, and TGRS/Hu are not used to estimate the closure and remain external references. The raw pre-closure Modified-Lie medians are plotted so the correction is auditable.

The positive angular dressing `|G(phi)|^2 = exp(lambda0 + lambda2*cos(2*phi))` realizes the two smooth scale factors without changing Fourier phase. Separate along- and cross-wind closure functions correct directional energy, while anisotropy `gamma` remains a model output rather than a directly imposed observational value.

## Spectral implementation

In the Lie/Creamer formulation, `h_tx` and `h_ty` are implemented as the two Riesz components of elevation. The primary grid uses `dk = kp/12`; independent octave tiles synthesize unresolved short-wave bands to `pi*1000 rad/m`. Elfouhaily uses `Cd=(0.8+0.065*U10)*1e-3` and `alpha_p=0.006*sqrt(Omega)`.

Run in MATLAB:

```matlab
cd('E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\CoxMunk\modified_lie_mss_constrained_code')
run_thesis_two_group_validation
```

Figures, CSV tables, and the MAT file are written to `output`.
