#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
SKILLS=/mnt/e/MyResearch/analog-circuit-skills
mkdir -p "$SKILLS/.work_comparator/logs"

echo "=== analog-circuit-skills FP32 vs FP64 ==="
echo ""

files=(
    "$SKILLS/.work_comparator/netlists/testbench/strongarm_wave_vin+1mv.cir"
    "$SKILLS/.work_comparator/netlists/testbench/strongarm_ramp.cir"
    "$SKILLS/.work_comparator/netlists/testbench/strongarm_noise_vin+1.00mv.cir"
    "$SKILLS/.work_comparator/netlists/testbench/strongarm_noise_vin+0.35mv.cir"
    "$SKILLS/.work_comparator/netlists/testbench/strongarm_noise_vin+0.00mv.cir"
)

total=0; passed=0; failed=0

for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    total=$((total+1))
    fname=$(basename "$f")
    echo -n "[$total] $fname ... "

    out64=$($FP64 -b "$f" 2>&1)
    ret64=$?
    out32=$($FP32 -b "$f" 2>&1)
    ret32=$?

    # Remove model parameter NaN values from output
    out32c=$(echo "$out32" | grep -v "<<NAN")
    out64c=$(echo "$out64" | grep -v "<<NAN")

    reason=""
    if echo "$out32c" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32c" | grep -qi "doAnalyses: iteration limit reached"; then
        reason="NOCONV_FP32"
    elif echo "$out32c" | grep -qi "singular matrix"; then
        reason="SINGULAR_FP32"
    elif echo "$out64c" | grep -qi "timestep too small"; then
        reason="TTS_FP64"
    elif [ $ret32 -ne 0 ] && [ $ret32 -ne 2 ]; then
        reason="EXIT_${ret32}_FP32"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        echo "FAIL: $reason"
    else
        passed=$((passed+1))
        echo "PASS (FP32=$ret32, FP64=$ret64)"
    fi
done

echo ""
echo "=== StrongARM: $total circuits | PASS: $passed | FAIL: $failed ==="
