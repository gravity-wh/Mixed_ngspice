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

### B1. ✅ CLAIMED & FIXED — parse_eng() misinterprets parameter names as suffixes
- **File**: `float_spice/float_spice.c:197-215`
- **Bug**: `strtof(buf, NULL)` reads a float, then the function checks trailing characters against engineering suffixes (k, m, u, n, p, f, meg, mil). But BSIM4 parameter names like `paramchk`, `pclm`, `permod`, `fnoimod`, `noia`, `mobmod` START with characters that ARE valid suffixes. `parse_eng("1")` followed by `"paramchk=..."` → suffix 'p' matched → returns `1e-12` instead of `1`.
- **Impact**: Most BSIM4 parameters parsed from .model cards are silently corrupted. vth0, u0, toxe happen to work because their values don't have adjacent parameter names starting with suffix chars. But nfactor, pclm, vsat, and dozens of others may be silently wrong.
- **Fix**: Use `strtof(buf, &endptr)` and check `endptr` for the actual stop position. Removed independent `ne` computation loop — now relies solely on `strtof`'s `endptr` to locate where the numeric portion ends.

### B2. ✅ CLAIMED & FIXED — PMOS devices evaluated with NMOS parameters
- **File**: `float_spice/float_spice.c:644-669`
- **Bug**: `BSIM4Param *pp = &pp_nmos;` — main() selects NMOS model pointer, passes it to dc_solve() and all output code. dc_solve() has no per-device model selection. PMOS transistors get NMOS vth0, u0, vsat.
- **Impact**: Any circuit with PMOS produces garbage. `mx_pmos_dc.sp` would show NMOS-like behavior.
- **Fix**: Two-part fix:
  1. **Per-device model lookup** (L660-669): `mos_pp[j]` assigns `&pp_pmos` or `&pp_nmos` based on `find_model()` + type check. `dc_solve()` already accepts `BSIM4Param *const *pp_arr` and dereferences `pp_arr[j]` per device.
  2. **PMOS defaults** (L644-647): `pp_pmos` starts from `bsim4_default()` but overrides `vth0=-0.62261` (negative threshold) and `u0=0.015` (hole mobility). If a PMOS `.model` card exists, `bsim4_from_model()` overwrites these defaults with card values.
- **Claimed by**: agent1 @ 2026-07-24

### B3. ✅ CLAIMED & FIXED — Voltage source current always zero
- **File**: `float_spice/float_spice.c`
- **Bug**: `iv[j] = 0.0` at initialization. Never written to after DC solve. No mechanism exists to compute Vsrc currents because the solver fixes node voltages directly (no MNA branch current variables).
- **Impact**: All source currents print as 0. KCL cannot be verified. Power cannot be computed.
- **Fix**: After DC solve (or best-effort partial convergence), compute Vsrc currents via KCL at the positive node. Three KCL blocks added — one in the success path and two in the early-return paths. All use consistent "current INTO node" convention: `nc[node] = sum of currents INTO node from non-Vsrc elements`, then `iv[j] = -nc[Vsrc+.p]` (SPICE convention: positive = current from + to - through source).

### B4. ✅ FIXED — Matrix assembly: fixed-node column zeroing breaks KCL consistency
- **File**: `float_spice/float_spice.c`
- **Fixed by**: agent4 @ 2026-07-24
- **Bug**: After assembling Jacobian, rows AND columns for fixed nodes were zeroed. MOSFET off-diagonal stamps `a[d+s*n]` and `a[s+d*n]` were emitted even when target column was a fixed node, then wiped by post-processing. Column zeroing destroyed KCL structure needed for vsrc current computation.
- **Fix** (2 changes):
  1. **MOSFET guard**: Wrapped `a[m->d+m->s*n]` with `if(!vfixed[m->s])` and vice versa — no more stamping into fixed columns.
  2. **Row-only zeroing**: Post-processing now zeroes ONLY the row (`a[j+i*n]=0`) and preserves column entries (`a[i+j*n]`). Since dv[fixed]=0 after solve, column entries are inert for Newton but essential for KCL current computation.

### B5. ✅ CLAIMED & FIXED — All-nodes-fixed circuit converges trivially without computing anything
- **File**: `float_spice/float_spice.c:425-432`
- **Bug**: When all non-GND nodes are voltage-fixed, `max_dv` stays 0 (no free nodes to iterate). Function returns 1. MOSFET currents are computed during assembly but vsrc currents are never calculated.
- **Impact**: The NMOS test case "works" only because all nodes are voltage-driven. Add one resistor and it would fail.
- **Fix**: Added post-convergence KCL pass at end of `dc_solve()`. Computes all device currents at converged node voltages, then back-calculates vsrc currents via `iv[j] = -nc[p]` (SPICE convention: current n+→n- through source). Uses "current leaving the node" convention consistent with matrix assembly. Also fixed sign conventions in the two early-return KCL blocks (failure path and non-convergence path).

### B6. ✅ CLAIMED & FIXED — Gmin hardcoded to 1e-10, never steps
- **File**: `float_spice/float_spice.c:352-435`
- **Bug**: `REAL gmin = R(1e-10)` — hardcoded inside the Newton loop, 100x larger than typical (1e-12). Never reduced. No gmin stepping cascade.
- **Impact**: DC solution is biased. Large gmin draws non-physical current from every node.
- **Fix**: Added 3-stage gmin stepping outer loop (1e-9 → 1e-10 → 1e-12). Each stage starts from the previous stage's converged solution, providing a progressively more accurate DC operating point. If any stage fails to converge, the solver returns immediately with the total iteration count.

### B7. ✅ CLAIMED & FIXED — No convergence recovery cascade
- **File**: `float_spice/float_spice.c:352-495`
- **Bug**: If `lu_solve()` returns -1 (singular matrix), function bails immediately. No gmin stepping, no source stepping, no pseudo-transient fallback.
- **Impact**: Any circuit with even mild convergence difficulty immediately fails.
- **Fix**: Added 5-level recovery cascade within each gmin stage. Recovery 0–2: bump effective gmin 10× per attempt (adds diagonal dominance to cure singular Jacobian). Recovery 3–4: 100× gmin + 0.1× voltage step clamping. If a stage exhausts all recovery, falls back to re-running the previous (larger gmin) stage. Only the first stage failing with full recovery is a hard bail.

### B8. ✅ FIXED — Floating voltage source (neither terminal at GND) assigns meaningless voltage
- **File**: `float_spice/float_spice.c:378-388`
- **Bug**: Originally `v[p] = dc*0.5; vfixed[n] = 1` — no constraint enforced, negative terminal never assigned.
- **Impact**: Any circuit with a Vsource between two non-GND nodes was completely broken.
- **Fix** (agent4 @ 2026-07-24, MNA upgrade by agent2 @ 2026-07-24): Full MNA branch current variables. Grounded Vsrcs use simple node fixing. Floating Vsrcs get a branch current variable — matrix expands from n×n to N×N (N=n+n_float). Newton system: `[J_nl B; B^T 0] [Δv; ΔI] = [-f-BI; E-(v[p]-v[n])]`. Branch currents solved directly. Extracted `compute_nc()` helper for grounded-Vsrc KCL.

### B9. ✅ ALREADY FIXED — BSIM4 toxe=0 guard missing → coxe=INF → NaN
- **File**: `float_spice/float_spice.c:108-112`
- **Status**: Already implemented. `bsim4_eval()` now uses `toxe_safe` with guard `if(toxe_safe < 1e-12) toxe_safe = 1.8e-9;` before computing `coxe`. Safe default 1.8nm prevents INF/NaN cascade when model parsing fails.

### B10. ✅ CLAIMED & FIXED — No NaN detection anywhere
- **File**: `float_spice/float_spice.c` (3 locations)
- **Bug**: After one divergent Newton step producing NaN, all subsequent steps continue with NaN. No firewall, no reset, no fallback.
- **Impact**: Silent NaN propagation. Impossible to debug without adding print statements.
- **Fix**: Three-layer NaN firewall:
  1. **`IS_NAN(x)` macro** — IEEE 754 portable `(x)!=(x)` check
  2. **`bsim4_eval` output guard** — if ids/gm/gds/gmbs are NaN, return safe off-state (1e-15, 0)
  3. **`dc_solve` voltage update** — if `v_new` is NaN, reset node to 0, set `had_nan` flag that forces retry via recovery cascade instead of false convergence
  4. **Post-convergence KCL** — NaN check on computed vsrc currents, default to 0

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
| PULSE/SIN/PWL Vsrc waveforms | ✅ Parsing + evaluator (agent4) | All TRAN circuits |
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
| Gmin stepping (1e-2 → 1e-12) | ✅ 3-stage (1e-9/1e-10/1e-12) |
| Source stepping (ramp from 0) | ✅ 4-stage (1e-3→1e-2→1e-1→1.0) agent4 |
| Solution limiting (per-node) | ✅ Adaptive [0.01..5.0]V agent4 |
| Cmin stepping (diagonal damping) | ✅ 3-stage (1e-6/1e-9/0) agent4 |
| Pseudo-transient fallback | ✅ Cmin=1e-3 last-resort inject agent4 |
| RELTOL/ABSTOL/VNTOL convergence | ❌ ABSTOL only |
| Pivot tolerance (>1e-30) | ❌ |
| .option parsing for all above | ❌ |

---

## 🔀 Remaining Work (Revised)

### Phase 0: Fix Critical Bugs (blocks everything)

| # | Bug | File | Est. |
|---|-----|------|:--:|
| P0.1 | ✅ Fix parse_eng() suffix bug | float_spice.c | 30min |
| P0.2 | ✅ toxe=0 guard + NaN firewall (B9+B10) | float_spice.c | 30min |
| P0.3 | ✅ Fix matrix assembly (B4: skip fixed nodes) | float_spice.c | 1.5h |
| P0.4 | ✅ Compute vsrc currents after DC solve (B3) | float_spice.c | 1h |
| P0.5 | ✅ Per-device model selection NMOS/PMOS (B2) | float_spice.c | 1h |
| P0.6 | ✅ Gmin stepping (3 stages) (B6) | float_spice.c | 1.5h |
| P0.7 | ✅ Replace printf (double) casts → real_to_str (agent3) | float_spice.c | 1h |
| **P0 Subtot** | | | **~7h** |

### Phase 1: Make BSIM4 Physically Correct

| # | Task | Est. |
|---|------|:--:|
| P1.1 | ✅ Expand BSIM4Param from 16→51 fields (agent5 @ 2026-07-24) | 2h |
| P1.2 | ✅ Full Vth: SCE(dvt0/1)+DIBL(dsub)+NW(k3,w0)+LPE(nlx) (agent3 @ 2026-07-24) | 2h |
| P1.3 | ✅ Implement Rds: rdsw/prwg — source/drain resistance (agent1 @ 2026-07-24) | 1.5h |
| P1.4 | ✅ Implement 5-part Early voltage stack: Vasat+VACLM+VADIBL+VADITS+VASCBE (agent5 @ 2026-07-24) | 3h |
| P1.5 | ✅ mobMod=0/1/2 + EU exponent (agent1 @ 2026-07-24) | 2h |
| P1.6 | ✅ Subthreshold: voffcv + cdsc/d/b n_eff + dual-branch Vgsteff (agent3 @ 2026-07-24) | 2h |
| **P1 Subtot** | | **~12.5h** |

### Phase 2: Solver Robustness

| # | Task | Est. |
|---|------|:--:|
| P2.1 | ✅ Source stepping (4 ramp stages) (agent4 @ 2026-07-24) | 2h |
| P2.2 | ✅ Adaptive voltage limiting (agent4 @ 2026-07-24) | 1.5h |
| P2.3 | ✅ Cmin stepping + pseudo-transient fallback (agent4 @ 2026-07-24) | 3h |
| P2.4 | ✅ Floating Vsrc MNA branch variables (B8 fix, agent2 @ 2026-07-24) | 2h |
| P2.5 | ✅ Current source support (agent2 @ 2026-07-24) | 1h |
| **P2 Subtot** | | **~9.5h** |

### Phase 3: SPICE Compatibility

| # | Task | Est. |
|---|------|:--:|
| P3.1 | ✅ .control block: op/dc/tran + print v()/i() (agent3 @ 2026-07-24) | 2h |
| P3.2 | ✅ .option + .param + .temp parsing (agent1 @ 2026-07-24) | 2h |
| P3.3 | ✅ .subckt framework + X instantiation (agent1 @ 2026-07-24) | 4h |
| P3.4 | ✅ Vsrc waveforms (SIN/PULSE/PWL) (agent4 @ 2026-07-24) | 2h |
| P3.5 | ✅ Nested DC sweep (agent2 @ 2026-07-24) | 2h |
| P3.6 | ✅ R/C/V/I values via parse_eng (agent2 @ 2026-07-24) | 1h |
| **P3 Subtot** | | **~13h** |

### Phase 4: TRAN + Verification + Docs

| # | Task | Est. |
|---|------|:--:|
| P4.1 | ✅ Trapezoidal integration + capacitor companion model (agent5 @ 2026-07-24) | 2h |
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
