#!/bin/bash
# run_all.sh — Full test suite for Mixed_ngspice
# Runs all test circuits through FP32 and FP64 ngspice, compares results.
# Usage: bash test/run_all.sh [--quick] [--fp32-only] [--fp64-only]

set -euo pipefail
cd "$(dirname "$0")/.."

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
TIMEOUT=30
QUICK=0
MODE="both"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) QUICK=1; shift ;;
    --fp32-only) MODE="fp32"; shift ;;
    --fp64-only) MODE="fp64"; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

run_test() {
  local name="$1"
  local spice_file="$2"
  local bin="$3"
  local log="$4"

  TOTAL=$((TOTAL + 1))
  echo -n "  [$name] $bin ... "

  if timeout "$TIMEOUT" "$bin" --batch "$spice_file" > "$log" 2>&1; then
    if grep -qi "error\|fatal\|singular\|timestep too small" "$log"; then
      echo -e "${RED}ERROR${NC}"
      FAIL=$((FAIL + 1))
      tail -5 "$log"
    elif grep -qi "nan\|inf" "$log"; then
      echo -e "${YELLOW}NaN/Inf${NC}"
      FAIL=$((FAIL + 1))
      grep -i "nan\|inf" "$log" | head -3
    else
      echo -e "${GREEN}OK${NC}"
      PASS=$((PASS + 1))
    fi
  else
    echo -e "${RED}CRASH${NC}"
    FAIL=$((FAIL + 1))
    tail -3 "$log"
  fi
}

mkdir -p logs

echo "============================================"
echo "  Mixed_ngspice Test Suite"
echo "============================================"
echo ""

# --- Test 1: Single PMOS ---
echo "--- 01_single_pmos ---"
if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
  run_test "01_pmos" "test/circuits/01_single_pmos/test.sp" "$FP32_BIN" "logs/01_pmos_fp32.log"
fi
if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
  run_test "01_pmos" "test/circuits/01_single_pmos/test.sp" "$FP64_BIN" "logs/01_pmos_fp64.log"
fi
echo ""

# --- Test 2: Single NMOS ---
echo "--- 02_single_nmos ---"
if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
  run_test "02_nmos" "test/circuits/02_single_nmos/test.sp" "$FP32_BIN" "logs/02_nmos_fp32.log"
fi
if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
  run_test "02_nmos" "test/circuits/02_single_nmos/test.sp" "$FP64_BIN" "logs/02_nmos_fp64.log"
fi
echo ""

# --- Test 3: 6T Bias ---
echo "--- 03_bias_6t ---"
if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
  run_test "03_bias6t" "test/circuits/03_bias_6t/test.sp" "$FP32_BIN" "logs/03_bias6t_fp32.log"
fi
if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
  run_test "03_bias6t" "test/circuits/03_bias_6t/test.sp" "$FP64_BIN" "logs/03_bias6t_fp64.log"
fi
echo ""

# --- Test 4: 22T Op-Amp DC ---
echo "--- 04_opamp_22t_dc ---"
if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
  run_test "04_opamp_dc" "test/circuits/04_opamp_22t/dc.sp" "$FP32_BIN" "logs/04_opamp_dc_fp32.log"
fi
if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
  run_test "04_opamp_dc" "test/circuits/04_opamp_22t/dc.sp" "$FP64_BIN" "logs/04_opamp_dc_fp64.log"
fi
echo ""

# --- Test 5: 22T Op-Amp TRAN (skip in quick mode) ---
if [[ "$QUICK" -eq 0 ]]; then
  echo "--- 05_opamp_22t_tran ---"
  if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
    run_test "05_opamp_tran" "test/circuits/04_opamp_22t/tran.sp" "$FP32_BIN" "logs/05_opamp_tran_fp32.log"
  fi
  if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
    run_test "05_opamp_tran" "test/circuits/04_opamp_22t/tran.sp" "$FP64_BIN" "logs/05_opamp_tran_fp64.log"
  fi
  echo ""
fi

# --- Summary ---
echo "============================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, $TOTAL total"
echo "============================================"

# --- Cross-compare if both modes run ---
if [[ "$MODE" == "both" && -f "scripts/compare_fp.py" ]]; then
  echo ""
  echo "--- Cross-comparison (FP32 vs FP64) ---"
  for pair in "01_pmos" "02_nmos" "03_bias6t" "04_opamp_dc"; do
    if [[ -f "logs/${pair}_fp32.log" && -f "logs/${pair}_fp64.log" ]]; then
      echo "  $pair:"
      python3 scripts/compare_fp.py "logs/${pair}_fp32.log" "logs/${pair}_fp64.log" 2>/dev/null || true
    fi
  done
fi

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
