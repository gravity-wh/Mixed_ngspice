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

## Test Suite

| Circuit | Transistors | Analysis | Expected Error |
|---------|------------|----------|----------------|
| Single PMOS | 1 | .OP | < 0.001% |
| Single NMOS | 1 | .OP | < 0.001% |
| Bias 6T | 6 | .OP + .TRAN | < 0.003% |
| Op-amp 22T | 22 | .OP + .TRAN | < 0.005% |

## Supported Process Corners

| Corner | Status |
|--------|--------|
| TT (Typical-Typical) | Verified |
| FF (Fast-Fast) | In progress |
| SS (Slow-Slow) | In progress |
| FNSP (Fast-NMOS Slow-PMOS) | In progress |
| SNFP (Slow-NMOS Fast-PMOS) | In progress |

Generated via `scripts/gen_corners.py` from HSPICE corner libraries.

## Documentation

- [Complete Reproduction Guide](docs/FP32混合精度_完整复现指南.md)
- [Precision Loss Validation](docs/FP32_精度损失验证报告.md)
- [FP64 Retention Strategy](docs/FP64_保留策略分析.md)
- [Non-TT Corner Convergence Solutions](docs/非TT工艺角FP32收敛_解决方案调研.md)

## Repository Structure

```
Mixed_ngspice/
├── patches/          # 11 patches against vanilla ngspice-46
├── scripts/          # Build, comparison, and corner-generation scripts
├── test/             # Test circuits, models, and automation
├── docs/             # Technical documentation
└── .github/          # CI workflows
```

## License

BSD 3-Clause License — same as ngspice.

## References

- Ngspice: http://ngspice.sourceforge.net/
- BSIM4v5: BSIM Group, UC Berkeley
