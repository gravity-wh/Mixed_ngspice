#!/bin/bash
# Phase 1 REAL: Automated iterative fix for -DSINGLE_PRECISION build
# Strategy: build → capture errors → fix → repeat
set -euo pipefail
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_fp32_auto

echo "=== Phase 1 REAL: Auto-fix SINGLE_PRECISION build ==="

# Setup: extract pristine + apply base patches + infrastructure fixes
rm -rf "$BUILD"
mkdir -p "$BUILD"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
BASE="$BUILD/ngspice-46"

echo "--- Setup: patches + infra fixes ---"
for p in "$REPO"/patches/clean/001-*.patch "$REPO"/patches/clean/002-*.patch \
         "$REPO"/patches/clean/003-*.patch "$REPO"/patches/clean/004-*.patch \
         "$REPO"/patches/clean/005-*.patch "$REPO"/patches/clean/006-*.patch \
         "$REPO"/patches/clean/007-*.patch "$REPO"/patches/clean/008-*.patch \
         "$REPO"/patches/clean/009-*.patch "$REPO"/patches/clean/010-*.patch \
         "$REPO"/patches/clean/011-*.patch; do
    (cd "$BASE" && patch -p1 -N -s < "$p" 2>/dev/null || true)
done

# Fix 1: spmatrix.h
sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' \
    "$BASE/src/include/ngspice/spmatrix.h"

# Fix 2: spdefs.h
sed -i 's|^#define spREAL  double|#ifndef spREAL\n#define spREAL  SPICE_REAL\n#endif|' \
    "$BASE/src/maths/sparse/spdefs.h"

# Fix 3: smpdefs.h — rewrite with SMP_REAL
cat > "$BASE/src/include/ngspice/smpdefs.h" << 'ENDSMP'
#ifndef ngspice_SMPDEFS_H
#define ngspice_SMPDEFS_H
#include "ngspice/typedefs.h"
#include <stdio.h>
#include <math.h>
#include "ngspice/complex.h"
#ifdef KLU
#include "ngspice/klu.h"
#include "ngspice/spmatrix.h"
#endif
typedef struct MatrixFrame MatrixFrame;
typedef struct MatrixElement *SMPelement;
typedef struct sSMPmatrix { MatrixFrame *SPmatrix; } SMPmatrix;
#ifdef SINGLE_PRECISION
typedef SPICE_REAL SMP_REAL;
#else
typedef double SMP_REAL;
#endif
#ifdef KLU
void spDeterminant_KLU(SMPmatrix *, int *, SMP_REAL *, SMP_REAL *);
void SMPconvertCOOtoCSC(SMPmatrix *);
#else
int SMPaddElt(SMPmatrix *, int, int, SMP_REAL);
#endif
SMP_REAL *SMPmakeElt(SMPmatrix *, int, int);
void SMPcClear(SMPmatrix *); void SMPclear(SMPmatrix *);
int SMPcLUfac(SMPmatrix *, SMP_REAL);
int SMPluFac(SMPmatrix *, SMP_REAL, SMP_REAL);
int SMPcReorder(SMPmatrix *, SMP_REAL, SMP_REAL, int *);
int SMPreorder(SMPmatrix *, SMP_REAL, SMP_REAL, SMP_REAL);
void SMPcaSolve(SMPmatrix *, SMP_REAL[], SMP_REAL[], SMP_REAL[], SMP_REAL[]);
void SMPcSolve(SMPmatrix *, SMP_REAL[], SMP_REAL[], SMP_REAL[], SMP_REAL[]);
void SMPsolve(SMPmatrix *, SMP_REAL[], SMP_REAL[]);
int SMPmatSize(SMPmatrix *); int SMPnewMatrix(SMPmatrix *, int);
void SMPdestroy(SMPmatrix *); int SMPpreOrder(SMPmatrix *);
void SMPprint(SMPmatrix *, char *);
void SMPprintRHS(SMPmatrix *, char *, SMP_REAL*, SMP_REAL*);
void SMPgetError(SMPmatrix *, int *, int *);
int SMPcProdDiag(SMPmatrix *, SPcomplex *, int *);
int SMPcDProd(SMPmatrix *, SPcomplex *, int *);
SMPelement *SMPfindElt(SMPmatrix *, int, int, int);
int SMPcZeroCol(SMPmatrix *, int); int SMPcAddCol(SMPmatrix *, int, int);
int SMPzeroRow(SMPmatrix *, int);
void SMPconstMult(SMPmatrix *, SMP_REAL);
void SMPmultiply(SMPmatrix *, SMP_REAL *, SMP_REAL *, SMP_REAL *, SMP_REAL *);
#endif
ENDSMP

# Fix 4: spsmp.c — replace double with SMP_REAL in function signatures
SPSMP="$BASE/src/maths/sparse/spsmp.c"
sed -i 's/\(SMPaddElt.*\)double /\1SMP_REAL /g' "$SPSMP"
sed -i 's/\(SMPcLUfac.*\)double /\1SMP_REAL /g' "$SPSMP"
sed -i 's/\(SMPluFac.*\)double /\1SMP_REAL /g' "$SPSMP"
sed -i 's/\(SMPcReorder.*\)double /\1SMP_REAL /g' "$SPSMP"
sed -i 's/\(SMPreorder.*\)double /\1SMP_REAL /g' "$SPSMP"
sed -i 's/double RHS\[\]/SMP_REAL RHS[]/g' "$SPSMP"
sed -i 's/double iRHS\[\]/SMP_REAL iRHS[]/g' "$SPSMP"
sed -i 's/double Spare\[\]/SMP_REAL Spare[]/g' "$SPSMP"
sed -i 's/double iSpare\[\]/SMP_REAL iSpare[]/g' "$SPSMP"
sed -i 's/double RHSsolution\[\]/SMP_REAL RHSsolution[]/g' "$SPSMP"
sed -i 's/double iRHSsolution\[\]/SMP_REAL iRHSsolution[]/g' "$SPSMP"
sed -i 's/double constant/SMP_REAL constant/g' "$SPSMP"
sed -i 's/double \*RHS/SMP_REAL *RHS/g' "$SPSMP"
sed -i 's/double \*Solution/SMP_REAL *Solution/g' "$SPSMP"
sed -i 's/double \*iRHS/SMP_REAL *iRHS/g' "$SPSMP"
sed -i 's/double \*iSolution/SMP_REAL *iSolution/g' "$SPSMP"

# Fix 5: spsolve.c stdlib
sed -i '1s/^/#include <stdlib.h>\n/' "$BASE/src/maths/sparse/spsolve.c"

# Fix 6: Global — all device ext.h, noi.c, trunc.c — double* → SPICE_REAL*
find "$BASE/src/spicelib/devices" -name "*ext.h" -exec sed -i 's/double \*/SPICE_REAL */g' {} \;
find "$BASE/src/spicelib/devices" -name "*noi*.c" -exec sed -i 's/double \*OnDens/SPICE_REAL *OnDens/g' {} \;
find "$BASE/src/spicelib/devices" -name "*trunc*.c" -exec sed -i 's/double \*/SPICE_REAL */g' {} \;
find "$BASE/src/spicelib/devices" -name "*disto*.c" -exec sed -i 's/double \*/SPICE_REAL */g' {} \;

echo "--- Configure ---"
cd "$BASE"
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/cfg_auto.log 2>&1

echo "--- Iterative fix loop (max 20 rounds) ---"
for round in $(seq 1 20); do
    echo -n "  Round $round: "
    if make -j$(nproc) > /tmp/build_auto.log 2>&1; then
        echo "BUILD OK!"
        break
    fi
    errors=$(grep -c "error:" /tmp/build_auto.log || echo "0")
    echo "$errors errors"

    # Extract error patterns: "conflicting types for 'FUNCNAME'; have ... double ..."
    grep "error: conflicting types for" /tmp/build_auto.log | \
        sed "s/.*'\([^']*\)'.*/\1/" | sort -u > /tmp/funcs_to_fix.txt

    funcs=$(cat /tmp/funcs_to_fix.txt)
    if [ -z "$funcs" ]; then
        echo "  No conflicting-type errors found — remaining errors:"
        grep "error:" /tmp/build_auto.log | head -5
        break
    fi

    # For each conflicting function, find its definition and fix double* params
    for func in $funcs; do
        # Find files defining this function (not just declaring)
        def_files=$(grep -rl "^$func\b\|^.*\b$func(" "$BASE/src" --include="*.c" 2>/dev/null | head -3)
        for f in $def_files; do
            # Replace double* with SPICE_REAL* in the function signature context
            sed -i "/^$func\b/,/^{/ s/double \*/SPICE_REAL */g" "$f" 2>/dev/null || true
            sed -i "s/^$func(.*double \*/$func(SPICE_REAL */g" "$f" 2>/dev/null || true
        done
        # Also fix declarations in headers
        decl_files=$(grep -rl "$func" "$BASE/src/include" --include="*.h" 2>/dev/null | head -3)
        for f in $decl_files; do
            sed -i "s/\($func.*\)double \*/\1SPICE_REAL */g" "$f" 2>/dev/null || true
        done
    done
    echo "  Fixed $(wc -l < /tmp/funcs_to_fix.txt) functions"
done

echo ""
echo "=== Final status ==="
if [ -f "$BASE/src/ngspice" ]; then
    echo "Binary built successfully"
    objdump -d "$BASE/src/ngspice" 2>/dev/null | grep -c cvtss2sd && echo "cvtss2sd"
else
    echo "Build incomplete — remaining errors:"
    grep "error:" /tmp/build_auto.log | head -10
fi
