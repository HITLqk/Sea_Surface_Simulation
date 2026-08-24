# Nonlinear Sea and Breaking-Wave Simulation

本目录只保留当前验证所需的非线性海面与卷浪生成代码，不包含涌浪、baseline、雷达散射、回波或统计拟合模块。

## Files

- `Lie_Contrast.m`: 修正 Lie 变换和水平坐标压缩的非线性海面原型，来源于 `SeaClutterSimulation/Lie_Contrast.m`。
- `default_localized_curl_config.m`: 单个局部卷浪斑块的默认参数。
- `generate_localized_elfouhaily_curl_patch.m`: 生成配对的背景面和局部三维卷浪面，共用顶点索引和三角面连接关系。
- `run_localized_elfouhaily_curl_demo.m`: 卷浪生成、可视化和 MAT 保存示例。

## Current Boundary

`Lie_Contrast.m` 和局部卷浪生成器目前是两个可独立运行的原型。后续应把修正 Lie 海面封装为函数，再将其输出作为局部卷浪变换的背景输入；在完成数值检查前，不直接把两个脚本拼接为论文最终 G1。

当前卷浪生成器输出的关键配对数据为：

```text
surfaceData.verticesBaseline  % 未卷曲背景顶点
surfaceData.vertices          % 卷曲后顶点
surfaceData.faces             % 两组共享的三角面连接
surfaceData.breakingMask      % 卷浪顶点掩膜
surfaceData.breakingFacetMask % 卷浪面元掩膜
```

## Run

在 MATLAB 中将当前目录设为工作目录，然后运行：

```matlab
run_localized_elfouhaily_curl_demo
```

结果默认写入本目录的 `output` 子目录。

