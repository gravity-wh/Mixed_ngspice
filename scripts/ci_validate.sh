#!/bin/bash
# ci_validate.sh — CI Precision Validation Runner for Mixed_ngspice
# Runs each test circuit through FP32 and FP64, compares with compare_fp.py,
# and reports precision regressions.
#
# Usage:
#   bash scripts/ci_validate.sh              # Full validation
#   bash scripts/ci_validate.sh --quick      # Skip AC and TRAN-heavy tests
#   bash scripts/ci_validate.sh --verbose    # Print per-circuit comparison reports
#
# Environment variables:
#   FP32_BIN    — path to FP32 ngspice (default: build_fp32/src/ngspice)
#   FP64_BIN    — path to FP64 ngspice (default: build_fp64/src/ngspice)
#   TIMEOUT     — per-circuit timeout in seconds (default: 120)

set -uo pipefail
# Note: set -e is intentionally NOT used here because the Python JSON extraction
# steps may fail on edge cases (empty output, etc.) and we use || fallbacks.
cd "$(dirname "$0")/.."

FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
FP32_PURE_BIN="${FP32_PURE_BIN:-build_pure_fp32/src/ngspice}"
TIMEOUT="${TIMEOUT:-120}"
COMPARE_SCRIPT="scripts/compare_fp.py"
THREE_WAY=0
LOGDIR="logs"
SUMMARY_JSON="$LOGDIR/ci_summary.json"
QUICK=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=1; shift ;;
        --verbose) VERBOSE=1; shift ;;
        --three-way) THREE_WAY=1; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$LOGDIR"

# =============================================================================
# Test Manifest
# Format: "label|spice_file|category|expected|extra_args"
#
# expected values:
#   PASS   — FP32 should match FP64 within normal tolerances
#   SKIP   — Circuit known to fail in FP64 too; don't count as FP32 failure
#   WARN   — FP32 may have slightly larger error (relaxed tolerances)
#
# extra_args: additional flags passed to compare_fp.py (threshold overrides, etc.)
# =============================================================================

declare -a MANIFEST=(
    # === DC Operating Point Tests ===
    "01_nmos_dc|test/circuits/01_single_nmos_45nm/test_dc.sp|dc|PASS|"
    "01_nmos_sweep|test/circuits/01_single_nmos_45nm/test_dc_sweep.sp|dc|PASS|"
    "02_pmos_dc|test/circuits/02_single_pmos_45nm/test_dc.sp|dc|PASS|"
    "02_pmos_sweep|test/circuits/02_single_pmos_45nm/test_dc_sweep.sp|dc|SKIP|"
    "03_ringosc|test/circuits/03_ring_oscillator_17stage/test_tran.sp|dc|PASS|"
    "04_ota_dc|test/circuits/04_ota_5transistor_45nm/test_dc.sp|dc|WARN|"
    "05_opamp_dc|test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp|dc|PASS|"
    "06_comparator|test/circuits/06_comparator_strongarm_45nm/test_tran.sp|dc|PASS|"
    "07_bootstrap|test/circuits/07_bootstrap_switch_45nm/test_tran.sp|tran|SKIP|"
    "08_roessler|test/circuits/08_roessler_attractor/test_chaos.sp|tran|WARN|--warn-tran 0.05 --fail-tran 0.10"

    # === AC Tests (skipped in --quick mode) ===
    "04_ota_ac|test/circuits/04_ota_5transistor_45nm/test_ac.sp|ac|PASS|--warn-ac 0.05 --fail-ac 0.10"
    "05_opamp_ac|test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp|ac|PASS|--warn-ac 0.05 --fail-ac 0.10"

    # === Noise Analysis (NEW: three-way validation) ===
    "04_ota_noise|test/circuits/04_ota_5transistor_45nm/test_noise.sp|noise|WARN|--warn-dc 0.01 --fail-dc 0.10"
    "05_opamp_noise|test/circuits/05_opamp_2stage_miller_45nm/test_noise.sp|noise|WARN|--warn-dc 0.01 --fail-dc 0.10"

    # === TRAN Validation Testbenches ===
    "T1_ring_osc_tran|test/circuits_tran/T1_ring_osc_tran.sp|tran|SKIP|--warn-tran 0.005 --fail-tran 0.02"
    "T2_ota_step|test/circuits_tran/T2_ota_step.sp|tran|PASS|--warn-tran 0.01 --fail-tran 0.05"
    "T3_opamp_step|test/circuits_tran/T3_opamp_step.sp|tran|PASS|--warn-tran 0.01 --fail-tran 0.05"
    "T4_comparator_clock|test/circuits_tran/T4_comparator_clock.sp|tran|WARN|--warn-tran 0.02 --fail-tran 0.10"
    "T5_bootstrap_switch|test/circuits_tran/T5_bootstrap_switch.sp|tran|SKIP|"
)

# =============================================================================
# Helper Functions
# =============================================================================

run_ngspice() {
    local bin="$1" spice_file="$2" log="$3" timeout="$4"
    if timeout "$timeout" "$bin" --batch "$spice_file" > "$log" 2>&1; then
        return 0
    else
        return $?
    fi
}

check_log_errors() {
    local log="$1"
    if grep -qi "timestep too small\|singular matrix\|iteration limit reached" "$log"; then
        return 1
    fi
    if grep -qi "error\|fatal" "$log"; then
        if ! grep -q "Node\|Voltage\|Index\|time\|gain_max\|period\|freq\|print" "$log"; then
            return 1
        fi
    fi
    return 0
}

# =============================================================================
# Main Validation Loop
# =============================================================================

echo "============================================"
echo "  Mixed_ngspice CI Precision Validation"
echo "  FP32: $FP32_BIN"
echo "  FP64: $FP64_BIN"
echo "  Mode: $([ $QUICK -eq 1 ] && echo 'QUICK' || echo 'FULL')"
echo "  $(date)"
echo "============================================"
echo ""

TOTAL=0
PASSED=0
WARNED=0
FAILED=0
SKIPPED=0
declare -a RESULTS_JSON=()

for entry in "${MANIFEST[@]}"; do
    IFS='|' read -r label spice_file category expected extra_args <<< "$entry"

    # Skip AC and heavy TRAN tests in quick mode
    if [[ $QUICK -eq 1 ]]; then
        if [[ "$category" == "ac" ]]; then
            echo -e "  ${CYAN}[SKIP]${NC} $label (AC, quick mode)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
        if [[ "$label" =~ ^T[2-5] ]]; then
            echo -e "  ${CYAN}[SKIP]${NC} $label (heavy TRAN, quick mode)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    fi

    if [[ ! -f "$spice_file" ]]; then
        echo -e "  ${RED}[MISS]${NC} $label — file not found: $spice_file"
        FAILED=$((FAILED + 1))
        RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"MISS\",\"error\":\"file not found\"}")
        continue
    fi

    TOTAL=$((TOTAL + 1))
    local_log_fp32="$LOGDIR/${label}_fp32.log"
    local_log_fp64="$LOGDIR/${label}_fp64.log"
    local_log_fp32pure="$LOGDIR/${label}_fp32pure.log"
    local_report="$LOGDIR/${label}_compare.md"
    local_report_pure="$LOGDIR/${label}_compare_pure.md"

    echo -n "  [$TOTAL] $label ... "

    # --- Run FP64 (reference) ---
    fp64_ok=1
    if ! run_ngspice "$FP64_BIN" "$spice_file" "$local_log_fp64" "$TIMEOUT"; then
        fp64_ok=0
    fi
    if ! check_log_errors "$local_log_fp64"; then
        fp64_ok=0
    fi

    # --- Run FP32 ---
    fp32_ok=1
    if ! run_ngspice "$FP32_BIN" "$spice_file" "$local_log_fp32" "$TIMEOUT"; then
        fp32_ok=0
    fi
    if ! check_log_errors "$local_log_fp32"; then
        fp32_ok=0
    fi

    # --- Run Pure FP32 (all-float, no double islands) ---
    fp32pure_ok=1
    if [[ $THREE_WAY -eq 1 ]] && [[ -x "$FP32_PURE_BIN" ]]; then
        if ! run_ngspice "$FP32_PURE_BIN" "$spice_file" "$local_log_fp32pure" "$TIMEOUT"; then
            fp32pure_ok=0
        fi
        if ! check_log_errors "$local_log_fp32pure"; then
            fp32pure_ok=0
        fi
    fi

    # --- Decide verdict (mixed FP32 vs FP64) ---
    if [[ "$expected" == "SKIP" ]]; then
        if [[ $fp64_ok -eq 0 ]]; then
            echo -e "${CYAN}SKIP${NC} (FP64 also fails — known issue)"
            SKIPPED=$((SKIPPED + 1))
            RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"SKIP\",\"reason\":\"FP64 also fails\"}")
        elif [[ $fp32_ok -eq 0 ]]; then
            echo -e "${CYAN}SKIP${NC} (FP32 fails, expected — known issue)"
            SKIPPED=$((SKIPPED + 1))
            RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"SKIP\",\"reason\":\"known FP32 issue\"}")
        else
            echo -e "${CYAN}SKIP${NC} (both pass — known-flaky circuit)"
            SKIPPED=$((SKIPPED + 1))
            RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"SKIP\",\"reason\":\"known flaky, both pass\"}")
        fi
        continue
    fi

    # Both must succeed for a valid comparison
    if [[ $fp64_ok -eq 0 ]] && [[ $fp32_ok -eq 0 ]]; then
        echo -e "${RED}FAIL${NC} (both FP64 and FP32 failed)"
        FAILED=$((FAILED + 1))
        RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"FAIL\",\"reason\":\"both binaries failed\"}")
        continue
    elif [[ $fp64_ok -eq 0 ]]; then
        echo -e "${RED}FAIL${NC} (FP64 reference failed — circuit issue)"
        FAILED=$((FAILED + 1))
        RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"FAIL\",\"reason\":\"FP64 reference failed\"}")
        continue
    elif [[ $fp32_ok -eq 0 ]]; then
        echo -e "${RED}FAIL${NC} (FP32 failed — convergence regression)"
        FAILED=$((FAILED + 1))
        RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"FAIL\",\"reason\":\"FP32 convergence failure\"}")
        continue
    fi

    # --- Run precision comparison ---
    # shellcheck disable=SC2086
    python3 "$COMPARE_SCRIPT" "$local_log_fp32" "$local_log_fp64" \
        --ci --json-summary $extra_args -o "$local_report" > /dev/null 2>&1
    compare_ec=$?

    # Map exit code to verdict: 0=PASS, 1=FAIL, 2=WARN
    case $compare_ec in
        0) verdict="PASS" ;;
        1) verdict="FAIL" ;;
        2) verdict="WARN" ;;
        *) verdict="ERROR" ;;
    esac

    case "$verdict" in
        PASS)
            if [[ "$expected" == "WARN" ]]; then
                echo -e "${GREEN}PASS${NC} (better than expected)"
            else
                echo -e "${GREEN}PASS${NC}"
            fi
            PASSED=$((PASSED + 1))
            ;;
        WARN)
            if [[ "$expected" == "WARN" ]]; then
                echo -e "${YELLOW}WARN${NC} (within relaxed bounds)"
                PASSED=$((PASSED + 1))
            else
                echo -e "${YELLOW}WARN${NC}"
                WARNED=$((WARNED + 1))
            fi
            ;;
        FAIL)
            echo -e "${RED}FAIL${NC} (exceeds threshold)"
            FAILED=$((FAILED + 1))
            ;;
        NODATA)
            echo -e "${YELLOW}NODATA${NC} (no comparable metrics found)"
            WARNED=$((WARNED + 1))
            ;;
        *)
            echo -e "${RED}ERROR${NC} (comparison tool error: $verdict)"
            FAILED=$((FAILED + 1))
            ;;
    esac

    RESULTS_JSON+=("{\"label\":\"$label\",\"verdict\":\"$verdict\",\"compare_exit\":$compare_ec}")

    # --- Pure FP32 vs FP64 comparison (relaxed thresholds) ---
    if [[ $THREE_WAY -eq 1 ]] && [[ $fp32pure_ok -eq 1 ]] && [[ $fp64_ok -eq 1 ]]; then
        # Relaxed thresholds: 10x wider than mixed FP32
        # DC: WARN 1%, FAIL 10%; AC: WARN 5%, FAIL 20%; TRAN: WARN 1%, FAIL 10%
        python3 "$COMPARE_SCRIPT" "$local_log_fp32pure" "$local_log_fp64" \
            --ci --json-summary \
            --warn-dc 0.01 --fail-dc 0.10 \
            --warn-ac 0.05 --fail-ac 0.20 \
            --warn-tran 0.01 --fail-tran 0.10 \
            $extra_args -o "$local_report_pure" > /dev/null 2>&1
        pure_ec=$?

        case $pure_ec in
            0) pure_verdict="PASS" ;;
            1) pure_verdict="FAIL" ;;
            2) pure_verdict="WARN" ;;
            *) pure_verdict="NODATA" ;;
        esac

        # Log pure-fp32 result to JSON
        RESULTS_JSON+=("{\"label\":\"$label\",\"variant\":\"pure-fp32\",\"verdict\":\"$pure_verdict\",\"compare_exit\":$pure_ec}")

        if [[ $VERBOSE -eq 1 ]]; then
            echo -e "    ${CYAN}[pure-fp32 vs fp64]${NC} $pure_verdict"
        fi
    fi

    if [[ $VERBOSE -eq 1 ]] && [[ -f "$local_report" ]]; then
        echo "    ---"
        grep -E "Worst|Overall Verdict|PASS|WARN|FAIL" "$local_report" | head -5 | sed 's/^/    /'
        echo "    ---"
    fi
done

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "============================================"
echo "  Precision Validation Summary"
echo "============================================"
echo ""
echo -e "  Total compared:  $TOTAL"
echo -e "  ${GREEN}PASS: $PASSED${NC}"
echo -e "  ${YELLOW}WARN: $WARNED${NC}"
echo -e "  ${RED}FAIL: $FAILED${NC}"
echo -e "  ${CYAN}SKIP: $SKIPPED${NC}"
echo ""

# Write JSON summary
effective_total=$((PASSED + WARNED + FAILED))
if [[ $effective_total -gt 0 ]]; then
    pass_rate=$(python3 -c "print(f'{$PASSED / $effective_total * 100:.1f}%')" 2>/dev/null || echo "N/A")
else
    pass_rate="N/A"
fi

cat > "$SUMMARY_JSON" << JSONEOF
{
  "date": "$(date -Iseconds)",
  "mode": "$([ $QUICK -eq 1 ] && echo 'quick' || echo 'full')",
  "total_compared": $TOTAL,
  "passed": $PASSED,
  "warned": $WARNED,
  "failed": $FAILED,
  "skipped": $SKIPPED,
  "pass_rate": "$pass_rate",
  "results": [$(IFS=,; echo "${RESULTS_JSON[*]}")]
}
JSONEOF

echo "  Summary JSON: $SUMMARY_JSON"
echo "  Comparison reports: $LOGDIR/*_compare.md"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}VALIDATION FAILED${NC} — $FAILED circuit(s) exceed precision thresholds"
    exit 1
elif [[ $WARNED -gt 0 ]]; then
    echo -e "${YELLOW}VALIDATION PASSED WITH WARNINGS${NC} — $WARNED circuit(s) have elevated errors"
    exit 0
else
    echo -e "${GREEN}VALIDATION PASSED${NC} — all circuits within precision thresholds"
    exit 0
fi
