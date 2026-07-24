# Mixed_ngspice — Project Roadmap

## 🎯 Project Goal

Build a **zero-double float-first SPICE engine** — every floating-point operation uses `float` (FP32), zero `cvtss2sd` instructions in application code. Two complementary approaches:

| Approach | Dir | Status | cvtss2sd |
|----------|-----|:--:|:--:|
| **From-scratch** `float_spice` | `float_spice/` | v2.0 POC ✅ | **22** (printf only) |
| **Retrofitted** ngspice-46 | `patches/` + `scripts/build.sh` | v1.9 | 632 |

---

## 📋 Task Board

Each task is independent and can be worked on in parallel by different agents. Tasks are tagged by module.

### Module A: float_spice Core Engine

> **File**: `float_spice/float_spice.c` (~600 lines C, `REAL=float` throughout)

#### A1. Eliminate printf cvtss2sd (22 → 3)
- **Goal**: Replace all `(double)` casts in `printf()` calls with integer-based float formatting
- **Check**: `objdump -d float_spice | grep -c cvtss2sd` returns ≤ 5
- **Context**: The `fprint_real()` and `fprint_sci()` helpers already exist in the file (lines ~475-495) but are unused. Replace every `printf("...%f...", (double)float_val)` with `printf("..."); fprint_real(float_val); printf("...")` in the `main()` function. The POC v1 achieved 3 cvtss2sd with this approach.
- **Estimated**: 30 min

#### A2. Fix BSIM4 subthreshold current accuracy
- **Goal**: Subthreshold Ids within 2× of ngspice FP64 reference
- **Check**: `float_spice test/circuits/mx/mx_nmos_dc.sp` produces `i(vd)` ≈ `-1.48e-05` (currently `0`)
- **Root Cause**: Two issues — (a) voltage source currents are not computed after DC solve (always 0), (b) the `vgsteff_smooth()` transition at VGS≈VTH uses a simplified single-exp smoothing that underestimates subthreshold current by ~40×
- **Fix (a)**: After DC solve, compute `i[vsrc]` from KCL: `i[j] = -(gmin*v[p] + sum(device currents into p))`
- **Fix (b)**: The standalone test at `/tmp/test_bsim4.c` produces correct output. Compare with the inlined version to find the discrepancy. Likely cause: `pp->toxe` parsed as 0 from `.model` card, causing `coxe = INF` → `beta0 = INF` → wrong Ids. Add a guard: `if(pp->toxe < 1e-12) pp->toxe = 1.8e-9;`
- **Estimated**: 1h

#### A3. Add PMOS support
- **Goal**: PMOS transistors produce correct negative VTH and negative Ids
- **Check**: `float_spice test/circuits/mx/mx_pmos_dc.sp` converges
- **Context**: PMOS model parameters are already parsed from `.model pmos pmos`. In `bsim4_eval()`, when `model_type == "pmos"`: flip VGS→VSG, VDS→VSD, VTH→|VTH|, return negative Ids. Add a `int is_pmos` parameter to `bsim4_eval()`.
- **Estimated**: 1h

#### A4. Nested DC sweep
- **Goal**: Support `dc vd 0 1.1 0.01 vg 0 1.1 0.2` (nested sweep)
- **Check**: `float_spice test/circuits/mx/mx_nmos_sweep.sp` produces a 2D sweep table
- **Context**: The parser already extracts `dc_src`, `dc_start`, `dc_stop`, `dc_step` but only handles one source. Extend to two sources: outer loop over source2, inner loop over source1. Print in matrix format.
- **Estimated**: 1h

#### A5. TRAN transient analysis
- **Goal**: Capacitor charging/discharging works (trapezoidal integration)
- **Check**: A simple RC circuit netlist produces exponential charge curve
- **Context**: Capacitor companion model for trapezoidal: `I(n+1) = (2C/Δt)*V(n+1) - [(2C/Δt)*V(n) + I(n)]`. Add equivalent conductance `geq = 2C/dt` between cap nodes, and current source `ieq` to RHS. Include in the Newton system.
- **Estimated**: 2h

---

### Module B: CI & Build System

> **Files**: `.github/workflows/test.yml`, `scripts/build.sh`, `patches/*.patch`

#### B1. Fix patch 001 for vanilla ngspice-46
- **Goal**: `bash scripts/build.sh` succeeds on CI (currently fails: "Patch 001 failed to apply!")
- **Check**: CI run is green on the `build-and-test` job
- **Root Cause**: `patches/001-typedefs-spice-macros.patch` was generated against a locally modified `typedefs.h`, not the vanilla ngspice-46.tar.gz from SourceForge. The patch expects context lines that don't exist in the original.
- **Fix**: Download vanilla ngspice-46.tar.gz, extract, apply the intended changes to `src/include/ngspice/typedefs.h`, then `diff -u original modified > patches/001-typedefs-spice-macros.patch`. The change is: add `#include "ngspice/config.h"` and the `SPICE_REAL` typedef block after the header guard.
- **Estimated**: 1h

#### B2. Add float_spice to CI
- **Goal**: CI builds and verifies float_spice on every push
- **Check**: CI job includes `make -C float_spice && make verify -C float_spice`
- **Context**: Add a new CI step after the existing build steps:
  ```yaml
  - name: Build and verify float_spice
    run: |
      cd float_spice && make
      CVD=$(objdump -d float_spice | grep -c "cvtss2sd" || echo "0")
      echo "cvtss2sd count: $CVD"
      ./float_spice ../test/circuits/mx/mx_nmos_dc.sp
  ```
- **Estimated**: 20 min

---

### Module C: Release & Documentation

> **Files**: `README.md`, GitHub Releases

#### C1. Create GitHub Release v2.0
- **Goal**: Tagged release with build artifacts and Release Notes
- **Check**: `gh release view v2.0` shows the release
- **Steps**:
  1. Ensure all P0 tasks (A1, B1, B2) are complete
  2. Build final binary: `cd float_spice && make`
  3. Tag: `git tag -a v2.0 -m "v2.0: zero-double float-first SPICE engine"`
  4. Create release with binary attached
- **Release Notes template**: Include cvtss2sd count verification, DC accuracy vs ngspice, supported analyses, known limitations
- **Estimated**: 30 min

#### C2. Update README with float_spice section
- **Goal**: README.md documents the from-scratch approach alongside the retrofitted approach
- **Check**: First-time visitor can build and run float_spice in < 5 min
- **Estimated**: 20 min

---

### Module D: Validation & Comparison

> **Files**: `scripts/compare_fs.sh` (new)

#### D1. Automated float_spice vs ngspice comparison
- **Goal**: One command compares float_spice output against FP64 ngspice
- **Check**: `bash scripts/compare_fs.sh test/circuits/mx/mx_nmos_dc.sp` prints relative error
- **Context**: Run float_spice, parse node voltages from output. Run `build_fp64/src/ngspice -b`, parse voltages. Compute `|v_fs - v_fp64| / max(|v_fp64|, 1e-6)`. Exit code 0 if all < 1%.
- **Estimated**: 30 min

---

## 🔀 Parallel Execution Guide

These groups have NO dependencies and can be worked on simultaneously:

```
Agent 1: A1 (printf fix) ──────────────────────┐
Agent 2: A2 (BSIM4 accuracy) ───────────────────┤
Agent 3: B1 (patch 001) + B2 (CI float_spice) ──┼──→ C1 (Release)
Agent 4: A3 (PMOS) ─────────────────────────────┤
Agent 5: D1 (comparison script) ────────────────┘
```

After A1 + B1 + B2 are done → C1 (Release) can proceed.

---

## 🏁 Success Criteria for v2.0

```bash
# 1. Zero cvtss2sd in application code
objdump -d float_spice/float_spice | grep -c cvtss2sd  # → ≤ 5

# 2. DC solver converges
float_spice/float_spice test/circuits/mx/mx_nmos_dc.sp  # → 1 iteration

# 3. Voltages match ngspice FP64 within 1%
# float_spice: V(D)=1.100000  ngspice: v(d)=1.100000e+00  → 0% error

# 4. CI is green
# GitHub Actions: build-and-test → PASS

# 5. Release exists
gh release view v2.0
```
