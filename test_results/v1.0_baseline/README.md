# v1.0 Baseline — 6 FP64 Islands

> **Git**: `7f00872` · **日期**: 2026-07-20 · **状态**: ⚠️ Strawman 对照数据

## 构建配置

| 参数 | 值 |
|------|-----|
| SPICE_REAL | `float` |
| 补丁 | patches/ 001–016 |
| FP64 islands | **0** (Pure FP32 strawman — 所有 double 被移除) |
| 编译选项 | `--enable-shared=no` |

> ⚠️ **重要**: 此目录中的日志来自 **Pure FP32 (no-islands)** strawman 构建，不是 Mixed FP32 v1.0。
> Mixed FP32 v1.0 (保留 6 个 FP64 islands, 11/11 PASS) 的对比日志没有存档。

## 测试电路

| # | 电路 | PDK | MOS | 分析 |
|---|------|-----|-----|------|
| 01 | Single NMOS | PTM 45nm LP | 1 | DC OP, DC Sweep |
| 02 | Single PMOS | PTM 45nm LP | 1 | DC OP, DC Sweep |
| 03 | Ring Oscillator 17-stage | PTM 45nm LP | 34 | DC OP (名为 tran 但只有 .op) |
| 04 | 5T OTA | PTM 45nm LP | 5 | DC OP |
| 05 | 2-Stage Miller OpAmp | PTM 45nm LP | 7 | DC OP |
| 06 | StrongARM Comparator | PTM 45nm HP | 14 | DC OP |
| 07 | Bootstrap Switch | PTM 45nm HP | 7 | TRAN |
| 08 | Rössler Attractor | Behavioral | 0 | TRAN |
| T1 | Ring Oscillator TRAN | PTM 45nm LP | 34 | TRAN |

## 结果汇总

| 指标 | 值 |
|------|-----|
| 总对比数 | 11 |
| PASS | 2 (01_nmos_sweep, 08_roessler) |
| WARN | 2 (01_nmos_dc, 02_pmos_dc) |
| FAIL | 4 (03_ringosc, 04_ota_dc, 05_opamp_dc, 06_comparator) |
| SKIP | 3 (02_pmos_sweep, 07_bootstrap, T1_ring_osc_tran) |
| **Pass rate** | **25%** |

## 失败原因

Pure FP32 构建移除了所有 FP64 保护:
- **Vbi overflow**: nsd×ndep > FLT_MAX → +Inf → NaN 传播
- **NOIA overflow**: 6.25×10⁴¹ > FLT_MAX → 噪声计算失效
- **消去误差**: Vbseff, Vth k1ox, Abulk, Leff/Weff 精度不足 → DC 收敛失败

这些失败正是 FP64 islands 分析的实验验证——证明了 6 个孤岛的每个都是必需的。

## 文件清单

```
v1.0_baseline/
├── README.md
├── ci_summary.json           # CI 汇总
├── fp32/                     # 11 个 Pure FP32 构建日志
│   ├── 01_nmos_dc_fp32.log
│   ├── 01_nmos_sweep_fp32.log
│   ├── ...
│   └── T1_ring_osc_tran_fp32.log
├── fp64/                     # 11 个 FP64 参考日志
│   └── (对应)
└── compare/                  # 7 个对比报告
    ├── 01_nmos_dc_compare.md
    └── ...
```
