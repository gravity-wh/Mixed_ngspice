# Mixed_ngspice P0 测试结果

> 日期: 2026-07-17

## P0-1: AnalogGym LDO 全变体

| 变体 | 功率管 M | 结果 | 原因 |
|------|----------|:--:|------|
| Basic LDO | M=253 | ✅ | DC+AC+TRAN 全部通过（之前已验证） |
| ldo_1 | M=928 | ⬜ | 需要 AnalogGym 运行时环境 `../simulations/` |
| ldo_2 | M=? | ⬜ | 同上——每变体有独立 subcircuit 拓扑 |
| ldo_folded_cascode | M=? | ⬜ | 同上——折叠共源共栅误差放大器 |

**结论**: AnalogGym 的 per-variant testbench 依赖框架生成的 `../simulations/` 目录（不在 git 仓库中）。ldo_1 (M=928 功率管) 的压力测试需完整 AnalogGym 环境。Basic LDO (M=253) 已验证通过，LDO 类别的基本可行性已确认。

## P0-2: StrongARM 比较器 (analog-circuit-skills)

PTM 45nm HP, 15T 动态锁存比较器。Python 框架直接调用 FP32 ngspice。

| 测试脚本 | 结果 | 数据 |
|----------|:--:|------|
| `run_tran_strongarm_wave.py` | ✅ | τ=7.9ps，再生锁存正常 |
| `run_tran_strongarm_ramp.py` | ✅ | -2mV→+2mV 斜坡, 100 周期 |
| `run_tran_strongarm_noise.py` | ❌ | FOM=NaN，噪声 1/f 缺失 |

**关键发现**: StrongARM 比较器的瞬态噪声 FOM 为 NaN，与 OTA 噪声分析的 1/f 缺失是同一根因（BSIM4 `oxideTrapDensity` 在 FP32 下溢出 + `Nintegrate` 精度不足）。**这跨电路类型（放大器→比较器）复现了噪声硬边界**。

## 更新的能力边界矩阵

```
DC收敛   ✅ 35/35 PVT (PTM) + 17/17 AMP (SKY130)
DC精度   ✅ <0.005% (PTM), <1% (SKY130 LDO)
AC小信号 ✅ 增益/PM/UGBW 精确 (PTM+SKY130)
TRAN模拟 ✅ gear+TRTOL 修复 TRAP (PTM+SKY130)
TRAN开关 ⚠️ 需 UIC+串阻 (自举开关, 比较器)
噪声分析 ❌ 1/f 缺失 — OTA+比较器双电路确认, 系统性硬边界
```

## 下一步

- P1: AnalogGym Bandgap (含 BJT, 新器件类型)
- P1: analog-circuit-skills OTA/运放噪声 testbench (量化噪声边界)
- P2: 安装 AnalogGym 完整环境 → LDO 全变体 + PLL
