# work_dirs — PTM 180nm BSIM3v3 独立测试数据

> **构建**: 单次 FP32 构建 · **日期**: 2026-07-21 · **状态**: ⚠️ 单边 (无 FP64 对照)

## 说明

这三个电路使用 PTM 180nm BSIM3v3 模型 (Level 49)，与主测试套件中的 BSIM4v5 (Level 54) 代码路径不同。
数据从 `test/{ota,opamp,ldo}_work/` 迁移而来。每个电路包含完整的 ngspice log、提取的数值数据、和 PNG 图表。

**关键局限性**: 所有数据只有一个构建的输出——没有 FP64 参考对照。因此无法判断 FP32 改动是否影响了 BSIM3v3 路径。

## ota_ptm180/ — 五管 OTA

| 分析 | Log | 数据文件 | 图 | 状态 |
|------|-----|---------|----|------|
| DC Sweep | ota_dc.log | ota_dc_vinp.txt, ota_dc_vout.txt | ota_dc.png | ✅ |
| AC | ota_ac.log | ota_ac_freq.txt, ota_ac_gain_db.txt, ota_ac_phase.txt | ota_ac.png | ✅ |
| NOISE | ota_noise.log | ota_noise_freq.txt, ota_noise_onoise.txt | ota_noise.png | ✅ |

性能摘要 (来自 ota_report.txt): DC gain 34.33 dB, UGB 84.97 MHz, PM 77.2°

## opamp_ptm180/ — 两级 Miller OpAmp

| 分析 | Log | 数据文件 | 图 | 状态 |
|------|-----|---------|----|------|
| DC OP | opamp_dc.log | opamp_dc_nodes.txt, opamp_dc_currents.txt | opamp_dc_nodes.png | ✅ |
| AC | opamp_ac.log | opamp_ac_freq.txt, opamp_ac_gain_db.txt, opamp_ac_phase.txt | opamp_ac.png | ✅ |
| NOISE | opamp_noise.log | opamp_noise_freq.txt, onoise.txt, inoise.txt | opamp_noise.png | ✅ |
| NOISE Unity | opamp_noise_unity.log | freq.txt, onoise.txt, inoise.txt | — | ✅ |
| PZ | opamp_pz.log | — | — | ⚠️ 迭代达上限 |

性能摘要: DC gain 64.25 dB, UGB 13.66 MHz, PM 80.7°, en@1kHz 97.9 nV/√Hz

## ldo_ptm180/ — LDO

| 分析 | Log | 数据文件 | 图 | 状态 |
|------|-----|---------|----|------|
| DC OP + Sweep | ldo_dc.log | line_vin/vout.txt, load_vout.txt | ldo_dc.png | ✅ |
| AC Loop Gain | ldo_ac_loopgain.log | freq.txt, mag.txt, phase.txt | ldo_ac.png | ✅ |
| AC PSRR + Zout | ldo_ac_psrr.log | psrr_freq/mag/phase.txt, zout_freq/mag/phase.txt | — | ✅ |
| NOISE | ldo_noise.log | freq.txt, onoise.txt | ldo_noise.png | ✅ |
| TRAN | ldo_tran.log | vin.txt, vout.txt (空?) | ldo_tran.png | ❌ TRAN 失败 |

性能摘要: VOUT 1.805V, Line reg 1.08 mV/V, DC loop gain 51.7 dB, GBW 1.18 MHz, PM 58.6°

## 文件清单

```
work_dirs/
├── README.md
├── ota_ptm180/
│   ├── ota_report.txt
│   ├── *.log (3 个)
│   ├── *.txt (9 个提取数据)
│   └── plots/ (3 个 PNG)
├── opamp_ptm180/
│   ├── opamp_report.txt
│   ├── *.log (5 个)
│   ├── *.txt (15 个提取数据)
│   └── plots/ (3 个 PNG)
└── ldo_ptm180/
    ├── ldo_report.txt
    ├── ldo_auto_design.txt
    ├── *.log (5 个)
    ├── *.txt (18 个提取数据)
    └── plots/ (4 个 PNG)
```
