# Mixed_ngspice — Honest Project Roadmap

> Last updated: 2026-07-24. Based on exhaustive gap analysis across 5 dimensions.

## 🎯 Project Goal

Build a **zero-double float-first SPICE engine** — every floating-point operation uses `float` (FP32). Two approaches:

| Approach | Dir | Status | cvtss2sd | Verdict |
|----------|-----|:--:|:--:|---------|
| **From-scratch** `float_spice` | `float_spice/` | v2.0 POC | **22** (printf) | Proof-of-concept. Solver converges only on voltage-source-only circuits. BSIM4 is a toy model. |
| **Retrofitted** ngspice-46 | `patches/` + `scripts/build.sh` | v1.9 | **632** (math) | Production-grade but can never reach 0 cvtss2sd. 130/155 circuits PASS. |

---

## 🔴 CRITICAL BUGS FOUND (July 24 Deep Analysis)

These were discovered during a line-by-line audit of float_spice.c against the reference BSIM4v5 implementation. They block ALL DC accuracy and must be fixed before any other work.

### B1. parse_eng() misinterprets parameter names as suffixes
- **File**: `float_spice/float_spice.c:197-218`
- **Bug**: `strtof(buf, NULL)` reads a float, then the function checks trailing characters against engineering suffixes (k, m, u, n, p, f, meg, mil). But BSIM4 parameter names like `paramchk`, `pclm`, `permod`, `fnoimod`, `noia`, `mobmod` START with characters that ARE valid suffixes. `parse_eng("1")` followed by `"paramchk=..."` → suffix 'p' matched → returns `1e-12` instead of `1`.
- **Impact**: Most BSIM4 parameters parsed from .model cards are silently corrupted. vth0, u0, toxe happen to work because their values don't have adjacent parameter names starting with suffix chars. But nfactor, pclm, vsat, and dozens of others may be silently wrong.
- **Fix**: Use `strtof(buf, &endptr)` and check `endptr` for the actual stop position.

### B2. PMOS devices evaluated with NMOS parameters
- **File**: `float_spice/float_spice.c:480`
- **Bug**: `BSIM4Param *pp = &pp_nmos;` — main() selects NMOS model pointer, passes it to dc_solve() and all output code. dc_solve() has no per-device model selection. PMOS transistors get NMOS vth0, u0, vsat.
- **Impact**: Any circuit with PMOS produces garbage. `mx_pmos_dc.sp` would show NMOS-like behavior.
- **Fix**: dc_solve() must accept per-device model pointers, or a model lookup based on device model name.

### B3. Voltage source current always zero
- **File**: `float_spice/float_spice.c:367`
- **Bug**: `iv[j] = 0.0` at initialization. Never written to after DC solve. No mechanism exists to compute Vsrc currents because the solver fixes node voltages directly (no MNA branch current variables).
- **Impact**: All source currents print as 0. KCL cannot be verified. Power cannot be computed.
- **Fix**: After DC solve, compute `iv[j] = -(sum of device currents into p) - gmin*v[p]` via KCL.

### B4. Matrix assembly: fixed-node column zeroing breaks KCL consistency
- **File**: `float_spice/float_spice.c:416-419`
- **Bug**: After assembling the full Jacobian, rows AND columns for fixed nodes are zeroed. But the RHS entries for neighboring free nodes include contributions from the fixed node's voltage (`g*(v[fixed] - v[free])`). Zeroing the column removes the Jacobian entry for `dv[fixed]` but the RHS still expects it. Newton step becomes inconsistent.
- **Fix**: During assembly, check `vfixed[node]` BEFORE stamping. Skip stamps for fixed nodes entirely (don't zero-after-the-fact).

### B5. All-nodes-fixed circuit converges trivially without computing anything
- **File**: `float_spice/float_spice.c:425-432`
- **Bug**: When all non-GND nodes are voltage-fixed, `max_dv` stays 0 (no free nodes to iterate). Function returns 1. MOSFET currents are computed during assembly but vsrc currents are never calculated.
- **Impact**: The NMOS test case "works" only because all nodes are voltage-driven. Add one resistor and it would fail.

### B6. Gmin hardcoded to 1e-10, never steps
- **File**: `float_spice/float_spice.c:376`
- **Bug**: `REAL gmin = R(1e-10)` — 100x larger than typical (1e-12). Never reduced. No gmin stepping cascade.
- **Impact**: DC solution is biased. Large gmin draws non-physical current from every node.

### B7. No convergence recovery cascade
- **File**: `float_spice/float_spice.c:421`
- **Bug**: If `lu_solve()` returns -1 (singular matrix), function bails immediately. No gmin stepping, no source stepping, no pseudo-transient fallback.
- **Impact**: Any circuit with even mild convergence difficulty immediately fails.

### B8. Floating voltage source (neither terminal at GND) assigns meaningless voltage
- **File**: `float_spice/float_spice.c:370-371`
- **Bug**: `v[p] = dc*0.5; vfixed[n] = 1` — no constraint `v[p]-v[n]=Vdc` is enforced. The negative terminal is marked fixed but never assigned a value.
- **Impact**: Any circuit with a Vsource between two non-GND nodes is completely broken.

### B9. BSIM4 toxe=0 guard missing → coxe=INF → NaN
- **File**: `float_spice/float_spice.c:107`
- **Bug**: `coxe = 3.9*eps0/(pp->toxe + 1e-30)` — if model card parsing fails and toxe stays 0, coxe becomes INF (~3.4e38). All subsequent beta/Ids/gm/gds are INF or NaN.
- **Fix**: Add `if(pp->toxe < 1e-12) pp->toxe = 1.8e-9f;`

### B10. No NaN detection anywhere
- **File**: entire file
- **Bug**: After one divergent Newton step producing NaN, all subsequent steps continue with NaN. No firewall, no reset, no fallback.
- **Impact**: Silent NaN propagation. Impossible to debug without adding print statements.

---

## 📊 BSIM4 Model Gap: 16/400+ Parameters, 5/30+ Physical Effects

| What We Have | What's Missing |
|-------------|----------------|
| Vth0 + body + linear DIBL | Short-channel Vth roll-off (dvt0/1/2), narrow-width (k3/w0), pocket implant, LPE |
| Simple Eeff mobility (mobMod=0) | mobMod=1/2, Coulomb scattering (ud), eu exponent, L-dependent mobility |
| Linear CLM (1/pclm) | 5-part Early voltage stack: Vasat+VACLM+VADIBL+VASCBE+VADITS |
| Single-exp subthreshold | mstar dual-branch smoothing, voffcv, minv, cdsc/d |
| Vdsat = Vgst*EsatL/(Abulk*(...)) | Lambda (a1/a2), Rds feedback, Vgst2Vtm thermal term |
| No Rds | rdsw, rsw, rdw, prwg, prwb — Ids overestimated at high VGS |
| No SCBE | pscbe1/2 — missing output conductance kink at high VDS |
| No temperature | kt1/kt2/ute/ua1/ub1/uc1 — fixed 300K |
| No capacitance | cgso/cgdo/cgbo/cj — TRAN cannot work |
| No gate tunneling | aigc/bigc/cigc/nigc — essential for tox<2nm |
| No GIDL | agidl/bgidl — drain leakage at high VDG |
| No noise | noia/noib/kf/af — noise analysis impossible |
| No junction diodes | jss/jsws/cjs/mjs — body leakage missing |
| Hardcoded phis=0.6, xj=1.4e-8 | Should compute from ndep/nsd/NSUB |

**Bottom line**: The current BSIM4 is a Level-1 model with a few Level-54 parameter names. It captures basic MOSFET behavior but will differ from ngspice by 10-100x in subthreshold and 2-5x in strong inversion saturation.

---

## 📋 Parser Gap: 20+ Missing SPICE Features

| Feature | Status | Blocks N Circuits |
|---------|:------|:--:|
| `.subckt` / `.ends` / `X` calls | ❌ | 95% of 121 circuits |
| `.control` block parsing | ❌ (silently skipped) | 90% of circuits |
| `.option gmin/reltol/...` | ❌ (silently skipped) | Most circuits |
| `.param` / `{}` evaluation | ❌ | OTA/opamp bias circuits |
| `.temp` | ❌ | Temperature-dependent sims |
| `.ic` / `.nodeset` | ❌ | TRAN startup |
| `.lib 'file' section` | ❌ | SKY130 PDK circuits |
| Current sources (`Ixxx`) | ❌ | OTA bias circuits |
| PULSE/SIN/PWL Vsrc waveforms | ❌ | All TRAN circuits |
| Controlled sources (E/F/G/H) | ❌ | Behavioral models |
| Spectre syntax (`simulator lang=spectre`) | ❌ | MG dataset (24 circuits) |
| Nested DC sweep | ❌ | MOSFET family curves |
| `$` inline comments | ❌ | PDK .lib files |
| `.meas` statements | ❌ | Performance extraction |
| Resistor/Capacitor engineering suffixes | ❌ (sscanf %f only) | `5k` → `5.0` |

**Bottom line**: float_spice can currently parse ~2-3 of 121 test circuits (mx_nmos_dc.sp, mx_pmos_dc.sp, mx_nmos_sweep.sp). 95%+ of circuits use features we don't support.

---

## 📋 Solver Gap: Missing Convergence Infrastructure

| Feature | Status |
|---------|:------|
| Gmin stepping (1e-2 → 1e-12) | ❌ Hardcoded 1e-10 |
| Source stepping (ramp from 0) | ❌ |
| Solution limiting (per-node) | ❌ ±1.0V hard clamp |
| Cmin stepping (diagonal damping) | ❌ |
| Pseudo-transient fallback | ❌ |
| RELTOL/ABSTOL/VNTOL convergence | ❌ ABSTOL only |
| Pivot tolerance (>1e-30) | ❌ |
| .option parsing for all above | ❌ |

---

## 🔀 Remaining Work (Revised)

### Phase 0: Fix Critical Bugs (blocks everything)

| # | Bug | File | Est. |
|---|-----|------|:--:|
| P0.1 | Fix parse_eng() suffix bug | float_spice.c | 30min |
| P0.2 | Add toxe=0 guard + NaN firewall | float_spice.c | 30min |
| P0.3 | Fix matrix assembly (skip fixed nodes, don't zero) | float_spice.c | 1.5h |
| P0.4 | Compute vsrc currents after DC solve | float_spice.c | 1h |
| P0.5 | Per-device model selection (NMOS/PMOS) | float_spice.c | 1h |
| P0.6 | Gmin stepping (3 stages) | float_spice.c | 1.5h |
| P0.7 | Replace printf (double) casts → fprint_real | float_spice.c | 1h |
| **P0 Subtot** | | | **~7h** |

### Phase 1: Make BSIM4 Physically Correct

| # | Task | Est. |
|---|------|:--:|
| P1.1 | Expand BSIM4Param from 16→40 fields | 2h |
| P1.2 | Implement full Vth (dvt0/1/2, dsub, k3, w0) | 2h |
| P1.3 | Implement Rds (rdsw/rsw/rdw/prwg) | 1.5h |
| P1.4 | Implement full Early voltage stack (VACLM+VADIBL) | 3h |
| P1.5 | Implement mobMod=0/1/2 + Coulomb scattering | 2h |
| P1.6 | Implement proper subthreshold (mstar, voffcv, minv) | 2h |
| **P1 Subtot** | | **~12.5h** |

### Phase 2: Solver Robustness

| # | Task | Est. |
|---|------|:--:|
| P2.1 | Source stepping (4 ramp stages) | 2h |
| P2.2 | Adaptive voltage limiting | 1.5h |
| P2.3 | Cmin stepping + pseudo-transient fallback | 3h |
| P2.4 | Floating Vsrc support (branch variable) | 2h |
| P2.5 | Current source support | 1h |
| **P2 Subtot** | | **~9.5h** |

### Phase 3: SPICE Compatibility

| # | Task | Est. |
|---|------|:--:|
| P3.1 | .control block interpreter (op/dc/tran/print) | 2h |
| P3.2 | .option + .param + .temp parsing | 2h |
| P3.3 | .subckt framework + X instantiation | 4h |
| P3.4 | Vsrc waveforms (SIN/PULSE/PWL) | 2h |
| P3.5 | Nested DC sweep + engineering suffixes in R/C | 2h |
| P3.6 | Resistor/Capacitor values via parse_eng | 1h |
| **P3 Subtot** | | **~13h** |

### Phase 4: TRAN + Verification + Docs

| # | Task | Est. |
|---|------|:--:|
| P4.1 | Trapezoidal integration + capacitor companion | 2h |
| P4.2 | BSIM4 Cgs/Cgd/Cgb for TRAN | 2h |
| P4.3 | Output format ngspice-compatible (compare_fp.py) | 2h |
| P4.4 | Batch test script (mx/ circuits) | 1.5h |
| P4.5 | Fix CI patch 001 (vanilla ngspice-46) | 1.5h |
| P4.6 | float_spice in CI + cvtss2sd check | 1h |
| P4.7 | ARCHITECTURE.md + BSIM4_MODEL.md + COMPARISON.md | 3h |
| P4.8 | GitHub Release v3.0 | 30min |
| **P4 Subtot** | | **~13.5h** |

---

## 📊 Grand Total

| Phase | Description | Est. |
|-------|-------------|:--:|
| P0 | Fix critical bugs | 7h |
| P1 | BSIM4 physical model | 12.5h |
| P2 | Solver robustness | 9.5h |
| P3 | SPICE compatibility | 13h |
| P4 | TRAN + verification + docs + release | 13.5h |
| **Total** | | **~55.5h** |

---

## 🏁 Success Criteria for v3.0

```bash
# 1. Zero cvtss2sd
objdump -d float_spice/float_spice | grep -c cvtss2sd  # ≤ 5

# 2. DC solver converges on NMOS + PMOS
./float_spice test/circuits/mx/mx_nmos_dc.sp  # V(D)=1.100, i(VD)≈-1.48e-5
./float_spice test/circuits/mx/mx_pmos_dc.sp  # correct PMOS behavior

# 3. Resistor-loaded circuit works
# (create a simple NMOS + RD circuit, verify Ids vs ngspice)

# 4. DC sweep works
./float_spice test/circuits/mx/mx_nmos_sweep.sp  # produces Id-Vd curve

# 5. CI is green
# GitHub Actions: build-and-test → PASS, float_spice verify → PASS

# 6. Release exists
gh release view v3.0
```
