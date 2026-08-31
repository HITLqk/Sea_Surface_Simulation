# 局部卷浪双指标验证结果

## 实验设置

- 配对组：G0 no-curl 与 G1 with-curl；
- 每一对使用相同随机海面、相同波峰、相同局部材料窗口和相同雷达视向；
- 没有 weak、moderate、strong 离散验证组；
- G1 的卷浪控制参数 `chi` 在 `[0.15, 1.00]` 内分层连续采样；
- 蒙特卡洛样本数：`N = 60`；
- 固定局部窗口：传播向 `3.2 m`，峰线向 `6.4 m`；
- 观测条件元数据：`10 GHz`、`12 deg` 擦地角、up-wave；
- 散射量采用现有回波程序中的面元代理定义：

```text
sigma_i = Area_i * cos(theta_i)^2
```

该定义为固定单通道局部 RCS proxy，本实验不比较极化。

## 指标一：局部散射增强量

```text
Gb = CurlRcs_dBsm - PreRcs_dBsm
```

60 组结果为：

| 统计量 | 结果 |
|---|---:|
| Median `Gb` | `5.069 dB` |
| Q25 | `2.312 dB` |
| Q75 | `6.919 dB` |
| Minimum | `0.127 dB` |
| Maximum | `9.046 dB` |
| `P(Gb > 0)` | `1.000` |

在当前参数范围和散射代理下，全部 G1 样本的局部积分响应均高于严格配对的 G0。

## 指标二：散射增强与连续卷浪参数

`Gb(chi)` 的统计关系为：

| 指标 | 结果 |
|---|---:|
| Pearson correlation | `0.9794` |
| Spearman correlation | `0.9823` |
| Linear trend slope | `10.592 dB/chi` |

八个连续 `chi` 分箱的中位 `Gb` 依次为：

```text
0.295, 1.465, 3.067, 4.532,
5.572, 6.559, 7.305, 8.025 dB
```

这说明当前几何变换与现有面元 RCS proxy 之间存在清晰、稳定的连续响应，而不是由离散强度组或更换随机海面造成的跳变。

## 文献参考值状态

代码已经提供：

- 论文 figure 坐标轴交互标定；
- 曲线逐点数字化；
- 原始散射量到 dB 的转换；
- 同一文献内部 `Gb_ref = S_ref,dB - S_pre,dB` 的计算；
- pre-to-mature 阶段归一化 `chi_ref`；
- West 2002、Li and West 2006 与 Sletten 2003 曲线的合并和叠加绘图。

当前本机没有 West 2002 和 Li and West 2006 的完整曲线图，因此 `literature_gb_reference.csv` 仍是带 `NaN` 的审计模板。程序不会把摘要描述、HH/VV 差值或 Sletten 的 35% 事件能量占比冒充 `Gb_ref`。

因此，本次已经完成的是：

```text
模型内部的 G0/G1 局部配对验证
+
Gb(chi) 连续趋势验证
```

尚未完成的是：

```text
模型 Gb 与文献数字化 Gb_ref 的定量比较
```

只有取得两篇 IEEE 全文目标 figure 并完成数字化后，才能在论文中写“与文献增强量级一致”。

## 输出文件

- `output/local_curl_dual_metric_raw.csv`
- `output/local_curl_dual_metric_summary.csv`
- `output/local_curl_dual_metric_results.mat`
- `output/local_curl_dual_metric_validation_final.png`
- `output/local_curl_dual_metric_validation_final.pdf`
