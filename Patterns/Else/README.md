# Front-angle and Front-rear Asymmetry Validation

This module performs paired Monte Carlo validation for three groups:

- G0: no explicit curl;
- G1: the previous shallow-curl parameter domain;
- G2: the corrected proposed parameter domain.

The driver continues sampling until 100 seeds are valid in all three groups,
so every retained realization is a complete paired comparison. The outputs contain the
front-face angle, crest-front steepness, crest-rear steepness, and their ratio
`A_fr = epsilon_f/epsilon_r` for every valid realization.

Run in MATLAB:

```matlab
run_angle_asymmetry_monte_carlo
```

Results are written to `Else/output` as raw and summary CSV files, a MAT file,
and a two-panel PNG/PDF figure.
