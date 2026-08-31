# Literature reference extraction audit

## Usable quantitative reference

The current comparison uses Kim and Johnson, *IEEE TGRS*, vol. 40,
no. 10, 2002, Fig. 8(a), DOI 10.1109/TGRS.2002.802475.

- The source uses the LONGTANK wave sequence and reports 10--14 GHz
  image-domain scattering over incidence angles 60--80 degrees
  (grazing angles 30--10 degrees).
- Only the fixed HH panel is digitized. No polarization comparison is made.
- Direct, single-bounce, and double-bounce maximum image magnitudes were
  digitized at each wave stage.
- The dominant-path magnitude is the maximum of the three mechanisms.
- Waves 1--8 define the prebreaking reference. Their median dominant-path
  magnitude is -21.65 dB.
- Waves 9--16 define the breaking interval. The derived reference metric is
  `Gb_ref = dominant_path(wave) - median(dominant_path(waves 1:8))`.
- The resulting breaking-stage range is 2.25--7.85 dB and the median is
  6.10 dB. A conservative +/-1 dB digitization uncertainty is retained.

This `Gb_ref` is a derived comparison quantity, not an indicator explicitly
defined by Kim and Johnson. It is suitable for checking the order of magnitude
and stage trend of a local breaker enhancement. It is not an absolute NRCS
calibration target because the source quantity is maximum image magnitude.

## Supporting baselines not converted into Gb

West and Zhao, *IEEE TGRS*, vol. 40, no. 3, 2002, use 32 Monte Carlo roughness
realizations and compare a model-based solution with a full MM/GTD numerical
reference. They report agreement within 2 dB under most conditions. This is a
method-accuracy baseline, not a prebreaking-to-breaking gain curve.

Li et al., *IEEE TGRS*, vol. 55, no. 4, 2017, compare sea-surface NRCS with and
without breakers against measured/empirical data. At 15 m/s and moderate
incidence, the paper states an approximately 2 dB HH increase. That is a
whole-surface NRCS result and is therefore not mixed into the local `Gb_ref`
curve used here.

West (2002), Li and West (2006), and Sletten et al. (2003) remain useful
mechanism references, but no values from unavailable or relative-only figures
are inserted into the quantitative CSV.
