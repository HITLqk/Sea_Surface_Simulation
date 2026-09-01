# 动态风浪雷达回波验证代码

## 本轮修改目的

解决此前 Proposed 与 Linear 的 RTI 时间相关性和幅度边缘分布几乎相同的问题。当前版本不包含卷浪或破碎，改进集中在风浪造成的慢时间调制与分辨单元尺度的海杂波纹理。

## 回波模型修改

1. Linear 保留双时间尺度圆对称复高斯散斑，慢分量功率占比为 0.41。
2. Proposed 的慢复散斑功率占比提高到 0.90，慢相关时间设为 1.40 s。
3. Proposed 加入均值严格归一到 1 的时空相关 Gamma 功率纹理，名义形状参数为 `nu = 1`，相关时间为 1.80 s，距离相关尺度为 90 m。
4. Gamma 纹理在脉冲压缩后作用于分辨单元复回波，避免被接收机距离响应错误平均掉。
5. 纹理不改变平均回波功率，因此 Linear 与 Proposed 的差异主要体现在慢时间连续性和归一化分布形状，而不是人为的整体增益。
6. 该机制属于复合高斯风浪调制模型，不应表述为 TSC 本身产生了重尾，也不应表述为卷浪散射。

## 小规模端到端检查

使用 2048 脉冲、2.5--2.7 km 距离段完成了包含海面、TSC、散斑、脉压、噪声和统计验证的试跑。

| 指标 | Linear | Proposed | Measured |
|---|---:|---:|---:|
| 100 ms 强度相关 | 0.0185 | 0.2527 | 0.0864 |
| Weibull 形状参数 | 2.0226 | 1.5805 | 1.4903 |
| K 分布形状参数 | 90.61 | 1.9328 | 1.5996 |
| 归一化幅度 P99.9 | 2.5937 | 3.3381 | 4.1025 |
| 超过 2 RMS 的概率 | 0.0172 | 0.0336 | 0.0450 |
| 对实测 Log-CCDF RMSE | 1.6182 | 0.9601 | - |

结果表明 Proposed 已与近 Rayleigh 的 Linear 明显分离，并向实测重尾靠近。当前 Proposed 的时间相关性高于实测；全尺寸结果若仍偏高，应优先下调 `windWaveTextureCorrelationTimeS` 和 `proposedSlowSpecklePowerFraction`，不要重新改变分布机制。

## 运行顺序

```matlab
run_dynamic_wind_wave_surface
run_wind_wave_radar_simulation
run_wind_wave_validation
```

服务器正式运行时，输出分别写入 `surface_output`、`simulation_output` 和 `validation_output`。运行新版本前应确认旧的 `simulation_output` 已被替换，否则验证脚本仍会读取旧回波。

