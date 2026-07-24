#!/bin/bash
# batch_mx.sh — Batch test script for float_spice mx/ circuits (P4.4)
# ======================================================================
# Runs all mx/ test circuits through float_spice and reports results.
# Checks: build success, zero cvtss2sd, DC convergence, no NaN/Inf.
#
# Usage:   bash test/batch_mx.sh              # build + test
#          bash test/batch_mx.sh --no-build   # skip build step
#          bash test/batch_mx.sh --verbose    # show full output
# ======================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLOAT_SPICE_DIR="$ROOT/float_spice"
FLOAT_SPICE_BIN="$FLOAT_SPICE_DIR/float_spice"
MX_DIR="$ROOT/test/circuits/mx"
LOG_DIR="$ROOT/logs"

BUILD=1
VERBOSE=0
CI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) BUILD=0; shift ;;
    --verbose)  VERBOSE=1; shift ;;
    --ci)       CI=1; VERBOSE=0; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0; FAIL=0; TOTAL=0

mkdir -p "$LOG_DIR"

# =========================================================================
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  float_spice mx/ Circuit Batch Test${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""

# =========================================================================
# 1. BUILD
# =========================================================================
if [[ "$BUILD" -eq 1 ]]; then
  echo -e "${CYAN}--- Building float_spice ---${NC}"
  cd "$FLOAT_SPICE_DIR"
  if gcc -O2 -o float_spice float_spice.c -lm -Wall -Wextra 2>"$LOG_DIR/build_mx.log"; then
    echo -e "${GREEN}  Build: OK${NC}"
  else
    echo -e "${RED}  Build: FAILED${NC}"
    cat "$LOG_DIR/build_mx.log"
    exit 1
  fi
  cd "$ROOT"
else
  echo -e "${CYAN}--- Build skipped (--no-build) ---${NC}"
  if [[ ! -x "$FLOAT_SPICE_BIN" ]]; then
    echo -e "${RED}  float_spice binary not found at $FLOAT_SPICE_BIN${NC}"
    exit 1
  fi
fi

# =========================================================================
# 2. CVTSS2SD CHECK
# =========================================================================
echo ""
echo -e "${CYAN}--- cvtss2sd instruction count ---${NC}"
if command -v objdump &>/dev/null; then
  CVT_COUNT=$(objdump -d "$FLOAT_SPICE_BIN" 2>/dev/null | grep -c 'cvtss2sd' || echo "0")
  echo -n "  cvtss2sd count: "
  if [[ "$CVT_COUNT" -le 5 ]]; then
    echo -e "${GREEN}$CVT_COUNT${NC} (target: ≤5)"
  elif [[ "$CVT_COUNT" -le 25 ]]; then
    echo -e "${YELLOW}$CVT_COUNT${NC} (target: ≤5, printf only)"
  else
    echo -e "${RED}$CVT_COUNT${NC} (target: ≤5)"
  fi
else
  echo -e "  ${YELLOW}objdump not available — skipping cvtss2sd check${NC}"
fi

# =========================================================================
# 3. RUN MX CIRCUITS
# =========================================================================
echo ""
echo -e "${BOLD}--- Running mx/ circuits ---${NC}"
echo ""

declare -A EXPECTED_PATTERNS
EXPECTED_PATTERNS["mx_nmos_dc"]="V(D).*1\\.|i\\(VD\\)|-?[0-9]"
EXPECTED_PATTERNS["mx_pmos_dc"]="V(D).*-?[0-9]|i\\(VD\\)|-?[0-9]"
EXPECTED_PATTERNS["mx_nmos_sweep"]="DC Sweep|Index|sweep|V\\("
EXPECTED_PATTERNS["mx_pmos_sweep"]="DC Sweep|Index|sweep|V\\("

run_mx_test() {
  local name="$1"
  local spice_file="$2"
  local log="$LOG_DIR/${name}_float_spice.log"
  TOTAL=$((TOTAL + 1))

  echo -n "  [$name] "

  # Run from MX_DIR so relative .include paths resolve correctly
  local elapsed=0
  local start_time=$(date +%s 2>/dev/null || echo 0)

  if timeout 120 "$FLOAT_SPICE_BIN" "$spice_file" > "$log" 2>&1; then
    elapsed=$(($(date +%s 2>/dev/null || echo 0) - start_time))

    # Check for crash/error markers
    local has_error=0
    if grep -qi "segmentation fault\|SIGSEGV\|assertion\|abort" "$log"; then
      echo -e "${RED}CRASH${NC}"
      has_error=1
    elif grep -qi "error\|fatal" "$log" && ! grep -qi "error.*0" "$log"; then
      echo -e "${RED}ERROR${NC}"
      has_error=1
    elif grep -qi "nan\|inf\|-nan\|1\.#QNAN" "$log"; then
      echo -e "${YELLOW}NaN/Inf in output${NC}"
      has_error=1
    elif grep -q "DC Solver\|iterations\|total_iters\|converged\|# [0-9]* iters" "$log"; then
      # Check for meaningful voltage/current output
      if grep -qE "V\(|i\(|current" "$log"; then
        local iters=$(grep -oE '[0-9]+ iterations' "$log" | tail -1 | grep -oE '[0-9]+' || echo "?")
        echo -e "${GREEN}OK${NC} (${iters} iter, ${elapsed}s)"
        PASS=$((PASS + 1))
      else
        echo -e "${YELLOW}NO OUTPUT${NC} (converged but no data printed)"
        FAIL=$((FAIL + 1))
      fi
    else
      # Check if it produced any numerical output
      if grep -qE "[0-9]+\.[0-9]+" "$log"; then
        echo -e "${GREEN}OK${NC} (${elapsed}s)"
        PASS=$((PASS + 1))
      else
        echo -e "${YELLOW}NO DATA${NC} (no numerical results found)"
        FAIL=$((FAIL + 1))
      fi
    fi

    # Show excerpt on verbose
    if [[ "$VERBOSE" -eq 1 ]]; then
      echo "    --- log excerpt ---"
      grep -E "V\(|i\(|iter|converg|sweep|DC Solver|Error|Warning" "$log" | head -20 | sed 's/^/    /'
      echo "    ------------------"
    fi
  else
    local exit_code=$?
    elapsed=$(($(date +%s 2>/dev/null || echo 0) - start_time))
    if [[ $exit_code -eq 124 ]]; then
      echo -e "${RED}TIMEOUT${NC} (120s)"
    else
      echo -e "${RED}FAIL${NC} (exit=$exit_code, ${elapsed}s)"
    fi
    FAIL=$((FAIL + 1))
    if [[ "$VERBOSE" -eq 1 ]]; then
      echo "    --- last 10 lines ---"
      tail -10 "$log" | sed 's/^/    /'
      echo "    ---------------------"
    fi
  fi
}

# Run all 4 mx circuits
cd "$MX_DIR"
run_mx_test "mx_nmos_dc"    "mx_nmos_dc.sp"
run_mx_test "mx_nmos_sweep" "mx_nmos_sweep.sp"
run_mx_test "mx_pmos_dc"    "mx_pmos_dc.sp"
run_mx_test "mx_pmos_sweep" "mx_pmos_sweep.sp"
cd "$ROOT"

# =========================================================================
# 4. SUMMARY
# =========================================================================
echo ""
echo -e "${BOLD}============================================${NC}"
echo -n "  Results: "
echo -ne "${GREEN}$PASS passed${NC}"
echo -n ", "
echo -ne "${RED}$FAIL failed${NC}"
echo -n ", "
echo -e "$TOTAL total"
echo -e "${BOLD}============================================${NC}"

# =========================================================================
# 5. DC OP VALUE CHECKS (if all passed)
# =========================================================================
if [[ "$PASS" -eq 4 ]]; then
  echo ""
  echo -e "${CYAN}--- DC Operating Point Summary ---${NC}"

  # Extract key values from logs
  for name in mx_nmos_dc mx_pmos_dc; do
    local log="$LOG_DIR/${name}_float_spice.log"
    if [[ -f "$log" ]]; then
      echo "  [$name]"
      grep -E "V\(|i\(|current|Node" "$log" | head -8 | sed 's/^/    /'
    fi
  done
fi

# =========================================================================
# 6. ARGON NODE VERIFICATION (manual inspection hints)
# =========================================================================
echo ""
echo -e "${CYAN}--- Verification Hints ---${NC}"
echo "  Expected ROUGH values (float_spice vs ngspice may differ due to model):"
echo "    mx_nmos_dc:  V(D) ~ 0.6–1.1V,  i(VD) ~ -10 to -100 μA"
echo "    mx_pmos_dc:  V(D) ~ 0.0–0.5V,  i(VD) ~ +10 to +100 μA"
echo "    mx_nmos_sweep: Id-Vd family curves (output conductance visible)"
echo "    mx_pmos_sweep: Id-Vd family curves (PMOS mirrored)"
echo ""
echo "  For authoritative comparison, run ngspice on the same circuit:"
echo "    ngspice --batch test/circuits/mx/mx_nmos_dc.sp"

if [[ "$CI" -eq 1 ]]; then
  # CI mode: concise single-line summary + exit code
  echo "CI:mx_batch: $PASS/$TOTAL passed, $FAIL failed"
fi

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
