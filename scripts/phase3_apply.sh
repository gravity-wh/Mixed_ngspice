#!/bin/bash
# Phase 3: Apply fp32 math to non-BSIM device models
set -euo pipefail
SRC=/tmp/build_fp32_phase1/ngspice-46/src/spicelib/devices
cd "$SRC"

echo "=== Phase 3: Non-BSIM Device fp32 Conversion ==="

# Target: BJT, Diode, MOS1-9, JFET, MES, HFET, VBIC, HICUM, SOI3, VDMOS
targets="bjt dio mos1 mos2 mos3 mos6 mos9 jfet jfet2 mes mesa hfet1 hfet2 vbic hicum2 soi3 vdmos nbjt nbjt2"

convert_file() {
    local f="$1"
    local changed=0

    # Add fp32_math.h include
    if grep -q 'ngspice/typedefs.h' "$f" 2>/dev/null && ! grep -q 'fp32_math.h' "$f" 2>/dev/null; then
        sed -i 's|#include "ngspice/typedefs.h"|#include "ngspice/typedefs.h"\n#include "ngspice/fp32_math.h"|' "$f"
        changed=1
    fi

    # Replace exp(log(arg)) pattern: exp(-MJ*log(arg)) -> powf alternative
    # Keep as-is for now — these are junction capacitance patterns

    # Replace in hot-path files (*load.c, *temp.c, *eval.c)
    local base=$(basename "$f")
    if echo "$base" | grep -qE 'load\.c|temp\.c|eval\.c|dset\.c'; then
        if grep -qE '[^A-Z_]exp\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Z_]\)exp(/\1SPICE_EXP(/g' "$f"
            sed -i 's/^exp(/SPICE_EXP(/g' "$f"
            changed=1
        fi
        if grep -qE '[^A-Z_]log\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Z_]\)log(/\1SPICE_LOG(/g' "$f"
            sed -i 's/^log(/SPICE_LOG(/g' "$f"
            changed=1
        fi
    fi

    return $changed
}

converted=0
for d in $targets; do
    if [ -d "$d" ]; then
        for f in "$d"/*.c; do
            if convert_file "$f"; then
                echo "  MODIFIED: $f"
                converted=$((converted+1))
            fi
        done
    fi
done

echo ""
echo "--- $converted files converted ---"
echo "=== Phase 3 Done ==="
