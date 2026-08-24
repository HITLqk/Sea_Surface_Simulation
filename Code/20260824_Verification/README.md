# Verification Code Selection

本目录按验证功能整理现有可复用代码，并与以下工作目录同步：

```text
E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication
```

## Current Status

| Folder | Status | Decision |
|---|---|---|
| `CoxMunk` | Empty | 旧 `cox_munk.m` 的 proposed 和 standard Lie 曲线实际调用同一个 `Elfouhaily` 函数，仅积分范围不同，不能用于方法验证 |
| `Curl` | 1 reusable function | 保留 `analyze_simulated_breaker_facets.m`，其输入与当前 `surfaceData` 配对网格接口一致 |
| `RadarEcho` | Empty | 旧代码将理论分布拟合误当作仿真-实测比较，并对实测 RTI 单独平移峰值；后续重新实现 |
| `Simulation` | 5 files | 已保存非线性海面原型、局部卷浪生成器、配置、演示和说明 |

## Retained Curl Function

`Curl/analyze_simulated_breaker_facets.m` 可从同一连接关系的背景面和卷浪面中提取：

- 卷浪足迹面积；
- 背景/卷浪表面积及比值；
- 有效长度、宽度和长宽比；
- 高度范围；
- 法向向下的翻卷面元面积比例。

该函数还包含旧实验使用的面元朝向统计字段。后续编写精简 Letter 验证时，可以只使用上述几何量，不必保留全部雷达视角曲线。

## Excluded Code

本次没有复制：

- 涌浪方向谱与涌浪生成代码；
- Random-Stokes 或其他 baseline；
- 旧 `cox_munk.m`；
- `sim_analyse.m` 及 K/Weibull/log-normal 拟合脚本；
- 对实测数据逐图峰值平移的 RTI 脚本；
- 依赖旧绝对路径和旧输出 MAT 的批处理验证脚本。

空目录表示当前没有足够可靠的代码，后续将在对应目录中重新实现。

