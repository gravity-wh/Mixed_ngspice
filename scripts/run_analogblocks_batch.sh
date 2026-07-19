#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
AB=/mnt/e/MyResearch/Analog_blocks/Analog_Blocks

echo "=== Analog_blocks SKY130A FP32 vs FP64 ==="
echo ""

# Find representative circuits from each category
files=()
# Bandgap
files+=("$AB/Bandgap/Netlists/Design/BGR_1.8v/Bandgap1.8v.spice")
files+=("$AB/Bandgap/Netlists/Design/BGR_1.8v/Bandgap1.8v_OTA.spice")
# OTA
files+=("$AB/OTA/Netlists/Design/Folded_Cascode/Transistor_1.8v/Folded_Cascode_OTA.spice")
files+=("$AB/OTA/Netlists/Design/Miller_OTA/Transitor1.8v/Miller_OTA_NMOS_1.8v.spice")
# LDO
files+=("$AB/LDO/Netlists/Design/LDO_Folded_1.8v/LDO_Folded_1.8v.spice")
files+=("$AB/LDO/Netlists/Design/LDO_Folded_1.8v/Error_amplifier_Folded.spice")
# Testbenches
files+=("$AB/Bandgap/Netlists/Testbench/Bandgap1.8v_meas.spice")
files+=("$AB/OTA/Netlists/Testbench/Testbench_OTA")

total=0; passed=0; failed=0

for f in "${files[@]}"; do
    [ -f "$f" ] || { echo "SKIP: $(basename "$f") (not found)"; continue; }
    total=$((total+1))
    fname=$(basename "$f")
    echo -n "[$total] $fname ... "

    out64=$($FP64 -b "$f" 2>&1)
    out32=$($FP32 -b "$f" 2>&1)
    out32c=$(echo "$out32" | grep -v "<<NAN")
    out64c=$(echo "$out64" | grep -v "<<NAN")

    reason=""
    fp64fail=0
    if echo "$out64c" | grep -qi "timestep too small\|iteration limit reached"; then
        fp64fail=1
    fi

    if echo "$out32c" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32c" | grep -qi "iteration limit reached"; then
        reason="NOCONV_FP32"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        fp64tag="OK"
        [ $fp64fail -eq 1 ] && fp64tag="ALSO_FAIL"
        echo "FAIL: $reason (FP64: $fp64tag)"
    else
        passed=$((passed+1))
        echo "PASS"
    fi
done

echo ""
echo "=== Analog_blocks Summary: $total circuits | PASS: $passed | FAIL: $failed ==="
