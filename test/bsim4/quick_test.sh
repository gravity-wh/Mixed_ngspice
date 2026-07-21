#!/bin/bash
# Quick test of all three BSIM4 circuits
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
TB=/mnt/e/MyResearch/Mixed_ngspice/test/bsim4/testbenches
LOG=/mnt/e/MyResearch/Mixed_ngspice/test/bsim4/quick_test.log

{
echo "============================================"
echo "  BSIM4 Circuit Quick Test"
echo "  $(date)"
echo "============================================"

echo ""
echo "--- OTA DC (FP64) ---"
$FP64 -b $TB/ota_dc_bsim4.cir 2>&1 | grep -E "v\(|Error|failed|singular|Doing"

echo ""
echo "--- OPAMP DC (FP64) ---"
$FP64 -b $TB/opamp_dc_bsim4.cir 2>&1 | grep -E "v\(|Error|failed|singular|Doing"

echo ""
echo "--- LDO DC (FP64) ---"
$FP64 -b $TB/ldo_dc_bsim4.cir 2>&1 | grep -E "v\(|vout|Error|failed|singular|Doing"

echo ""
echo "============================================"
echo "  FP32 vs FP64 Batch Comparison"
echo "============================================"

total=0; passed=0; failed=0
for cir in ota_dc opamp_dc ldo_dc; do
    total=$((total+1))
    echo -n "[$total] ${cir}_bsim4.cir ... "

    out64=$($FP64 -b $TB/${cir}_bsim4.cir 2>&1)
    ret64=$?
    out32=$($FP32 -b $TB/${cir}_bsim4.cir 2>&1)
    ret32=$?

    reason=""
    if echo "$out32" | grep -qi "error\|failed\|singular"; then
        reason="ERROR_FP32"
    elif echo "$out64" | grep -qi "error\|failed\|singular"; then
        reason="ERROR_FP64"
    elif echo "$out32" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32" | grep -qi "iteration limit"; then
        reason="NOCONV_FP32"
    elif [ $ret32 -ne 0 ] && [ $ret32 -ne 1 ]; then
        reason="EXIT_${ret32}_FP32"
    elif [ $ret64 -ne 0 ] && [ $ret64 -ne 1 ]; then
        reason="EXIT_${ret64}_FP64"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        echo "FAIL: $reason"
    else
        passed=$((passed+1))
        echo "PASS (FP32=$ret32, FP64=$ret64)"

        # Extract and compare DC values
        v32=$(echo "$out32" | grep "v(out)" | head -1 | awk '{print $NF}')
        v64=$(echo "$out64" | grep "v(out)" | head -1 | awk '{print $NF}')
        if [ -n "$v32" ] && [ -n "$v64" ]; then
            echo "       Vout: FP32=$v32  FP64=$v64"
        fi
    fi
done

echo ""
echo "RESULTS: $total circuits | $passed PASSED | $failed FAILED"
if [ $failed -eq 0 ]; then
    echo "ALL PASSED"
else
    echo "SOME FAILED"
fi
} | tee $LOG
