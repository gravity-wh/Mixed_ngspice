#!/bin/bash
set -euo pipefail
NEW=/tmp/build_fp32_phase1/ngspice-46/src/ngspice
REF=/mnt/e/MyResearch/Mixed_ngspice/build_fp64/src/ngspice
DIR=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/mx

PASS=0; TOTAL=0
echo "============================================"
echo " Phase 1.5: FP32 DC Accuracy Verification"
echo "============================================"
echo ""

for circuit in mx_nmos_dc.sp mx_pmos_dc.sp mx_nmos_sweep.sp mx_pmos_sweep.sp; do
    TOTAL=$((TOTAL+1))
    name="${circuit%.sp}"
    echo -n "  [$name] "

    new_out=$("$NEW" --batch "$DIR/$circuit" 2>&1)
    ref_out=$("$REF" --batch "$DIR/$circuit" 2>&1)

    # Extract key values
    new_vd=$(echo "$new_out" | grep -oP 'v\(d\)\s*=\s*\K[0-9eE.+-]+' | head -1)
    ref_vd=$(echo "$ref_out" | grep -oP 'v\(d\)\s*=\s*\K[0-9eE.+-]+' | head -1)
    new_id=$(echo "$new_out" | grep -oP 'i\(vd\)\s*=\s*\K[0-9eE.+-]+' | head -1)
    ref_id=$(echo "$ref_out" | grep -oP 'i\(vd\)\s*=\s*\K[0-9eE.+-]+' | head -1)

    # Check NaN
    if echo "$new_vd $new_id" | grep -qi "nan\|inf"; then
        echo "NaN/Inf detected"; continue; fi

    # Check match
    if [ "$new_vd" = "$ref_vd" ] && [ "$new_id" = "$ref_id" ]; then
        echo "MATCH V(D)=$new_vd I(VD)=$new_id"
        PASS=$((PASS+1))
    else
        echo "DIFF  V(D): $new_vd vs $ref_vd  I(VD): $new_id vs $ref_id"
    fi
done

echo ""
echo "============================================"
echo " Phase 1.5: $PASS/$TOTAL circuits match"
echo "============================================"
if [ "$PASS" -lt 4 ]; then
    echo "TARGET NOT MET: need 4/4"
    exit 1
fi
echo "Phase 1 COMPLETE"
