# FP32 vs FP64 Accuracy Report

- **FP32**: `12_ldo_ptm130_fp32.log`
- **FP64**: `12_ldo_ptm130_fp64.log`

## DC Operating Point

*No node voltages found in output.*

## DC Measured Values

| Metric | FP64 | FP32 | RelErr | Status |
|--------|------|------|--------|--------|
| `i(vin_src)` | -5.127210e-02 | -5.123050e-02 | 8.11e-04 | PASS |
| `v(vout)` | 1.297462e+00 | 1.296496e+00 | 7.45e-04 | PASS |
| `v(vref)` | 6.500000e-01 | 6.500000e-01 | 0.00e+00 | PASS |

## Summary

- **Metrics compared**: 3
- **PASS**: 3 | **WARN**: 0 | **FAIL**: 0
- **Worst error**: 8.11e-04 on `i(vin_src)` (dc)

**Overall Verdict: PASS**
