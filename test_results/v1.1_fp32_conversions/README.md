# v1.1 — 3 纯 FP32 数值方法

> **Git**: `492ba5d` / `c21c9f8` · **日期**: 2026-07-20 · **状态**: ⬜ 对比数据缺失

## 构建配置

| 参数 | 值 |
|------|-----|
| SPICE_REAL | `float` |
| 补丁 | patches/ 001–016 (含 012 Vbi fix, 013 multi-T NaN fix, 015 noise FP64) |
| FP64 islands | **3** (Abulk, Leff/Weff, NOIA — 全部不在热路径) |
| 纯 FP32 修复 | Vbi log 拆分, Vbseff 平方差分解, Vth k1ox Dekker 减法 |

## 变更说明

| 孤岛 | 方法 | 文件 | 变更 |
|------|------|------|------|
| Vbi overflow | log(a) + log(b) − 2·log(c) | b4v5temp.c | 5 double → 0 |
| Vbseff 消去 | (T₀−√C)·(T₀+√C) | b4v5ld.c | 25 double → ~10 |
| Vth k1ox 消去 | Dekker 精确减法 (6 FP32 ops) | b4v5ld.c | 4 double → 0 |

## 文档化结果 (未存档对照日志)

- **11/11 电路 PASS** (来自 commit message)
- b4v5ld.c: 65 → 55 double
- b4v5temp.c: 32 → 30 double
- 热路径 FP64 islands: 3 → 1 (仅 Abulk)

## 待执行测试

### 优先级 🔴 — 基本 DC 回归 (11 电路)

```bash
bash test_results/scripts/run_v1.1_comparison.sh
```

| # | 电路 | 分析 | 网表 |
|---|------|------|------|
| 01 | NMOS DC | DC OP | test/circuits/01_single_nmos_45nm/test_dc.sp |
| 01 | NMOS Sweep | DC Sweep | test/circuits/01_single_nmos_45nm/test_dc_sweep.sp |
| 02 | PMOS DC | DC OP | test/circuits/02_single_pmos_45nm/test_dc.sp |
| 02 | PMOS Sweep | DC Sweep | test/circuits/02_single_pmos_45nm/test_dc_sweep.sp |
| 03 | Ring Osc | DC OP | test/circuits/03_ring_oscillator_17stage/test_tran.sp |
| 04 | OTA DC | DC OP | test/circuits/04_ota_5transistor_45nm/test_dc.sp |
| 05 | OpAmp DC | DC OP | test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp |
| 06 | Comparator | DC OP | test/circuits/06_comparator_strongarm_45nm/test_tran.sp |
| 07 | Bootstrap | TRAN | test/circuits/07_bootstrap_switch_45nm/test_tran.sp |
| 08 | Rössler | TRAN | test/circuits/08_roessler_attractor/test_chaos.sp |
| T1 | Ring Osc TRAN | TRAN | test/circuits_tran/T1_ring_osc_tran.sp |

### 优先级 🟡 — NOISE 对比 (FP32 敏感)

```bash
# OTA NOISE
ngspice --batch test/circuits/04_ota_5transistor_45nm/test_noise.sp > test_results/v1.1_fp32_conversions/fp32/04_ota_noise_fp32.log
# OpAmp NOISE
ngspice --batch test/circuits/05_opamp_2stage_miller_45nm/test_noise.sp > test_results/v1.1_fp32_conversions/fp32/05_opamp_noise_fp32.log
```

> NOIA overflow (6.25×10⁴¹ > FLT_MAX) 是 FP32 已知风险。v1.1 保留了 NOIA FP64 island，NOISE 应该无 NaN。需双边对比确认。

## 测试结果 (2026-07-24)

| 指标 | 值 |
|------|-----|
| 总测试数 | 13 (11 DC/TRAN + 2 NOISE) |
| PASS | 11 |
| FP64 已知失败 | 2 (07_bootstrap, T1_ring_osc_tran — FP64 也失败，电路自身问题) |
| FP32 NOISE NaN | 0 (OTA 和 OpAmp NOISE 均无 NaN/Inf) |
| **有效通过率** | **11/11 = 100%** (排除 FP64 已知电路问题) |

## 文件清单

```
v1.1_fp32_conversions/
├── README.md
├── fp32/                     ← 13 个 ngspice log
├── fp64/                     ← 13 个 ngspice log
└── compare/                  ← 11 个对比报告
```
