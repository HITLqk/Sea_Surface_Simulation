# Breaker Morphology Monte Carlo Validation

## Final representative configuration

- Random seed: `20260825`
- Sea state: `U10 = 5.0 m/s`, inverse wave age `0.84`, target `Hs = 0.35 m`
- Corrected curl: `amplitudeCurl = 0.21 m`, `curlMultiplier = 1.16 rad`,
  `pivotDepth = 0.915 m`, `forwardGain = 1.05`,
  `verticalAngleRatio = 1.59`
- Normalization: Elfouhaily spectral-peak wavelength,
  `lambda_p = 22.6930 m`

| Metric | Simulation | Erinin reference | Result |
|---|---:|---:|---|
| Front-face angle | 68.54 deg | 65-70 deg | PASS |
| `r_x/lambda_p` | 0.0565 | 0.049-0.069 | PASS |
| `r_y/lambda_p` | 0.0525 | 0.045-0.059 | PASS |

## Independent Monte Carlo validation

The final run used random seed `20260901` and generated 100 surfaces per
group. Every realization changed the random sea seed and independently sampled
five curl parameters within its group range.

| Group | Valid runs | Joint passes | Pass rate | Angle mean +/- 95% CI | `r_x/lambda_p` mean +/- 95% CI | `r_y/lambda_p` mean +/- 95% CI |
|---|---:|---:|---:|---:|---:|---:|
| Original | 100 | 0 | 0% | 6.69 +/- 1.65 deg | 0.04482 +/- 0.00077 | 0.00210 +/- 0.00015 |
| Corrected | 100 | 82 | 82% | 68.10 +/- 0.35 deg | 0.05640 +/- 0.00051 | 0.05290 +/- 0.00059 |

The pass rate is a strict joint criterion: angle and both normalized scales
must fall inside their reference intervals in the same realization.

## Why the original model differed

The curl generator was not structurally unable to create a plunging profile.
The main problem was the demonstration constraint
`verticalAngleRatio = 0.28`, which reduced the vertical rotation to 28% of the
horizontal curl angle. It produced a long forward lip with almost no downward
turning. The old assertion further required forward displacement to exceed
downward displacement, reinforcing that shallow geometry.

The correction restores a mature downward rotation and constrains coupled
parameters using Monte Carlo results. The final corrected ranges are:

| Parameter | Corrected range |
|---|---:|
| `amplitudeCurl` | 0.19-0.23 m |
| `curlMultiplier` | 1.12-1.20 rad |
| `pivotDepth` | 0.85-0.98 m |
| `forwardGain` | 0.98-1.12 |
| `verticalAngleRatio` | 1.54-1.64 |

The default model uses the center of this range. The model assertion now
requires downward displacement to reach at least 25% of forward displacement,
instead of requiring forward displacement to dominate.

## Paper use

For the five-page Letter, use only
`breaker_morphology_monte_carlo.png` and the two summary rows. The
single-realization profile is an internal diagnostic and need not appear in the
paper.

Reference: M. A. Erinin et al., "Plunging breakers. Part 1. Analysis of an
ensemble of wave profiles," *Journal of Fluid Mechanics*, vol. 967, 2023,
doi:10.1017/jfm.2023.379.
