#!/bin/bash
# Phase 2: Apply fp32 math transformations to all BSIM family evaluation files
set -euo pipefail
SRC=/tmp/build_fp32_phase1/ngspice-46/src/spicelib/devices
cd "$SRC"

echo "=== Phase 2: BSIM Family fp32 Conversion ==="
echo ""

# Count patterns before
for dir in bsim4 bsim4v6 bsim4v7 bsimsoi hisim2 hisimhv1 hisimhv2 \
           bsim3 bsim3v0 bsim3v1 bsim3v32 \
           bsim3soi_dd bsim3soi_fd bsim3soi_pd; do
    if [ -d "$dir" ]; then
        exp=$(grep -r 'exp((double)' "$dir"/ 2>/dev/null | wc -l || echo 0)
        sqrt=$(grep -r 'sqrt((double)' "$dir"/ 2>/dev/null | wc -l || echo 0)
        dexp=$(grep -rl 'DEXP' "$dir"/ 2>/dev/null | wc -l || echo 0)
        echo "  BEFORE $dir: exp(double)=$exp sqrt(double)=$sqrt DEXP_files=$dexp"
    fi
done

echo ""
echo "--- Applying fp32 transformations ---"

# Function: convert a single C file
convert_file() {
    local f="$1"
    local changed=0

    # Add fp32_math.h include after typedefs.h
    if grep -q 'ngspice/typedefs.h' "$f" 2>/dev/null && ! grep -q 'fp32_math.h' "$f" 2>/dev/null; then
        sed -i 's|#include "ngspice/typedefs.h"|#include "ngspice/typedefs.h"\n#include "ngspice/fp32_math.h"|' "$f"
        changed=1
    fi

    # Replace exp((double)(X)) with SPICE_EXP(X)
    if grep -q 'exp((double)' "$f" 2>/dev/null; then
        sed -i 's/exp((double)(\([^)]*\)))/SPICE_EXP(\1)/g' "$f"
        changed=1
    fi

    # Replace sqrt((double)(X)) with SPICE_SQRT(X)
    if grep -q 'sqrt((double)' "$f" 2>/dev/null; then
        sed -i 's/sqrt((double)(\([^)]*\)))/SPICE_SQRT(\1)/g' "$f"
        changed=1
    fi

    # Replace log((double)(X)) with SPICE_LOG(X)
    if grep -q 'log((double)' "$f" 2>/dev/null; then
        sed -i 's/log((double)(\([^)]*\)))/SPICE_LOG(\1)/g' "$f"
        changed=1
    fi

    # Fix DEXP macro: (SPICE_REAL)exp((double)(A)) -> (SPICE_REAL)SPICE_EXP(A)
    if grep -q '(SPICE_REAL)exp((double)' "$f" 2>/dev/null; then
        sed -i 's/(SPICE_REAL)exp((double)(\([^)]*\)))/(SPICE_REAL)SPICE_EXP(\1)/g' "$f"
        changed=1
    fi

    # Replace bare exp( with SPICE_EXP( — only in hot-path files
    # Guard: skip if already SPICE_EXP or expf
    local base=$(basename "$f")
    if echo "$base" | grep -qE 'ld\.c|temp\.c|eval\.c|noi\.c|geo\.c' 2>/dev/null; then
        if grep -qE '[^A-Z_]exp\(' "$f" 2>/dev/null; then
            # Replace exp( -> SPICE_EXP( but not SPICE_EXP( or expf(
            sed -i 's/\([^A-Z_]\)exp(/\1SPICE_EXP(/g' "$f"
            sed -i 's/^exp(/SPICE_EXP(/g' "$f"
            changed=1
        fi
        if grep -qE '[^A-Z_]sqrt\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Z_]\)sqrt(/\1SPICE_SQRT(/g' "$f"
            sed -i 's/^sqrt(/SPICE_SQRT(/g' "$f"
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
for dir in bsim4 bsim4v6 bsim4v7 bsimsoi hisim2 hisimhv1 hisimhv2 \
           bsim3 bsim3v0 bsim3v1 bsim3v32 \
           bsim3soi_dd bsim3soi_fd bsim3soi_pd; do
    if [ -d "$dir" ]; then
        for f in "$dir"/*.c; do
            if convert_file "$f"; then
                echo "  MODIFIED: $f"
                converted=$((converted+1))
            fi
        done
    fi
done

echo ""
echo "--- $converted files converted ---"
echo ""

# Count patterns after
for dir in bsim4 bsim4v6 bsim4v7 bsimsoi hisim2 hisimhv1 hisimhv2 \
           bsim3 bsim3v0 bsim3v1 bsim3v32 \
           bsim3soi_dd bsim3soi_fd bsim3soi_pd; do
    if [ -d "$dir" ]; then
        exp=$(grep -r 'exp((double)' "$dir"/ 2>/dev/null | wc -l || echo 0)
        sqrt=$(grep -r 'sqrt((double)' "$dir"/ 2>/dev/null | wc -l || echo 0)
        echo "  AFTER  $dir: exp(double)=$exp sqrt(double)=$sqrt"
    fi
done

echo ""
echo "=== Phase 2 Conversion Done ==="
