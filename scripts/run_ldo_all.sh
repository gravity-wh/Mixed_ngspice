#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
LDO=/mnt/e/MyResearch/AnalogGym/AnalogGym/Low\ Dropout\ Regulator/ldo_spice_testbench

echo "=== AnalogGym LDO: 4 variants FP32 ==="
echo ""

variants=(ldo_1 ldo_2 ldo_simple ldo_folded_cascode)
passed=0; failed=0

for v in "${variants[@]}"; do
    cir="$LDO/${v}_acdc.cir"
    [ -f "$cir" ] || { echo "  SKIP $v (no testbench)"; continue; }

    echo -n "  $v ... "

    # Fix broken paths: ../simulations/XXX → correct path
    sed "s|\.include\s\+\.\./simulations/${v}.txt|.include ../design_variables/${v}.txt|g" "$cir" | \
    sed "s|\.include\s\+\.\./simulations/${v}_vars.spice|.include ../spice_netlist/${v}_vars.spice|g" | \
    sed "s|\.include\s\+\.\./simulations/${v}_dev_params.spice|.include ../spice_netlist/${v}_dev_params.spice|g" \
    > "/tmp/ldo_${v}_fixed.cir"

    out=$($FP32 -b "/tmp/ldo_${v}_fixed.cir" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")

    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1)); echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1)); echo "FAIL_SING"
    elif echo "$outc" | grep -qi "iteration limit"; then
        failed=$((failed+1)); echo "FAIL_NOCONV"
    elif echo "$outc" | grep -qi "unknown subckt\|no definition\|no such file\|include.*error\|cannot find\|can't open"; then
        failed=$((failed+1))
        err=$(echo "$outc" | grep -i "unknown subckt\|no definition\|no such file\|can't open\|cannot find" | head -1)
        echo "FAIL_INCLUDE: $err"
    else
        passed=$((passed+1))
        vout=$(echo "$out" | grep -oP 'vout\s*=\s*\S+' | head -1)
        echo "PASS ($vout)"
    fi
    rm -f "/tmp/ldo_${v}_fixed.cir"
done

echo ""
echo "=== LDO Summary: $passed/4 PASS ==="
