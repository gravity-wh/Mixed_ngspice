# Changelog

## v0.1.0 (2026-07-16)

### Added
- SPICE_REAL type system with 18 SPICE_* math macros (typedefs.h)
- 1337 struct member fields: double → SPICE_REAL (bsim4v5def.h)
- Hot-path B4V5_FP32_MATH guard with expf/logf/sqrtf overrides (b4v5ld.c)
- NaN firewall: 40+ CHECK_NAN guards + matrix stamp zeroing
- Double-precision islands: Vbseff (sqrt cancellation), Leff/Weff (size binning)
- Explicit float geometry calculations (b4v5geo.c)
- Selective exp→expf, log→logf, sqrt→sqrtf in hot path (b4v5ld.c)
- Phis/sqrtPhis/Xdep double-precision protection block
- Vgsteff explicit float calculation with NaN/Inf guards
- DEXP macro upgraded to expf for FP32 mode
- All device support functions: double → SPICE_REAL (devsup.c)
- Auxiliary analysis files: SPICE_* guard blocks (b4v5noi/pzld/acld.c)
- sparse matrix config: include typedefs.h (spconfig.h)

### Verified
- TT corner: single PMOS, single NMOS, 6T bias, 22T op-amp
- DC accuracy < 0.003%, transient 1.7-2.8× speedup
- No NaN or divergence in TT corner

### Known Issues
- Non-TT corners (FF/SS/FNSP/SNFP): convergence failures (Vth shift → deep subthreshold → expf underflow)
- DEVpnjlim arg>2.0 fix not yet applied to FP32 build
- AC/noise analysis not validated
- KLU solver disabled

## v0.1.1 (2026-07-17)

### Fixed
- **Critical: vbi overflow in PTM 45nm models** (b4v5temp.c)
  - `nsd * ndep = 2e20 * 3.24e18 = 6.48e38 > FLT_MAX(3.4e38)` overflowed to inf
  - Added `(double)` casts to prevent FP32 overflow in log argument
  - Root cause of all PTM 45nm single-transistor NaN failures
- `CHECK_NAN(Vth)` added to prevent NaN propagation through Vth→Vgsteff→ueff chain

### Known Issues
- Multi-transistor circuits (OTA, opamp) with PTM 45nm still have NaN convergence issues
- Non-TT corners (FF/SS/FNSP/SNFP) not yet verified

## v1.0 (2026-07-20) — Baseline

### Added
- Patch 014: Cmin stepping + per-node Solution Limiting (sollim) for DC convergence
- Patch 015: FP64 noise island — fixes 1/f flicker noise NaN
- Full 11-circuit verification suite (DC: 6, TRAN: 5)
- Universal convergence recipe: VDD series 1Ω + gate/clock 100Ω + gmin=1e-10 sollim
- Ring oscillator fix: alternating IC + startup NMOS + UIC (no cshunt/reltol hacks)

### Verified
- 11/11 circuits PASS (NMOS, PMOS, OTA, OpAmp, StrongARM, LDO DC + Bootstrap, StrongARM, OTA-CL, OpAmp-CL, RingOsc TRAN)
- 6 FP64 precision islands audited: 136 double ops across 3 files, all intentional
- DC accuracy <1%, TRAN convergence with minimal options
- Ngspice official ring oscillator examples also verified

### Known Issues
- StrongARM comparator TRAN requires subcircuit body-node workaround
- SKY130 PNP BJT temperature sweep TTS at −40°C
- bc018 PMOS requires gmin≥1e-9 for convergence

## v1.1 (2026-07-20) — Pure FP32 Numerical Methods

### Changed
- **Vbi overflow FP64 island → log-split identity** (b4v5temp.c)
  - `log(nsd*ndep/ni²)` → `logf(nsd)+logf(ndep)−2*logf(ni)` — mathematical identity, zero precision loss
- **Vbseff cancellation FP64 island → difference-of-squares** (b4v5ld.c, 2 blocks)
  - `sqrt(T₀²−C)` → `sqrt((T₀−√C)·(T₀+√C))` — avoids near-zero subtraction
- **Vth k1ox cancellation FP64 island → Dekker exact subtraction** (b4v5ld.c)
  - 6 FP32 ops recover lost mantissa bits from subtraction of ~100x magnitude difference

### Result
- FP64 islands: 6 → 3 (hot path: 3 → 1)
- b4v5ld.c double: 65 → 55; b4v5temp.c double: 32 → 30
- Remaining islands (all non-critical): Abulk (deep nesting, setup-only), Leff/Weff (pow chain, setup-only), Noise NOIA (noise-only)
- 11/11 regression unchanged
