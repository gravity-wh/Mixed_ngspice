# FP32 vs FP64 Accuracy Report

- **FP32**: `T5_ota_openloop_fp32.log`
- **FP64**: `T5_ota_openloop_fp64.log`

## DC Operating Point

### Node Voltages

| Node | FP64 | FP32 | RelErr | Status |
|------|------|------|--------|--------|
| `inn` | 5.500000e-01 | 5.500000e-01 | 0.00e+00 | PASS |
| `inp` | 5.500000e-01 | 5.500000e-01 | 0.00e+00 | PASS |
| `netd` | 5.694630e-01 | 5.695840e-01 | 2.12e-04 | PASS |
| `out` | 5.694600e-01 | 5.695820e-01 | 2.14e-04 | PASS |
| `tail` | 1.292890e-02 | 1.306490e-02 | 1.05e-02 | FAIL |
| `vbias` | 5.958530e-01 | 5.955260e-01 | 5.49e-04 | PASS |
| `vdd` | 1.100000e+00 | 1.100000e+00 | 0.00e+00 | PASS |

## Summary

- **Metrics compared**: 7
- **PASS**: 6 | **WARN**: 0 | **FAIL**: 1
- **Worst error**: 1.05e-02 on `v(tail)` (dc)

**Overall Verdict: FAIL**
