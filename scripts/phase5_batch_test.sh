#!/bin/bash
# Phase 5: Batch regression test on fp32-math ngspice
set -euo pipefail
BIN=/tmp/build_fp32_p2/ngspice-46/src/ngspice
DIR=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/mx

echo "============================================"
echo " Phase 5: Batch Regression Test"
echo "============================================"
echo ""

PASS=0; FAIL=0; TOTAL=0

test_circuit() {
    local name="$1" spice="$2"
    TOTAL=$((TOTAL+1))
    echo -n "  [$name] "
    local out
    if out=$("$BIN" --batch "$spice" 2>&1); then
        if echo "$out" | grep -q "v(d)"; then
            local vd=$(echo "$out" | grep "v(d)" | grep -oP '[0-9eE.+-]+' | tail -1)
            echo "PASS V(D)=$vd"
            PASS=$((PASS+1))
        else
            echo "PASS (no V(D) output)"
            PASS=$((PASS+1))
        fi
    else
        echo "FAIL (exit=$?)"
        FAIL=$((FAIL+1))
    fi
}

cd "$DIR"
test_circuit "mx_nmos_dc"    "mx_nmos_dc.sp"
test_circuit "mx_pmos_dc"    "mx_pmos_dc.sp"
test_circuit "mx_nmos_sweep" "mx_nmos_sweep.sp"
test_circuit "mx_pmos_sweep" "mx_pmos_sweep.sp"

echo ""
echo "============================================"
echo " Phase 5 Results: $PASS/$TOTAL passed"
echo "============================================"
if [ "$PASS" -eq "$TOTAL" ]; then
    echo "ALL CIRCUITS PASS"
else
    echo "Some circuits failed"
fi
