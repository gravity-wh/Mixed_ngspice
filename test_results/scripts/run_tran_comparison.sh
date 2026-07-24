#!/bin/bash
# run_tran_comparison.sh — FP32 vs FP64 for circuits_tran/ netlists
#
# Usage:
#   FP32_BIN=build_fp32/src/ngspice FP64_BIN=build_fp64/src/ngspice bash test_results/scripts/run_tran_comparison.sh [--all]
#
# Default: runs the 3 highest-priority TRAN tests.
# --all:   runs all 12 TRAN netlists.

set -euo pipefail

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
OUTDIR="test_results/v1.2_full"
TRAN="test/circuits_tran"
COMPARE_SCRIPT="scripts/compare_fp.py"

mkdir -p "$OUTDIR"/{fp32,fp64,compare}

# Priority TRAN tests (meaningful for analog verification)
PRIORITY_TESTS=(
  "T2_ota_step"
  "T3_opamp_step"
  "T5_ota_openloop"
)

# Full test set
ALL_TESTS=(
  "T1_nmos_gate_step"
  "T1_ring_osc_tran"
  "T2_ota_step"
  "T2_pmos_gate_step"
  "T3_bgr_startup"
  "T3_opamp_step"
  "T4_comparator_clock"
  "T4_ring_osc_tran"
  "T5_bootstrap_switch"
  "T5_ota_openloop"
  "T6_opamp_openloop"
  "T7_inverter_chain"
)

if [ "${1:-}" = "--all" ]; then
  SELECTED=("${ALL_TESTS[@]}")
  echo "=== Running ALL 12 TRAN tests ==="
else
  SELECTED=("${PRIORITY_TESTS[@]}")
  echo "=== Running 3 priority TRAN tests (use --all for full set) ==="
fi
echo ""

PASS=0; FAIL=0; SKIP=0

for label in "${SELECTED[@]}"; do
  # Map label to netlist file
  netlist="$TRAN/${label}.sp"
  fp32_log="$OUTDIR/fp32/${label}_fp32.log"
  fp64_log="$OUTDIR/fp64/${label}_fp64.log"
  compare_md="$OUTDIR/compare/${label}_compare.md"

  echo -n "[$label] "

  if [ ! -f "$netlist" ]; then
    echo "SKIP — netlist not found"
    ((SKIP++)) || true
    continue
  fi

  $FP32_BIN --batch "$netlist" > "$fp32_log" 2>&1 || { echo "FP32 FAIL"; ((FAIL++)); continue; }
  $FP64_BIN --batch "$netlist" > "$fp64_log" 2>&1 || { echo "FP64 FAIL"; ((FAIL++)); continue; }

  if python3 "$COMPARE_SCRIPT" "$fp32_log" "$fp64_log" -o "$compare_md" 2>/dev/null; then
    echo "PASS"; ((PASS++))
  else
    echo "WARN (see $compare_md)"; ((FAIL++))
  fi
done

echo ""
echo "=== TRAN Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP ==="
