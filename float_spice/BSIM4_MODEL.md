# BSIM4v5 Model Implementation in float_spice

> 74 parameters, 15+ physical effects. All FP32 arithmetic. Compatible with PTM 45nm/HP/LP and standard BSIM4 model cards.

## Parameter Catalog

### Core Parameters (15)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `vth0` | 0.62261 | V | Threshold voltage @ Vbs=0, long channel |
| `k1` | 0.4 | V^(1/2) | First-order body effect coefficient |
| `k2` | 0.0 | — | Second-order body effect coefficient |
| `nfactor` | 1.6 | — | Subthreshold swing ideality factor |
| `eta0` | 0.0125 | — | DIBL coefficient |
| `u0` | 0.049 | m²/V·s | Low-field mobility (NMOS) |
| `ua` | 6e-10 | m/V | Linear mobility degradation |
| `ub` | 1.2e-18 | m²/V² | Quadratic mobility degradation |
| `uc` | 0.0 | m/V² | Body-bias mobility degradation |
| `vsat` | 130000 | m/s | Saturation velocity |
| `toxe` | 1.8e-9 | m | Electrical gate oxide thickness |
| `mobmod` | 0 | — | Mobility model selector (0/1/2) |
| `ud` | 0.0 | m/V | Coulomb scattering coefficient |
| `eu` | 1.0 | — | Coulomb scattering exponent |
| `pclm` | 0.02 | — | Channel length modulation parameter |

### Short-Channel Vth (12)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `dvt0` | 2.2 | — | SCE coefficient (first) |
| `dvt1` | 0.53 | — | SCE coefficient (second) |
| `dvt2` | -0.032 | V⁻¹ | SCE body-bias dependence |
| `dvt0w` | 0.0 | m⁻¹ | SCE width-dependence (first) |
| `dvt1w` | 5.3e6 | m⁻¹ | SCE width-dependence (second) |
| `dvt2w` | -0.032 | V⁻¹ | SCE body-bias width-dependence |
| `dsub` | 0.56 | — | DIBL exponent coefficient |
| `k3` | 80.0 | — | Narrow-width coefficient |
| `k3b` | 0.0 | V⁻¹ | Narrow-width body-bias coefficient |
| `w0` | 2.5e-6 | m | Narrow-width characteristic width |
| `nlx` | 1.74e-7 | m | LPE (lateral pocket implant) length |
| `etab` | -0.07 | V⁻¹ | DIBL body-bias coefficient |

### Source/Drain Resistance (7)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `rdsw` | 0.0 | Ω·m | Per-side resistance × Weff |
| `rsw` | 0.0 | Ω·m | Source-side resistance |
| `rdw` | 0.0 | Ω·m | Drain-side resistance |
| `prwg` | 0.0 | V⁻¹ | Gate-bias dependence of Rds |
| `prwb` | 0.0 | V⁻¹ | Body-bias dependence of Rds |
| `prt` | 0.0 | K⁻¹ | Temperature coefficient of Rds |
| `wr` | 1.0 | — | Width exponent for Rds scaling |

### Early Voltage Stack (7)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `pvag` | 0.0 | — | Gate-bias dependent Early voltage |
| `pdiblc1` | 0.001 | — | DIBL effect on Rout (first) |
| `pdiblc2` | 0.001 | — | DIBL effect on Rout (second) |
| `pdiblcb` | 0.0 | V⁻¹ | DIBL body-bias effect on Rout |
| `drout` | 0.56 | — | DIBL Rout channel-length dependence |
| `pscbe1` | 4.24e8 | V/m | SCBE coefficient 1 |
| `pscbe2` | 1.0e-5 | m/V | SCBE coefficient 2 |

### Subthreshold (7)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `voff` | -0.08 | V | Offset voltage in subthreshold (shifts I-V) |
| `voffcv` | 0.0 | V | Offset voltage in Vgsteff (CV model) |
| `minv` | 0.0 | — | Moderate inversion parameter |
| `cdsc` | 2.4e-4 | V⁻¹ | Drain coupling to subthreshold slope |
| `cdscd` | 0.0 | V⁻² | Quadratic drain coupling |
| `cdscb` | 0.0 | V⁻¹ | Body-bias coupling to subthreshold slope |
| `cit` | 0.0 | F/m² | Interface trap capacitance |

### Saturation / Vdsat (5)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `a0` | 1.0 | — | Bulk charge coefficient |
| `a1` | 0.0 | V⁻¹ | First non-saturation factor |
| `a2` | 1.0 | — | Second non-saturation factor |
| `ags` | 0.0 | V⁻¹ | Gate-bias Abulk coefficient |
| `delta` | 0.01 | — | Vdseff smoothing transition width |

### Temperature (7)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `kt1` | -0.11 | V | Temperature coefficient of Vth |
| `kt1l` | 0.0 | V·m | Length-dependent Vth temperature coeff |
| `kt2` | 0.022 | — | Body-bias temperature coefficient |
| `ute` | -1.5 | — | Mobility temperature exponent |
| `ua1` | 4.31e-9 | m/V | Temperature coefficient of ua |
| `ub1` | -7.61e-18 | m²/V² | Temperature coefficient of ub |
| `uc1` | -5.6e-11 | m/V² | Temperature coefficient of uc |

### Geometry Offsets (4)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `wint` | 5e-9 | m | Width offset (Weff = W − 2·wint) |
| `lint` | 0.0 | m | Length offset (Leff = L − 2·lint) |
| `dwg` | 0.0 | m/V | Gate width offset coefficient |
| `dwb` | 0.0 | m/V | Substrate width offset coefficient |

### Capacitance & Junction (4)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `cgso` | 0.0 | F/m | Gate-source overlap capacitance per width |
| `cgdo` | 0.0 | F/m | Gate-drain overlap capacitance per width |
| `cgbo` | 0.0 | F/m | Gate-body overlap capacitance per length |
| `cj` | 5.0e-4 | F/m² | Junction bottom capacitance per area |

### Noise (2)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `noia` | 0.0 | — | Flicker noise parameter A |
| `noib` | 0.0 | — | Flicker noise parameter B |

### Physical / Process (4)

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `xj` | 1.5e-8 | m | Junction depth |
| `ndep` | 1.7e17 | cm⁻³ | Channel doping concentration |
| `nsd` | 1.0e20 | cm⁻³ | Source/drain doping concentration |
| `at` | 3.3e4 | m/s·K | Temperature coefficient of vsat |

## Physical Effects

### 1. Threshold Voltage (P1.2)

**Body effect** (classical):
```
sq     = √(φs − Vbs)       where Vbs ≤ 0, clamped
Vth_b  = vth0 + k1·(sq − √φs) − k2·Vbs
```

**SCE — Short-Channel Effect**:
The depletion region under the gate reduces the gate's control of the channel, lowering Vth in short devices.
```
Characteristic length:  lt = √(ε_si · Toxe · Xdep / ε_ox)
                        lto = √(ε_si · Toxe · Xdep0 / ε_ox)

SCE roll-off:           ΔVth = θ · (Vbi − φs)
                where   θ = DVT0 · exp(−DVT1 · Leff / lt)
```

Physical constants used:
| Symbol | Value | Unit |
|--------|-------|------|
| ε_si | 1.035×10⁻¹² | F/cm |
| ε_ox | 3.453×10⁻¹³ | F/cm |
| q | 1.602×10⁻¹⁹ | C |
| ni | 1.45×10¹⁰ | cm⁻³ |

Numerical behavior:
- Long channel (L=10µm): `L/lt` large → `exp(−dvt1·L/lt)` ≈ 0 → no SCE roll-off
- Short channel (L=45nm): `L/lt` small → ~0.3V roll-off (balanced against nlx)
- `Vbi` clamped to [0.5, 1.2]V for numerical safety

**DIBL — Drain-Induced Barrier Lowering**:
Vds lowers the source-channel barrier, further reducing Vth.
```
ΔVth_dibl = exp(−DSUB · Leff / lto) · eta0 · Vds
```
- Scales with Vds (larger effect at higher drain bias)
- Exponential decay with channel length (negligible for L > 0.5µm)

**Narrow-Width Effect**:
Narrow channels have higher Vth due to fringing fields and STI stress.
```
ΔVth_nw = (K3 + K3b·Vbs) · Toxe / (Weff + W0) · φs
              where K3b = k2/2
```
- Dominant when Weff < W0 (≈2.5µm)
- Body-bias dependent via K3b term

**LPE — Lateral Pocket Implant**:
Counter-dopes the channel near source/drain to suppress SCE, raising Vth.
```
ΔVth_nlx = k1 · (√(1 + nlx/Leff) − 1) · √φs
```
- Significant for Leff < 0.5µm
- Compensates SCE roll-off at minimum channel length

**Full Vth**:
```
Vth = Vth_body − ΔVth_sce − ΔVth_dibl + ΔVth_nw + ΔVth_nlx
```
Clamped to ≥ 0.02V for numerical safety.

### 2. Subthreshold Vgsteff (P1.6)

**Effective ideality factor** with drain/body coupling:
```
n_eff = nfactor + cdsc·Vds + cdscd·Vds² + cdscb·Vbs
```
Clamped to [1.0, 10.0].

**Gate overdrive** offset by voffcv:
```
Vgst = Vgs − Vth − voffcv
```
voffcv shifts the subthreshold I-V curve horizontally (corrects measured vs. modeled).

**Dual-branch Vgsteff**:
```
If Vgst > 0.1:                     Strong inversion — direct linear
    Vgsteff = Vgst

If Vgst ≤ 0.1:
    arg = Vgst / (n_eff · Vt)
    Vgsteff = n_eff · Vt · ln(1 + exp(arg))
```

Protection:
- `arg > 80`: exponential overflow → use `Vgsteff = Vgst` (strong inversion asymptote)
- `arg < −40`: exponential underflow → `Vgsteff = 0` (deep subthreshold, Ids ≈ 0)
- `Vgsteff < 0`: clamp to 0

### 3. Mobility Degradation (P1.5)

**Effective vertical field**:
```
Eeff = (Vgsteff + 2·Vth + Vth0) / (6·Toxe)
```

**mobMod=0** (default): Surface-roughness dominated
```
ueff = u0 / (1 + (Ua + Uc·Vbs)·Eeff + Ub·Eeff² + ud·Eeff^eu)
```

**mobMod=1**: Linear degradation only
```
ueff = u0 / (1 + (Ua + Uc·Vbs)·Eeff)
```

**mobMod=2**: Same formula as mobMod=0.

**Coulomb scattering** (`ud > 0`):
An additional term `ud·Eeff^eu` captures remote-charge impurity scattering. Active regardless of mobMod.

Clamped: `ueff ≥ 1e-4` for numerical safety.

### 4. Abulk — Bulk Charge Factor

```
Ab0   = 1 + k1 / (2·√φs)
Abulk = Ab0 + a0·Leff / (Leff + 2·√(xj·Toxe))
```
Clamped to ≥ 1.0.

### 5. Velocity Saturation

```
EsatL = 2 · vsat / ueff · Leff
Vdsat = Vgsteff · EsatL / (Abulk · (Vgsteff + EsatL))
Vdseff = smooth(Vds, Vdsat)     // smooth transition at Vdsat
```

`smooth_vdseff()`: Continuous derivative at Vds=Vdsat via:
```
δ = 0.01
x = Vdsat − Vds − δ
Vdseff = Vdsat − 0.5·(x + √(x² + 4δ·Vdsat))
```

### 6. Drain Current + Early Voltage Stack (P1.4)

**Intrinsic drain current** (no CLM):
```
Ids0 = β · (Vgsteff − Abulk·Vdseff/2) · Vdseff / (1 + Vdseff/EsatL)
     where β = ueff · Cox · Weff / Leff
```

**5-part Early voltage stack** (harmonic sum):
```
1/Vaeff = 1/Vasat + 1/VACLM + 1/VADIBL + 1/VADITS + 1/VASCBE
```

| Component | Mechanism | Key Parameter | Formula |
|-----------|-----------|---------------|---------|
| **Vasat** | Velocity saturation | — | `EsatL + Vdsat + 2·Vgsteff/Abulk` |
| **VACLM** | Channel length modulation | pclm | `Fp·litl/(pclm·Abulk·EsatL·Leff)` |
| **VADIBL** | DIBL effect on Rout | pdiblc2 | `(Vgsteff+2Vt)/θrout · (1−Abulk·Vdsat/(Abulk·Vdsat+Vgsteff+2Vt))` |
| **VADITS** | Drain-induced Vth shift | pdiblc1 | `1/pdiblc1` |
| **VASCBE** | Substrate current body effect | pscbe1,2 | `Leff·exp(pscbe1·litl/Vd_diff)/pscbe2` |

Characteristic lengths:
```
litl   = √(ε_si · Toxe · xj / ε_ox)     // CLM length
lt_est = √(ε_si · Toxe · Xdep / ε_ox)    // DIBL thermal length
```

Each component is individually clamped to ≥ 1e-6V; harmonics sum via `1/Σ(1/Vi)` with ≥ 1e-3V floor.

**Final Ids**:
```
Ids = Ids0 · (1 + Vd_diff / Vaeff)
     where Vd_diff = max(Vds − Vdseff, 0)
```

**Analytical gm/gds/gmbs**:
```
Linear region (Vds < Vdsat):
    gm  = β · Vds / (1 + Vds/EsatL)
    gds = β · (Vgsteff − Abulk·Vds) / (1 + Vds/EsatL)²

Saturation region (Vds ≥ Vdsat):
    gm  = β · Vdsat / (1 + Vdsat/EsatL) · (1 + Vd_diff/Vaeff)
    gds = Ids / Vaeff
```

Subthreshold override: `gm = Ids/(nfactor·Vt)` for `Vgsteff < 0.05V`.
Body transconductance: `gmbs = −gm · ∂Vth/∂Vbs`.

### 7. Source/Drain Resistance — Rds (P1.3)

When `rdsw > 0`:
```
Rs_per_side = RDSW / (Weff · (1 + PRWG·Vgsteff))
Rout = 2 · Rs_per_side         // source + drain
```

Three degenerations:
1. **Source degeneration**: `gm → gm/(1 + gm·Rs)`, `gmbs → gmbs/(1 + gm·Rs)`
2. **Drain feedback**: `gds → gds/(1 + gds·Rout)`
3. **Ids correction**: `Ids → Ids/(1 + Ids·Rout/Vdseff)`

Disabled when `rdsw = 0` (default).

### 8. Intrinsic Capacitances — P4.2 (Meyer Model)

```
Cox = ε_ox / Toxe · Weff · Leff
```

| Region | Condition | Cgs | Cgd | Cgb |
|--------|-----------|-----|-----|-----|
| Cutoff | Vgsteff ≤ 0 | 0 | 0 | Cox |
| Linear | Vgsteff > 0, Vds < Vdsat | Cox/2 | Cox/2 | 0 |
| Saturation | Vgsteff > 0, Vds ≥ Vdsat | 2Cox/3 | 0 | 0 |

Plus overlap/fringing:
```
Cgs += cgso · Weff
Cgd += cgdo · Weff
Cgb += cgbo · Leff
```

All clamped to ≥ 0.

## Numerical Safeguards

| Guard | Location | Rationale |
|-------|----------|-----------|
| `toxe < 1e-12` → `1.8e-9` | bsim4_eval entry | Prevents Cox = INF |
| `Vbi` clamped [0.5, 1.2]V | Vth calculation | Physical range for silicon |
| `xdep, lt, lto ≥ 1e-10` | Characteristic lengths | Prevents division by zero |
| `Vth ≥ 0.02V` | Vth output | Prevents negative/unphysical threshold |
| `ueff ≥ 1e-4` | Mobility | Prevents zero/negative mobility |
| `n_eff` clamped [1.0, 10.0] | Subthreshold | Bounds exponential argument |
| `arg` clamped for exp | Vgsteff | Prevents exp(80+) overflow, exp(-40-) underflow |
| `Vaeff ≥ 1e-3` | Early voltage | Prevents infinite Rout → zero gds |
| `gm/gds/gmbs ≥ 1e-15` | Output | Prevents zero transconductance |
| NaN firewall | End of bsim4_eval | Returns safe off-state (Ids=1e-15, g=0) |

## PMOS Convention

PMOS devices use SPICE sign conventions:
- `vth0 = −0.62261` (negative threshold for enhancement-mode PMOS)
- `u0 = 0.015` m²/V·s (hole mobility, ~3.3× lower than NMOS)
- All voltages (Vgs, Vds, Vbs) remain referenced to source as positive quantities
- Ids flows from source to drain (conventional current direction)

## Parameter Flow

```
.model nmos nmos vth0=0.5 k1=0.35 ...
           │
           ▼
parse_model_line()          → Model.type="nmos", Model.p[] = {vth0=0.5, k1=0.35, ...}
           │
           ▼
bsim4_from_model(&pp, &m)  → pp.vth0 = model_get(m, "vth0", default)
           │                   Starts from bsim4_default(), overwrites each
           │                   parameter found in the .model card.
           ▼
mos_pp[j] = &pp_nmos        → Per-device pointer (NMOS vs PMOS resolved
  or       = &pp_pmos          by model type matching)
```

Unspecified parameters retain their defaults from `bsim4_default()`, matching BSIM4v5 UG recommendations.
