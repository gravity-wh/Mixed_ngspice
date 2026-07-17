# Mixed_ngspice TRAN 瞬态全面验证方案

> 目标：在现有 DC 收敛成果上，建立科学的 TRAN 瞬态验证体系，判断 FP32 混合精度是否达标

---

## 一、核心挑战

DC 和 TRAN 的本质区别：

| | DC 工作点 | TRAN 瞬态 |
|---|---|---|
| 误差模式 | 单点收敛 → 有/无 | **时域累积** → 每步误差会传播 |
| 精度敏感点 | 初始猜测 | **开关事件** (矩阵条件数瞬时飙升) |
| 验证方式 | 对比单个电压值 | **对比整个波形** + 时序参数 |
| FP32 vs FP64 | <0.005% | 预计 **~0.1-1%** (开关处误差最大) |

关键发现（文献）：**FP32 瞬态在矩阵条件数 > 10⁴ 时精度验证失败**。开关事件（时钟沿、比较器锁存）正是条件数瞬时飙升的时刻——这是 TRAN 验证的核心难点。

---

## 二、验证指标体系

### 2.1 波形级指标（覆盖全时域）

| 指标 | 计算方式 | 合格标准 |
|------|----------|----------|
| **NRMSE** (归一化均方根误差) | RMS(FP32-FP64) / VDD × 100% | < 1% |
| **最大偏差** | max\|V_FP32(t) - V_FP64(t)\| / VDD × 100% | < 3% |
| **偏差时域分布** | 误差 vs 时间的散点图 | 误差不随时间发散 |

### 2.2 时序级指标（覆盖关键事件）

| 指标 | 适用电路 | 合格标准 |
|------|----------|----------|
| **频率/周期** | 环形振荡器 | FP32 vs FP64 偏差 < 0.5% |
| **建立时间** (1%/0.1%) | OTA/运放阶跃响应 | 偏差 < 2% |
| **过冲** | OTA/运放阶跃响应 | 偏差 < 0.5% VDD |
| **传播延迟** | 比较器 | 偏差 < 1% 或 < 1ps |
| **上升/下降时间** (10%-90%) | 自举开关/反相器 | 偏差 < 2% |

### 2.3 求解器健康指标

| 指标 | 含义 | 合格标准 |
|------|------|----------|
| **时间步数比** | FP32步数 / FP64步数 | < 2× (FP32不应因精度不足反复拒步) |
| **拒步率** | 被拒绝步数 / 总步数 | FP32 ≤ FP64 (不应更差) |
| **最小时间步** | 瞬态中用到的最小步长 | FP32 ≥ FP64×0.5 (不应因NaN强制切更小步) |
| **NaN事件数** | TRAN中触发CHECK_NAN次数 | **0** (DC可以容忍恢复, TRAN不行) |

---

## 三、测试电路设计

需要为现有电路补全 TRAN 激励，使其在闭环/切换状态下运行：

### Test T1 — 环形振荡器频率测量

**当前状态**: 只有单级反相器 DC 基线，无完整瞬态
**需要构建**:

```spice
* 17级环形振荡器 + 启动电路
.include ptm45lp.lib
VDD VDD 0 DC 1.1

* 17级反相器链 (34T)
Xinv1 out1 in VDD inv
Xinv2 out2 out1 VDD inv
...
Xinv17 in out16 VDD inv

* 启动: 用NMOS开关短接第1级输入到地10ns, 然后释放
Mstart in start VSS 0 nmos W=1u L=45n
Vstart start 0 PULSE(1.1 0 0 1p 1p 10n 100n)

* 测量: 自动提取频率
.tran 1p 50n
.meas TRAN period TRIG v(in) VAL=0.55 RISE=5 TARG v(in) VAL=0.55 RISE=6
.meas TRAN freq PARAM='1/period'
```

**验证指标**: FP32频率 vs FP64频率偏差，瞬态波形叠加对比
**预期**: 频率偏差 < 0.5%

### Test T2 — OTA 阶跃响应（闭环 unity-gain buffer）

**当前状态**: DC+AC 收敛，无 TRAN
**需要构建**:

```spice
* OTA 接成 unity-gain buffer (OUT→INN)
.include ptm45lp_tt.lib
.param VDD=1.1 ibias=10u

* OTA 核心 (同上)
MBIAS VBIAS VBIAS 0 0 nmos W=4u L=0.18u
IBIAS VDD VBIAS DC 10u
M1 OUT INP TAIL 0 nmos W=2u L=0.18u
M2 NETD OUT TAIL 0 nmos W=2u L=0.18u   ; ← 闭环: INN=OUT
M3 OUT NETD VDD VDD pmos W=4u L=0.18u
M4 NETD NETD VDD VDD pmos W=4u L=0.18u
M5 TAIL VBIAS 0 0 nmos W=4u L=0.18u

* 阶跃激励 (小信号1mV + 大信号100mV)
VIN INP 0 PWL(0 0.55 5n 0.55 5.001n 0.551 50n 0.551)
*                                 ↑ 1mV step

.tran 0.1n 100n
.meas TRAN settle_1p TRIG v(out) VAL=0.551 RISE=1 TARG v(out) VAL=0.5515
.meas TRAN overshoot MAX v(out) FROM=5n TO=20n
```

**验证指标**: 1mV 小信号阶跃建立时间, 100mV 大信号阶跃 slew rate + 建立时间
**预期**: 建立时间偏差 < 2%, 过冲偏差 < 0.5% VDD

### Test T3 — 运放闭环阶跃响应

**当前状态**: DC+AC 收敛, 无 TRAN
**需要构建**:

```spice
* 2-stage opamp 接成 unity-gain buffer (OUT→INN)
.include ptm45lp_tt.lib
.param VDD=1.1 ibias=20u

* ... 运放核心 (同 DC 网表, 但 INN=OUT) ...

* 阶跃激励: 大信号 + 小信号
VIN INP 0 PWL(0 0.55 5n 0.55 5.001n 0.65 100n 0.65)

.tran 0.1n 200n
.meas TRAN settle_1p  ...  ; 1% 建立时间
.meas TRAN settle_01p ...  ; 0.1% 建立时间
.meas TRAN overshoot MAX v(out) FROM=5n TO=50n
```

**验证指标**: 大信号阶跃 + 小信号建立 + 过冲 + slew rate
**这是最难的 TRAN 测试**——两级放大 + Miller 补偿 → 多极点闭环响应 → FP32 下的极点精度直接影响建立波形

### Test T4 — 比较器时钟瞬态

**当前状态**: DC 收敛 (CLK 常开), 无瞬态比较
**需要构建**:

```spice
* StrongARM 比较器 + 时钟 + 差分斜坡输入
.include ptm45hp.lib
VDD VDD 0 DC 1.0
VCLK CLK 0 PULSE(0 1.0 2n 50p 50p 2n 5n)
VINP INP 0 PWL(0 0.5 5n 0.55)
VINN INN 0 DC 0.5
* ... 比较器核心 ...

.tran 1p 20n
.meas TRAN regen_time ...  ; 锁存再生时间 (VXP/VXN交叉点)
```

**验证指标**: 再生时间 (比较器从 CLK↓ 到输出有效的延迟)
**难点**: CLK 切换时矩阵条件数瞬时飙升 → FP32 最容易在此处失稳

### Test T5 — 自举开关（已有，需增强）

**当前状态**: 已有 20ns TRAN, 但缺少 FP64 对比
**需要增强**:

- 同时跑 FP32 和 FP64
- 固定 max step = 10ps (确保时间点对齐)
- 逐点对比 V(vsampled) 波形
- 统计: RMS误差, 最大偏差, 步数比

---

## 四、验证流程

### Step 1: 构建 FP64 参考基线

```bash
# 构建不含 --enable-single-precision 的 FP64 版本
cd /mnt/e/MyResearch/Ngspice
tar xzf ngspice-46.tar.gz
cd ngspice-46
# 应用 patch 001-014 (SPICE_REAL=double 时 patch 自动降级为 no-op)
for p in /mnt/e/MyResearch/Mixed_ngspice/patches/*.patch; do
    patch -p1 < $p
done
./configure --disable-klu --disable-xspice CFLAGS="-O2"
make -j$(nproc)
# FP64 binary: src/ngspice
```

### Step 2: 批量运行 + 数据采集

对每个测试电路 (T1-T5), 每个工艺角 (TT/FF/SS):

```bash
# FP64 参考
ngspice_fp64 -b test_T1_tt.sp -o T1_tt_fp64.raw
# FP32 被测
ngspice_fp32 -b test_T1_tt.sp -o T1_tt_fp32.raw
```

### Step 3: 自动化对比脚本

```python
def compare_transient(raw_fp64, raw_fp32, vdd):
    t64, v64 = parse_raw(raw_fp64)
    t32, v32 = parse_raw(raw_fp32)
    
    # 插值到统一时间轴
    v32_interp = np.interp(t64, t32, v32)
    
    # 波形指标
    rmse = np.sqrt(np.mean((v32_interp - v64)**2)) / vdd
    max_err = np.max(np.abs(v32_interp - v64)) / vdd
    
    # 发散检测: 分时段统计误差
    n_segments = 10
    seg_rmse = []
    for i in range(n_segments):
        a, b = i*len(t64)//n_segments, (i+1)*len(t64)//n_segments
        seg_rmse.append(np.sqrt(np.mean((v32_interp[a:b]-v64[a:b])**2))/vdd)
    
    diverging = seg_rmse[-1] > 2 * seg_rmse[0]  # 误差翻倍 → 发散
    
    # 步数对比
    step_ratio = len(t32) / len(t64)
    
    return {
        'rmse': rmse, 'max_err': max_err,
        'diverging': diverging, 'step_ratio': step_ratio,
        'seg_rmse': seg_rmse
    }
```

### Step 4: 判定标准

| 结果 | 判定 |
|------|------|
| NRMSE < 0.5%, 不发散, 步数比 < 1.3 | ✅ **FP32 TRAN 达标** |
| NRMSE < 1%, 不发散, 步数比 < 2 | ⚠️ 可接受 (需记录偏差来源) |
| NRMSE > 1% 或 发散 或 步数比 > 2 | ❌ 需要修复 (定位具体开关事件) |

---

## 五、验证矩阵

```
电路        分析      TT    FF    SS    指标
─────────────────────────────────────────────
T1 环振     频率      ?     ?     ?     周期, 波形RMS
T2 OTA      阶跃      ?     ?     ?     建立时间, 过冲
T3 运放     阶跃      ?     ?     ?     建立时间, slew rate
T4 比较器   瞬态      ?     —     —     再生时间
T5 自举开关 瞬态      ?     —     —     波形RMS, 步数比
```

---

## 六、预期难点与对策

| 难点 | 原因 | 对策 |
|------|------|------|
| 环振启动失败 | 17级链在DC偏置下进入亚稳态 | 用NMOS开关强制注入初始脉冲 |
| 开关处 FP32 NaN | CLK沿→矩阵条件数瞬升>10⁴ | sollim + cmin 在 TRAN 模式下测试 |
| 步数爆炸 | FP32 反复拒步→强行切更小步→死循环 | 监控最小步长, 若 < 1e-15 则标记为 FAIL |
| 时域发散 | 误差随时间累积, 后期波形完全不同 | 分时段统计 RMSE, 检测发散趋势 |
| FP64 参考不可得 | 无法在同一代码基构建FP64 | patch 001 的条件编译使 SPICE_REAL=double 时自动退化为 no-op |

---

*方案制定: 2026-07-17*
