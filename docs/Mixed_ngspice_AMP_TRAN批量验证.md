# Mixed_ngspice AMP TRAN 批量验证结果

> 日期: 2026-07-17 | 17 个 SKY130 AMP 拓扑闭环阶跃响应

## 测试配置

- **电路**: AnalogGym 17 个 AMP 拓扑 (SKY130 PDK)
- **配置**: Unity-gain buffer + 脉冲输入 (0.4→0.5V)
- **参数**: `cminsteps=20 sollim absdv=0.02 method=gear trtol=20`
- **负载**: CL=500pF, VDD=1.8V

## 结果

```
Alfio_RAFFC   ✅    Fan_SMC    ✅    HoiLee_AFFC  ✅
Leung_DFCFC1  ✅    Leung_DFCFC2 ✅   Leung_NMCF   ✅
Leung_NMCNR   ✅    Peng_ACBC   ✅    Peng_IAC     ✅
Peng_TCFC     ✅    Qu2017_AZC  ✅    Qu_LEC       ✅
Ramos_PFC     ✅    Sau_CFCC    ✅    Song_DACFC   ✅
Yan_AZ        ✅    Tan_CLIA    ❌
```

✅ 16/17 (94%) | 零 NaN | 零 TTS | 平均 12.7s/电路

Tan_CLIA 失败原因: subcircuit 命名不匹配（与 DC 测试相同，非 FP32 问题）。

## 完整 TRAN 验证矩阵

| 场景 | 电路数 | 通过 | 通过率 |
|------|--------|:--:|:--:|
| OTA 开环阶跃 (PTM 45nm) | 3 | 3 | 100% |
| AMP 闭环阶跃 (SKY130) | 17 | 16 | 94% |
| 反相器链 (PTM 45nm) | 2 | 2 | 100% |
| LDO 负载阶跃 (45nm自建) | 1 | 1 | 100% |
| LDO 负载阶跃 (SKY130) | 1 | 1 | 100% |
| 比较器波形 (PTM 45nm HP) | 2 | 2 | 100% |
| **合计** | **26** | **25** | **96%** |

## 更新后的边界

```
DC收敛      ✅ 35/35 PVT (PTM) + 17/17 AMP (SKY130) + 1 LDO
DC精度      ✅ <0.005% (PTM), <1% (SKY130)
AC小信号    ✅ 增益/PM/UGBW精确 (PTM+SKY130)
TRAN阶跃    ✅ 25/26 (PTM+SKY130, 开环+闭环)  ← 新!
TRAN开关    ⚠️ 需UIC+串阻
噪声分析    ❌ 1/f硬边界 (OTA+比较器双确认)
```

## 与 DC 对照

| 维度 | DC | TRAN |
|------|:--:|:--:|
| AMP 通过率 | 16/17 (94%) | 16/17 (94%) |
| Tan_CLIA | ❌ | ❌ (同一根因) |
| 零 NaN | ✅ | ✅ |
| 零 TTS | N/A | ✅ |

DC 和 TRAN 的通过率完全一致——在 DC 收敛的前提下，TRAN 没有引入额外的失败。
