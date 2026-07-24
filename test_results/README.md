# Mixed_ngspice Test Results — Master Index

> 最后更新: 2026-07-24

## 目录结构

```
test_results/
├── README.md                          ← 你在这里
├── v1.0_baseline/                     # 6 FP64 islands 基线
├── v1.1_fp32_conversions/             # 3 纯 FP32 数值方法
├── v1.2_full/                         # 全 double-precision BSIM4
├── work_dirs/                         # PTM 180nm BSIM3v3 独立数据
│   ├── ota_ptm180/
│   ├── opamp_ptm180/
│   └── ldo_ptm180/
└── scripts/                           # 测试脚本
```

## 版本概览

| 版本 | Git Tag/Commit | 描述 | 状态 |
|------|---------------|------|------|
| **v1.0** | `7f00872` | 6 FP64 islands 基线, 136 double ops | 11/11 PASS 文档化 |
| **v1.1** | `492ba5d` / `c21c9f8` | Vbi/Vbseff/Vth k1ox → 纯 FP32 | 11/11 PASS 文档化 |
| **v1.2** | `24aabbc` / `d8c6ba8` | Double-precision BSIM4 math | **40/40 PASS** 文档化 |

## 数据完整性状态

| 版本 | FP32 vs FP64 对比日志 | 覆盖率 | 备注 |
|------|----------------------|--------|------|
| v1.0 | ✅ 有 (Pure FP32 strawman) | 11/11 电路 | Strawman 对照实验数据 (25% pass) |
| v1.1 | ✅ **已补全** (2026-07-24) | 13/13 logs, 11/11 comparable | 2 电路 FP64 已知失败 |
| v1.2 | ⚠️ 部分补全 | 6/40 (PTM 130nm + TRAN) | 剩余 34 tests 待补 |
| work_dirs | ⚠️ 单边 (FP32 only) | 3 电路 × 多分析 | BSIM3v3 路径，无 FP64 对照 |

## 每个版本的详细说明

### v1.0_baseline/ — 6 FP64 Islands 基线

- **构建配置**: SPICE_REAL=float + 6 个 FP64 孤岛保留
- **日志来源**: `logs/` 目录 (2026-07-20 Pure FP32 strawman 对照实验)
- **电路**: 01–08 (PTM 45nm) + T1 ring osc
- **数据内容**:
  - `fp32/` — 11 个 FP32 构建的 ngspice 原始输出
  - `fp64/` — 11 个 FP64 参考构建的 ngspice 原始输出
  - `compare/` — 7 个 compare_fp.py 生成的对比报告
  - `ci_summary.json` — CI 汇总 (25% pass rate, strawman 对照)

> ⚠️ 注意：这些日志来自 **Pure FP32** (no-islands) strawman 构建，不是 Mixed FP32 v1.0。
> v1.0 的 11/11 PASS 是基于 Mixed FP32 (保留 6 个 FP64 islands) 构建，该构建的对比日志未存档。

### v1.1_fp32_conversions/ — 3 纯 FP32 数值方法

- **构建配置**: SPICE_REAL=float + 仅 3 个 FP64 islands (Abulk, Leff/Weff, NOIA)
- **变更**: Vbi log 拆分, Vbseff 平方差分解, Vth k1ox Dekker 减法
- **日志状态**: ⬜ **全部缺失** — 需要构建后运行
- **待执行测试**:
  - 01–08 电路 DC/TRAN (11 项)
  - 重点: OTA/OpAmp NOISE 对比 (NOIA overflow 敏感)

### v1.2_full/ — 全 Double-Precision BSIM4 Math

- **构建配置**: SPICE_REAL=float (存储) + double BSIM4 math (exp/log/sqrt 计算)
- **覆盖**: 15 电路 × 6 PDK × 6 分析类型 = 40 tests
- **日志状态**: ⬜ **全部缺失** — 需要构建后运行
- **待执行测试** (按优先级):
  1. 🔴 PTM 130nm 3 电路 (BSIM4v5, v1.2 新增) — DC + AC + NOISE
  2. 🟡 PTM 45nm OTA/OpAmp NOISE (FP32 敏感点)
  3. 🟢 circuits_tran/ 重点网表 (T2 ota_step, T3 opamp_step)
  4. ⚪ 工艺角 (FF/FS/SF/SS)

### work_dirs/ — PTM 180nm BSIM3v3

- **构建**: 单次 FP32 构建 (无 FP64 对照)
- **数据内容**: DC/AC/NOISE/TRAN/PZ 的 ngspice log + 提取数据 + PNG 图
- **缺失**: 所有电路均无 FP64 对照数据

## 如何补全测试数据

### 前置条件

需要两个 ngspice 构建:
```bash
# FP32 构建 (当前版本)
bash scripts/build.sh --fp32-only -j 4

# FP64 参考 (未修改的 ngspice-46)
bash scripts/build.sh --fp64-only -j 4
```

### 运行所有缺失测试

```bash
# v1.1 对比 (11 电路)
bash test_results/scripts/run_v1.1_comparison.sh

# v1.2 对比 (40 tests)
bash test_results/scripts/run_v1.2_comparison.sh

# 仅 PTM 130nm (最高优先级)
bash test_results/scripts/run_ptm130_comparison.sh

# circuits_tran (12 TRAN 网表)
bash test_results/scripts/run_tran_comparison.sh
```

### 生成对比报告

```bash
# 单电路对比
python scripts/compare_fp.py <fp32.log> <fp64.log> -o compare.md

# 批量对比
python scripts/compare_three.py <fp32pure.log> <fp32mixed.log> <fp64.log>
```

## 数据集标注规范

每个 `fp32/` 和 `fp64/` 目录下的日志文件命名:
```
{circuit_id}_{analysis}_{precision}.log

示例:
01_nmos_dc_fp32.log          # NMOS DC OP, FP32 构建
04_ota_ac_fp64.log           # OTA AC, FP64 参考
10_ota_ptm130_dc_fp32.log    # PTM 130nm OTA DC, FP32 构建
```

每个版本目录的 README.md 须包含:
- 构建配置 (SPICE_REAL, 补丁列表, 编译选项)
- 测试日期
- 电路列表 (名称, PDK, 晶体管数, 分析类型)
- PASS/FAIL 汇总
- 已知问题
