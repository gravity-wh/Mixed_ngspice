# Mixed_ngspice Baseline v1.1

> Tag: `baseline-v1.1` · Date: 2026-07-20 · Status: **11/11 PASS**

## Changes from v1.0

| Change | v1.0 | v1.1 |
|--------|------|------|
| Vbi computation | FP64 island: `(double)nsd*(double)ndep` | Pure FP32: `logf(nsd)+logf(ndep)−2*logf(ni)` |
| Vbseff sqrt | FP64 island: `double dT0, dT1` | Pure FP32: `(T₀−√C)·(T₀+√C)` factorization |
| Vth k1ox subtraction | FP64 island: `(double)k1ox*...−(double)k1*...` | Pure FP32: Dekker exact subtraction (6 ops) |
| FP64 islands | 6 | 3 |
| Hot-path double ops | ~65/transistor/iteration | ~35/transistor/iteration |
| 11-circuit regression | 11/11 | 11/11 (unchanged) |

## Binary

| Precision | Path | SINGLE_PRECISION |
|-----------|------|:--:|
| FP32 | `Ngspice/ngspice-46_mixed/build/src/ngspice` | ✅ |
| FP64 | `Ngspice/ngspice-46_mixed/build64/src/ngspice` | ❌ |

## Remaining FP64 Islands (3, all non-critical)

| Island | File | Lines | Why Not Converted |
|--------|------|:--:|------|
| Abulk | b4v5ld.c | ~35 | Deep nested cancellation chain; setup-only (1× per device) |
| Leff/Weff | b4v5temp.c | ~28 | pow(Lnew, Lln) spans 20+ orders; setup-only |
| Noise NOIA | b4v5noi.c | ~39 | Noise analysis only; not in DC/AC/TRAN hot path |

## Verified Circuits (11/11)

### DC OP (6/6)
NMOS · PMOS · OTA · OpAmp · StrongARM · LDO

### TRAN (5/5)
Bootstrap · StrongARM (clocked) · OTA closed-loop · OpAmp closed-loop · Ring Oscillator

## Universal Convergence Recipe
```
VDD series 1Ω + gate/clock series 100Ω + gmin=1e-10 sollim
Ring osc: alternating IC (0/1.1V) + startup NMOS + UIC
```
