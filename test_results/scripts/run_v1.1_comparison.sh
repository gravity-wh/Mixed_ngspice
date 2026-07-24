#!/bin/bash
# run_v1.1_comparison.sh — FP32 vs FP64 comparison for v1.1 (11 circuits)
#
# Usage:
#   FP32_BIN=build_fp32/src/ngspice FP64_BIN=build_fp64/src/ngspice bash test_results/scripts/run_v1.1_comparison.sh
#
# Output: test_results/v1.1_fp32_conversions/{fp32,fp64,compare}/

set -euo pipefail

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
OUTDIR="test_results/v1.1_fp32_conversions"
CIRCUITS="test/circuits"
TRAN="test/circuits_tran"
COMPARE_SCRIPT="scripts/compare_fp.py"

mkdir -p "$OUTDIR"/{fp32,fp64,compare}

echo "=== v1.1 FP32 vs FP64 Comparison ==="
echo "FP32 binary: $FP32_BIN"
echo "FP64 binary: $FP64_BIN"
echo "Output:      $OUTDIR"
echo ""

# ── Test matrix ──────────────────────────────────────────
declare -A TESTS
TESTS=(
  ["01_nmos_dc"]="$CIRCUITS/01_single_nmos_45nm/test_dc.sp"
  ["01_nmos_sweep"]="$CIRCUITS/01_single_nmos_45nm/test_dc_sweep.sp"
  ["02_pmos_dc"]="$CIRCUITS/02_single_pmos_45nm/test_dc.sp"
  ["02_pmos_sweep"]="$CIRCUITS/02_single_pmos_45nm/test_dc_sweep.sp"
  ["03_ringosc"]="$CIRCUITS/03_ring_oscillator_17stage/test_tran.sp"
  ["04_ota_dc"]="$CIRCUITS/04_ota_5transistor_45nm/test_dc.sp"
  ["05_opamp_dc"]="$CIRCUITS/05_opamp_2stage_miller_45nm/test_dc.sp"
  ["06_comparator"]="$CIRCUITS/06_comparator_strongarm_45nm/test_tran.sp"
  ["07_bootstrap"]="$CIRCUITS/07_bootstrap_switch_45nm/test_tran.sp"
  ["08_roessler"]="$CIRCUITS/08_roessler_attractor/test_chaos.sp"
  ["T1_ring_osc_tran"]="$TRAN/T1_ring_osc_tran.sp"
)

PASS=0; FAIL=0; SKIP=0
SUMMARY_JSON="$OUTDIR/ci_summary.json"
echo '{"results":[]}' > "$SUMMARY_JSON"

for label in "${!TESTS[@]}"; do
  netlist="${TESTS[$label]}"
  fp32_log="$OUTDIR/fp32/${label}_fp32.log"
  fp64_log="$OUTDIR/fp64/${label}_fp64.log"
  compare_md="$OUTDIR/compare/${label}_compare.md"

  echo -n "[$label] "

  # Check netlist exists
  if [ ! -f "$netlist" ]; then
    echo "SKIP (netlist not found: $netlist)"
    ((SKIP++)) || true
    continue
  fi

  # Run FP32
  if ! $FP32_BIN --batch "$netlist" > "$fp32_log" 2>&1; then
    echo "FP32 FAIL (convergence?)"
    ((FAIL++)) || true
    continue
  fi

  # Run FP64
  if ! $FP64_BIN --batch "$netlist" > "$fp64_log" 2>&1; then
    echo "FP64 FAIL (convergence?)"
    ((FAIL++)) || true
    continue
  fi

  # Compare
  if python3 "$COMPARE_SCRIPT" "$fp32_log" "$fp64_log" -o "$compare_md" 2>/dev/null; then
    echo "PASS"
    ((PASS++)) || true
  else
    echo "WARN (comparison found diffs, see $compare_md)"
    ((FAIL++)) || true
  fi
done

echo ""
echo "=== Summary ==="
echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
echo "Logs: $OUTDIR/fp32/ + $OUTDIR/fp64/"
echo "Reports: $OUTDIR/compare/"
