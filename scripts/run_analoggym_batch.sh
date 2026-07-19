#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
GYM=/mnt/e/MyResearch/AnalogGym/AnalogGym

echo "=== AnalogGym SKY130 FP32 vs FP64 ==="
echo ""

# Test 1: AMP ACDC
echo "--- [1] AMP ACDC ---"
cd "$GYM/Amplifier/amp_spice_testbench"
echo -n "  FP64 ... "
out64=$($FP64 -b TB_Amplifier_ACDC.cir 2>&1)
out64c=$(echo "$out64" | grep -v "<<NAN")
if echo "$out64c" | grep -qi "timestep too small\|iteration limit reached"; then
    echo "FAIL_TTS/NOCONV"
else
    # Extract key metrics
    gain=$(echo "$out64" | grep -oP 'gain\s*=\s*\S+' | head -1)
    pm=$(echo "$out64" | grep -oP 'pm\s*=\s*\S+' | head -1)
    ugbw=$(echo "$out64" | grep -oP 'ugbw\s*=\s*\S+' | head -1)
    echo "OK ($gain $pm $ugbw)"
fi

echo -n "  FP32 ... "
out32=$($FP32 -b TB_Amplifier_ACDC.cir 2>&1)
out32c=$(echo "$out32" | grep -v "<<NAN")
if echo "$out32c" | grep -qi "timestep too small"; then
    echo "FAIL_TTS"
elif echo "$out32c" | grep -qi "iteration limit reached"; then
    echo "FAIL_NOCONV"
else
    gain=$(echo "$out32" | grep -oP 'gain\s*=\s*\S+' | head -1)
    pm=$(echo "$out32" | grep -oP 'pm\s*=\s*\S+' | head -1)
    ugbw=$(echo "$out32" | grep -oP 'ugbw\s*=\s*\S+' | head -1)
    echo "OK ($gain $pm $ugbw)"
fi

# Test 2: AMP TRAN
echo "--- [2] AMP TRAN ---"
cd "$GYM/Amplifier/amp_spice_testbench"
echo -n "  FP64 ... "
out64=$($FP64 -b TB_Amplifier_Tran.cir 2>&1)
out64c=$(echo "$out64" | grep -v "<<NAN")
if echo "$out64c" | grep -qi "timestep too small\|iteration limit reached"; then
    echo "FAIL"
else
    sr=$(echo "$out64" | grep -oP 'sr_pos\s*=\s*\S+' | head -1)
    echo "OK ($sr)"
fi

echo -n "  FP32 ... "
out32=$($FP32 -b TB_Amplifier_Tran.cir 2>&1)
out32c=$(echo "$out32" | grep -v "<<NAN")
if echo "$out32c" | grep -qi "timestep too small"; then
    echo "FAIL_TTS"
elif echo "$out32c" | grep -qi "iteration limit reached"; then
    echo "FAIL_NOCONV"
else
    sr=$(echo "$out32" | grep -oP 'sr_pos\s*=\s*\S+' | head -1)
    echo "OK ($sr)"
fi

# Test 3: LDO ACDC
echo "--- [3] LDO ACDC ---"
cd "$GYM/Low Dropout Regulator/ldo_spice_testbench"
echo -n "  FP64 ... "
out64=$($FP64 -b TB_LDO_ACDC.cir 2>&1)
out64c=$(echo "$out64" | grep -v "<<NAN")
if echo "$out64c" | grep -qi "timestep too small\|iteration limit reached"; then
    echo "FAIL"
else
    vout=$(echo "$out64" | grep -oP 'vout\s*=\s*\S+' | head -1)
    echo "OK ($vout)"
fi

echo -n "  FP32 ... "
out32=$($FP32 -b TB_LDO_ACDC.cir 2>&1)
out32c=$(echo "$out32" | grep -v "<<NAN")
if echo "$out32c" | grep -qi "timestep too small"; then
    echo "FAIL_TTS"
elif echo "$out32c" | grep -qi "iteration limit reached"; then
    echo "FAIL_NOCONV"
else
    vout=$(echo "$out32" | grep -oP 'vout\s*=\s*\S+' | head -1)
    echo "OK ($vout)"
fi

echo ""
echo "=== AnalogGym Complete ==="
