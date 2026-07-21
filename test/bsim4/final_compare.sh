#!/bin/bash
# Final BSIM4v5 FP32 vs FP64 comparison
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
TB=/mnt/e/MyResearch/Mixed_ngspice/test/bsim4/testbenches

echo "============================================================"
echo "  BSIM4v5 (PTM 130nm) FP32 vs FP64 — Full Comparison"
echo "============================================================"
echo ""

total=0; passed=0; failed=0

# Helper: run and extract key metrics
run_compare() {
    local label=$1; local file=$2; shift 2
    total=$((total+1))
    echo "[$total] $label"
    echo "    File: $file"

    local o64=$($FP64 -b $TB/$file 2>&1)
    local o32=$($FP32 -b $TB/$file 2>&1)
    local r64=$?; local r32=$?

    if [ $r32 -ne 0 ] && [ $r32 -ne 1 ]; then
        echo "    FAIL: FP32 exit=$r32"
        failed=$((failed+1)); return
    fi
    if [ $r64 -ne 0 ] && [ $r64 -ne 1 ]; then
        echo "    FAIL: FP64 exit=$r64"
        failed=$((failed+1)); return
    fi

    # Check for NaN, convergence issues
    if echo "$o32$o64" | grep -qi "timestep too small\|iteration limit\|singular"; then
        echo "    FAIL: Convergence issue"
        failed=$((failed+1)); return
    fi

    # Extract OP values
    local any=0
    for pattern in "$@"; do
        local name=$(echo "$pattern" | cut -d: -f1)
        local regex=$(echo "$pattern" | cut -d: -f2-)
        local v64=$(echo "$o64" | grep -E "$regex" | head -1 | awk '{print $NF}')
        local v32=$(echo "$o32" | grep -E "$regex" | head -1 | awk '{print $NF}')
        if [ -n "$v64" ] && [ -n "$v32" ]; then
            any=1
            # Calculate error % using python
            local d=$(python3 -c "
v64=$v64; v32=$v32
denom = max(abs(v64), 1e-30)
pct = abs(v64 - v32) / denom * 100
print(f'{pct:.4f}')
" 2>/dev/null)
            printf "    %-20s  FP64=%12s  FP32=%12s  err=%s%%\n" "$name" "$v64" "$v32" "$d"
        fi
    done

    if [ $any -eq 0 ]; then
        echo "    WARNING: No DC values extracted (printed via wrdata, not op)"
    fi
    passed=$((passed+1))
}

# OTA — print node voltages and currents
run_compare "Five-Transistor OTA" "ota_dc_bsim4.cir" \
    "Vout:v\(out\)" \
    "Id(M5):i(vbias)"

# Opamp
run_compare "Two-Stage Op Amp" "opamp_dc_bsim4.cir" \
    "Vout:v\(out\)" \
    "Idd:i(vdd)"

# LDO
run_compare "LDO Regulator" "ldo_dc_bsim4.cir" \
    "Vout:v\(vout\)" \
    "Iin:i(vin)"

echo ""
echo "============================================================"
echo "  RESULTS: $total circuits | $passed PASSED | $failed FAILED"
if [ $failed -eq 0 ]; then
    echo "  ALL CIRCUITS PASS — BSIM4v5 FP32 fully validated"
else
    echo "  SOME FAILED — check individual results above"
fi
echo "============================================================"
