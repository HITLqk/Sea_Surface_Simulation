# Front-angle and Asymmetry Validation Results

## Experiment

- Groups: G0 no-breaking, G1 shallow-curl ablation, G2 proposed model.
- Complete paired samples: 100 per group.
- Attempted seed/parameter pairs: 131.
- Complete-pair acceptance rate: 76.34%.
- Every retained pair uses the same random sea seed in G0, G1, and G2.

## Results

| Group | Angle median (95% bootstrap CI) | Angle coverage in 65-70 deg | `epsilon_f` median | `epsilon_r` median | `A_fr` median (95% bootstrap CI) | `P(A_fr>1)` |
|---|---:|---:|---:|---:|---:|---:|
| G0 No-breaking | 4.57 deg (3.82-5.26) | 0% | 0.0556 | 0.0597 | 0.962 (0.824-1.091) | 46% |
| G1 Shallow-curl | 3.71 deg (2.50-4.30) | 0% | 0.0576 | 0.0602 | 1.008 (0.855-1.214) | 50% |
| G2 Proposed | 68.14 deg (67.70-68.54) | 77% | 0.4690 | 0.0796 | 5.814 (5.364-6.652) | 100% |

## Interpretation

The proposed model produces a mature front-face angle consistent with the
Erinin 65-70 deg envelope. G0 and G1 remain shallow and do not enter that
range.

The asymmetry result does not pass the auxiliary empirical envelope. G2 has a
very steep front and a comparatively mild rear slope, giving `A_fr` around
5.8 rather than 1.6-2.35. This indicates that the current corrected curl
shortens the front zero-crossing distance too strongly. The model should not
yet be described as validated for front-rear asymmetry.

The 1.6-2.35 interval is a derived auxiliary range, not a universal interval
directly reported by Bonmarin. It is shown for diagnosis and is not used as a
hard universal pass criterion.
