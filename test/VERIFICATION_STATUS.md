# Circuit Verification Status — 2026-07-24

## Summary

| Status | Count | Description |
|--------|:---:|------|
| ✅ VERIFIED | 17 | 0 NaN with Phase5/v1.2 binary |
| ⚠️ PDK_NEEDED | 83 | Subcircuit PDK not yet linked |
| 🔧 CORRUPTED | 4 | MX generated DC/Sweep files need regeneration |
| 🔲 UNTESTED | 48 | PDK verification pending |

## Verified Circuits (0 NaN)

### MX — Mixed_ngspice PTM45 (14 original + 1 generated)
- 01_single_nmos_45nm/test_dc.sp ✅
- 01_single_nmos_45nm/test_dc_sweep.sp ✅
- 02_single_pmos_45nm/test_dc.sp ✅
- 02_single_pmos_45nm/test_dc_sweep.sp ✅
- 04_ota_5transistor_45nm/test_dc.sp ✅
- 04_ota_5transistor_45nm/test_ac.sp ✅
- 05_opamp_2stage_miller_45nm/test_dc.sp ✅
- 05_opamp_2stage_miller_45nm/test_ac.sp ✅
- 03_ring_oscillator_17stage/test_tran.sp ✅
- 06_comparator_strongarm_45nm/test_tran.sp ✅
- 07_bootstrap_switch_45nm/test_tran.sp ✅
- 08_roessler_attractor/test_chaos.sp ✅
- circuits_tran/T1-T7 ✅
- mx/MX_08_roessler_attractor_test_chaos_fixed.sp ✅

### AB — Analog_blocks SKY130 (2 verified)
- AB_BGR_2_Bandgap_2_tb.spice ✅
- AB_LDO_test_LDO_test_tb.spice ✅

## PDK Requirements

| Dataset | PDK Needed | Status |
|---------|-----------|:---:|
| MX | PTM45 LP/HP (.model NMOS level=54) | ✅ Available |
| HC | SKY130 (.subckt pmos_3p3 etc.) | ❌ Needs lib include |
| AB | SKY130 (sky130.lib.spice) | ✅ Available |
| MG | SKY130 or custom | 🔲 TBD |
| OF | SKY130 / GF180 | 🔲 TBD |
| AG | SKY130 / SMIC180 | 🔲 TBD |
| CA | SKY130 | 🔲 TBD |
| S5 | SKY130 | 🔲 TBD |

## Next Steps

1. Regenerate corrupted MX DC/Sweep files
2. Add SKY130 subcircuit library includes for HC circuits
3. Verify MG/OF/AG/CA/S5 PDK paths
4. Run full batch: `bash test/run_and_record.sh v1.2`
