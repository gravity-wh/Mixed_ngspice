#!/bin/bash
# finish_sp_build.sh — Complete the SINGLE_PRECISION build
# Run INSIDE WSL: bash /mnt/e/MyResearch/Mixed_ngspice/scripts/finish_sp_build.sh
set -euo pipefail

BUILD=/tmp/build_fp32_v2
BASE=$BUILD/ngspice-46
REPO=/mnt/e/MyResearch/Mixed_ngspice

if [ ! -d "$BASE" ]; then
    echo "Setting up build..."
    rm -rf "$BUILD" && mkdir -p "$BUILD"
    tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"

    echo "Applying patches..."
    for p in "$REPO"/patches/clean/0*.patch; do
        (cd "$BASE" && patch -p1 -N -s < "$p" 2>/dev/null || true)
    done

    # Infrastructure fixes
    sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' "$BASE/src/include/ngspice/spmatrix.h"
    sed -i 's|^#define spREAL  double|#ifndef spREAL\n#define spREAL  SPICE_REAL\n#endif|' "$BASE/src/maths/sparse/spdefs.h"
    sed -i '1s/^/#include <stdlib.h>\n/' "$BASE/src/maths/sparse/spsolve.c"
    cp "$REPO/ngspice-46/src/include/ngspice/fp32_math.h" "$BASE/src/include/ngspice/"

    # Rewrite smpdefs.h
    cat > "$BASE/src/include/ngspice/smpdefs.h" << 'ENDSMP'
#ifndef ngspice_SMPDEFS_H
#define ngspice_SMPDEFS_H
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
typedef float SMP_REAL;
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

    ./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
        CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
        --prefix="$BUILD/install" > /tmp/cfg_sp.log 2>&1
fi

cd "$BASE"

# Fix spsmp.c signatures
S="$BASE/src/maths/sparse/spsmp.c"
sed -i 's/\bdouble Value\b/SMP_REAL Value/g' "$S"
sed -i 's/\bdouble PivTol\b/SMP_REAL PivTol/g' "$S"
sed -i 's/\bdouble Gmin\b/SMP_REAL Gmin/g' "$S"
sed -i 's/\bdouble PivRel\b/SMP_REAL PivRel/g' "$S"
sed -i 's/\bdouble constant\b/SMP_REAL constant/g' "$S"
sed -i 's/\bdouble RHS\[\]/SMP_REAL RHS[]/g' "$S"
sed -i 's/\bdouble iRHS\[\]/SMP_REAL iRHS[]/g' "$S"
sed -i 's/\bdouble Spare\[\]/SMP_REAL Spare[]/g' "$S"
sed -i 's/\bdouble iSpare\[\]/SMP_REAL iSpare[]/g' "$S"
sed -i 's/\bdouble RHSsolution\[\]/SMP_REAL RHSsolution[]/g' "$S"
sed -i 's/\bdouble iRHSsolution\[\]/SMP_REAL iRHSsolution[]/g' "$S"
sed -i 's/\bdouble \*RHS\b/SMP_REAL *RHS/g' "$S"
sed -i 's/\bdouble \*Solution\b/SMP_REAL *Solution/g' "$S"
sed -i 's/\bdouble \*iRHS\b/SMP_REAL *iRHS/g' "$S"
sed -i 's/\bdouble \*iSolution\b/SMP_REAL *iSolution/g' "$S"
sed -i '125s/\bdouble \*/SMP_REAL */' "$S"

# Fix device model declarations globally
echo "Fixing device model signatures..."
find "$BASE/src/spicelib/devices" \( -name "*.h" -o -name "*.c" \) | while read f; do
    # noise function declarations and definitions
    sed -i 's/\(\bnoise\b[^(]*([^)]*\)double\s*\*/\1SPICE_REAL */g' "$f"
    # trunc function declarations and definitions
    sed -i 's/\(\btrunc\b[^(]*([^)]*\)double\s*\*/\1SPICE_REAL */g' "$f"
    # disto function declarations and definitions
    sed -i 's/\(\bdisto\b[^(]*([^)]*\)double\s*\*/\1SPICE_REAL */g' "$f"
done

# Build
echo "Building..."
if make -j$(nproc) > /tmp/build_sp.log 2>&1; then
    echo "BUILD SUCCESS!"
    objdump -d "$BASE/src/ngspice" 2>/dev/null | grep -c cvtss2sd || echo "0 cvtss2sd"
else
    echo "Errors: $(grep -c 'error:' /tmp/build_sp.log)"
    echo "=== Remaining errors ==="
    grep 'error:' /tmp/build_sp.log | sed 's/.*error: //' | sort -u | head -15
fi
