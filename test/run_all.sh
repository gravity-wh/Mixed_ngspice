#!/bin/bash
# run_all.sh — Full test suite for Mixed_ngspice
# Usage: bash test/run_all.sh [--quick] [--fp32-only] [--fp64-only] [--open-only]

set -euo pipefail
cd "$(dirname "$0")/.."

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
FP32_PURE_BIN="${FP32_PURE_BIN:-build_pure_fp32/src/ngspice}"
TIMEOUT=60
QUICK=0
MODE="both"
OPEN_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) QUICK=1; shift ;;
    --fp32-only) MODE="fp32"; shift ;;
    --fp64-only) MODE="fp64"; shift ;;
    --pure-fp32-only) MODE="pure-fp32"; shift ;;
    --all-three) MODE="all"; shift ;;
    --open-only) OPEN_ONLY=1; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0; FAIL=0; TOTAL=0

# Helper: should we run this variant?
run_fp32() { [[ "$MODE" == "both" || "$MODE" == "fp32" || "$MODE" == "all" ]]; }
run_fp64() { [[ "$MODE" == "both" || "$MODE" == "fp64" || "$MODE" == "all" ]]; }
run_pure_fp32() { [[ "$MODE" == "pure-fp32" || "$MODE" == "all" ]]; }
have_pure_fp32() { [[ -x "$FP32_PURE_BIN" ]]; }

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
if run_fp32; then
  run_test "01_nmos_dc" "test/circuits/01_single_nmos_45nm/test_dc.sp" "$FP32_BIN" "logs/01_nmos_dc_fp32.log"
fi
if run_fp64; then
  run_test "01_nmos_dc" "test/circuits/01_single_nmos_45nm/test_dc.sp" "$FP64_BIN" "logs/01_nmos_dc_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "01_nmos_dc" "test/circuits/01_single_nmos_45nm/test_dc.sp" "$FP32_PURE_BIN" "logs/01_nmos_dc_fp32pure.log"
fi

# --- 02: Single PMOS 45nm ---
echo "--- 02_single_pmos_45nm ---"
if run_fp32; then
  run_test "02_pmos_dc" "test/circuits/02_single_pmos_45nm/test_dc.sp" "$FP32_BIN" "logs/02_pmos_dc_fp32.log"
fi
if run_fp64; then
  run_test "02_pmos_dc" "test/circuits/02_single_pmos_45nm/test_dc.sp" "$FP64_BIN" "logs/02_pmos_dc_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "02_pmos_dc" "test/circuits/02_single_pmos_45nm/test_dc.sp" "$FP32_PURE_BIN" "logs/02_pmos_dc_fp32pure.log"
fi

# --- 03: Ring Oscillator ---
echo "--- 03_ring_oscillator ---"
if run_fp32; then
  run_test "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp" "$FP32_BIN" "logs/03_ringosc_fp32.log"
fi
if run_fp64; then
  run_test "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp" "$FP64_BIN" "logs/03_ringosc_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp" "$FP32_PURE_BIN" "logs/03_ringosc_fp32pure.log"
fi

# --- 04: Five-Transistor OTA ---
echo "--- 04_ota_5t_dc ---"
if run_fp32; then
  run_test "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp" "$FP32_BIN" "logs/04_ota_dc_fp32.log"
fi
if run_fp64; then
  run_test "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp" "$FP64_BIN" "logs/04_ota_dc_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp" "$FP32_PURE_BIN" "logs/04_ota_dc_fp32pure.log"
fi

if [[ "$QUICK" -eq 0 ]]; then
  echo "--- 04_ota_5t_ac ---"
  if run_fp32; then
    run_test "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp" "$FP32_BIN" "logs/04_ota_ac_fp32.log"
  fi
  if run_fp64; then
    run_test "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp" "$FP64_BIN" "logs/04_ota_ac_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp" "$FP32_PURE_BIN" "logs/04_ota_ac_fp32pure.log"
  fi
fi

# --- 05: Two-Stage Miller Op-Amp ---
echo "--- 05_opamp_2stage_dc ---"
if run_fp32; then
  run_test "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp" "$FP32_BIN" "logs/05_opamp_dc_fp32.log"
fi
if run_fp64; then
  run_test "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp" "$FP64_BIN" "logs/05_opamp_dc_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp" "$FP32_PURE_BIN" "logs/05_opamp_dc_fp32pure.log"
fi

if [[ "$QUICK" -eq 0 ]]; then
  echo "--- 05_opamp_2stage_ac ---"
  if run_fp32; then
    run_test "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp" "$FP32_BIN" "logs/05_opamp_ac_fp32.log"
  fi
  if run_fp64; then
    run_test "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp" "$FP64_BIN" "logs/05_opamp_ac_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp" "$FP32_PURE_BIN" "logs/05_opamp_ac_fp32pure.log"
  fi
fi

# --- 06: StrongArm Comparator ---
echo "--- 06_comparator_strongarm ---"
if run_fp32; then
  run_test "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp" "$FP32_BIN" "logs/06_comparator_fp32.log"
fi
if run_fp64; then
  run_test "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp" "$FP64_BIN" "logs/06_comparator_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp" "$FP32_PURE_BIN" "logs/06_comparator_fp32pure.log"
fi

# --- 07: Bootstrap Switch ---
echo "--- 07_bootstrap_switch ---"
if run_fp32; then
  run_test "07_bootstrap" "test/circuits/07_bootstrap_switch_45nm/test_tran.sp" "$FP32_BIN" "logs/07_bootstrap_fp32.log"
fi
if run_fp64; then
  run_test "07_bootstrap" "test/circuits/07_bootstrap_switch_45nm/test_tran.sp" "$FP64_BIN" "logs/07_bootstrap_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "07_bootstrap" "test/circuits/07_bootstrap_switch_45nm/test_tran.sp" "$FP32_PURE_BIN" "logs/07_bootstrap_fp32pure.log"
fi

# --- 08: Roessler Attractor (precision stress test) ---
echo "--- 08_roessler_attractor ---"
if run_fp32; then
  run_test "08_roessler" "test/circuits/08_roessler_attractor/test_chaos.sp" "$FP32_BIN" "logs/08_roessler_fp32.log"
fi
if run_fp64; then
  run_test "08_roessler" "test/circuits/08_roessler_attractor/test_chaos.sp" "$FP64_BIN" "logs/08_roessler_fp64.log"
fi
if run_pure_fp32 && have_pure_fp32; then
  run_test "08_roessler" "test/circuits/08_roessler_attractor/test_chaos.sp" "$FP32_PURE_BIN" "logs/08_roessler_fp32pure.log"
fi

echo ""
# =============================================================================
# DC SWEEP TESTS (not run in --quick mode)
# =============================================================================
if [[ "$QUICK" -eq 0 ]]; then
  echo "=== DC SWEEP TESTS ==="

  echo "--- 01_nmos_sweep ---"
  if run_fp32; then
    run_test "01_nmos_sweep" "test/circuits/01_single_nmos_45nm/test_dc_sweep.sp" "$FP32_BIN" "logs/01_nmos_sweep_fp32.log"
  fi
  if run_fp64; then
    run_test "01_nmos_sweep" "test/circuits/01_single_nmos_45nm/test_dc_sweep.sp" "$FP64_BIN" "logs/01_nmos_sweep_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "01_nmos_sweep" "test/circuits/01_single_nmos_45nm/test_dc_sweep.sp" "$FP32_PURE_BIN" "logs/01_nmos_sweep_fp32pure.log"
  fi

  echo "--- 02_pmos_sweep ---"
  if run_fp32; then
    run_test "02_pmos_sweep" "test/circuits/02_single_pmos_45nm/test_dc_sweep.sp" "$FP32_BIN" "logs/02_pmos_sweep_fp32.log"
  fi
  if run_fp64; then
    run_test "02_pmos_sweep" "test/circuits/02_single_pmos_45nm/test_dc_sweep.sp" "$FP64_BIN" "logs/02_pmos_sweep_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "02_pmos_sweep" "test/circuits/02_single_pmos_45nm/test_dc_sweep.sp" "$FP32_PURE_BIN" "logs/02_pmos_sweep_fp32pure.log"
  fi
fi

# =============================================================================
# TRAN VALIDATION TESTBENCHES (circuits_tran/)
# Enhanced TRAN tests with .meas and .save for waveform comparison.
# Not run in --quick mode (heavier simulations).
# =============================================================================
if [[ "$QUICK" -eq 0 ]]; then
  echo "=== TRAN VALIDATION TESTBENCHES (T1-T5) ==="

  echo "--- T1_ring_osc_tran ---"
  if run_fp32; then
    run_test "T1_ring_osc" "test/circuits_tran/T1_ring_osc_tran.sp" "$FP32_BIN" "logs/T1_ring_osc_fp32.log"
  fi
  if run_fp64; then
    run_test "T1_ring_osc" "test/circuits_tran/T1_ring_osc_tran.sp" "$FP64_BIN" "logs/T1_ring_osc_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "T1_ring_osc" "test/circuits_tran/T1_ring_osc_tran.sp" "$FP32_PURE_BIN" "logs/T1_ring_osc_fp32pure.log"
  fi

  echo "--- T2_ota_step ---"
  if run_fp32; then
    run_test "T2_ota_step" "test/circuits_tran/T2_ota_step.sp" "$FP32_BIN" "logs/T2_ota_step_fp32.log"
  fi
  if run_fp64; then
    run_test "T2_ota_step" "test/circuits_tran/T2_ota_step.sp" "$FP64_BIN" "logs/T2_ota_step_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "T2_ota_step" "test/circuits_tran/T2_ota_step.sp" "$FP32_PURE_BIN" "logs/T2_ota_step_fp32pure.log"
  fi

  echo "--- T3_opamp_step ---"
  if run_fp32; then
    run_test "T3_opamp_step" "test/circuits_tran/T3_opamp_step.sp" "$FP32_BIN" "logs/T3_opamp_step_fp32.log"
  fi
  if run_fp64; then
    run_test "T3_opamp_step" "test/circuits_tran/T3_opamp_step.sp" "$FP64_BIN" "logs/T3_opamp_step_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "T3_opamp_step" "test/circuits_tran/T3_opamp_step.sp" "$FP32_PURE_BIN" "logs/T3_opamp_step_fp32pure.log"
  fi

  echo "--- T4_comparator_clock ---"
  if run_fp32; then
    run_test "T4_comparator_clock" "test/circuits_tran/T4_comparator_clock.sp" "$FP32_BIN" "logs/T4_comparator_clock_fp32.log"
  fi
  if run_fp64; then
    run_test "T4_comparator_clock" "test/circuits_tran/T4_comparator_clock.sp" "$FP64_BIN" "logs/T4_comparator_clock_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "T4_comparator_clock" "test/circuits_tran/T4_comparator_clock.sp" "$FP32_PURE_BIN" "logs/T4_comparator_clock_fp32pure.log"
  fi

  echo "--- T5_bootstrap_switch ---"
  if run_fp32; then
    run_test "T5_bootstrap" "test/circuits_tran/T5_bootstrap_switch.sp" "$FP32_BIN" "logs/T5_bootstrap_fp32.log"
  fi
  if run_fp64; then
    run_test "T5_bootstrap" "test/circuits_tran/T5_bootstrap_switch.sp" "$FP64_BIN" "logs/T5_bootstrap_fp64.log"
  fi
  if run_pure_fp32 && have_pure_fp32; then
    run_test "T5_bootstrap" "test/circuits_tran/T5_bootstrap_switch.sp" "$FP32_PURE_BIN" "logs/T5_bootstrap_fp32pure.log"
  fi
fi

echo ""
echo "============================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, $TOTAL total"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
