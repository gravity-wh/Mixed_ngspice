## Summary
V1 verification ran 14 circuits and found 4 P0-level bugs that block ALL Phase 5 work.

## P0 Bugs Found

| # | Bug | Severity | Impact |
|---|-----|:--:|------|
| P0.1 | real_to_str() static buf corrupts all multi-value printf | BLOCKER | Device params/model info untrustable |
| P0.2 | Multi-transistor circuits converge to zero-current trivial solution | BLOCKER | OTA/OpAmp/Comparator all broken |
| P0.3 | parse_include() ignores continuation lines | BLOCKER | ALL PTM .lib model parameters lost |
| P0.4 | (double) casts in param_subst and AC output | LOW | Violates zero-double purity claim |

## Causal Chain

P0.3 (include ignores + lines)
  -> PTM .lib model params all lost
  -> All MOSFETs use BSIM4 defaults
  -> Multi-transistor circuits converge to zero (P0.2)

P0.1 (static buf)
  -> All multi-value printf shows last-evaluated value
  -> Even correctly converging circuits show corrupted output
  -> MASKS all other bugs (there may be more hidden)

## float_spice v2.5 Real State

| Claim | Reality |
|-------|---------|
| 4 mx/ circuits PASS | Nominally converge but output UNTRUSTABLE due to P0.1 |
| BSIM4v5 51 params | Defaults only (P0.3 breaks .lib loading) |
| 0 cvtss2sd | At least 2 (double) casts exist (P0.4) |
| 8 open circuit coverage | Only single-transistor circuits converge (P0.2) |
| 2361 lines with AC/Noise code | Never tested, correctness unknown |

## Phase 5 Impact

ALL 24 Phase 5 Issues are BLOCKED until:
1. P0.1 fix (30min): real_to_str ring buffer
2. P0.3 fix (1h): parse_include continuation handling
3. Re-run V1 to confirm fixes work
4. P0.2 re-evaluation (likely fixed by P0.3)
5. Re-run V2 DC accuracy measurement

## Recommended Order

1. Fix P0.1 -> make output trustable
2. Fix P0.3 -> make PTM models load correctly
3. Re-run V1 -> verify fixes
4. If P0.2 persists -> investigate dc_solve
5. After all P0 fixed -> re-run V2 accuracy
6. Based on V2 data -> decide which Phase 5 issues are worth doing

## Methodology Lesson

The 24 Phase 5 issues were created with ZERO verification. V1 found 4 blocking bugs in 1 hour.
Correct approach: VERIFY first, THEN plan, THEN code.

## Related Issues
- #32 P0.1: real_to_str static buf
- #33 P0.2: multi-transistor zero convergence
- #34 P0.3: parse_include continuation lines
- #35 P0.4: (double) casts
