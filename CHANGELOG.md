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
