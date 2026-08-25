# Nonlinear Lie-improved Elfouhaily Sea

该模块生成卷浪触发前的单值非线性风浪海面，后续可作为 `Curl` 模块的背景海面。它不在本阶段生成多值翻卷几何。

## 保留的原有代码

从 `源代码/matlab程序` 保留了以下思路：

- `Elfouhaily.m` 的长波、短波平衡范围和波龄参数；
- `Elfouhaily2D.m` 的二维方向扩展函数；
- `generateSeaSurface2D.m` 和 `ConjugateSymmetric_zyg.m` 的频域随机采样与共轭对称实海面构造思路。

这些公式已收入独立生成函数，运行时不依赖原始文件夹。

## 非线性改进

线性海面为 `eta_1`。二阶 Lie/Creamer 型束缚谐波采用宽带伪微分算子：

```text
eta_2 = 0.5 |grad| [eta_1^2 - E(eta_1^2)].
```

对单色深水波 `eta_1=a cos(kx)`，该式精确给出二次谐波系数 `0.5 k a^2 cos(2kx)`，因此会形成更尖窄的波峰和更宽平的波谷。

改进点为：

1. 风速只用于无量纲非线性增益，不再直接与波数算子混乘。Elfouhaily 一阶波幅已随风速增长，因此无量纲二阶乘子使用轻微负指数，防止高风速时对海况影响重复计算；二阶项的绝对幅度仍然随海况增大。
2. 风向通过波矢在主风向上的投影调制二阶分量。
3. 在二阶乘积前后使用光滑高频截止，抑制频谱卷绕与网格毛刺。
4. 水平 Riesz 位移使波峰沿传播方向变得更陡，并通过雅可比线搜索自动避免网格折叠。

## 文件

- `default_nonlinear_lie_config.m`：海面、Lie 变换和输出参数。
- `generate_nonlinear_lie_elfouhaily_surface.m`：核心频谱生成和非线性坐标变换。
- `run_nonlinear_lie_elfouhaily_demo.m`：运行、断言、指标输出和三张独立 Figure。

## 运行

```matlab
run_nonlinear_lie_elfouhaily_demo
```

`output` 中会生成线性海面、非线性海面、中心顺风截面图和供后续 `Curl` 使用的 MAT 数据。
