# Method applicability scope for NAV X-band sea-detecting dataset

Date: 2026-07-09

## Purpose

This note resets the applicability scope of the proposed sea-surface modeling and radar-echo simulation method after applying it to the dataset located at:

`E:\_Dataset\2026_07_03_NAVXbandSeadetecting`

The current experimental observation is that the simulation performs well under this dataset scenario. Therefore, the paper should define the proposed method as a scenario-conditioned simulation method rather than a universally valid sea-clutter generator.

## Dataset facts confirmed from local files

The dataset folder contains:

- Two radar echo files:
  - `20210106155330_01_staring.mat`
  - `20210106155432_01_staring.mat`
- Wind field file:
  - `wind_info_2021010600.nc`
- Wave field file:
  - `wave_info_2021010612.nc`
- Dataset instruction and experiment documents:
  - `雷达对海探测数据使用说明（20191020）5.pdf`
  - `X波段雷达对海探测试验与数据获取.pdf`
  - `X波段雷达对海探测试验与数据获取年度进展.pdf`

The two local radar files are `staring` mode data. Their file headers indicate MATLAB 5.0 MAT-file format.

The dataset documentation states that the sea-detecting radar data sharing program uses X-band solid-state fully coherent radar to collect target and sea-clutter data under different sea states, resolutions, and grazing angles, with synchronous marine meteorological and hydrological data.

Relevant radar and scene information extracted from the documentation:

- Radar type: X-band solid-state coherent surveillance / navigation radar.
- Frequency range: 9.3-9.5 GHz.
- Polarization: HH.
- Radar modes: staring and circular scanning; the current local files are staring mode.
- Range settings mentioned in the documentation: 3 nm and 6 nm are typical for target/clutter experiments.
- PRF settings mentioned in the documentation: 3.0 kHz for 3 nm and 1.6 kHz for 6 nm in some experiments.
- Data include complex baseband radar echoes and radar headers.
- Weather and sea-state data include wind components, wave height, wave direction, wave period, and dominant wave speed.

## Recommended scope definition

The method should be positioned as applicable to:

`X-band coherent maritime radar echo simulation over wind- and wave-conditioned sea surfaces under low-to-moderate grazing-angle sea-detecting scenarios, especially for staring-mode sea-clutter and target-background simulation.`

In Chinese:

`该方法主要适用于 X 波段全相参对海探测雷达在凝视观测条件下的海面建模与雷达回波仿真，尤其适合带有风速、风向、有效浪高、浪向等同步海洋环境约束的低至中等擦地角海杂波场景。`

## Core applicable scenarios

### 1. X-band maritime surveillance / navigation radar scenes

The method is most directly supported by the NAV X-band sea-detecting dataset. It should be claimed for X-band radar scenes rather than all radar bands.

Recommended wording:

`The proposed simulator is designed for X-band coherent maritime radar scenarios and is validated using NAV X-band staring-mode sea-detecting data.`

### 2. Staring-mode sea clutter sequences

Because the current local radar files are `staring.mat`, the strongest experimental claim should focus on time-sequential radar echoes at a fixed azimuth.

This is suitable for:

- Sea clutter amplitude statistics.
- Temporal echo fluctuation.
- Doppler or slow-time analysis.
- Background simulation for small target detection at a fixed look direction.

Avoid making the first paper depend on wide-area scanning-mode claims unless scanning data are later added.

### 3. Wind- and wave-conditioned sea surface simulation

The method is suitable when external environmental parameters are available or can be controlled:

- 10 m wind speed.
- Wind direction.
- Significant wave height.
- Mean wave direction.
- Mean wave period.
- Dominant wave speed.

This is the best bridge between physical sea-surface modeling and data-driven radar detection:

`The simulator does not generate arbitrary clutter samples only; it generates sea surfaces and radar echoes conditioned on measurable marine environmental variables.`

### 4. Low-to-moderate grazing-angle coastal sea-detecting scenarios

The source program is designed for sea-detecting radar experiments at coastal sites, with documented grazing-angle ranges roughly from small angles to moderate angles depending on the site. Therefore, the paper should emphasize low-to-moderate grazing angles.

This is important because sea clutter statistics and electromagnetic scattering mechanisms change significantly with grazing angle. A method validated in this dataset should not automatically be claimed for high grazing-angle airborne or satellite geometries.

### 5. AI-oriented synthetic data augmentation for maritime target detection

The method is not primarily a replacement for measured datasets. Its most defensible role is:

- Expanding sea-clutter background diversity.
- Generating physically consistent negative samples.
- Producing controlled target-background scenarios.
- Testing detector robustness across wind and wave conditions.

Recommended wording:

`The simulated echoes are intended to complement measured radar data by providing controllable, physics-guided training and evaluation samples for maritime target detection.`

## Conditionally applicable scenarios

These can be discussed as extensions, but should not be the strongest claim unless additional experiments are performed.

### 1. Scanning-mode radar images

The dataset documentation supports scanning mode, but the current local files are staring mode. The method can be extended to scanning scenes by updating the geometry for azimuth-varying beams and range-azimuth sampling.

Required before strong claim:

- Use real scanning-mode MAT files.
- Validate range-azimuth clutter texture.
- Account for antenna rotation and azimuth-dependent grazing angle.

### 2. Other X-band sea-clutter datasets

The method may transfer to other X-band datasets such as IPIX-like or Fynmeet-like sea clutter, but direct transfer should be described as future validation unless tested.

Required before strong claim:

- Match radar frequency, polarization, PRF, range resolution, and grazing angle.
- Compare amplitude distribution, Doppler spectrum, and temporal/spatial correlation.

### 3. High sea states with breaking waves

If the method uses modified nonlinear sea-surface modeling, it can be argued to support high sea states. However, the current dataset-specific claim should depend on whether the NAV samples include such sea states and whether wind/wave labels confirm them.

Required before strong claim:

- Select samples with high wind speed or larger significant wave height.
- Show improved agreement over a linear sea-surface baseline.
- Validate slope statistics or backscatter changes under high sea state.

### 4. Low sea states with swell-dominated surfaces

If the method includes directional spreading or swell factors, it can support swell-like regular sea surfaces. The claim should be tied to wave direction, period, and significant wave height from `wave_info_2021010612.nc`.

Required before strong claim:

- Extract local wave parameters corresponding to the radar acquisition time.
- Show directional sea-surface texture or correlation agreement with real echoes.

## Scenarios not yet covered

The first GRSL paper should not claim direct applicability to:

- Fully general radar bands such as L, S, C, Ku, Ka, or millimeter-wave systems.
- Non-HH polarimetric configurations unless corresponding scattering models and validation data are added.
- Satellite SAR or high-altitude airborne geometries.
- Extreme sea states, rain-contaminated clutter, sea spray, or severe atmospheric ducting unless explicitly modeled.
- General target echo simulation with accurate target RCS, micro-motion, wake, and shadowing unless those modules are implemented.
- Universal replacement of measured radar data for AI training.

## Recommended paper positioning

The paper should use a bounded claim:

`This letter develops a wind- and wave-conditioned sea-surface modeling method for X-band coherent maritime radar echo simulation. The method is evaluated using NAV X-band staring-mode sea-detecting data with synchronized wind and wave information, demonstrating its applicability to controlled sea-clutter background generation for maritime target detection.`

Chinese version:

`本文提出一种面向 X 波段全相参对海探测雷达的风浪条件约束海面建模方法，并结合同步风浪信息和凝视模式实测数据验证其在海杂波背景仿真中的有效性。该方法的主要应用目标是为海面目标检测提供可控、物理一致的仿真背景数据，而不是替代所有体制和所有海况下的实测海杂波。`

## Suggested applicability paragraph for the manuscript

`The proposed method is intended for coherent X-band maritime radar scenarios where sea clutter is observed at low-to-moderate grazing angles and where basic marine environmental parameters, such as wind speed, wind direction, significant wave height, and mean wave direction, are available. In this work, the method is evaluated using NAV X-band staring-mode sea-detecting data, which contain complex radar echoes and synchronized wind-wave information. Therefore, the current validation mainly supports staring-mode sea-clutter and target-background simulation under coastal sea-detecting conditions. Extension to scanning-mode imaging, other radar bands, and extreme meteorological conditions requires additional geometry modeling and dataset-specific validation.`

## Experimental validation recommendations

For the current dataset, the experiments should be organized around these validation layers:

1. Environment matching:
   - Match radar acquisition time with `wind_info_2021010600.nc` and `wave_info_2021010612.nc`.
   - Extract wind speed, wind direction, significant wave height, wave direction, and wave period near the radar site and acquisition time.

2. Sea-surface realism:
   - Validate spectrum recovery / energy consistency.
   - Validate slope statistics or RMS wave-height trend against the wind-wave condition.
   - Compare sea-surface morphology under different wind and wave parameters.

3. Radar echo agreement:
   - Compare amplitude distribution between measured and simulated echoes.
   - Compare temporal autocorrelation or spatial/range-bin correlation.
   - Compare Doppler spectra for staring-mode slow-time data.

4. AI-oriented utility:
   - Show that synthetic sea-clutter backgrounds increase controlled diversity.
   - Use the dataset as the measured anchor and the simulator as a conditional augmentation tool.

## Short conclusion

The most defensible applicability scope is:

`X-band HH-polarized coherent maritime radar, staring-mode or locally fixed-look sea-clutter scenes, low-to-moderate grazing angles, coastal sea-detecting geometry, and wind-wave-conditioned sea surfaces.`

This scope is narrow enough to be scientifically credible and broad enough to support the paper's motivation: generating controllable simulation data for AI-based maritime target detection where measured radar data are limited.

