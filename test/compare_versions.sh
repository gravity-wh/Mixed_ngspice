#!/bin/bash
# compare_versions.sh — Run all tests across all available versions, compare results
# Usage: bash test/compare_versions.sh [v1.2] [v1.6] [fp64]
set -euo pipefail
cd "$(dirname "$0")/.."

BIN_DIR="bin"
RESULTS="test_results/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS"

# Auto-detect available binaries
VERSIONS=()
for ver in fp64 v1.2 v1.6; do
    [ -x "$BIN_DIR/ngspice-$ver" ] && VERSIONS+=("$ver")
done
# Allow user override
[ $# -gt 0 ] && VERSIONS=("$@")

echo "============================================================"
echo "  Multi-Version Comparison Test"
echo "  Versions: ${VERSIONS[*]}"
echo "  Results:  $RESULTS"
echo "============================================================"
echo ""

# Test circuits (category → netlist)
declare -A TESTS=(
    ["NMOS_DC"]="test/circuits/01_single_nmos_45nm/test_dc.sp"
    ["PMOS_DC"]="test/circuits/02_single_pmos_45nm/test_dc.sp"
    ["OTA_DC"]="test/circuits/04_ota_5transistor_45nm/test_dc.sp"
    ["OpAmp_DC"]="test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp"
)

for ver in "${VERSIONS[@]}"; do
    bin="$BIN_DIR/ngspice-$ver"
    ver_dir="$RESULTS/$ver"
    mkdir -p "$ver_dir"

    echo "--- $ver ---"
    for name in "${!TESTS[@]}"; do
        netlist="${TESTS[$name]}"
        log="$ver_dir/${name}.log"
        echo -n "  $name ... "
        if timeout 30 "$bin" --batch "$netlist" > "$log" 2>&1; then
            nan=$(grep -c FP32-NAN "$log" 2>/dev/null) || nan=0
            echo "NaN=$nan"
        else
            echo "TIMEOUT/CRASH"
        fi
    done
    echo ""
done

# Quick comparison table
echo "============================================================"
echo "  NaN Summary"
echo "============================================================"
printf "  %-15s" "Circuit"
for ver in "${VERSIONS[@]}"; do printf " %8s" "$ver"; done
echo ""
for name in "${!TESTS[@]}"; do
    printf "  %-15s" "$name"
    for ver in "${VERSIONS[@]}"; do
        log="$RESULTS/$ver/${name}.log"
        if [ -f "$log" ]; then
            nan=$(grep -c FP32-NAN "$log" 2>/dev/null) || nan=0
            printf " %8s" "$nan"
        else
            printf " %8s" "?"
        fi
    done
    echo ""
done
echo ""
echo "  Results saved to: $RESULTS"
