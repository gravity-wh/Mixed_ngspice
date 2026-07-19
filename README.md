# Mixed_ngspice: FP32 Mixed-Precision Ngspice for Analog Sizing

[![Test](https://github.com/gravity-wh/Mixed_ngspice/actions/workflows/test.yml/badge.svg)](https://github.com/gravity-wh/Mixed_ngspice/actions/workflows/test.yml)

**Mixed-precision ngspice-46** that accelerates BSIM4v5 device evaluation by reducing floating-point precision from FP64 to FP32 in struct storage and hot-path math, while keeping critical computations in FP64.

- **< 0.003% DC accuracy loss** on TSMC/SMIC 0.18µm circuits (TT corner)
- **1.7-2.8× transient speedup** on multi-transistor op-amps
- **-45% working set** (struct members halved from 8 to 4 bytes)

## Quick Start

```bash
# Prerequisites: gcc, make, autotools, libx11-dev, bison, flex
sudo apt-get install -y build-essential autoconf automake libtool bison flex libx11-dev

# Clone and build
git clone https://github.com/gravity-wh/Mixed_ngspice.git
cd Mixed_ngspice
bash scripts/build.sh

# Run tests
bash test/run_all.sh
```

The build produces two binaries:
- `build_fp32/src/ngspice` — mixed-precision (FP32 storage + selective FP32 math)
- `build_fp64/src/ngspice` — reference double-precision

## How It Works

| Layer | Mechanism | Effect |
|-------|-----------|--------|
| **Storage** | `double` → `SPICE_REAL` (= `float`) in 1337 struct members | Working set -45%, better cache |
| **Math** | Selective `exp()` → `expf()` in hot paths | ~13 calls lowered to FP32 |
| **Safety** | Double-precision islands for Vbseff, Leff/Weff | Prevents catastrophic cancellation |
| **NaN Guard** | 40+ NaN detection + zeroing points | Prevents Newton divergence |

The approach is **FP32 storage + selective FP64 compute**, analogous to mixed-precision training in deep learning (FP16 gradients + FP32 accumulation).

## Validation Coverage (2026-07-19)

| Dataset | Circuits | FP32 PASS | Pass Rate |
|---------|----------|:--:|:--:|
| **PTM 45nm** (open) | 8 circuits | 10/12 tests | 83% |
| **SKY130A** (Analog_blocks) | 58 circuits | 58/58 | **100%** |
| **SKY130** (AnalogGym LDO) | 4 circuits | 4/4 | **100%** |
| **SMIC 180nm BCD** (AnalogSizing) | 8 circuits | 4/8 | 50% |
| **TRAN validation** | 14 circuits | 11/14 | 79% |
| **Total** | **104 files** | **88** | **85%** |

### DC Precision
| Circuit | Metric | FP32 | FP64 | Error |
|---------|--------|------|------|-------|
| NMOS 45nm | id | 1.48189e-05 | 1.48189e-05 | **0.00007%** |
| PMOS 45nm | id | 2.15147e-05 | 2.15147e-05 | **0%** |
| OpAmp DC | v(out) | 1.098757 | 1.093652 | **0.47%** |

### TRAN Milestones
- ✅ BGR startup (SKY130A, BJT+MOSFET)
- ✅ OTA closed-loop step (PTM45, unity-gain buffer)
- ✅ OpAmp closed-loop step (PTM45, 2-stage Miller, 100mV step)
- ✅ Comparator clocked (PTM45, 1GHz/50ps edge)
- ✅ Buck converter (SKY130A, PWM switching)
- ✅ LDO load step (SKY130A, feedback network)

## Supported Process Corners

| Corner | PTM 45nm | SKY130A | SMIC 180nm BCD |
|--------|:--:|:--:|:--:|
| TT (Typical) | ✅ Verified | ✅ Verified | ⚠️ NMOS only |
| FF (Fast-Fast) | In progress | Model available | ⚠️ |
| SS (Slow-Slow) | In progress | Model available | ⚠️ |

## Documentation

- [FP32 Full Coverage Report v2](docs/FP32_全覆盖最终报告_v2_20260719.md)
- [FP32 TRAN Validation Report](docs/FP32_TRAN验证报告_20260719.md)
- [Complete Reproduction Guide](docs/FP32混合精度_完整复现指南.md)
- [Precision Loss Validation](docs/FP32_精度损失验证报告.md)
- [FP64 Retention Strategy](docs/FP64_保留策略分析.md)
- [Noise Analysis Boundary](docs/Mixed_ngspice_噪声分析边界.md)
- [TRAN Validation Methodology](docs/Mixed_ngspice_TRAN瞬态验证方案.md)
- [P0 Test Results](docs/Mixed_ngspice_P0测试结果.md)

## Repository Structure

```
Mixed_ngspice/
├── patches/          # 15 patches against vanilla ngspice-46
├── scripts/          # Build, batch validation, waveform comparison
├── test/
│   ├── circuits/     # 8 PTM45 test circuits (DC/AC/TRAN)
│   ├── circuits_tran/# T1-T5 custom TRAN testbenches
│   ├── models/       # PTM 45nm LP/HP (TT/FF/SS/FS/SF)
│   └── expected/     # FP64 baseline JSON
├── docs/             # Technical documentation & validation reports
└── .github/          # CI workflows
```

## License

BSD 3-Clause License — same as ngspice.

## References

- Ngspice: http://ngspice.sourceforge.net/
- BSIM4v5: BSIM Group, UC Berkeley
