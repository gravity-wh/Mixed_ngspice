# FP32 vs FP64 Accuracy Report

- **FP32**: `T3_opamp_step_fp32.log`
- **FP64**: `T3_opamp_step_fp64.log`

## DC Operating Point

### Node Voltages

| Node | FP64 | FP32 | RelErr | Status |
|------|------|------|--------|--------|
| `inp` | 5.500000e-01 | 5.500000e-01 | 0.00e+00 | PASS |
| `neta` | 5.591800e-01 | 5.642260e-01 | 9.02e-03 | WARN |
| `netb` | 1.100000e+00 | 9.740820e-03 | 9.91e-01 | FAIL |
| `out` | 2.920130e-07 | 1.091620e+00 | 1.09e+03 | FAIL |
| `tail1` | 4.404610e-03 | 8.620900e-03 | 9.57e-01 | FAIL |
| `vbias` | 6.340310e-01 | 6.337280e-01 | 4.78e-04 | PASS |
| `vdd` | 1.100000e+00 | 1.100000e+00 | 0.00e+00 | PASS |

## DC Measured Values

| Metric | FP64 | FP32 | RelErr | Status |
|--------|------|------|--------|--------|
| `overshoot` | 1.587480e-05 | 1.093840e+00 | 1.09e+03 | FAIL |
| `vout_final` | 2.868890e-07 | 1.091170e+00 | 1.09e+03 | FAIL |

## Summary

- **Metrics compared**: 9
- **PASS**: 3 | **WARN**: 1 | **FAIL**: 5
- **Worst error**: 1.09e+03 on `overshoot` (dc)
- :warning: **NaN detected** in output

**Overall Verdict: FAIL**
