#!/bin/bash
# run_new_circuits_batch.sh — FP32 vs FP64 validation for new Arcadia-1 circuits
# Tests: five_transistor_ota, two_stage_opamp, LDO
# Checks: exit code, NaN, TTS, NOCONV, SINGULAR

FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
TEST_DIR=/mnt/e/MyResearch/Mixed_ngspice/test

# Verify binaries exist
if [ ! -f "$FP32" ]; then echo "ERROR: FP32 binary not found: $FP32"; exit 1; fi
if [ ! -f "$FP64" ]; then echo "ERROR: FP64 binary not found: $FP64"; exit 1; fi

# ===================================================================
# Circuit netlists to test
# ===================================================================
declare -A CIRCUIT_NAMES
NETLISTS=()

# --- five_transistor_ota ---
OTA_DIR="$TEST_DIR/ota_work/netlists/testbench"
for f in "$OTA_DIR"/ota_dc.cir "$OTA_DIR"/ota_ac.cir "$OTA_DIR"/ota_noise.cir; do
    [ -f "$f" ] && NETLISTS+=("$f") && CIRCUIT_NAMES["$f"]="OTA"
done

# --- two_stage_opamp ---
OPAMP_DIR="$TEST_DIR/opamp_work/netlists/testbench"
for f in "$OPAMP_DIR"/opamp_dc.cir "$OPAMP_DIR"/opamp_ac.cir \
         "$OPAMP_DIR"/opamp_pz.cir "$OPAMP_DIR"/opamp_noise.cir \
         "$OPAMP_DIR"/opamp_noise_unity.cir; do
    [ -f "$f" ] && NETLISTS+=("$f") && CIRCUIT_NAMES["$f"]="OPAMP"
done

# --- LDO ---
LDO_DIR="$TEST_DIR/ldo_work/netlists/testbench"
for f in "$LDO_DIR"/ldo_dc.cir "$LDO_DIR"/ldo_ac_loopgain.cir \
         "$LDO_DIR"/ldo_ac_psrr.cir "$LDO_DIR"/ldo_noise.cir \
         "$LDO_DIR"/ldo_tran.cir; do
    [ -f "$f" ] && NETLISTS+=("$f") && CIRCUIT_NAMES["$f"]="LDO"
done

echo "============================================================"
echo "  Mixed_ngspice FP32 vs FP64 — New Circuit Batch Test"
echo "============================================================"
echo "  FP32: $FP32"
echo "  FP64: $FP64"
echo "  Circuits to test: ${#NETLISTS[@]}"
echo ""

total=0; passed=0; failed=0
declare -A FAIL_REASONS

for f in "${NETLISTS[@]}"; do
    total=$((total+1))
    fname=$(basename "$f")
    circuit="${CIRCUIT_NAMES[$f]}"
    echo -n "[$total] $circuit/$fname ... "

    out64=$($FP64 -b "$f" 2>&1)
    ret64=$?
    out32=$($FP32 -b "$f" 2>&1)
    ret32=$?

    reason=""
    # Check for NaN
    if echo "$out32" | grep -q "<<NAN\|nan\|NaN"; then
        reason="NaN_FP32"
    elif echo "$out64" | grep -q "<<NAN\|nan\|NaN"; then
        reason="NaN_FP64"
    # Check convergence failures
    elif echo "$out32" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32" | grep -qi "doAnalyses: iteration limit reached"; then
        reason="NOCONV_FP32"
    elif echo "$out32" | grep -qi "singular matrix"; then
        reason="SINGULAR_FP32"
    elif echo "$out64" | grep -qi "timestep too small"; then
        reason="TTS_FP64"
    elif echo "$out64" | grep -qi "doAnalyses: iteration limit reached"; then
        reason="NOCONV_FP64"
    elif echo "$out64" | grep -qi "singular matrix"; then
        reason="SINGULAR_FP64"
    # Check abnormal exits
    elif [ $ret32 -ne 0 ] && [ $ret32 -ne 1 ] && [ $ret32 -ne 2 ]; then
        reason="EXIT_${ret32}_FP32"
    elif [ $ret64 -ne 0 ] && [ $ret64 -ne 1 ] && [ $ret64 -ne 2 ]; then
        reason="EXIT_${ret64}_FP64"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        FAIL_REASONS["$reason"]=$(( ${FAIL_REASONS["$reason"]} + 1 ))
        echo "FAIL: $reason"
    else
        passed=$((passed+1))
        echo "PASS (FP32=$ret32, FP64=$ret64)"
    fi
done

echo ""
echo "============================================================"
echo "RESULTS SUMMARY"
echo "============================================================"
echo "  Total:  $total"
echo "  Passed: $passed"
echo "  Failed: $failed"
echo ""

if [ $failed -gt 0 ]; then
    echo "Failure breakdown:"
    for reason in "${!FAIL_REASONS[@]}"; do
        echo "  $reason: ${FAIL_REASONS[$reason]}"
    done
    echo ""
    echo "❌ SOME TESTS FAILED"
    exit 1
else
    echo "✅ ALL TESTS PASSED"
    exit 0
fi
