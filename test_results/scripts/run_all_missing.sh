#!/bin/bash
# run_all_missing.sh — Master script to run ALL missing FP32 vs FP64 comparisons
#
# This script orchestrates the complete test gap fill:
#   1. v1.1 11-circuit DC/TRAN comparison
#   2. PTM 130nm 3-circuit comparison
#   3. OTA/OpAmp NOISE comparison
#   4. Priority TRAN tests from circuits_tran/
#
# Usage:
#   FP32_BIN=build_fp32/src/ngspice FP64_BIN=build_fp64/src/ngspice bash test_results/scripts/run_all_missing.sh
#
# After running, update the coverage matrix:
#   python3 scripts/report_matrix.py test_results/ > docs/circuit_coverage_matrix.html

set -euo pipefail

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"

echo "╔══════════════════════════════════════════════════╗"
echo "║  Mixed_ngspice — Complete Test Gap Fill          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "FP32: $FP32_BIN"
echo "FP64: $FP64_BIN"
echo ""

# Phase 1: v1.1 baseline (11 circuits)
echo "━━━ Phase 1/4: v1.1 11-circuit baseline ━━━"
bash test_results/scripts/run_v1.1_comparison.sh
echo ""

# Phase 2: PTM 130nm (3 circuits, highest priority gap)
echo "━━━ Phase 2/4: PTM 130nm BSIM4v5 ━━━"
bash test_results/scripts/run_ptm130_comparison.sh
echo ""

# Phase 3: NOISE comparison
echo "━━━ Phase 3/4: OTA/OpAmp NOISE ━━━"
OUTDIR="test_results/v1.1_fp32_conversions"
COMPARE="scripts/compare_fp.py"
mkdir -p "$OUTDIR"/{fp32,fp64,compare}

for test in "04_ota_noise:test/circuits/04_ota_5transistor_45nm/test_noise.sp" \
            "05_opamp_noise:test/circuits/05_opamp_2stage_miller_45nm/test_noise.sp"; do
  label="${test%%:*}"
  netlist="${test##*:}"
  echo -n "[$label] "
  $FP32_BIN --batch "$netlist" > "$OUTDIR/fp32/${label}_fp32.log" 2>&1 || { echo "FP32 FAIL"; continue; }
  $FP64_BIN --batch "$netlist" > "$OUTDIR/fp64/${label}_fp64.log" 2>&1 || { echo "FP64 FAIL"; continue; }
  python3 "$COMPARE" "$OUTDIR/fp32/${label}_fp32.log" "$OUTDIR/fp64/${label}_fp64.log" -o "$OUTDIR/compare/${label}_compare.md" 2>/dev/null && echo "PASS" || echo "WARN"
done
echo ""

# Phase 4: Priority TRAN tests
echo "━━━ Phase 4/4: Priority TRAN tests ━━━"
bash test_results/scripts/run_tran_comparison.sh
echo ""

echo "╔══════════════════════════════════════════════════╗"
echo "║  All tests complete.                             ║"
echo "║  Results: test_results/v1.*/compare/             ║"
echo "║  Update matrix: docs/circuit_coverage_matrix.html║"
echo "╚══════════════════════════════════════════════════╝"
