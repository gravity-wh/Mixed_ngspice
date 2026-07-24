#!/bin/bash
# run_ptm130_comparison.sh — FP32 vs FP64 comparison for PTM 130nm BSIM4v5 (3 circuits)
#
# Usage:
#   FP32_BIN=build_fp32/src/ngspice FP64_BIN=build_fp64/src/ngspice bash test_results/scripts/run_ptm130_comparison.sh
#
# These 3 circuits are the v1.2 additions that currently have NO FP32 vs FP64 data.

set -euo pipefail

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
OUTDIR="test_results/v1.2_full"
BSIM4DIR="test/bsim4"
COMPARE_SCRIPT="scripts/compare_fp.py"

mkdir -p "$OUTDIR"/{fp32,fp64,compare}

echo "=== PTM 130nm BSIM4v5 FP32 vs FP64 ==="
echo ""

declare -A TESTS
TESTS=(
  ["10_ota_ptm130_dc"]="$BSIM4DIR/testbenches/ota_dc_bsim4.cir"
  ["11_opamp_ptm130_dc"]="$BSIM4DIR/testbenches/opamp_dc_bsim4.cir"
  ["12_ldo_ptm130_dc"]="$BSIM4DIR/testbenches/ldo_dc_bsim4.cir"
)

PASS=0; FAIL=0

for label in "${!TESTS[@]}"; do
  netlist="${TESTS[$label]}"
  fp32_log="$OUTDIR/fp32/${label}_fp32.log"
  fp64_log="$OUTDIR/fp64/${label}_fp64.log"
  compare_md="$OUTDIR/compare/${label}_compare.md"

  echo -n "[$label] "

  if [ ! -f "$netlist" ]; then
    echo "SKIP — netlist not found"
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
echo "=== PTM 130nm Summary: PASS=$PASS FAIL=$FAIL ==="
