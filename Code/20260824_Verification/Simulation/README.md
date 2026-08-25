# Nonlinear Sea and Breaking-Wave Simulation

本目录只保留当前验证所需的非线性海面与卷浪生成代码，不包含涌浪、baseline、雷达散射、回波或统计拟合模块。

## Files

- `Lie_Contrast.m`: 修正 Lie 变换和水平坐标压缩的非线性海面原型，来源于 `SeaClutterSimulation/Lie_Contrast.m`。
- `default_localized_curl_config.m`: 单个局部卷浪斑块的默认参数。
- `generate_localized_elfouhaily_curl_patch.m`: 自动搜索边界安全区域内的最高有效波峰，并在该峰顶生成配对的背景面和局部三维卷浪面。
- `run_localized_elfouhaily_curl_demo.m`: 卷浪生成、六个独立 MATLAB figure 的可视化和 MAT 保存示例。
- `plot_curled_sea_only.m`: 只绘制卷曲后 G1 海面并导出独立 PNG，不包含对照组、剖面线或位置标记。
- `run_high_sea_state_curl_demo.m`: 在 `36 m x 36 m` 计算域内，以独立随机相位生成 `U10=12 m/s`、`Hs=0.90 m`、逆波龄 `2.0` 的较高海况卷浪，并以三个独立 figure 输出卷曲海面、中心剖面对比和翻卷近景。

## Current Boundary

`Lie_Contrast.m` 和局部卷浪生成器目前是两个可独立运行的原型。后续应把修正 Lie 海面封装为函数，再将其输出作为局部卷浪变换的背景输入；在完成数值检查前，不直接把两个脚本拼接为论文最终 G1。

当前卷浪生成器输出的关键配对数据为：

```text
surfaceData.verticesBaseline  % 未卷曲背景顶点
surfaceData.vertices          % 卷曲后顶点
surfaceData.faces             % 两组共享的三角面连接
surfaceData.breakingMask      % 卷浪顶点掩膜
surfaceData.breakingFacetMask % 卷浪面元掩膜
surfaceData.crestDetection    % 自动选中的背景波峰位置和高程
```

默认 `cfg.patch.centerMode='highest_crest'`。搜索先对背景面轻度平滑以定位主波峰，再在附近原始网格上细化到真实最高点，同时排除无法完整容纳卷浪斑块的边界区域。设置为 `'manual'` 时才使用 `cfg.patch.centerXY`。

卷曲核心默认由 `curlCenterOffset` 移到峰前肩部；`transitionLength` 定义更宽的平滑演化带。演化带中的海面会发生低幅抬升和水平前倾，因此 G1 剖面不会只在卷曲核心内突变，也不会在核心外立刻与 G0 完全重合。

该选项解决“卷浪几何与背景峰顶错位”，不等同于验证破碎起始判据。后续加入独立的运动学判据时，应由判据输出触发峰位置，再通过 `'manual'` 模式传入同一个局部卷曲变换。

默认参数采用温和卷浪：局部核心修正高度 `0.055 m`、最大卷曲角 `18 deg`，并使用 `1.20 m` 的宽过渡带。需要构造不同强度组时，应逐级调整参数并保留相同背景随机种子，不应直接恢复早期 `0.42 m/62 deg` 的展示型强参数。

## Run

在 MATLAB 中将当前目录设为工作目录，然后运行：

```matlab
run_localized_elfouhaily_curl_demo
```

结果默认写入本目录的 `output` 子目录。六项可视化分别打开为独立的 MATLAB figure，并导出为 `01_...png` 至 `06_...png`，不再使用 `tiledlayout` 拼接。

只生成卷曲后的独立海面图时运行：

```matlab
plot_curled_sea_only
```

输出文件为 `output/curled_sea_surface_only.png`。

生成较高海况卷浪时运行：

```matlab
run_high_sea_state_curl_demo
```

结果写入 `output/high_sea_state`，包括独立海面图、独立剖面对比图和卷曲近景。脚本要求局部传播映射雅可比 `du_final/du` 出现负值；如果只变陡而没有水平回折，断言会失败。完整海面可由固定随机种子和该脚本参数重建，因此不重复提交大体积 MAT 中间数据。

