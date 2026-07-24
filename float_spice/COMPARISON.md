# float_spice vs ngspice — Comparison

> A practical guide to understanding what float_spice can and cannot do compared to the reference ngspice-46 engine.

## Quick Summary

| Dimension | float_spice v2.5 | ngspice-46 (Mixed_ngspice v1.9) |
|-----------|:---:|:---:|
| **Float precision** | Pure FP32 — 0 cvtss2sd | Mixed FP32/FP64 — ~632 cvtss2sd |
| **Code size** | ~1,675 lines (single file) | ~500K lines |
| **BSIM4 parameters** | 51 | 400+ |
| **BSIM4 physical effects** | 15+ | 30+ |
| **Test circuits supported** | ~3-5 (mx/ subset) | 130/155 |
| **DC convergence** | 3-stage gmin + 4-ramp source + Cmin | Full SPICE convergence |
| **TRAN analysis** | Trapezoidal, caps + MOS caps | Full BE + TRAP + Gear |
| **Parser features** | 12/30+ SPICE features | Full SPICE3f5 + extensions |
| **Build** | `gcc -O2 -o float_spice float_spice.c -lm` | autotools (./configure && make) |

## Feature Matrix

### Analysis Modes

| Mode | float_spice | ngspice |
|------|:--:|:--:|
| `.op` (DC operating point) | ✅ | ✅ |
| `.dc` (DC sweep) | ✅ Single + nested | ✅ Full |
| `.tran` (Transient) | ✅ Trapezoidal | ✅ TRAP/BE/Gear |
| `.ac` (AC small-signal) | ❌ | ✅ |
| `.noise` | ❌ | ✅ |
| `.pz` (Pole-zero) | ❌ | ✅ |
| `.disto` | ❌ | ✅ |
| `.tf` (Transfer function) | ❌ | ✅ |
| `.sens` | ❌ | ✅ |

### SPICE Elements

| Element | float_spice | ngspice |
|---------|:--:|:--:|
| Resistor (R) | ✅ | ✅ |
| Capacitor (C) | ✅ | ✅ |
| Voltage source (V) — DC | ✅ | ✅ |
| Voltage source (V) — SIN | ✅ | ✅ |
| Voltage source (V) — PULSE | ✅ | ✅ |
| Voltage source (V) — PWL | ✅ | ✅ |
| Voltage source (V) — EXP/AM/SFFM | ❌ | ✅ |
| Current source (I) — DC | ✅ | ✅ |
| MOSFET (M) — BSIM4v5 | ✅ 51 params | ✅ 400+ params |
| MOSFET (M) — other levels | ❌ | ✅ Levels 1-73 |
| BJT (Q) | ❌ | ✅ |
| JFET (J) | ❌ | ✅ |
| Diode (D) | ❌ | ✅ |
| Controlled sources (E/F/G/H) | ❌ | ✅ |
| Transmission line (T) | ❌ | ✅ |
| Mutual inductor (K) | ❌ | ✅ |
| Subcircuit (X) | ✅ Inline expansion | ✅ Native hierarchy |

### Parser Features

| Feature | float_spice | ngspice |
|---------|:--:|:--:|
| `.model` cards | ✅ Key=value | ✅ Full |
| `.include` | ✅ Recursive | ✅ Full |
| `.subckt` / `.ends` / `X` | ✅ Inline expansion | ✅ Native |
| `.control` block | ✅ op/dc/tran/print/plot | ✅ Full interactive |
| `.option` | ✅ gmin/abstol/reltol/maxiter | ✅ 100+ options |
| `.param` + `{name}` | ✅ | ✅ + expressions |
| `.temp` | ✅ C→K conversion | ✅ Full temp model |
| `.ic` / `.nodeset` | ❌ | ✅ |
| `.lib 'file' section` | ❌ | ✅ |
| `.meas` | ❌ | ✅ |
| `.alter` | ❌ | ✅ |
| `$` inline comments | ❌ | ✅ |
| Spectre syntax | ❌ | ❌ (patched) |
| Engineering suffixes | ✅ (k,m,u,n,p,f,meg,mil) | ✅ Full |
| Continuation lines (`+`) | ✅ | ✅ |

### Solver Features

| Feature | float_spice | ngspice |
|---------|:--:|:--:|
| MNA with branch currents | ✅ Floating Vsrcs | ✅ Full |
| Gmin stepping | ✅ 3-stage (1e-9→1e-10→1e-12) | ✅ Adaptive |
| Source stepping | ✅ 4-ramp (0.1%→100%) | ✅ Full |
| Cmin stepping | ✅ 3-stage (1e-6→1e-9→0) | ✅ Full |
| Pseudo-transient fallback | ✅ Cmin=1e-3 | ✅ Full |
| Adaptive voltage limiting | ✅ [0.01..5.0]V | ✅ Full |
| Recovery cascade | ✅ 5-level | ✅ Full |
| NaN firewall | ✅ 3-layer | ✅ (not needed, FP64) |
| RELTOL convergence | ❌ ABSTOL only | ✅ |
| Pivot tolerance | ❌ >1e-30 | ✅ |
| Sparse matrix | ❌ Dense (N≤256) | ✅ KLU/Sparse |

## BSIM4 Model Fidelity

### What float_spice implements

```
Vth    ✓  vth0 + body + SCE(dvt0/1) + DIBL(dsub,eta0) + NW(k3,w0) + LPE(nlx)
Vgsteff ✓  n_eff drain/body-dependent + voffcv + dual-branch smooth transition
Mobility ✓  mobMod=0/1/2 + Coulomb scattering (ud,eu)
Vdsat   ✓  bulk-charge + velocity saturation
Ids     ✓  5-part Early voltage stack (Vasat+VACLM+VADIBL+VADITS+VASCBE)
Rds     ✓  rdsw + prwg bias-dependent source/drain degeneration
Caps    ✓  Meyer Cgs/Cgd/Cgb + overlap/fringing
NaN     ✓  3-layer firewall (diode clamp + safe output + recovery retry)
```

### What's missing (in reference ngspice)

```
Vth     ✗  dvt2 body-bias dependent SCE, pocket-implant Vth roll-up
Vgsteff  ✗  minv moderate-inversion dual-branch, full BSIM4 smoothing
Mobility ✗  L-dependent mobility (ua+uc·Vbs scaling with Leff)
CLM     ✗  pvag gate-bias dependent Early voltage
SCBE    ✗  Full two-part pscbe model with Vgsteff dependence
Temperature ✗  kt1/kt2/ute/ua1/ub1/uc1 (parsed, not used in formulas)
Noise    ✗  noia/noib flicker noise model
Junction  ✗  Source/drain diodes (js, jsw, cj, mj)
GIDL     ✗  agidl/bgidl gate-induced drain leakage
Gate tunnel ✗  aigc/bigc/cigc (essential for toxe<2nm)
```

### Expected Accuracy

| Operating Region | float_spice vs ngspice | Notes |
|------------------|:----------------------:|-------|
| Strong inversion, long L | **<5%** in Ids | Classical square-law, BSIM core matches |
| Strong inversion, min L | **10-30%** in Ids | SCE simplified, Rds linear, no pvag |
| Subthreshold | **2-10×** in Ids | No minv bridging, simplified smoothing |
| Output resistance | **2-5×** in gds | Harmonic Early stack vs full BSIM4 |
| gds @ high Vds | **5-20×** | No pscbe2 Vgsteff dependence |
| Vth (long L) | **<5mV** | vth0 + body matched |
| Vth (short L) | **20-50mV** | SCE single-exp vs. full dvt0/1/2 model |

### Test Circuit Coverage

| Circuit | float_spice | Required Features |
|---------|:--:|-------------------|
| `mx_nmos_dc.sp` | ✅ | M, V(DC), .model, .include |
| `mx_pmos_dc.sp` | ✅ | M, V(DC), .model, .include, PMOS type |
| `mx_nmos_sweep.sp` | ✅ | M, V(DC), .dc sweep |
| `mx/circuits` with resistors | ✅ | R + M + V |
| `mx/circuits` with capacitors | ✅ | C + M + V (TRAN ready) |
| OTA/OpAmp circuits | ⚠️ | Requires .subckt (✅), but multiple MOSFETs |
| Comparator (StrongARM) | ⚠️ | .subckt, TRAN, MOS caps |
| Ring oscillator | ⚠️ | TRAN + .subckt + multi-stage |
| Behavioral models | ❌ | E/F/G/H sources |
| PDK .lib files | ❌ | .lib 'section', Spectre syntax |

## Performance Characteristics

| Metric | float_spice | ngspice (retrofitted) |
|--------|:--:|:--:|
| **Instructions per BSIM4 eval** | ~500 (all FP32) | ~2,000 (FP32 storage, FP64 math) |
| **Matrix solve** | O(N³) dense | O(N^1.2) sparse (KLU) |
| **Memory per node** | N² × 4 bytes | ~20×N × 8 bytes (sparse) |
| **Code L1-I$ pressure** | ~12KB hot path | ~40KB hot path |
| **SIMD potential** | Full AVX-512 (128b×4 floats) | Limited (mixed prec) |

### float_spice is faster when:
- Fewer than ~50 nodes (dense matrix faster than sparse overhead)
- BSIM4-dominant circuits (FET op-amps)
- Cold-cache scenarios (compact code, better I$ hit rate)

### ngspice is faster when:
- More than ~200 nodes (sparse matrix scales better)
- Many passives (R/C dominate, not BSIM4)
- Circuits needing KLU (power grids, RC extraction)

## Build & Verify

```bash
# float_spice: single-file build
gcc -O2 -o float_spice float_spice.c -lm

# ngspice (retrofitted): autotools
bash scripts/build.sh

# Verify zero cvtss2sd (float_spice target: 0)
objdump -d float_spice | grep -c cvtss2sd

# Compare outputs
python3 scripts/compare_fp.py float_output.txt ngspice_reference.txt
```

## When to Use Which

### Use float_spice for:
- **Learning** SPICE internals — single-file, readable, ~1,675 lines
- **Embedded simulation** — minimal dependencies (libm only), tiny binary
- **Zero-double research** — verify FP32-only SPICE feasibility
- **Sizing inner loops** — fast BSIM4 evaluation for gradient-free optimisers
- **Education** — clean implementation of MNA + Newton + BSIM4

### Use ngspice (retrofitted) for:
- **Production circuit design** — verified against PDK reference
- **Full SPICE compatibility** — .subckt trees, .lib, E/F/G/H sources
- **Mixed-signal verification** — AC, noise, distortion analysis
- **PDK-based design** — vendor models with 400+ BSIM4 parameters
- **Benchmark baselines** — reference for float_spice accuracy comparison

### Use vanilla ngspice-46 for:
- **Golden reference** — full double precision, no modifications
- **Corner simulation** — FF/SS/FNSP/SNFP with proper temperature models
- **RF analysis** — S-parameters, harmonic balance
- **Anything not listed above**

## Migration Path

For circuits that currently run in ngspice but not float_spice:

```
1. Simplify to DC OP → remove TRAN/AC commands
2. Flatten subcircuits → expand .subckt manually
3. Replace E/F/G/H with equivalent R/M/V networks
4. Convert .lib to inline .model cards
5. Remove .meas, .alter, .ic, .nodeset
6. Simplify Vsrc to DC-only (or SIN/PULSE/PWL)
```

The test circuit `mx_nmos_dc.sp` is the canonical example of a float_spice-compatible netlist.

## Known Gaps (Roadmap P4.3-P4.8)

See [ROADMAP.md](../ROADMAP.md) for current status. Remaining Phase 4 tasks:

| # | Task | Status |
|---|------|:--:|
| P4.3 | Output format ngspice-compatible (compare_fp.py) | 🔴 |
| P4.4 | Batch test script (mx/ circuits) | 🔴 |
| P4.5 | Fix CI patch 001 (vanilla ngspice-46) | 🔴 |
| P4.6 | float_spice in CI + cvtss2sd check | 🔴 |
| P4.7 | ARCHITECTURE.md + BSIM4_MODEL.md + COMPARISON.md | 🟡 In progress |
| P4.8 | GitHub Release v3.0 | 🔴 |
