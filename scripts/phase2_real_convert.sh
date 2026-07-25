#!/bin/bash
# Phase 2 REAL: Truly replace exp/sqrt/log/pow with float variants in BSIM eval files
set -euo pipefail
SRC=/mnt/e/MyResearch/Mixed_ngspice/ngspice-46
DST=/tmp/build_fp32_phase1/ngspice-46

echo "=== Phase 2 REAL: fp32 math replacement in BSIM evaluation files ==="

# The bsim4v5 pattern (from 003-b4v5ld.patch):
#   1. Add SPICE_EXP/SQRT/LOG/POW macros → expf/sqrtf/logf/powf casts
#   2. Replace exp() → SPICE_EXP(), sqrt() → SPICE_SQRT(), etc.
#   3. Fix DEXP macro to use expf
#
# We apply this to each BSIM family *ld.c and *temp.c file

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
    d="$DST/src/spicelib/devices/$dir"
    [ -d "$d" ] || continue

    for f in "$d"/*ld.c "$d"/*temp.c "$d"/*eval.c "$d"/*geo.c "$d"/*noi.c; do
        [ -f "$f" ] || continue
        bname=$(basename "$f")
        changed=0

        # Step 1: Add SPICE_EXP macros if not already present
        if ! grep -q 'SPICE_EXP(x).*expf' "$f" 2>/dev/null; then
            # Insert after first #include block
            sed -i "0,/^#include/{/^#include.*\$/a\\
$MACRO_BLOCK
}" "$f"
            changed=1
        fi

        # Step 2: Fix DEXP macro if present (only in BSIM4 series)
        if grep -q '(SPICE_REAL)exp((double)(A))' "$f" 2>/dev/null; then
            sed -i 's/(SPICE_REAL)exp((double)(A))/(SPICE_REAL)expf((float)(A))/g' "$f"
            changed=1
        fi
        if grep -q 'exp((double)(A))' "$f" 2>/dev/null; then
            sed -i 's/exp((double)(A))/expf((float)(A))/g' "$f"
            changed=1
        fi

        # Step 3: Replace bare exp( in math context (not SPICE_EXP, not expf, not export)
        # Match: whitespace + exp( → whitespace + SPICE_EXP(
        exp_before=$(grep -c '[^A-Za-z_]exp(' "$f" 2>/dev/null || echo 0)
        if [ "$exp_before" -gt 0 ] 2>/dev/null; then
            # Replace " exp(" → " SPICE_EXP("
            sed -i 's/\([^A-Za-z_]\)exp(/\1SPICE_EXP(/g' "$f"
            # Replace "(exp(" → "(SPICE_EXP("
            sed -i 's/(exp(/(SPICE_EXP(/g' "$f"
            # Fix double SPICE: SPICE_EXP(SPICE_EXP( → SPICE_EXP(
            sed -i 's/SPICE_SPICE_EXP(/SPICE_EXP(/g' "$f"
            changed=1
        fi

        # Step 4: Replace bare sqrt(
        sqrt_before=$(grep -c '[^A-Za-z_]sqrt(' "$f" 2>/dev/null || echo 0)
        if [ "$sqrt_before" -gt 0 ] 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)sqrt(/\1SPICE_SQRT(/g' "$f"
            sed -i 's/(sqrt(/(SPICE_SQRT(/g' "$f"
            sed -i 's/SPICE_SPICE_SQRT(/SPICE_SQRT(/g' "$f"
            changed=1
        fi

        # Step 5: Replace bare log(
        log_before=$(grep -c '[^A-Za-z_]log(' "$f" 2>/dev/null || echo 0)
        if [ "$log_before" -gt 0 ] 2>/dev/null; then
            sed -i 's/\([^A-Za-z_]\)log(/\1SPICE_LOG(/g' "$f"
            sed -i 's/(log(/(SPICE_LOG(/g' "$f"
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
echo "=== Phase 2 REAL done ==="
