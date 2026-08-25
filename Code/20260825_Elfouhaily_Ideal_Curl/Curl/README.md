# Elfouhaily Sea with Height-selected Ideal Curl

这是一套重新建立的二维卷浪代码，不依赖此前的局部卷浪实现。卷曲变换参考 `SeaClutterSimulation/Curl_Wave/Curl_Wave_Echo/Ideal_Curl_Wave_Echo.m`。

## Method

1. 直接生成二维 Elfouhaily 随机海面，不叠加一维高斯主波，也不使用非线性海面。
2. 对海面轻度平滑，以 `mean(Z)+k*std(Z)` 为高度门限，在边界安全区域选择超过门限的最高有效波峰。
3. 以检测波峰为局部坐标中心，将传播方向坐标 `u` 对应到 `Ideal_Curl_Wave_Echo.m` 的局部 `Y`。
4. 使用原方法的指数权重 `exp(-abs(u)/amplitudeCurl)` 生成卷曲，并将水平前伸角与竖向下卷角解耦，使卷唇先沿 `+u` 传播方向前伸，再轻微向下翻转。
5. 沿波峰方向增加紧支撑余弦窗，使卷曲只作用于有限波峰段。每个二维网格点保留自身 Elfouhaily 高程，因此不再是将一条曲线横向复制得到的柱状海面。

演示脚本使用 `forwardGain=1.15`、`verticalAngleRatio=0.28`、`curlMultiplier=0.55 rad` 和 `pivotDepth=0.95 m`。程序同时检查传播方向映射 `du_final/du`：没有负值时会判定为仅变形、未形成几何卷曲。另外要求最大前向位移大于最大向下位移，避免再次退化为近乎竖直的下落线。

当前固定随机种子的运行结果为：最大前向位移 `0.5710 m`，最大向下位移 `0.0135 m`，翻卷点 `175` 个，最小传播雅可比 `-1.2015`。

程序还验证波峰窗外位移为零，并检查卷曲中心附近沿波峰方向的高程标准差大于零，以排除将单条曲线横向复制形成柱状面的退化情况。

## Files

- `default_elfouhaily_ideal_curl_config.m`: 默认海面、检测和卷曲参数。
- `generate_elfouhaily_ideal_curl_surface.m`: 二维 Elfouhaily 海面、按高度选峰和 Ideal 卷曲变换。
- `run_elfouhaily_ideal_curl_demo.m`: 四个独立 MATLAB figure 及 PNG 输出，包括二维海面远景、中心剖面和三维局部卷曲近景。

## Run

```matlab
run_elfouhaily_ideal_curl_demo
```

结果写入 `output` 目录。

