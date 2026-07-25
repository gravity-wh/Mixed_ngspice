#!/bin/bash
# Phase 2 REAL: Full build with fp32 math in all BSIM evaluation files
# Runs entirely inside WSL
set -euo pipefail
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_fp32_p2

echo "=== Phase 2 REAL: fp32 BSIM + full rebuild ==="
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "--- Extracting pristine ngspice-46 ---"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
BASE="$BUILD/ngspice-46"
DEVICES="$BASE/src/spicelib/devices"

echo "--- Applying 11 base patches ---"
for p in "$REPO/patches/clean"/*.patch; do
    (cd "$BASE" && patch -p1 -N -s < "$p" 2>/dev/null || true)
done
echo "  11 patches applied"

echo "--- Adding SPICE_EXP macros to BSIM evaluation files ---"

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

TARGET_DIRS="bsim4 bsim4v6 bsim4v7 bsimsoi bsim3 bsim3v0 bsim3v1 bsim3v32 \
            bsim3soi_dd bsim3soi_fd bsim3soi_pd bsim1 bsim2"

converted=0
for dir in $TARGET_DIRS; do
    d="$DEVICES/$dir"
    [ -d "$d" ] || continue
    for f in "$d"/*ld.c "$d"/*temp.c "$d"/*eval.c "$d"/*geo.c "$d"/*noi.c; do
        [ -f "$f" ] || continue
        bname=$(basename "$f")
        changed=0

        # Add SPICE_EXP macros
        if ! grep -q 'SPICE_EXP(x).*expf' "$f" 2>/dev/null; then
            # Insert after last #include line
            last_include=$(grep -n '^#include' "$f" | tail -1 | cut -d: -f1)
            if [ -n "$last_include" ]; then
                sed -i "${last_include}a\\\n${MACRO_BLOCK}" "$f"
                changed=1
            fi
        fi

        # Fix DEXP macro
        if grep -q '(SPICE_REAL)exp((double)(A))' "$f" 2>/dev/null; then
            sed -i 's/(SPICE_REAL)exp((double)(A))/(SPICE_REAL)expf((float)(A))/g' "$f"
            changed=1
        fi
        if grep -q 'exp((double)(A))' "$f" 2>/dev/null; then
            sed -i 's/exp((double)(A))/expf((float)(A))/g' "$f"
            changed=1
        fi

        # Replace exp( with SPICE_EXP( (not already SPICE_EXP or expf)
        if grep -qP '(?<!SPICE_)exp\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)exp(/\1SPICE_EXP(/g' "$f"
            sed -i 's/^exp(/SPICE_EXP(/g' "$f"
            sed -i 's/SPICE_SPICE_EXP(/SPICE_EXP(/g' "$f"
            changed=1
        fi

        # Replace sqrt( with SPICE_SQRT(
        if grep -qP '(?<!SPICE_)sqrt\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)sqrt(/\1SPICE_SQRT(/g' "$f"
            sed -i 's/^sqrt(/SPICE_SQRT(/g' "$f"
            sed -i 's/SPICE_SPICE_SQRT(/SPICE_SQRT(/g' "$f"
            changed=1
        fi

        # Replace log( with SPICE_LOG( (careful: not "logical" etc.)
        if grep -qP '(?<!SPICE_)log\(' "$f" 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)log(/\1SPICE_LOG(/g' "$f"
            sed -i 's/^log(/SPICE_LOG(/g' "$f"
            sed -i 's/SPICE_SPICE_LOG(/SPICE_LOG(/g' "$f"
            changed=1
        fi

        if [ "$changed" -eq 1 ]; then
            echo "  MODIFIED: $dir/$bname"
            converted=$((converted + 1))
        fi
    done
done
echo "--- $converted files converted ---"

echo "--- Configure ---"
cd "$BASE"
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/config_p2.log 2>&1
echo "  configure OK: $(tail -1 /tmp/config_p2.log)"

echo "--- make -j ---"
if make -j$(nproc) > /tmp/build_p2.log 2>&1; then
    echo "  BUILD OK"
else
    echo "BUILD FAILED — last 40 lines:"
    tail -40 /tmp/build_p2.log
    exit 1
fi

echo ""
echo "=== cvtss2sd count ==="
BEFORE=164
AFTER=$(objdump -d src/ngspice 2>/dev/null | grep -c "cvtss2sd" || echo "0")
echo "Before: $BEFORE  After: $AFTER  Reduction: $((BEFORE - AFTER))"
echo ""

if [ "$AFTER" -lt "$BEFORE" ]; then
    echo "=== SUCCESS: cvtss2sd reduced by $((BEFORE - AFTER)) ==="
else
    echo "=== WARNING: No cvtss2sd reduction — check conversion ==="
fi
echo "Binary: $(ls -la src/ngspice)"
