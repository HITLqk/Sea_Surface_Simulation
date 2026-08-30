# Breaker Morphology Validation

This directory implements the minimal morphology validation used by the
five-page GRSL manuscript. It measures only:

1. front-face angle, referenced to 65-70 deg;
2. normalized curl dimensions, referenced to
   `rx/lambda = 0.049-0.069` and `ry/lambda = 0.045-0.059`.

The ranges are the weak-to-strong envelope derived from Erinin et al.,
"Plunging breakers. Part 1," JFM 967 (2023), doi:10.1017/jfm.2023.379.

## Run

Keep `Patterns` and `Curl` as sibling directories, then run:

```matlab
run_breaker_morphology_validation
```

The script reuses the existing Curl generator without modifying it. Outputs
are written to `Patterns/output`:

- `breaker_morphology_validation.png` and `.pdf`;
- `breaker_morphology_metrics.csv`;
- `breaker_morphology_validation.mat`.

The default normalization uses the Elfouhaily spectral-peak wavelength. To
compare a measured profile, set `cfg.normalization.mode = 'fixed'` and supply
the measured local wavelength in `fixedWavelength`. A fixed literature
wavelength must not be used merely to force a metric into the reference band.

The profile panel uses equal physical scaling in `u/lambda` and `z/lambda`.
This is intentional: visually stretching the vertical axis can make a shallow
front face appear close to vertical and invalidate the angle comparison.
