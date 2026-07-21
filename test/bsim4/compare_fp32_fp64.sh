#!/bin/bash
# Full FP32 vs FP64 DC value comparison for BSIM4 circuits
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
TB=/mnt/e/MyResearch/Mixed_ngspice/test/bsim4/testbenches

echo "============================================================"
echo "  BSIM4v5 FP32 vs FP64 — DC Operating Point Comparison"
echo "============================================================"
echo ""

compare_dc() {
    local name=$1
    local file=$2
    local nodes=("${@:3}")

    echo "--- $name ---"
    local out64=$($FP64 -b $TB/$file 2>&1)
    local out32=$($FP32 -b $TB/$file 2>&1)

    local ret64=$?; local ret32=$?
    local status="PASS"
    if echo "$out32" | grep -qi "error\|failed"; then status="FAIL_FP32"; fi
    if echo "$out64" | grep -qi "error\|failed"; then status="FAIL_FP64"; fi
    echo "  Status: $status (FP32=$ret32, FP64=$ret64)"

    # Extract DC node voltages
    for node in "${nodes[@]}"; do
        local v64=$(echo "$out64" | grep "v(${node})" | head -1 | awk '{print $NF}' | tr -d '\r')
        local v32=$(echo "$out32" | grep "v(${node})" | head -1 | awk '{print $NF}' | tr -d '\r')
        if [ -n "$v64" ] && [ -n "$v32" ]; then
            # Calculate relative error
            local diff=$(python3 -c "print(abs($v64 - $v32) / max(abs($v64), 1e-30) * 100)" 2>/dev/null)
            if [ -n "$diff" ]; then
                printf "  V(%-8s)  FP64=%-14s  FP32=%-14s  Δ=%.4f%%\n" "$node" "$v64" "$v32" "$diff"
            else
                printf "  V(%-8s)  FP64=%-14s  FP32=%-14s\n" "$node" "$v64" "$v32"
            fi
        fi
    done

    # Extract currents
    for curr in "i(VDD_SRC)" "i(VIN_SRC)" "id"; do
        local i64=$(echo "$out64" | grep "$curr" | head -1 | awk '{print $NF}' | tr -d '\r')
        local i32=$(echo "$out32" | grep "$curr" | head -1 | awk '{print $NF}' | tr -d '\r')
        if [ -n "$i64" ] && [ -n "$i32" ]; then
            local diff=$(python3 -c "print(abs($i64 - $i32) / max(abs($i64), 1e-30) * 100)" 2>/dev/null)
            if [ -n "$diff" ]; then
                printf "  %-12s  FP64=%-14s  FP32=%-14s  Δ=%.4f%%\n" "$curr" "$i64" "$i32" "$diff"
            fi
        fi
    done
    echo ""
}

# OTA: check V(out), gm, id
compare_dc "Five-Transistor OTA" "ota_dc_bsim4.cir" "out" "inp" "inn" "vdd" "vbias" "tail"

# Opamp: check V(out), V(A), V(B), V(PBIAS), V(C), I(VDD)
compare_dc "Two-Stage Op Amp" "opamp_dc_bsim4.cir" "out" "a" "b" "p_bias" "c" "vdd"

# LDO: check V(vout), V(net30), V(ibias), V(net3), V(net4), V(net16)
compare_dc "LDO Regulator" "ldo_dc_bsim4.cir" "vout" "net30" "ibias" "net3" "net4" "net16" "net34"

echo "============================================================"
echo "  DONE"
echo "============================================================"
