#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice

echo "=========================================="
echo "  POST-REBUILD FP32 VALIDATION (patches 001-015)"
echo "=========================================="
echo ""

passed=0; failed=0; total=0

# --- PTM45 circuits (all 12 test files) ---
echo "=== 1. PTM45 Circuits ==="
for d in /mnt/e/MyResearch/Mixed_ngspice/test/circuits/*/; do
    for sp in "$d"*.sp; do
        [ -f "$sp" ] || continue
        total=$((total+1))
        name=$(basename "$(dirname "$sp")")/$(basename "$sp")
        echo -n "  [$total] $name ... "
        out=$($FP32 -b "$sp" 2>&1)
        outc=$(echo "$out" | grep -v "<<NAN")
        if echo "$outc" | grep -qi "timestep too small"; then
            failed=$((failed+1)); echo "FAIL_TTS"
        elif echo "$outc" | grep -qi "singular matrix"; then
            failed=$((failed+1)); echo "FAIL_SINGULAR"
        elif echo "$outc" | grep -qi "iteration limit reached"; then
            failed=$((failed+1)); echo "FAIL_NOCONV"
        else
            passed=$((passed+1)); echo "PASS"
        fi
    done
done

# --- AnalogSizing circuits ---
echo ""
echo "=== 2. AnalogSizing SMIC180 ==="
for sp in \
    /mnt/e/MyResearch/AnalogSizing/test_nmos.sp \
    /mnt/e/MyResearch/AnalogSizing/test_minimal.sp \
    /mnt/e/MyResearch/AnalogSizing/test_bias.sp \
    /mnt/e/MyResearch/AnalogSizing/test_hardcoded.sp \
    /mnt/e/MyResearch/AnalogSizing/datasweep_row20_dc.sp \
    /mnt/e/MyResearch/AnalogSizing/datasweep_row20.sp \
    /mnt/e/MyResearch/AnalogSizing/test/datasweep_row20_dc_fp32.sp \
    /mnt/e/MyResearch/AnalogSizing/test/opamp_tran_fp32.sp \
; do
    [ -f "$sp" ] || continue
    total=$((total+1))
    name=$(basename "$sp")
    echo -n "  [$total] $name ... "
    out=$($FP32 -b "$sp" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")
    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1)); echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1)); echo "FAIL_SINGULAR"
    elif echo "$outc" | grep -qi "iteration limit reached"; then
        failed=$((failed+1)); echo "FAIL_NOCONV"
    else
        passed=$((passed+1)); echo "PASS"
    fi
done

# --- Analog_blocks SKY130A ---
echo ""
echo "=== 3. Analog_blocks SKY130A ==="
for sp in \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/Bandgap/Netlists/Design/BGR_1.8v/Bandgap1.8v.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/Bandgap/Netlists/Design/BGR_1.8v/Bandgap1.8v_OTA.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/OTA/Netlists/Design/Folded_Cascode/Transistor_1.8v/Folded_Cascode_OTA.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/OTA/Netlists/Design/Miller_OTA/Transitor1.8v/Miller_OTA_NMOS_1.8v.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/LDO/Netlists/Design/LDO_Folded_1.8v/LDO_Folded_1.8v.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/LDO/Netlists/Design/LDO_Folded_1.8v/Error_amplifier_Folded.spice \
    /mnt/e/MyResearch/Analog_blocks/Analog_Blocks/Bandgap/Netlists/Testbench/Bandgap1.8v_meas.spice \
; do
    [ -f "$sp" ] || continue
    total=$((total+1))
    name=$(basename "$sp")
    echo -n "  [$total] $name ... "
    out=$($FP32 -b "$sp" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")
    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1)); echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1)); echo "FAIL_SINGULAR"
    elif echo "$outc" | grep -qi "iteration limit reached"; then
        failed=$((failed+1)); echo "FAIL_NOCONV"
    else
        passed=$((passed+1)); echo "PASS"
    fi
done

# --- AnalogGym SKY130 (ready-to-run) ---
echo ""
echo "=== 4. AnalogGym SKY130 ==="
cd /mnt/e/MyResearch/AnalogGym/AnalogGym/Amplifier/amp_spice_testbench
for cir in TB_Amplifier_ACDC.cir TB_Amplifier_Tran.cir; do
    [ -f "$cir" ] || continue
    total=$((total+1))
    echo -n "  [$total] AMP: $cir ... "
    out=$($FP32 -b "$cir" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")
    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1)); echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1)); echo "FAIL_SINGULAR"
    elif echo "$outc" | grep -qi "iteration limit reached"; then
        failed=$((failed+1)); echo "FAIL_NOCONV"
    else
        passed=$((passed+1)); echo "PASS"
    fi
done

cd "/mnt/e/MyResearch/AnalogGym/AnalogGym/Low Dropout Regulator/ldo_spice_testbench"
total=$((total+1))
echo -n "  [$total] LDO: TB_LDO_ACDC.cir ... "
out=$($FP32 -b TB_LDO_ACDC.cir 2>&1)
outc=$(echo "$out" | grep -v "<<NAN")
if echo "$outc" | grep -qi "timestep too small"; then
    failed=$((failed+1)); echo "FAIL_TTS"
elif echo "$outc" | grep -qi "singular matrix"; then
    failed=$((failed+1)); echo "FAIL_SINGULAR"
else
    passed=$((passed+1)); echo "PASS"
fi

# --- Summary ---
echo ""
echo "=========================================="
echo "  FINAL SUMMARY (POST-REBUILD)"
echo "=========================================="
echo "Total: $total | PASS: $passed | FAIL: $failed"
echo "Pass rate: $(( passed * 100 / total ))%"
