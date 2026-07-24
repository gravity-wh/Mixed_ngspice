# FP32 vs FP64 Accuracy Report

- **FP32**: `11_opamp_ptm130_fp32.log`
- **FP64**: `11_opamp_ptm130_fp64.log`

## DC Operating Point

*No node voltages found in output.*

## DC Measured Values

| Metric | FP64 | FP32 | RelErr | Status |
|--------|------|------|--------|--------|
| `i(vdd_src)` | -5.763010e-05 | -5.658190e-05 | 1.05e-03 | WARN |
| `v(inn)` | 6.500000e-01 | 6.500000e-01 | 0.00e+00 | PASS |
| `v(inp)` | 6.500000e-01 | 6.500000e-01 | 0.00e+00 | PASS |
| `v(out)` | 8.675799e-01 | 8.548998e-01 | 1.46e-02 | FAIL |

## Summary

- **Metrics compared**: 4
- **PASS**: 2 | **WARN**: 1 | **FAIL**: 1
- **Worst error**: 1.46e-02 on `v(out)` (dc)

**Overall Verdict: FAIL**
