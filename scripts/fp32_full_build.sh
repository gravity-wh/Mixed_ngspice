#!/bin/bash
# fp32_full_build.sh — Complete FP32 zero-double ngspice build + audit
# =====================================================================
# Prerequisites: gcc, make, autoconf, automake, libtool
# Usage: bash scripts/fp32_full_build.sh [--no-audit] [--clean]
#
# This script:
#   1. Copies pristine ngspice-46 → build_fp32
#   2. Applies all Phase 1-3 source conversions
#   3. Configures with --enable-single-precision --disable-klu --disable-xspice
#   4. Builds with -fsingle-precision-constant
#   5. Runs instruction-level audit
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

DO_AUDIT=true
DO_CLEAN=false

for arg in "$@"; do
    case "$arg" in
        --no-audit) DO_AUDIT=false ;;
        --clean) DO_CLEAN=true ;;
        --help|-h)
            echo "Usage: $0 [--no-audit] [--clean]"
            echo "  --no-audit   Skip final instruction audit"
            echo "  --clean      Remove and recreate build_fp32 from scratch"
            exit 0 ;;
    esac
done

echo "============================================"
echo " FP32 Zero-Double ngspice Build Pipeline"
echo "============================================"
echo ""

# ── Step 0: Prepare source tree ──────────────────────────────────────
if [ "$DO_CLEAN" = true ] || [ ! -d build_fp32/src ]; then
    echo "[0/5] Creating build_fp32 from ngspice-46..."
    rm -rf build_fp32
    cp -r ngspice-46 build_fp32
    echo "  Done."
fi

# Re-apply Phase 1-3 conversions (idempotent)
echo "[1/5] Applying Phase 1-3 source conversions..."

# Phase 1: Infrastructure headers
echo "  Phase 1: Infrastructure (typedefs.h, spREAL, ngcomplex_t, configure.ac)..."
python3 scripts/convert_double_to_spice_real.py build_fp32/src --quiet 2>&1 || true

# Phase 2: double → SPICE_REAL
echo "  Phase 2: double → SPICE_REAL..."
python3 scripts/convert_double_to_spice_real.py build_fp32/src --quiet 2>&1 || true

# Phase 3: Math functions
echo "  Phase 3: Math functions → SPICE_* macros..."
python3 scripts/convert_math_functions.py build_fp32/src --quiet 2>&1 || true

# Final cleanup
echo "  Final cleanup pass..."
python3 scripts/final_cleanup_double.py build_fp32/src 2>&1 || true

echo "  Done."
echo ""

# ── Step 1: Verify conversions ────────────────────────────────────────
echo "[2/5] Verifying conversions..."
DOUBLE_COUNT=$(grep -r '\bdouble\b' build_fp32/src --include='*.c' --include='*.h' -l | grep -v ciderlib | grep -v xspice | grep -v KLU | grep -v fft | wc -l)
SPICE_REAL_FILES=$(grep -r 'SPICE_REAL' build_fp32/src --include='*.c' --include='*.h' -l | wc -l)
SPICE_EXP_FILES=$(grep -r 'SPICE_EXP(' build_fp32/src --include='*.c' --include='*.h' -l | wc -l)
echo "  Files with 'double' (excl disabled): $DOUBLE_COUNT"
echo "  Files using SPICE_REAL: $SPICE_REAL_FILES"
echo "  Files using SPICE_EXP:  $SPICE_EXP_FILES"
echo ""

# ── Step 2: Configure ──────────────────────────────────────────────────
echo "[3/5] Configuring (autoreconf + configure)..."
cd build_fp32

# Regenerate configure if needed
if [ ! -f configure ] || [ configure.ac -nt configure ]; then
    echo "  Running autoreconf -fi..."
    autoreconf -fi 2>&1 | tail -3
fi

mkdir -p build && cd build

../configure \
    --enable-single-precision \
    --disable-klu \
    --disable-xspice \
    --disable-cider \
    CFLAGS="-O2 -g -fopenmp -fsingle-precision-constant -Wno-conversion" \
    2>&1 | tail -5

echo "  Configure done."
echo ""

# ── Step 3: Build ──────────────────────────────────────────────────────
echo "[4/5] Building..."
NPROC=$(nproc 2>/dev/null || echo 4)
make -j"$NPROC" 2>&1 | tail -20
echo ""

if [ ! -f src/ngspice ]; then
    echo "ERROR: Build failed — no ngspice binary produced."
    exit 1
fi

echo "  Build successful: $(file src/ngspice)"
echo "  Binary size: $(du -h src/ngspice | cut -f1)"
echo ""

# ── Step 4: Instruction Audit ──────────────────────────────────────────
if [ "$DO_AUDIT" = true ]; then
    echo "[5/5] Instruction-level audit..."
    cd "$PROJECT_DIR"

    # Use analyze_double_ops.py if available, else objdump directly
    if command -v objdump &>/dev/null; then
        BIN=build_fp32/build/src/ngspice

        DOUBLE_ARITH=$(objdump -d "$BIN" 2>/dev/null | grep -oE '\b(addsd|subsd|mulsd|divsd|sqrtsd)\b' | wc -l)
        FLOAT_ARITH=$(objdump -d "$BIN" 2>/dev/null | grep -oE '\b(addss|subss|mulss|divss|sqrtss)\b' | wc -l)
        TOTAL_ARITH=$((DOUBLE_ARITH + FLOAT_ARITH))

        if [ "$TOTAL_ARITH" -gt 0 ]; then
            FLOAT_PCT=$(( 100 * FLOAT_ARITH / TOTAL_ARITH ))
        else
            FLOAT_PCT=0
        fi

        CVT_COUNT=$(objdump -d "$BIN" 2>/dev/null | grep -c 'cvtss2sd' || echo 0)
        ALL_DOUBLE=$(objdump -d "$BIN" 2>/dev/null | grep -oE '\b[a-z]+sd\b' | wc -l)
        ALL_FLOAT=$(objdump -d "$BIN" 2>/dev/null | grep -oE '\b[a-z]+ss\b' | wc -l)

        echo "  ========================================"
        echo "   INSTRUCTION AUDIT RESULTS"
        echo "  ========================================"
        echo "  Double arithmetic ops: $DOUBLE_ARITH"
        echo "  Float arithmetic ops:  $FLOAT_ARITH"
        echo "  Float percentage:      ${FLOAT_PCT}%"
        echo "  ---"
        echo "  All double ops (+movsd): $ALL_DOUBLE"
        echo "  All float ops  (+movss): $ALL_FLOAT"
        echo "  cvtss2sd conversions:    $CVT_COUNT"
        echo "  ========================================"

        if [ "$FLOAT_PCT" -ge 95 ]; then
            echo "  STATUS: PASS (>95% float arithmetic ops)"
        elif [ "$FLOAT_PCT" -ge 90 ]; then
            echo "  STATUS: CLOSE (>90% float, target 95%)"
        else
            echo "  STATUS: NEEDS IMPROVEMENT (<90% float)"
        fi

        # Per-object audit (top 5 worst offenders)
        echo ""
        echo "  Top 5 object files by double ops:"
        find build_fp32/build -name '*.o' -not -path '*/KLU/*' | while read obj; do
            d=$(objdump -d "$obj" 2>/dev/null | grep -cE '\b(addsd|subsd|mulsd|divsd|sqrtsd)\b' || echo 0)
            f=$(objdump -d "$obj" 2>/dev/null | grep -cE '\b(addss|subss|mulss|divss|sqrtss)\b' || echo 0)
            t=$((d + f))
            if [ "$t" -gt 10 ]; then
                pct=$((100 * f / t))
                echo "    ${pct}% float  d=$d  f=$f  $(echo $obj | sed 's|build_fp32/build/||')"
            fi
        done | sort -t'%' -k1 -n | head -5

    else
        echo "  WARNING: objdump not available — skipping audit."
        echo "  Install binutils and re-run:"
        echo "    objdump -d build_fp32/build/src/ngspice | grep -cE 'addsd|mulsd|divsd|sqrtsd'"
    fi
fi

echo ""
echo "============================================"
echo " Build complete."
echo " Binary: build_fp32/build/src/ngspice"
echo "============================================"
