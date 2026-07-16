#!/bin/bash
# run_all.sh — Full test suite for Mixed_ngspice
# Usage: bash test/run_all.sh [--quick] [--fp32-only] [--fp64-only] [--open-only]

set -euo pipefail
cd "$(dirname "$0")/.."

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
TIMEOUT=60
QUICK=0
MODE="both"
OPEN_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) QUICK=1; shift ;;
    --fp32-only) MODE="fp32"; shift ;;
    --fp64-only) MODE="fp64"; shift ;;
    --open-only) OPEN_ONLY=1; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0; FAIL=0; TOTAL=0

run_test() {
  local name="$1"; local spice_file="$2"; local bin="$3"; local log="$4"
  TOTAL=$((TOTAL + 1))
  echo -n "  [$name] ... "
  if timeout "$TIMEOUT" "$bin" --batch "$spice_file" > "$log" 2>&1; then
    if grep -qi "error\|fatal\|singular\|timestep too small" "$log"; then
      echo -e "${RED}ERROR${NC}"; FAIL=$((FAIL + 1)); tail -3 "$log"
    elif grep -qi "nan\|inf" "$log"; then
      echo -e "${YELLOW}NaN/Inf${NC}"; FAIL=$((FAIL + 1))
    else
      echo -e "${GREEN}OK${NC}"; PASS=$((PASS + 1))
    fi
  else
    echo -e "${RED}CRASH${NC}"; FAIL=$((FAIL + 1)); tail -3 "$log"
  fi
}

mkdir -p logs

echo "============================================"
echo "  Mixed_ngspice Test Suite"
echo "============================================"
echo ""

# =============================================================================
# OPEN DATASETS — PTM 45nm BSIM4
# =============================================================================
echo "=== OPEN DATASETS (PTM 45nm BSIM4) ==="

# --- 01: Single NMOS 45nm ---
echo "--- 01_single_nmos_45nm ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "01_nmos_dc" "test/circuits/01_single_nmos_45nm/test_dc.sp" "$FP32_BIN" "logs/01_nmos_dc_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "01_nmos_dc" "test/circuits/01_single_nmos_45nm/test_dc.sp" "$FP64_BIN" "logs/01_nmos_dc_fp64.log"
fi

# --- 02: Single PMOS 45nm ---
echo "--- 02_single_pmos_45nm ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "02_pmos_dc" "test/circuits/02_single_pmos_45nm/test_dc.sp" "$FP32_BIN" "logs/02_pmos_dc_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "02_pmos_dc" "test/circuits/02_single_pmos_45nm/test_dc.sp" "$FP64_BIN" "logs/02_pmos_dc_fp64.log"
fi

# --- 03: Ring Oscillator ---
echo "--- 03_ring_oscillator ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp" "$FP32_BIN" "logs/03_ringosc_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp" "$FP64_BIN" "logs/03_ringosc_fp64.log"
fi

# --- 04: Five-Transistor OTA ---
echo "--- 04_ota_5t_dc ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp" "$FP32_BIN" "logs/04_ota_dc_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp" "$FP64_BIN" "logs/04_ota_dc_fp64.log"
fi

if [[ "$QUICK" -eq 0 ]]; then
  echo "--- 04_ota_5t_ac ---"
  if [[ "$MODE" != "fp64" ]]; then
    run_test "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp" "$FP32_BIN" "logs/04_ota_ac_fp32.log"
  fi
  if [[ "$MODE" != "fp32" ]]; then
    run_test "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp" "$FP64_BIN" "logs/04_ota_ac_fp64.log"
  fi
fi

# --- 05: Two-Stage Miller Op-Amp ---
echo "--- 05_opamp_2stage_dc ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp" "$FP32_BIN" "logs/05_opamp_dc_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp" "$FP64_BIN" "logs/05_opamp_dc_fp64.log"
fi

if [[ "$QUICK" -eq 0 ]]; then
  echo "--- 05_opamp_2stage_ac ---"
  if [[ "$MODE" != "fp64" ]]; then
    run_test "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp" "$FP32_BIN" "logs/05_opamp_ac_fp32.log"
  fi
  if [[ "$MODE" != "fp32" ]]; then
    run_test "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp" "$FP64_BIN" "logs/05_opamp_ac_fp64.log"
  fi
fi

# --- 06: StrongArm Comparator ---
echo "--- 06_comparator_strongarm ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp" "$FP32_BIN" "logs/06_comparator_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp" "$FP64_BIN" "logs/06_comparator_fp64.log"
fi

# --- 07: Bootstrap Switch ---
echo "--- 07_bootstrap_switch ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "07_bootstrap" "test/circuits/07_bootstrap_switch_45nm/test_tran.sp" "$FP32_BIN" "logs/07_bootstrap_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "07_bootstrap" "test/circuits/07_bootstrap_switch_45nm/test_tran.sp" "$FP64_BIN" "logs/07_bootstrap_fp64.log"
fi

# --- 08: Roessler Attractor (precision stress test) ---
echo "--- 08_roessler_attractor ---"
if [[ "$MODE" != "fp64" ]]; then
  run_test "08_roessler" "test/circuits/08_roessler_attractor/test_chaos.sp" "$FP32_BIN" "logs/08_roessler_fp32.log"
fi
if [[ "$MODE" != "fp32" ]]; then
  run_test "08_roessler" "test/circuits/08_roessler_attractor/test_chaos.sp" "$FP64_BIN" "logs/08_roessler_fp64.log"
fi

echo ""
echo "============================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, $TOTAL total"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
