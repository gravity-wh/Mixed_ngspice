# v1.2 — Full Double-Precision BSIM4 Math

> **Git**: `24aabbc` / `d8c6ba8` · **日期**: 2026-07-21 · **状态**: ⬜ 对比数据缺失

## 构建配置

| 参数 | 值 |
|------|-----|
| SPICE_REAL | `float` (存储) |
| BSIM4 math | `double` (exp/log/sqrt 内部计算) |
| 补丁 | patches/ 001–016 (全部) |
| 策略 | Phase5: float 存储 + double 运算 |

## 覆盖范围 — 15 电路 × 6 PDK × 6 分析类型 = 40 tests

### PTM 45nm LP (BSIM4v5 Level 54, VDD=1.1V)

| # | 电路 | MOS | DC OP | DC Sweep | AC | TRAN | NOISE | PZ |
|---|------|-----|-------|----------|----|------|-------|----|
| 01 | NMOS Single | 1 | ✅ | ✅ | — | — | — | — |
| 02 | PMOS Single | 1 | ✅ | ✅ | — | — | — | — |
| 03 | OTA 5T | 6 | ✅ | — | ✅ | 📐 | ✅ | — |
| 04 | OpAmp 2-stage | 8 | ✅ | — | ✅ | 📐 | ✅ | — |
| 05 | Ring Osc 17 | 34 | — | — | — | ✅ | — | — |

### PTM 45nm HP (BSIM4v5 Level 54, VDD=1.0V)

| # | 电路 | MOS | DC OP | TRAN |
|---|------|-----|-------|------|
| 06 | Comparator StrongARM | 15 | — | ✅ |
| 07 | Bootstrap Switch | 7 | — | ✅ |

### Behavioral

| # | 电路 | MOS | TRAN |
|---|------|-----|------|
| 08 | Rössler Attractor | 0 | ✅ |

### TSMC bc018 0.18µm (BSIM4v5 Level 14, VDD=1.8V) ⚠️ 私有

| # | 电路 | MOS | DC OP | TRAN |
|---|------|-----|-------|------|
| 09 | 22T OpAmp | 22 | ✅* | ✅ |

### PTM 130nm (BSIM4v5 Level 54, VDD=1.2V) 🔴 优先补测

| # | 电路 | MOS | DC OP | AC | TRAN | NOISE |
|---|------|-----|-------|----|------|-------|
| 10 | OTA 5T | 5 | ✅ | ✅ | 📐 | ✅ |
| 11 | OpAmp 2-stage | 8 | ✅ | ✅ | 📐 | ✅ |
| 12 | LDO | ~6 | ✅ | ✅ | 📐 | ✅ |

### PTM 180nm (BSIM3v3 Level 49, VDD=1.8V)

| # | 电路 | MOS | DC OP | AC | TRAN | NOISE | PZ |
|---|------|-----|-------|----|------|-------|----|
| 13 | OTA 5T | 5 | ✅ | ✅ | 📐 | ✅ | — |
| 14 | OpAmp 2-stage | 8 | ✅ | ✅ | 📐 | ✅ | ✅ |

### TSMC 180nm (BSIM3v3 Level 49, VDD=1.8V) ⚠️ 私有

| # | 电路 | MOS | DC OP | AC | TRAN | NOISE |
|---|------|-----|-------|----|------|-------|
| 15 | LDO | ~20 | ✅ | ✅ | ✅ | ✅ |

## 文档化结果 (来自 v1.2_test_results.md)

- **40/40 PASS, 0 NaN** 跨所有电路、PDK、分析类型
- BSIM 版本覆盖: 3 (Lv49 BSIM3v3, Lv14 BSIM4v5, Lv54 BSIM4v5)
- 工艺节点: 45nm, 130nm, 180nm, 0.18µm
- 晶体管数范围: 1–34
- FP32 vs FP64 精度: <0.01% @ bc018 VOUT

## 待执行测试 (按优先级)

### 🔴 P0: PTM 130nm 3 电路 (最高优先级)

BSIM4v5 130nm 是 v1.2 新增 PDK，目前没有任何 FP32 vs FP64 对照数据。

```bash
bash test_results/scripts/run_ptm130_comparison.sh
```

| 电路 | 网表 | 分析 |
|------|------|------|
| OTA 5T 130nm | test/bsim4/testbenches/ota_dc_bsim4.cir | DC OP + DC Sweep |
| OpAmp 130nm | test/bsim4/testbenches/opamp_dc_bsim4.cir | DC OP |
| LDO 130nm | test/bsim4/testbenches/ldo_dc_bsim4.cir | DC OP |

### 🟡 P1: NOISE 双边对照

NOIA overflow 是 FP32 已知风险。需确认 NOISE 在 Mixed FP32 下无 NaN。

| 电路 | 网表 | PDK |
|------|------|-----|
| OTA 5T 45nm | test/circuits/04_ota_5transistor_45nm/test_noise.sp | PTM 45nm LP |
| OpAmp 45nm | test/circuits/05_opamp_2stage_miller_45nm/test_noise.sp | PTM 45nm LP |

### 🟢 P2: TRAN 细粒度测试

| 网表 | 目标 |
|------|------|
| test/circuits_tran/T2_ota_step.sp | OTA 阶跃响应 |
| test/circuits_tran/T3_opamp_step.sp | OpAmp 阶跃响应 |
| test/circuits_tran/T5_ota_openloop.sp | OTA 开环阶跃 |

### ⚪ P3: 工艺角

全部 TT only。FF/FS/SF/SS 未测。

## 测试结果 (2026-07-24) — 部分补全

| 指标 | 值 |
|------|-----|
| PTM 130nm DC | 3/3 PASS ✅ |
| TRAN 补充 | 3/3 PASS ✅ |
| 剩余待补 | 45nm OTA/OpAmp AC/NOISE/TRAN, 180nm BSIM3v3, 工艺角 |

## 文件清单

```
v1.2_full/
├── README.md
├── fp32/                     ← 6 个 ngspice log (PTM 130nm × 3 + TRAN × 3)
├── fp64/                     ← 6 个 ngspice log
└── compare/                  ← 6 个对比报告
```
