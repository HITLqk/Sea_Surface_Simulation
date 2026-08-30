# Breaker Morphology Validation Results

## Run configuration

- Random seed: `20260825`
- Sea state: `U10 = 5.0 m/s`, inverse wave age `0.84`, target `Hs = 0.35 m`
- Curl overrides: `forwardGain = 1.15`, `verticalAngleRatio = 0.28`,
  `pivotDepth = 0.95 m`, `curlMultiplier = 0.55 rad`
- Normalization: Elfouhaily spectral-peak wavelength,
  `lambda_p = 22.6930 m`

## Metrics

| Metric | Simulation | Erinin reference | Result |
|---|---:|---:|---|
| Front-face angle | 14.17 deg | 65-70 deg | OUTSIDE |
| `r_x/lambda_p` | 0.0451 | 0.049-0.069 | OUTSIDE |
| `r_y/lambda_p` | 0.0024 | 0.045-0.059 | OUTSIDE |

## Interpretation

The existing configuration produces a forward-extended but only mildly
downward-curled crest. Its horizontal normalized scale is close to the lower
experimental bound, whereas the front-face angle and vertical curl scale are
far below the mature plunging-breaker envelope. Therefore, this realization
must not yet be presented as morphology validation success.

The earlier section figure visually exaggerated the steepness because the
horizontal and vertical axes used different display scales. The validation
figure uses equal physical scaling and reports the angle fitted from the
descending front branch.

Reference: M. A. Erinin et al., "Plunging breakers. Part 1. Analysis of an
ensemble of wave profiles," *Journal of Fluid Mechanics*, vol. 967, 2023,
doi:10.1017/jfm.2023.379.
