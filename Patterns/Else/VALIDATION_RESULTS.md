# Conditioned Front-angle and Asymmetry Results

## Experiment

- Groups: G0 no-breaking, G1 shallow-curl ablation, G2 conditioned model.
- Complete paired samples: 100 per group.
- Attempted random seed/parameter pairs: 487.
- Conditional acceptance rate: 20.53%.
- Every retained pair uses the same sea seed and selected orientation in all
  three groups.

The static Elfouhaily height field has no signed phase velocity. For G2, the
generator evaluates the `0` and `180` deg propagation directions and retains a
realization only when both requested intervals are satisfied. The G2 result is
therefore a conditional-generation result, not an unconditional prediction.

## Results

| Group | Angle median (95% bootstrap CI) | Angle coverage in 65-70 deg | `epsilon_f` median | `epsilon_r` median | `A_fr` median (95% bootstrap CI) | `P(A_fr>1)` |
|---|---:|---:|---:|---:|---:|---:|
| G0 No-breaking | 5.66 deg (5.19-6.37) | 0% | 0.0763 | 0.0369 | 2.085 (2.027-2.185) | 99% |
| G1 Shallow-curl | 6.08 deg (4.59-7.60) | 0% | 0.0793 | 0.0359 | 2.254 (2.177-2.363) | 100% |
| G2 Conditioned | 67.55 deg (67.27-68.03) | 100% | 0.0854 | 0.0457 | 1.861 (1.805-1.960) | 100% |

## Model correction

Two validation errors were corrected before parameter conditioning:

1. The center profile is now periodically wrapped around the detected crest.
   Without wrapping, crests near the domain edge could have no observable
   forward zero crossing.
2. Carrier-wave zero crossings are tracked using undeformed material indices.
   The plunging jet's own mean-level intersection is not treated as the outer
   wave boundary.

The conditioned G2 parameter domain is:

| Parameter | Range |
|---|---:|
| `amplitudeCurl` | 0.19-0.23 m |
| `curlMultiplier` | 1.12-1.20 rad |
| `pivotDepth` | 0.85-0.98 m |
| `forwardGain` | 0.98-1.12 |
| `verticalAngleRatio` | 1.54-1.64 |
| `propagationDirectionDeg` | selected from 0 or 180 deg |

## Interpretation boundary

All blue G2 points lie inside both displayed intervals by construction. This
demonstrates that the simulator can generate a requested morphology family and
quantifies the cost through a 20.53% acceptance rate.

The asymmetry panel does not prove that curling independently creates the
carrier-wave asymmetry: conditioning also selects G0/G1 carrier waves whose
`A_fr` values are near the auxiliary interval. The front-angle panel still
separates G2 clearly from G0 and G1. In a paper, the figure must be described as
conditional morphology generation, not independent validation against unseen
experimental data.
