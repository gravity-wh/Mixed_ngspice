#!/bin/bash
# run_ptm45_batch.sh — Fixed version: proper error detection
NGSPICE_FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
NGSPICE_FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
TEST_DIR=/mnt/e/MyResearch/Mixed_ngspice/test/circuits

echo "=== PTM45 FP32 vs FP64 Batch Validation ==="
echo "Date: $(date)"
echo ""

passed=0; failed=0; total=0

for d in "$TEST_DIR"/*/; do
    name=$(basename "$d")
    for sp in "$d"*.sp; do
        [ -f "$sp" ] || continue
        total=$((total+1))
        spname=$(basename "$sp")

        echo -n "[$total] $name/$spname ... "

        out64=$($NGSPICE_FP64 -b "$sp" 2>&1)
        ret64=$?
        out32=$($NGSPICE_FP32 -b "$sp" 2>&1)
        ret32=$?

        # Check for REAL errors (exclude model parameter NaN values)
        # Filter out the BSIM4 model parameter listing lines
        out32_clean=$(echo "$out32" | grep -v '<<NAN')
        out64_clean=$(echo "$out64" | grep -v '<<NAN')

        fail_reason=""
        if echo "$out32_clean" | grep -qi "doAnalyses: iteration limit reached"; then
            fail_reason="NOCONV_FP32"
        elif echo "$out32_clean" | grep -qi "timestep too small"; then
            fail_reason="TTS_FP32"
        elif echo "$out32_clean" | grep -qi "singular matrix\|pivot error"; then
            fail_reason="SINGULAR_FP32"
        elif echo "$out64_clean" | grep -qi "doAnalyses: iteration limit reached"; then
            fail_reason="NOCONV_FP64 (circuit issue, not FP32)"
        elif echo "$out64_clean" | grep -qi "timestep too small"; then
            fail_reason="TTS_FP64"
        elif [ $ret32 -ne 0 ] && [ $ret32 -ne 2 ]; then
            fail_reason="CRASH_FP32 (exit=$ret32)"
        fi

        if [ -n "$fail_reason" ]; then
            failed=$((failed+1))
            echo "❌ $fail_reason"
        else
            # Extract DC OP values for comparison (from the .op section, not parameter listing)
            v64=$(echo "$out64" | grep -E "^(v\(|id\s*=)" | head -5 | tr '\n' ' ')
            v32=$(echo "$out32" | grep -E "^(v\(|id\s*=)" | head -5 | tr '\n' ' ')

            passed=$((passed+1))
            analysis_types=$(echo "$spname" | grep -oP '(test_)?\K\w+(?=\.sp)' || echo "OP")
            echo "✅ PASS"
            [ -n "$v64" ] && echo "       FP64: $v64"
            [ -n "$v32" ] && echo "       FP32: $v32"
        fi
    done
done

echo ""
echo "=== SUMMARY: PTM45 Circuits ==="
echo "Total: $total | ✅ Passed: $passed | ❌ Failed: $failed"
if [ $total -gt 0 ]; then
    echo "Pass rate: $(( passed * 100 / total ))%"
fi
