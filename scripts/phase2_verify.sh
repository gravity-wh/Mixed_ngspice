#!/bin/bash
set -euo pipefail
NEW=/tmp/build_fp32_p2/ngspice-46/src/ngspice
REF=/mnt/e/MyResearch/Mixed_ngspice/build_fp64/src/ngspice
DIR=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/mx

echo "=== Phase 2 REAL: DC Verification ==="
echo ""

for circuit in mx_nmos_dc.sp mx_pmos_dc.sp; do
    name="${circuit%.sp}"
    echo -n "  [$name] "

    new_out=$("$NEW" --batch "$DIR/$circuit" 2>&1)
    ref_out=$("$REF" --batch "$DIR/$circuit" 2>&1)

    new_vd=$(echo "$new_out" | grep "v(d)" | grep -oP '[0-9eE.+-]+' | tail -1)
    ref_vd=$(echo "$ref_out" | grep "v(d)" | grep -oP '[0-9eE.+-]+' | tail -1)
    new_id=$(echo "$new_out" | grep "i(vd)" | grep -oP '[-]?[0-9eE.+-]+' | head -1)
    ref_id=$(echo "$ref_out" | grep "i(vd)" | grep -oP '[-]?[0-9eE.+-]+' | head -1)

    if [ "$new_vd" = "$ref_vd" ] && [ "$new_id" = "$ref_id" ]; then
        echo "MATCH V(D)=$new_vd I(VD)=$new_id"
    else
        echo "DIFF  V(D): $new_vd vs $ref_vd  I(VD): $new_id vs $ref_id"
    fi
done

echo ""
echo "=== Phase 2 REAL verification complete ==="
