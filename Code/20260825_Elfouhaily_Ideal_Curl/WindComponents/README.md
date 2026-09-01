# Directional Short-scale Wind Components

该模块在 `NonLiner` 生成的非线性 Elfouhaily 背景海面中，引入具有主导传播方向的短尺度风生波结构。它同时选出一个局部陡峭波峰，作为后续 `Curl` 卷浪构造的输入，但本模块不执行卷曲。

## 从 Swell_Wave 保留的思路

- `Main_SwellSimulation_ideal.m` 的方向谱集中与归一化思路；
- `applyHermitianSymmetry` / `ConjugateSymmetric_zyg.m` 的共轭对称实海面构造；
- `generateHeightMap` 的深水色散关系 `omega=sqrt(gk)` 和时间相位推进；
- `generateWaveChrip.m` 的主方向波峰检测与局部区域筛选思路。

原始代码用于涌浪，本模块只复用其数值结构，不使用涌浪调制因子。

## 核心流程

1. 读取 `NonLiner/output/nonlinear_lie_elfouhaily_surface.mat`。
2. 将背景海面的目标短波频带平滑分离。
3. 构造一个同频带、等能量、角度集中的随机风生波分量。
4. 用新分量替换背景中的原频带，避免直接叠加造成能量重复。
5. 通过对正、负波数分支施加相反的色散相位，定义唯一的正向传播。
6. 按总高度、顺传播方向负曲率和风生波峰值联合选择局部陡峭波峰。

默认短波波长范围为 `1.5-5.0 m`，角度标准差为 `8 deg`，主传播方向为 `0 deg`。这些尺度在 `0.25 m` 网格上至少有 6 个采样点，避免把未解析的次网格毛刺误当作短波。

## 文件

- `default_wind_components_config.m`：背景路径、波长带、传播方向和检测参数。
- `generate_directional_wind_components_surface.m`：频带替换、方向风生波和陡峭波峰检测。
- `run_directional_wind_components_demo.m`：数值断言、指标、四张独立 Figure 和 MAT 输出。

## 运行

```matlab
run_directional_wind_components_demo
```

结果保存在 `output` 中。`directional_wind_components_surface.mat` 中的 `X,Y,Z,detection` 可直接作为下一阶段局部卷浪构造的输入。
