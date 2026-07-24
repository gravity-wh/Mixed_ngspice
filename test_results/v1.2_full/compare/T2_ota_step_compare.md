# FP32 vs FP64 Accuracy Report

- **FP32**: `T2_ota_step_fp32.log`
- **FP64**: `T2_ota_step_fp64.log`

## DC Operating Point

### Node Voltages

| Node | FP64 | FP32 | RelErr | Status |
|------|------|------|--------|--------|
| `inp` | 5.500000e-01 | 5.500000e-01 | 0.00e+00 | PASS |
| `netd` | 9.601860e-01 | 9.602370e-01 | 5.31e-05 | PASS |
| `out` | 4.399180e-06 | 4.438180e-06 | 3.90e-05 | PASS |
| `tail` | 8.590810e-07 | 8.640770e-07 | 5.00e-06 | PASS |
| `vbias` | 5.958530e-01 | 5.955260e-01 | 5.49e-04 | PASS |
| `vdd` | 1.100000e+00 | 1.100000e+00 | 0.00e+00 | PASS |

## DC Measured Values

| Metric | FP64 | FP32 | RelErr | Status |
|--------|------|------|--------|--------|
| `overshoot` | 5.737940e-06 | 5.777090e-06 | 3.92e-05 | PASS |
| `vout_final` | 4.359890e-06 | 4.399250e-06 | 3.94e-05 | PASS |

## Summary

- **Metrics compared**: 8
- **PASS**: 8 | **WARN**: 0 | **FAIL**: 0
- **Worst error**: 5.49e-04 on `v(vbias)` (dc)

**Overall Verdict: PASS**
