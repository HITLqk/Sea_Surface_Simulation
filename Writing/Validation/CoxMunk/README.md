# Cox-Munk 验证代码

## 四组实际海面验证

按旧 `cox_munk.m` 的单幅曲线图格式运行四组实际表面：

```matlab
[raw,summary,assessment,fig] = ...
    run_four_group_original_style_validation();
```

默认使用 `U10=1:10 m/s`、逆波龄 `0.84`、每个风速 3 个配对随机种子。四组分别为 `Linear`、`G0_Nonlinear`、`G1_Upward` 和 `G1_Background`，所有 MSS 都从实际 `(X,Y,Z)` 三角面元法向量计算。`128 m` 区域不能容纳更高风速下的谱峰，验证程序会拒绝未解析的风速设置。输出目录为 `output_four_group_original_style`。

3 个种子用于形成可运行的初步曲线；论文定稿统计应将 `cfg.randomSeeds` 扩展到至少 20 个种子。

## 1. 原论文图复现

主入口 `run_cox_munk_validation.m` 忠实复现：

```text
源代码/matlab程序/cox_munk.m
```

运行：

```matlab
[curves,figureHandle] = run_cox_munk_validation();
```

输出写入 `output_original_reproduction`：

- `cox_munk_original_reproduction.png`；
- `cox_munk_original_reproduction.csv`；
- `cox_munk_original_reproduction.mat`。

复现参数与原脚本相同：

```text
U10 = 1:20 m/s
wave age = 0.84
Cox-Munk legacy wind transform = 1.6 U10^0.8
Cox-Munk total MSS = 0.003 + 5.12e-3 U12
upper/lower uncertainty = +/-0.0055
```

原始论文工程中的 `cox_munk.png` 使用了 `U10_U12(U)`，但该函数文件已经缺失。根据原图逐点核验，两条虚线对应的遗留关系为

```matlab
U12 = 1.6 .* U10.^0.8;
```

当前目录补入了兼容函数 `U10_U12.m`，以准确复现原图。这个幂律只能用于追溯旧图，不能未经文献依据就作为新实验中的标准大气风速高度换算。

## 2. 对原代码的审计结论

原脚本第 25 行和第 27 行实际调用的是同一个函数：

```matlab
f1 = @(k) k.^2.*Elfouhaily(k,U(i),age);
f2 = @(k) k.^2.*Elfouhaily(k,U(i),age);
```

两条曲线的唯一差别是积分波数范围：

| 原图标签 | 积分下限 | 积分上限 | 实际含义 |
|---|---:|---:|---|
| 所提方法 | 约 0.0628 rad/m | 约 3141.66 rad/m | Elfouhaily 谱的宽带 MSS 积分 |
| 标准 Lie 变换海面 | 约 0.1257 rad/m | 约 314.29 rad/m | 同一谱的较窄带 MSS 积分 |

因此，这张图可以被准确复现，但现有代码本身没有生成随机海面、没有调用 Lie 变换，也没有把卷浪几何放入计算。红线高于蓝线的原因是积分到更高波数，而不是代码已经证明所提非线性方法优于标准 Lie。

在论文中继续使用该图之前，需要重新定义两条曲线对应的物理带宽，或者分别从真实的 baseline/proposed 模型输出计算 MSS，不能只依靠图例给同一波谱积分赋予两个方法名称。

## 3. 三维表面诊断程序

之前生成的四面板 Monte Carlo 程序已改名为：

```matlab
run_surface_mss_diagnostic
```

它从实际随机三维表面的法向量计算 MSS，用于检查 NonLiner 和 Curl 的数值行为，不再作为原论文 Cox-Munk 图的主入口。

该诊断默认保持 NonLiner 原生配置：

```text
domain = 128 m x 128 m
dx = dy = 0.25 m
U10 = [3 5 7 10] m/s
20 random seeds per wind speed
```

当前 NonLiner 的非线性截止波数随 Nyquist 波数变化，不能直接把 `dx` 改成 `0.10 m` 后与原结果比较；诊断代码已加入保护。
