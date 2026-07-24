# float_spice Architecture

> v2.5 — Zero-double float-first SPICE engine. Every floating-point operation uses `float` (FP32).

## Overview

float_spice is a from-scratch SPICE engine built on three design principles:

1. **Zero `cvtss2sd`** — No float-to-double conversions in application code. `REAL` = `float` everywhere.
2. **MNA (Modified Nodal Analysis)** — Full nodal admittance matrix with branch current variables for floating voltage sources.
3. **BSIM4v5 physical model** — 51 parameters, 15+ physical effects, compatible with PTM/PDK model cards.

```
Source         Parser          Solver              Output
───────       ───────         ──────              ──────
netlist.sp → parse_netlist → dc_solve ────→ Node voltages
               │    │          │  │  │         Vsrc currents
               │    │          │  │  └── KCL back-computation
               │    │          │  └── Newton + Gmin + Source stepping
               │    │          └── MNA matrix assembly
               │    └── .subckt expansion + param substitution
               └── BSIM4 .model card parsing
```

## Component Hierarchy

```
main()
  ├── Circuit allocation (calloc → all zeros)
  ├── parse_netlist()                 # SPICE netlist → in-memory representation
  │    ├── parse_include()            # recursive .include
  │    ├── parse_model_line()         # .model cards → Model structs
  │    ├── parse_subckt()             # .subckt / .ends → Subckt structs
  │    ├── expand_subckt()            # X-line → inline expansion
  │    ├── parse_instance()           # R/M/V/I/C element lines
  │    ├── parse_option()             # .option gmin/abstol/reltol
  │    ├── parse_param() + param_subst()  # .param name=value + {name} substitution
  │    ├── parse_temp()               # .temp (Celsius → Kelvin)
  │    └── .control block parser      # op/dc/tran/print/plot
  ├── BSIM4 model resolution          # per-device NMOS/PMOS model pointer array
  ├── [tran_solve()]                  # if .tran
  │    └── dc_solve() per timestep
  ├── [DC sweep loops]                # if .dc
  │    └── dc_solve() per sweep point
  └── [DC OP]                         # if .op or default
       └── dc_solve()
            ├── Source-stepping outer loop (4 ramps)
            ├── Gmin-stepping middle loop (3 stages)
            ├── Cmin-stepping diagonal damping
            ├── Newton inner loop (up to max_iter)
            │    ├── Recovery cascade (5 levels)
            │    ├── MNA matrix assembly
            │    ├── LU factorisation + solve
            │    ├── Adaptive voltage limiting
            │    └── NaN firewall
            └── Post-convergence KCL: compute_nc()
```

## Core Data Structures

### Circuit (top-level container)

```c
typedef struct {
    int nn, nr, nm, nv, nc, ni, ngnd;     // counts
    char nmap[MAX_NODES][32];             // node name → index
    Resistor  *res;                        // [nr]
    Mosfet    *mos;                        // [nm]
    Vsource   *vsrc;                       // [nv]
    Capacitor *cap;                        // [nc]
    Isource   *isrc;                       // [ni]
    Model     models[MAX_MODELS];          // .model cards
    Subckt    subckts[MAX_SUBCKT];         // .subckt definitions
    // Control flags
    int  do_op, do_dc, do_tran, dc_nested;
    char dc_src[32], dc_src2[32];
    // Options (P3.2)
    REAL opt_gmin, opt_abstol, opt_reltol;
    int  opt_maxiter;
    REAL temp;                             // Kelvin
    // Control block (P3.1)
    int  in_control;
    struct { char what[4]; char name[32]; } prints[MAX_PRINTS];
    int  nprint;
    // TRAN state (P4.1)
    REAL  tran_dt;
    REAL *tran_v_prev, *tran_cap_i;
    REAL *tran_mos_v_prev, *tran_mos_cap_i;  // P4.2
} Circuit;
```

### BSIM4Param (51 parameters, all float)

```c
typedef struct {
    // Core (16): vth0,k1,k2,nfactor,eta0,u0,ua,ub,uc,vsat,toxe,
    //            mobmod,ud,eu,wint,lint,pclm,pdiblc1,a0
    // Short-channel Vth (7): dvt0,dvt1,dvt2,dsub,k3,w0,nlx
    // Rds (4): rdsw,rsw,rdw,prwg
    // Early voltage (4): pvag,pdiblc2,pscbe1,pscbe2
    // Subthreshold (5): voffcv,minv,cdsc,cdscd,cdscb
    // Temperature (6): kt1,kt2,ute,ua1,ub1,uc1
    // Capacitance (4): cgso,cgdo,cgbo,cj
    // Noise (2): noia,noib
    // Physical (3): xj,ndep,nsd
} BSIM4Param;
```

### BSIM4Out (evaluation result)

```c
typedef struct {
    REAL ids, gm, gds, gmbs, vth, vdsat, vdseff, vgsteff;
    REAL Abulk, ueff, EsatL, beta;
    REAL cgs, cgd, cgb;  // P4.2: intrinsic capacitances
} BSIM4Out;
```

### Vsource (with waveform types)

```c
typedef struct {
    char name[32]; int p, n; REAL dc;
    int  wf_type;        // WF_DC / WF_SIN / WF_PULSE / WF_PWL
    // SIN parameters: vo, va, freq, td_sin, theta
    // PULSE parameters: v1, v2, td_pulse, tr, tf, pw, per
    // PWL parameters: pwl_n, *pwl_t, *pwl_v
} Vsource;
```

## MNA Solver Pipeline

### 1. Source Stepping (Outer Loop)

```
Ramp 0: 0.1% → Ramp 1: 1% → Ramp 2: 10% → Ramp 3: 100%
```

- All Vsrc DC values scaled by ramp factor `α ∈ {1e-3, 1e-2, 1e-1, 1.0}`
- Grounded Vsrc fixed-node voltages re-initialised to scaled value
- Free node voltages **preserved** from previous ramp as initial guess
- Floating Vsrc MNA branch currents reset to 0 each ramp
- If any ramp fails → skip all remaining ramps → KCL fallback cleanup

### 2. Gmin + Cmin Stepping (Middle Loop)

```
Stage 0: gmin=1e-9,  cmin=1e-6  (easy convergence)
Stage 1: gmin=1e-10, cmin=1e-9  (intermediate)
Stage 2: gmin=1e-12, cmin=0.0   (accurate final)
```

- **Gmin**: Conductance from each free node to GND → diagonal dominance + DC bias
- **Cmin**: Diagonal-only damping → clean matrix conditioning, zero DC bias
- Each stage starts from previous stage's converged solution
- Both gmin and cmin values can be bumped 10× or 100× during recovery

### 3. Newton Inner Loop

```
for iter in 0..max_iter:
    for recovery in 0..5:            // Recovery cascade
        assemble MNA matrix            // R + M + Vsrc(MNA) + C + MOSCAP
        lu_solve(N, a, rhs, dx)       // dense LU with partial pivoting
        if success: break
        bump effective_gmin 10×       // recovery 0-2
        or bump 100× + tighten vlim   // recovery 3-4
    if all recovery failed:
        pseudo-transient fallback     // inject Cmin=1e-3 as pseudo-caps
        if still failed: stage back   // re-run previous gmin stage
    
    update v[0..n-1] += dx           // voltage update with adaptive limiting
    update iv[mna]  += dx[N-.. ]     // floating Vsrc branch currents
    
    if max_dv < abstol: converge → next stage
    if NaN detected: reset node → force recovery retry
```

### 4. Matrix Assembly (per Newton iteration)

The system matrix is `N × N` where `N = n + n_float`:
- Rows 0..n-1: KCL equations for node voltages
- Rows n..N-1: MNA constraint equations for floating Vsrc branch currents

```
Block structure:
┌─────────┬────┐
│ J_nl    │ B  │  Δv    =  -f_nl - B·I
│ (n×n)   │    │
├─────────┼────┤
│ B^T     │ 0  │  ΔI    =  E - (v[p] - v[n])
│ (nf×n)  │    │
└─────────┴────┘
```

**Assembly order** (each element stamps into `a[N*N]` and `rhs[N]`):

| Step | Elements | What's Stamped |
|------|----------|----------------|
| 1 | Gmin + Cmin | `a[j+j*N] += gmin+cmin`, `rhs[j] -= gmin*v[j]` (each free node) |
| 2 | Resistors | Conductance matrix (2×2 block: p,n × p,n) |
| 3 | Current sources | Constant current into RHS (zero Jacobian) |
| 4 | MOSFETs | gm/gds/gmbs transconductance matrix + ids RHS |
| 5 | MOSFET caps (TRAN) | Geq=2C/dt companion model (3 caps × 2 nodes) |
| 6 | MNA (floating Vsrcs) | ±1 in B and B^T blocks, `E-(v[p]-v[n])` in RHS |
| 7 | Capacitors (TRAN) | Geq companion model for discrete capacitors |
| 8 | Fixed-node clamping | Row j zeroed, `a[j+j*N]=1`, `rhs[j]=0` |

**Fixed-node handling** (grounded Vsrcs + GND):
- Only the **row** is zeroed — column entries are preserved for KCL consistency
- `dv[fixed] = 0` during solve (1 on diagonal → dx[j] = 0)
- Column entries `a[i+fixed*N]` remain → KCL at adjacent nodes is correct

### 5. Post-Convergence KCL

After convergence (or best-effort partial convergence):

```c
compute_nc(v, c, pp_arr, gfinal, nc);
// nc[node] = sum of currents INTO node from:
//   - Gmin: -gfinal * v[node]
//   - Resistors: I = (v[p]-v[n])/R
//   - MOSFETs: Ids (drain→source through channel)
//   - Current sources: Idc
//   - Capacitors (TRAN): Geq*(v[p]-v[n]) + Ieq
// Then: iv[j] = -nc[vsrc[j].p]  (SPICE sign convention)
```

**Sign convention**: SPICE defines positive Vsrc current as flowing from +terminal to -terminal through the source. `nc[p]` is the net current INTO node p from non-Vsrc elements. By KCL, the current leaving node p through the Vsrc is `-nc[p]`, which equals the current entering the Vsrc's positive terminal.

## BSIM4 Evaluation Pipeline

```
Vgs, Vds, Vbs, Weff, Leff
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Threshold Voltage (P1.2)        │
│    vth0 + body(γ·(√φs−Vbs−√φs))   │
│    − SCE(dvt0·exp(−dvt1·L/lt))    │
│    − DIBL(dsub·Vds·exp(−L/lto))   │
│    + NW((K3+K3b·Vbs)·toxe/Weff)   │
│    + LPE(k1·(√(1+nlx/L)−1))       │
├─────────────────────────────────────┤
│ 2. Vgsteff with subthreshold (P1.6)│
│    n_eff = nfactor + cdsc·Vds     │
│    Vgst = Vgs − Vth − voffcv      │
│    Vgst>0: direct linear           │
│    Vgst<0: n*Vt·ln(1+exp(Vgst/nVt))│
├─────────────────────────────────────┤
│ 3. Mobility degradation (P1.5)     │
│    ueff = u0 / (1 + Ua·Eeff       │
│              + Ub·Eeff²            │
│              + ud·Eeff^eu)         │
├─────────────────────────────────────┤
│ 4. Abulk, Vdsat, Vdseff            │
│    Abulk = Ab0 + a0·L/(L+2√xj·toxe)│
│    Vdsat = Vgsteff·EsatL/(Abulk·(…))│
│    Vdseff = smooth(Vds, Vdsat)     │
├─────────────────────────────────────┤
│ 5. Drain current + Early voltage   │
│    Ids0 = β·(Vgsteff−Abulk·Vdseff/2)·Vdseff/(1+Vdseff/EsatL) │
│    Vaeff = harmonic_sum(Vasat,     │
│             VACLM, VADIBL, VADITS, │
│             VASCBE)                │
│    Ids = Ids0·(1+Vds_diff/Vaeff)   │
├─────────────────────────────────────┤
│ 6. Rds: source/drain resistance    │
│    (P1.3) — degenerates gm/gds/Ids │
├─────────────────────────────────────┤
│ 7. Intrinsic capacitances (P4.2)   │
│    Cgs, Cgd, Cgb — Meyer model     │
├─────────────────────────────────────┤
│ 8. NaN firewall                    │
│    if IS_NAN(ids/gm/gds/gmbs):     │
│        return safe off-state       │
└─────────────────────────────────────┘
```

## LU Solver

- Dense matrix `N × N` (max 256 + floating Vsrcs)
- Partial pivoting: find max-magnitude pivot in column k
- Singularity check: `piv < 1e-30`
- Row swap with index tracking (`ipiv[]`)
- Forward elimination + back substitution
- Returns -1 on singular matrix → triggers recovery cascade

## TRAN Analysis Flow

```
tran_solve()
  ├── DC OP solve (tran_dt=0 → capacitors disabled)
  ├── Save initial capacitor currents
  ├── For each timestep:
  │    ├── Update Vsrc waveforms (time-varying SIN/PULSE/PWL)
  │    ├── Set tran_dt, tran_v_prev, tran_cap_i
  │    ├── dc_solve() → Newton with capacitor companions
  │    │    ├── Capacitor: Geq = 2C/dt, Ieq = -Geq·V_prev − I_prev
  │    │    └── MOSFET caps (P4.2): Cgs/Cgd/Cgb → 3×Geq + Ieq
  │    ├── Update cap_i history: Ieq_new = Geq·(V_new) + Ieq
  │    └── memcpy v_prev ← v
  └── Print time series
```

**Trapezoidal integration**: Uses the companion model `i = (2C/Δt)·Δv + I_history` which is exact for the trapezoidal rule.

## Memory Strategy

- **Zero-init via calloc**: All structs, arrays, and Circuit fields default to 0
- **Fixed-size pools**: `MAX_ELEMS=2048`, `MAX_NODES=256`, `MAX_SWEEP=10000`, `MAX_TRAN=5000`
- **Per-iteration allocations**: Matrix `a[N*N]`, RHS `rhs[N]`, solution `dx[N]` — calloc'd each Newton step (not reused to avoid stale data)
- **Solver-scoped**: `vfixed[n]`, `vs_mna[nv]`, `dc_orig[nv]` — each freed at dc_solve return
- **Per-sweep-point**: `v[nn]`, `iv[nv]` — calloc'd per DC sweep iteration

## Parser Architecture

The parser is a single-pass line reader with continuation line support (`+` prefix):

```
for each line:
    skip comments (*) and blank lines
    handle continuation lines (+ prefix → append to previous)
    param_subst() → expand {param_name}
    
    dispatch by prefix:
    .model    → parse_model_line()
    .include  → parse_include() [recursive]
    .subckt   → parse_subckt()
    .ends     → skip
    .op       → do_op=1
    .dc       → parse sweep parameters
    .tran     → parse timestep
    .option   → parse_option()
    .param    → parse_param()
    .temp     → parse_temp()
    .control  → in_control=1
    .endc     → in_control=0
    [in_control] → op/dc/tran/print/plot
    .end      → stop parsing
    X...      → expand_subckt() [inline expansion]
    M/R/V/I/C → parse_instance()
    .*        → skip unknown dot-commands
    else      → try parse_instance, else buffer as continuation
```

### Key Parser Features

| Feature | Implementation |
|---------|---------------|
| `.include` | Recursive: opens file, parses `.model` and nested `.include` |
| `.model` | Semicolon/space-delimited `key=value` pairs → `Model.p[]` |
| `.subckt` | Captures body lines, expands `X` calls inline with node substitution |
| `{param}` | `param_subst()` replaces `{name}` with value from `.param` |
| `parse_eng()` | `strtof(buf, &endptr)` + suffix check (k, m, u, n, p, f, meg, mil) |

## Build & Verification

```bash
gcc -O2 -o float_spice float_spice.c -lm
objdump -d float_spice | grep -c cvtss2sd  # target: 0
```

The `real_to_str()` helper (P0.7) avoids ALL `cvtss2sd` from printf-family calls. It decomposes a float into integer and fractional parts using only float + int arithmetic, then passes only integer format specifiers to `snprintf`.

## Design Decisions

1. **Dense LU not sparse**: 256 nodes max — dense 256×256 = 512KB fits in L2 cache. Sparse overhead not justified.
2. **No dynamic memory for elements**: Fixed-size pools simplify memory management and avoid fragmentation.
3. **Source stepping before gmin stepping**: Ramping sources from 0 prevents MOSFETs starting in deeply wrong bias regions.
4. **Separate NMOS/PMOS defaults**: `bsim4_default()` returns NMOS defaults; PMOS overrides `vth0=-0.62261, u0=0.015`.
5. **print requests as parsed strings**: `.control print v(d) i(vd)` stores `prints[k].what="v", .name="d"` — resolved at output time against solved voltages/currents.
