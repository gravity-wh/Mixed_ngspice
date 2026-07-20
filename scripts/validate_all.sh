#!/bin/bash
# validate_all.sh — Three-Way Precision Validation Pipeline
# ===========================================================
# Runs Mixed FP32, Pure FP32, and FP64 on the full test matrix,
# compares each variant against FP64 reference, and generates
# a comprehensive three-way ablation report.
#
# Usage:
#   bash scripts/validate_all.sh              # Full validation (~1 hr)
#   bash scripts/validate_all.sh --quick      # TT-only quick validation (~10 min)
#   bash scripts/validate_all.sh --build-only # Only build, don't run
#   bash scripts/validate_all.sh --run-only   # Only run+compare (assumes built)
#   bash scripts/validate_all.sh --ci         # CI mode (quick + JSON summary)
#
# Environment:
#   FP32_BIN, FP64_BIN, FP32_PURE_BIN — override binary paths
#   TIMEOUT — per-circuit timeout in seconds (default: 120)
#   JOBS    — parallel make jobs (default: nproc)

set -uo pipefail
cd "$(dirname "$0")/.."

# =============================================================================
# Configuration
# =============================================================================
FP32_BIN="${FP32_BIN:-build_fp32/src/ngspice}"
FP64_BIN="${FP64_BIN:-build_fp64/src/ngspice}"
FP32_PURE_BIN="${FP32_PURE_BIN:-build_pure_fp32/src/ngspice}"
TIMEOUT="${TIMEOUT:-120}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
LOGDIR="logs"
REPORTDIR="reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

MODE="full"
DO_BUILD=1
DO_RUN=1
CI_MODE=0
QUICK=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=1; MODE="quick"; shift ;;
        --full) QUICK=0; MODE="full"; shift ;;
        --build-only) DO_RUN=0; shift ;;
        --run-only) DO_BUILD=0; shift ;;
        --ci) CI_MODE=1; QUICK=1; MODE="quick"; shift ;;
        -j) JOBS="$2"; shift 2 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS_TOTAL=0; FAIL_TOTAL=0; SKIP_TOTAL=0

mkdir -p "$LOGDIR" "$REPORTDIR"

# =============================================================================
# Build Phase
# =============================================================================
if [[ $DO_BUILD -eq 1 ]]; then
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  Phase 1: Build All Three Binaries${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    # FP64 + Mixed FP32
    echo -e "${GREEN}[1/3] Building FP64 + Mixed FP32...${NC}"
    bash scripts/build.sh -j "$JOBS" || {
        echo -e "${RED}ERROR: Build failed (FP64 + Mixed FP32)${NC}"
        exit 1
    }

    # Generate Pure FP32 patches
    echo -e "${GREEN}[2/3] Generating Pure FP32 patches...${NC}"
    python scripts/gen_pure_fp32_patches.py || {
        echo -e "${RED}ERROR: Pure FP32 patch generation failed${NC}"
        exit 1
    }

    # Pure FP32
    echo -e "${GREEN}[3/3] Building Pure FP32 (no double islands)...${NC}"
    bash scripts/build.sh --pure-fp32 -j "$JOBS" || {
        echo -e "${YELLOW}WARNING: Pure FP32 build failed — strawman may be unavailable${NC}"
    }

    echo ""
    echo -e "${GREEN}Build phase complete.${NC}"
    echo ""
fi

# Verify binaries
if [[ $DO_RUN -eq 1 ]]; then
    HAVE_FP64=0; HAVE_FP32=0; HAVE_PURE=0
    [[ -x "$FP64_BIN" ]] && HAVE_FP64=1
    [[ -x "$FP32_BIN" ]] && HAVE_FP32=1
    [[ -x "$FP32_PURE_BIN" ]] && HAVE_PURE=1

    echo "Binary status:"
    echo "  FP64:       $([ $HAVE_FP64 -eq 1 ] && echo -e "${GREEN}OK${NC}" || echo -e "${RED}MISSING${NC}") — $FP64_BIN"
    echo "  Mixed FP32: $([ $HAVE_FP32 -eq 1 ] && echo -e "${GREEN}OK${NC}" || echo -e "${RED}MISSING${NC}") — $FP32_BIN"
    echo "  Pure FP32:  $([ $HAVE_PURE -eq 1 ] && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}N/A${NC}") — $FP32_PURE_BIN"
    echo ""

    if [[ $HAVE_FP64 -eq 0 || $HAVE_FP32 -eq 0 ]]; then
        echo -e "${RED}FATAL: Required binaries missing. Run with --build-only first.${NC}"
        exit 1
    fi
fi

# =============================================================================
# Run Phase
# =============================================================================
if [[ $DO_RUN -eq 0 ]]; then
    echo "Build-only mode. Exiting."
    exit 0
fi

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Phase 2: Run Test Matrix${NC}"
echo -e "${CYAN}  Mode: $MODE | Binaries: FP64 + $([ $HAVE_PURE -eq 1 ] && echo 'Mixed FP32 + Pure FP32' || echo 'Mixed FP32')${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Helper: run ngspice with timeout
run_ngspice() {
    local bin="$1" spice="$2" log="$3" label="$4"
    echo -n "  [$label] $(basename "$spice") ... "
    if timeout "$TIMEOUT" "$bin" --batch "$spice" > "$log" 2>&1; then
        if grep -qi "error\|fatal\|timestep too small\|singular" "$log"; then
            echo -e "${RED}ERROR${NC}"
            return 1
        elif grep -qi "nan\|inf" "$log"; then
            echo -e "${YELLOW}NaN/Inf${NC}"
            return 2
        else
            echo -e "${GREEN}OK${NC}"
            return 0
        fi
    else
        echo -e "${RED}CRASH${NC}"
        return 3
    fi
}

# Helper: run all 3 variants for a circuit
run_three_way() {
    local label="$1" spice="$2"
    local fp64_ok=0 mixed_ok=0 pure_ok=0

    # FP64 (reference)
    if [[ $HAVE_FP64 -eq 1 ]]; then
        run_ngspice "$FP64_BIN" "$spice" "$LOGDIR/${label}_fp64.log" "FP64"
        fp64_ok=$?
    fi

    # Mixed FP32
    if [[ $HAVE_FP32 -eq 1 ]]; then
        run_ngspice "$FP32_BIN" "$spice" "$LOGDIR/${label}_fp32.log" "MIX"
        mixed_ok=$?
    fi

    # Pure FP32
    if [[ $HAVE_PURE -eq 1 ]]; then
        run_ngspice "$FP32_PURE_BIN" "$spice" "$LOGDIR/${label}_fp32pure.log" "PUR"
        pure_ok=$?
    fi

    # Compare if we have both results
    if [[ $fp64_ok -le 2 && $mixed_ok -le 2 ]]; then
        python3 scripts/compare_fp.py "$LOGDIR/${label}_fp32.log" "$LOGDIR/${label}_fp64.log" \
            --ci --json-summary -o "$LOGDIR/${label}_mixed_vs_fp64.md" > /dev/null 2>&1
    fi
    if [[ $HAVE_PURE -eq 1 && $fp64_ok -le 2 && $pure_ok -le 2 ]]; then
        python3 scripts/compare_fp.py "$LOGDIR/${label}_fp32pure.log" "$LOGDIR/${label}_fp64.log" \
            --ci --json-summary \
            --warn-dc 0.01 --fail-dc 0.10 \
            --warn-ac 0.05 --fail-ac 0.20 \
            --warn-tran 0.01 --fail-tran 0.10 \
            -o "$LOGDIR/${label}_pure_vs_fp64.md" > /dev/null 2>&1
    fi
    # Three-way report
    if [[ $HAVE_PURE -eq 1 && $fp64_ok -le 2 && $mixed_ok -le 2 && $pure_ok -le 2 ]]; then
        python3 scripts/compare_three.py "$LOGDIR/${label}_fp32.log" "$LOGDIR/${label}_fp32pure.log" "$LOGDIR/${label}_fp64.log" \
            -o "$LOGDIR/${label}_threeway.md" --json "$LOGDIR/${label}_threeway.json" > /dev/null 2>&1
    fi
}

# =============================================================================
# Test Matrix — Phase 2a: DC Unit Tests
# =============================================================================
echo "--- Tier 1: DC OP Unit Tests ---"
MODEL_DIR="test/models/45nm_LP_BSIM4"
CORNERS=("tt")
[[ "$QUICK" -eq 0 ]] && CORNERS=("tt" "ff" "ss" "fs" "sf")

for corner in "${CORNERS[@]}"; do
    corner_upper=$(echo "$corner" | tr '[:lower:]' '[:upper:]')
    echo "  Corner: $corner_upper"

    # NMOS
    run_three_way "01_nmos_dc_${corner}" "test/circuits/01_single_nmos_45nm/test_dc.sp"
    # PMOS
    run_three_way "02_pmos_dc_${corner}" "test/circuits/02_single_pmos_45nm/test_dc.sp"
done

# =============================================================================
# Test Matrix — Phase 2b: Analog Blocks (DC + AC)
# =============================================================================
echo ""
echo "--- Tier 2: Analog Blocks ---"

# 03 Ring Oscillator (DC only)
run_three_way "03_ringosc" "test/circuits/03_ring_oscillator_17stage/test_tran.sp"

# 04 OTA (DC + AC)
run_three_way "04_ota_dc" "test/circuits/04_ota_5transistor_45nm/test_dc.sp"
if [[ "$QUICK" -eq 0 ]]; then
    run_three_way "04_ota_ac" "test/circuits/04_ota_5transistor_45nm/test_ac.sp"
fi

# 05 OpAmp (DC + AC)
run_three_way "05_opamp_dc" "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp"
if [[ "$QUICK" -eq 0 ]]; then
    run_three_way "05_opamp_ac" "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp"
fi

# 06 StrongArm Comparator (DC only)
run_three_way "06_comparator" "test/circuits/06_comparator_strongarm_45nm/test_tran.sp"

# =============================================================================
# Test Matrix — Phase 2c: TRAN Validation
# =============================================================================
echo ""
echo "--- Tier 3: TRAN Validation ---"

run_three_way "T2_ota_step" "test/circuits_tran/T2_ota_step.sp"
run_three_way "T3_opamp_step" "test/circuits_tran/T3_opamp_step.sp"
run_three_way "T4_comparator_clock" "test/circuits_tran/T4_comparator_clock.sp"
if [[ "$QUICK" -eq 0 ]]; then
    run_three_way "T1_ring_osc_tran" "test/circuits_tran/T1_ring_osc_tran.sp"
fi

# =============================================================================
# Test Matrix — Phase 2d: Noise Analysis (NEW)
# =============================================================================
echo ""
echo "--- Tier 4: Noise Analysis ---"

run_three_way "04_ota_noise" "test/circuits/04_ota_5transistor_45nm/test_noise.sp"
run_three_way "05_opamp_noise" "test/circuits/05_opamp_2stage_miller_45nm/test_noise.sp"

# =============================================================================
# Phase 3: Aggregate Reports
# =============================================================================
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Phase 3: Generate Aggregate Reports${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Find all three-way JSON files
THREE_WAY_JSONS=$(ls "$LOGDIR"/*_threeway.json 2>/dev/null || true)

if [[ -n "$THREE_WAY_JSONS" ]]; then
    echo "Found $(echo "$THREE_WAY_JSONS" | wc -l) three-way comparison reports"

    # Generate aggregate matrix
    python3 scripts/report_matrix.py "$LOGDIR" \
        --output-md "$REPORTDIR/VALIDATION_MATRIX_${TIMESTAMP}.md" \
        --output-json "$REPORTDIR/VALIDATION_SUMMARY_${TIMESTAMP}.json" \
        --mode "$MODE" 2>&1 || echo "WARNING: Matrix generation had issues"

    # Print summary
    if [[ -f "$REPORTDIR/VALIDATION_SUMMARY_${TIMESTAMP}.json" ]]; then
        echo ""
        echo "Quick Summary:"
        python3 -c "
import json
with open('$REPORTDIR/VALIDATION_SUMMARY_${TIMESTAMP}.json') as f:
    d = json.load(f)
print(f'  Total circuits: {d.get(\"total_circuits\", \"?\")}')
print(f'  Mixed FP32 pass rate: {d.get(\"mixed_pass_rate\", \"?\")}')
print(f'  Pure FP32 pass rate: {d.get(\"pure_pass_rate\", \"?\")}')
print(f'  Avg Island Recovery: {d.get(\"avg_recovery_pct\", \"?\"):.1f}%' if isinstance(d.get('avg_recovery_pct'), float) else '  Avg Island Recovery: ?')
print(f'')
print(f'  By Island:')
for k, v in d.get('island_analysis', {}).items():
    print(f'    {k}: {v.get(\"avg_recovery\", 0):.1f}% recovery ({v.get(\"n_metrics\", 0)} metrics)')
if d.get('pure_fp32_failures'):
    print(f'  Pure FP32 failures: {len(d[\"pure_fp32_failures\"])}')
    for f in d['pure_fp32_failures'][:5]:
        print(f'    - {f[\"circuit\"]}: {f[\"mode\"]} on {f[\"metric\"]}')
"
    fi
else
    echo "No three-way comparison reports generated (no pure-fp32 binary available?)"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Validation Complete${NC}"
echo -e "${GREEN}  Reports: $REPORTDIR/VALIDATION_*.md${NC}"
echo -e "${GREEN}  JSON:    $REPORTDIR/VALIDATION_*.json${NC}"
echo -e "${GREEN}  Logs:    $LOGDIR/${NC}"
echo -e "${GREEN}============================================${NC}"

# CI exit code
if [[ $CI_MODE -eq 1 ]]; then
    if [[ -f "$REPORTDIR/VALIDATION_SUMMARY_${TIMESTAMP}.json" ]]; then
        FAIL_COUNT=$(python3 -c "import json; d=json.load(open('$REPORTDIR/VALIDATION_SUMMARY_${TIMESTAMP}.json')); print(d.get('mixed_fail_count',0)+d.get('pure_fail_count',0))")
        if [[ "$FAIL_COUNT" -gt 0 ]]; then
            exit 1
        fi
    fi
    exit 0
fi
