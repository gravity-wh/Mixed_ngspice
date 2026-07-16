# Mixed_ngspice Test Suite

## Dataset Organization

### Open Datasets (freely redistributable)

| # | Circuit | Technology | Transistors | Analyses | Model |
|---|---------|------------|-------------|----------|-------|
| 01 | Single NMOS | 45nm LP | 1 | DC OP, DC Sweep | PTM BSIM4 |
| 02 | Single PMOS | 45nm LP | 1 | DC OP, DC Sweep | PTM BSIM4 |
| 03 | Ring Oscillator 17-stage | 45nm LP | 34 | TRAN, Freq Meas | PTM BSIM4 |
| 04 | Five-Transistor OTA | 45nm LP | 5 | DC OP, AC | PTM BSIM4 |
| 05 | Two-Stage Miller Op-Amp | 45nm LP | 7 | DC OP, AC | PTM BSIM4 |
| 06 | StrongArm Comparator | 45nm HP | 14 | TRAN | PTM BSIM4 |
| 07 | Bootstrap Switch | 45nm HP | 7 | TRAN | PTM BSIM4 |
| 08 | Roessler Attractor | — (behavioral) | 0 | TRAN | N/A |

### Private Datasets (TSMC 0.18um — NOT redistributable)

| # | Circuit | Technology | Transistors | Analyses |
|---|---------|------------|-------------|----------|
| P1 | Single PMOS | TSMC 0.18um | 1 | DC OP |
| P2 | Single NMOS | TSMC 0.18um | 1 | DC OP |
| P3 | 6T Bias Generator | TSMC 0.18um | 6 | DC OP |
| P4 | 22T Op-Amp | TSMC 0.18um | 22 | DC OP, TRAN |

## Model Libraries

| Directory | Process | BSIM Version | Level | VDD | License |
|-----------|---------|-------------|-------|-----|---------|
| `models/45nm_LP_BSIM4/` | PTM 45nm LP | BSIM4.0 | 54 | 1.1V | Open (PTM) |
| `models/45nm_HP_BSIM4/` | PTM 45nm HP | BSIM4.0 | 54 | 1.0V | Open (PTM) |
| `models_private_tsmc/` | TSMC 0.18um | BSIM4v5 | 14 | 1.8V | Proprietary |

## Quick Start

```bash
# Run all open tests
bash test/run_all.sh

# Run specific circuit
build_fp32/src/ngspice --batch test/circuits/04_ota_5transistor_45nm/test_dc.sp

# Compare FP32 vs FP64
python3 scripts/compare_fp.py logs/04_ota_dc_fp32.log logs/04_ota_dc_fp64.log
```

## Circuit Complexity Gradient

```
1 transistor  →  5 transistors  →  7 transistors  →  14 transistors  →  17 stages  →  22 transistors
   (01-02)         (04 OTA)        (05 OpAmp)        (06 Comparator)    (03 RingOsc)    (P4 TSMC)
```

## Model Compatibility Note

All open circuits use PTM 45nm models which declare `level=54` (BSIM4).
In ngspice-46, level=54 routes to the BSIM4v5 code path (`b4v5ld.c`),
which is exactly the code modified by this project. The `version=4.0`
parameter in PTM models is backward-compatible with BSIM4v5's code.
