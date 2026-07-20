# Mixed_ngspice Baseline v1.0

> Tag: `baseline-v1.0` · Date: 2026-07-20 · Status: **11/11 PASS**

## Binary

| Precision | Path | SINGLE_PRECISION |
|-----------|------|:--:|
| FP32 | `Ngspice/ngspice-46_mixed/build/src/ngspice` | ✅ |
| FP64 | `Ngspice/ngspice-46_mixed/build64/src/ngspice` | ❌ |

## Verified Circuits (11/11)

### DC OP (6/6)
| # | Circuit | Transistors | Technology | Options |
|---|---------|:--:|------|------|
| 1 | NMOS single | 1 | PTM45 LP | VDD R 1Ω |
| 2 | PMOS single | 1 | PTM45 LP | VDD R 1Ω |
| 3 | 5T OTA | 6 | PTM45 LP | VDD R 1Ω + gmin=1e-10 sollim |
| 4 | 2-Stage OpAmp | 8 | PTM45 LP | VDD R 1Ω |
| 5 | StrongARM Comparator | 15 | PTM45 HP | VDD R 1Ω |
| 6 | LDO | 10 | PTM45 LP | VDD R 1Ω + gmin=1e-10 sollim |

### TRAN (5/5)
| # | Circuit | Type | Technology | Options |
|---|---------|------|------|------|
| 7 | Bootstrap Switch | 500MHz sampling | PTM45 HP | VDD R 1Ω + clock R 100Ω + gmin=1e-10 sollim |
| 8 | StrongARM Comparator | 1GHz clock UIC | PTM45 HP | VDD R 1Ω + clock R 100Ω + gmin=1e-10 sollim |
| 9 | OTA closed-loop | Unity-gain step | PTM45 LP | VDD R 1Ω + gate R 100Ω + gmin=1e-10 sollim |
| 10 | OpAmp closed-loop | Unity-gain step | PTM45 LP | VDD R 1Ω + gate R 100Ω + gmin=1e-10 sollim |
| 11 | 17-Stage Ring Oscillator | Free oscillation | PTM45 LP | VDD R 1Ω + alternating IC + startup NMOS + UIC |

## FP64 Precision Islands (6)

| # | Island | File | Lines | Type |
|---|--------|------|:--:|------|
| 1 | Vbi | b4v5temp.c | 1 | Overflow (nsd·ndep=6.48e38) |
| 2 | Leff/Weff | b4v5temp.c | ~30 | Cancellation (L−2·dl) |
| 3 | Abulk | b4v5ld.c | ~35 | Cancellation (Leff/(Leff+2√(xj·Xdep))) |
| 4 | Vbseff/Phis/Xdep | b4v5ld.c | ~25 | Cancellation (sqrt(T₀²−C)) |
| 5 | Vth k1ox | b4v5ld.c | 4 | Cancellation (k1ox·√φs−k1·√φ) |
| 6 | Noise NOIA | b4v5noi.c | ~40 | Overflow (6.25e41) |

Total: 136 double occurrences across 3 files. 4 other source files + all headers = 0 double.

## Universal Convergence Recipe

```
VDD series 1Ω + gate/clock series 100Ω + gmin=1e-10 sollim
Ring osc additional: alternating IC (0/1.1V) + startup NMOS + UIC
```

## Patch Architecture

| Layer | Patches | Function |
|-------|---------|----------|
| 1 | 001 | SPICE_REAL type system + 18 math macros |
| 2 | 002 | 1337 struct members double→SPICE_REAL (-45% memory) |
| 3 | 003-011 | Hot-path FP32 + 6 FP64 islands + NaN firewall |
| 4 | 012-013 | Bug fixes (vbi overflow, multi-T NaN) |
| 5 | 014 | Solver enhancements (Cmin + Solution Limiting) |
| 6 | 015 | Noise FP64 island |
