#!/bin/bash
# Phase 3 REAL: fp32 math in non-BSIM device evaluation files
set -euo pipefail
BUILD=/tmp/build_fp32_p2
BASE="$BUILD/ngspice-46"
DEVICES="$BASE/src/spicelib/devices"

echo "=== Phase 3 REAL: Non-BSIM fp32 math ==="

MACRO_BLOCK='/* FP32 math: explicit float to eliminate cvtss2sd */
#define SPICE_EXP(x)  expf((float)(x))
#define SPICE_LOG(x)  logf((float)(x))
#define SPICE_SQRT(x) sqrtf((float)(x))
#define SPICE_POW(x,y) powf((float)(x),(float)(y))
#define SPICE_SIN(x)  sinf((float)(x))
#define SPICE_COS(x)  cosf((float)(x))
#define SPICE_FABS(x) fabsf((float)(x))
#define SPICE_ATAN(x) atanf((float)(x))
#define SPICE_TAN(x)  tanf((float)(x))
#define SPICE_TANH(x) tanhf((float)(x))
'

TARGET_DIRS="bjt dio mos1 mos2 mos3 mos6 mos9 jfet jfet2 mes mesa hfet1 hfet2 vbic hicum2 soi3 vdmos nbjt nbjt2"

converted=0
for dir in $TARGET_DIRS; do
    d="$DEVICES/$dir"
    [ -d "$d" ] || continue
    for f in "$d"/*load.c "$d"/*temp.c "$d"/*eval.c "$d"/*dset.c "$d"/*noi.c "$d"/*disto.c; do
        [ -f "$f" ] || continue
        bname=$(basename "$f")
        changed=0

        if ! grep -q 'SPICE_EXP(x).*expf' "$f" 2>/dev/null; then
            last_include=$(grep -n '^#include' "$f" | tail -1 | cut -d: -f1)
            if [ -n "$last_include" ]; then
                sed -i "${last_include}a\\\n${MACRO_BLOCK}" "$f"
                changed=1
            fi
        fi

        if grep -qP '(?<!SPICE_)exp\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)exp(/\1SPICE_EXP(/g' "$f"
            sed -i 's/^exp(/SPICE_EXP(/g' "$f"
            sed -i 's/SPICE_SPICE_EXP(/SPICE_EXP(/g' "$f"
            changed=1
        fi

        if grep -qP '(?<!SPICE_)sqrt\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)sqrt(/\1SPICE_SQRT(/g' "$f"
            sed -i 's/^sqrt(/SPICE_SQRT(/g' "$f"
            sed -i 's/SPICE_SPICE_SQRT(/SPICE_SQRT(/g' "$f"
            changed=1
        fi

        if [ "$changed" -eq 1 ]; then
            echo "  MODIFIED: $dir/$bname"
            converted=$((converted + 1))
        fi
    done
done
echo "--- $converted files converted ---"

cd "$BASE"
echo "--- Rebuild ---"
if make -j$(nproc) > /tmp/build_p3.log 2>&1; then
    echo "  BUILD OK"
else
    echo "BUILD FAILED — last 30 lines:"
    tail -30 /tmp/build_p3.log
    exit 1
fi

echo ""
echo "=== Phase 3 VERIFY ==="
NEW=src/ngspice
REF=/mnt/e/MyResearch/Mixed_ngspice/build_fp64/src/ngspice
DIR=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/mx
for circuit in mx_nmos_dc.sp mx_pmos_dc.sp; do
    name="${circuit%.sp}"
    new_out=$("$NEW" --batch "$DIR/$circuit" 2>&1)
    ref_out=$("$REF" --batch "$DIR/$circuit" 2>&1)
    new_vd=$(echo "$new_out" | grep "v(d)" | grep -oP '[0-9eE.+-]+' | tail -1)
    ref_vd=$(echo "$ref_out" | grep "v(d)" | grep -oP '[0-9eE.+-]+' | tail -1)
    if [ "$new_vd" = "$ref_vd" ]; then
        echo "  [$name] MATCH V(D)=$new_vd"
    else
        echo "  [$name] DIFF V(D): $new_vd vs $ref_vd"
    fi
done
echo "=== Phase 3 REAL complete ==="
