#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
AS=/mnt/e/MyResearch/AnalogSizing

echo "=== AnalogSizing SMIC 180nm BCD FP32 vs FP64 ==="
echo ""

files=(
    "$AS/test_nmos.sp"
    "$AS/test_minimal.sp"
    "$AS/test_bias.sp"
    "$AS/test_hardcoded.sp"
    "$AS/datasweep_row20_dc.sp"
    "$AS/datasweep_row20.sp"
    "$AS/test/datasweep_row20_dc_fp32.sp"
    "$AS/test/opamp_tran_fp32.sp"
)

total=0; passed=0; failed=0; fp64fail=0

for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    total=$((total+1))
    fname=$(basename "$f")
    echo -n "[$total] $fname ... "

    out64=$($FP64 -b "$f" 2>&1)
    ret64=$?
    out32=$($FP32 -b "$f" 2>&1)
    ret32=$?

    # Clean model parameter NaN values
    out32c=$(echo "$out32" | grep -v "<<NAN")
    out64c=$(echo "$out64" | grep -v "<<NAN")

    reason=""
    if echo "$out64c" | grep -qi "error\|fatal\|timestep too small\|iteration limit reached"; then
        fp64fail=$((fp64fail+1))
    fi

    if echo "$out32c" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32c" | grep -qi "doAnalyses: iteration limit reached"; then
        reason="NOCONV_FP32"
    elif echo "$out32c" | grep -qi "singular matrix"; then
        reason="SINGULAR_FP32"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        # Also check FP64 status
        fp64ok="OK"
        echo "$out64c" | grep -qi "error\|fatal\|timestep\|iteration" && fp64ok="ALSO_FAIL"
        echo "FAIL: $reason (FP64: $fp64ok)"
    else
        passed=$((passed+1))
        # Extract key DC values
        v64=$(echo "$out64" | grep -E "^v\(|^id " | head -2 | tr '\n' ' ')
        v32=$(echo "$out32" | grep -E "^v\(|^id " | head -2 | tr '\n' ' ')
        echo "PASS"
        [ -n "$v64" ] && echo "       FP64: $v64"
        [ -n "$v32" ] && echo "       FP32: $v32"
    fi
done

echo ""
echo "=== AnalogSizing Summary: $total circuits | PASS: $passed | FAIL: $failed (FP64 also fails: $fp64fail) ==="
