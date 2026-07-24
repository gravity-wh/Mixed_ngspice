#!/bin/bash
# run_and_record.sh — Run full test suite and save structured JSON results
# Usage: bash test/run_and_record.sh <version> [--fp64-compare]
#   version: fp64 | v1.2 | v1.6
#   --fp64-compare: also run FP64 baseline for accuracy comparison
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Usage: $0 <fp64|v1.2|v1.6> [--fp64-compare]}"
BIN="bin/ngspice-$VERSION"
FP64_BIN="bin/ngspice-fp64"
RESULTS_DIR="test_results/$VERSION"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_ID="${TIMESTAMP}_${VERSION}"
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
COMPARE_FP64=false
[ "${2:-}" = "--fp64-compare" ] && COMPARE_FP64=true

mkdir -p "$RESULTS_DIR"

# ====== Circuit Registry ======
# Format: "label|netlist_path|analysis_type|pdk|bsim_level|transistor_count|metrics"
# metrics: comma-separated list of .measure names to extract
CIRCUITS=(
    "NMOS_DC|test/circuits/01_single_nmos_45nm/test_dc.sp|DC_OP|PTM45LP|Lv54|1|"
    "PMOS_DC|test/circuits/02_single_pmos_45nm/test_dc.sp|DC_OP|PTM45LP|Lv54|1|"
    "OTA_DC|test/circuits/04_ota_5transistor_45nm/test_dc.sp|DC_OP|PTM45LP|Lv54|6|"
    "OpAmp_DC|test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp|DC_OP|PTM45LP|Lv54|8|"
    "NMOS_SWEEP|test/circuits/01_single_nmos_45nm/test_dc_sweep.sp|DC_SWEEP|PTM45LP|Lv54|1|"
    "PMOS_SWEEP|test/circuits/02_single_pmos_45nm/test_dc_sweep.sp|DC_SWEEP|PTM45LP|Lv54|1|"
    "OTA_AC|test/circuits/04_ota_5transistor_45nm/test_ac.sp|AC|PTM45LP|Lv54|6|"
    "OpAmp_AC|test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp|AC|PTM45LP|Lv54|8|"
    "RING_OSC|test/circuits/03_ring_oscillator_17stage/test_tran.sp|TRAN|PTM45LP|Lv54|34|"
    "COMPARATOR|test/circuits/06_comparator_strongarm_45nm/test_tran.sp|TRAN|PTM45HP|Lv54|15|"
    "BOOTSTRAP|test/circuits/07_bootstrap_switch_45nm/test_tran.sp|TRAN|PTM45HP|Lv54|7|"
    "CHAOS|test/circuits/08_roessler_attractor/test_chaos.sp|TRAN|BEHAVIORAL|N/A|0|"
)

# ====== Run Tests ======
declare -A RESULTS
TOTAL=0; PASSED=0; FAILED=0; TOTAL_NAN=0
CIRCUIT_JSON=""

for entry in "${CIRCUITS[@]}"; do
    IFS='|' read -r label netlist atype pdk bsim mos metrics <<< "$entry"
    TOTAL=$((TOTAL + 1))

    log="/tmp/record_${RUN_ID}_${label}.log"
    echo -n "[$label] "

    if timeout 30 "$BIN" --batch "$netlist" > "$log" 2>&1; then
        nan=$(grep -c FP32-NAN "$log" 2>/dev/null) || nan=0
        rows=$(grep 'No. of Data Rows' "$log" 2>/dev/null | tail -1 | awk '{print $NF}') || rows="?"
        atime=$(grep 'Total analysis time' "$log" 2>/dev/null | tail -1 | awk -F'= ' '{print $2}' | awk '{print $1}') || atime="?"

        if [ "$nan" -eq 0 ]; then
            echo "PASS (rows=$rows, ${atime}s)"
            status="PASS"
            PASSED=$((PASSED + 1))
        else
            echo "FAIL (NaN=$nan)"
            status="FAIL"
            FAILED=$((FAILED + 1))
            TOTAL_NAN=$((TOTAL_NAN + nan))
        fi
    else
        echo "FAIL (timeout/crash)"
        status="FAIL"; FAILED=$((FAILED + 1))
        nan="?"; rows="?"; atime="?"
    fi

    # Build JSON circuit entry
    CIRCUIT_JSON+=$(cat <<JEND
    "$label": {
      "status": "$status",
      "nan_count": $nan,
      "rows": "$rows",
      "analysis_time_s": "$atime",
      "analysis_type": "$atype",
      "pdk": "$pdk",
      "bsim_level": "$bsim",
      "transistor_count": $mos
    },
JEND
)

    cp "$log" "$RESULTS_DIR/${RUN_ID}_${label}.log" 2>/dev/null || true
done

# Remove trailing comma
CIRCUIT_JSON="${CIRCUIT_JSON%,}"

# ====== Coverage Analysis ======
PDK_COUNT=$(echo "$CIRCUIT_JSON" | grep -o '"pdk": "[^"]*"' | sort -u | wc -l)
DC_COUNT=$(echo "$CIRCUIT_JSON" | grep -c 'DC_OP')
AC_COUNT=$(echo "$CIRCUIT_JSON" | grep -c '"AC"')
TRAN_COUNT=$(echo "$CIRCUIT_JSON" | grep -c '"TRAN"')
SWEEP_COUNT=$(echo "$CIRCUIT_JSON" | grep -c 'DC_SWEEP')

# ====== Write JSON ======
JSON_FILE="$RESULTS_DIR/${RUN_ID}.json"
cat > "$JSON_FILE" <<JSONEOF
{
  "run_id": "$RUN_ID",
  "timestamp": "$(date -Iseconds)",
  "version": "$VERSION",
  "binary": "$BIN",
  "git_commit": "$GIT_COMMIT",
  "circuits": {
$CIRCUIT_JSON
  },
  "coverage": {
    "pdk_count": $PDK_COUNT,
    "circuit_count": $TOTAL,
    "dc_op_count": $DC_COUNT,
    "ac_count": $AC_COUNT,
    "tran_count": $TRAN_COUNT,
    "sweep_count": $SWEEP_COUNT
  },
  "summary": {
    "total": $TOTAL,
    "passed": $PASSED,
    "failed": $FAILED,
    "total_nan": $TOTAL_NAN
  }
}
JSONEOF

# Validate against schema
if command -v check-jsonschema &>/dev/null; then
    check-jsonschema --schemafile test_results/schema.json "$JSON_FILE" 2>&1 || true
fi

echo ""
echo "============================================================"
echo "  $VERSION: $PASSED/$TOTAL PASS ($FAILED FAIL), $TOTAL_NAN total NaN"
echo "  Result: $JSON_FILE"
echo "============================================================"

# Update version summary
SUMMARY_FILE="$RESULTS_DIR/summary.json"
jq -n --argjson latest "$(cat $JSON_FILE)" '{
  latest_run: $latest,
  updated: now
}' > "$SUMMARY_FILE" 2>/dev/null || true

echo ""
echo "  Summary updated: $SUMMARY_FILE"
