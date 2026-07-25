#!/bin/bash
# Phase 1 REAL: Fix infrastructure for -DSINGLE_PRECISION
set -euo pipefail
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_fp32_p3

echo "=== Phase 1 REAL: Infrastructure fixes for SINGLE_PRECISION ==="
rm -rf "$BUILD"
mkdir -p "$BUILD"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
BASE="$BUILD/ngspice-46"

echo "--- Applying base patches ---"
for p in "$REPO"/patches/clean/001-*.patch "$REPO"/patches/clean/002-*.patch \
         "$REPO"/patches/clean/003-*.patch "$REPO"/patches/clean/004-*.patch \
         "$REPO"/patches/clean/005-*.patch "$REPO"/patches/clean/006-*.patch \
         "$REPO"/patches/clean/007-*.patch "$REPO"/patches/clean/008-*.patch \
         "$REPO"/patches/clean/009-*.patch "$REPO"/patches/clean/010-*.patch \
         "$REPO"/patches/clean/011-*.patch; do
    (cd "$BASE" && patch -p1 -N -s < "$p" 2>/dev/null || true)
done
echo "  patches applied"

echo "--- Fix 1: spmatrix.h spREAL conditional ---"
sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' \
    "$BASE/src/include/ngspice/spmatrix.h"
echo "  spmatrix.h fixed"

echo "--- Fix 2: smpdefs.h — SMP_REAL type ---"
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

typedef struct sSMPmatrix {
    MatrixFrame *SPmatrix;
#ifdef KLU
    KLUmatrix *SMPkluMatrix;
    unsigned int CKTkluMODE:1;
    #define CKTkluON 1
    #define CKTkluOFF 0
    double CKTkluMemGrowFactor;
#endif
} SMPmatrix;

#ifdef SINGLE_PRECISION
#define SMP_REAL SPICE_REAL
#else
#define SMP_REAL double
#endif

#ifdef KLU
void spDeterminant_KLU(SMPmatrix *, int *, SMP_REAL *, SMP_REAL *);
void SMPconvertCOOtoCSC(SMPmatrix *);
#ifdef CIDER
void SMPsolveKLUforCIDER(SMPmatrix *, double[], double[], double[], double[]);
int SMPreorderKLUforCIDER(SMPmatrix *);
double *SMPmakeEltKLUforCIDER(SMPmatrix *, int, int);
void SMPclearKLUforCIDER(SMPmatrix *);
void SMPconvertCOOtoCSCKLUforCIDER(SMPmatrix *);
void SMPdestroyKLUforCIDER(SMPmatrix *);
int SMPnewMatrixKLUforCIDER(SMPmatrix *, int, unsigned int);
int SMPluFacKLUforCIDER(SMPmatrix *);
void SMPprintKLUforCIDER(SMPmatrix *, char *);
#endif
#else
int SMPaddElt(SMPmatrix *, int, int, SMP_REAL);
#endif

SMP_REAL *SMPmakeElt(SMPmatrix *, int, int);
void SMPcClear(SMPmatrix *);
void SMPclear(SMPmatrix *);
int SMPcLUfac(SMPmatrix *, SMP_REAL);
int SMPluFac(SMPmatrix *, SMP_REAL, SMP_REAL);
int SMPcReorder(SMPmatrix *, SMP_REAL, SMP_REAL, int *);
int SMPreorder(SMPmatrix *, SMP_REAL, SMP_REAL, SMP_REAL);
void SMPcaSolve(SMPmatrix *, SMP_REAL[], SMP_REAL[], SMP_REAL[], SMP_REAL[]);
void SMPcSolve(SMPmatrix *, SMP_REAL[], SMP_REAL[], SMP_REAL[], SMP_REAL[]);
void SMPsolve(SMPmatrix *, SMP_REAL[], SMP_REAL[]);
int SMPmatSize(SMPmatrix *);
int SMPnewMatrix(SMPmatrix *, int);
void SMPdestroy(SMPmatrix *);
int SMPpreOrder(SMPmatrix *);
void SMPprint(SMPmatrix *, char *);
void SMPprintRHS(SMPmatrix *, char *, SMP_REAL*, SMP_REAL*);
void SMPgetError(SMPmatrix *, int *, int *);
int SMPcProdDiag(SMPmatrix *, SPcomplex *, int *);
int SMPcDProd(SMPmatrix *, SPcomplex *, int *);
SMPelement *SMPfindElt(SMPmatrix *, int, int, int);
int SMPcZeroCol(SMPmatrix *, int);
int SMPcAddCol(SMPmatrix *, int, int);
int SMPzeroRow(SMPmatrix *, int);
void SMPconstMult(SMPmatrix *, SMP_REAL);
void SMPmultiply(SMPmatrix *, SMP_REAL *, SMP_REAL *, SMP_REAL *, SMP_REAL *);
#ifdef CIDER
void SMPcSolveForCIDER(SMPmatrix *, double[], double[], double[], double[]);
int SMPluFacForCIDER(SMPmatrix *);
int SMPnewMatrixForCIDER(SMPmatrix *, int, int);
void SMPsolveForCIDER(SMPmatrix *, double[], double[]);
#endif
#endif
ENDSMP
echo "  smpdefs.h rewritten"

echo "--- Fix 3: spsmp.c SMP function signatures ---"
SPSMP="$BASE/src/maths/sparse/spsmp.c"
sed -i 's/double Value/SMP_REAL Value/g' "$SPSMP"
sed -i 's/double PivTol/SMP_REAL PivTol/g' "$SPSMP"
sed -i 's/double Gmin/SMP_REAL Gmin/g' "$SPSMP"
sed -i 's/double PivRel/SMP_REAL PivRel/g' "$SPSMP"
sed -i 's/double RHS\[\]/SMP_REAL RHS[]/g' "$SPSMP"
sed -i 's/double iRHS\[\]/SMP_REAL iRHS[]/g' "$SPSMP"
sed -i 's/double Spare\[\]/SMP_REAL Spare[]/g' "$SPSMP"
sed -i 's/double iSpare\[\]/SMP_REAL iSpare[]/g' "$SPSMP"
sed -i 's/double constant/SMP_REAL constant/g' "$SPSMP"
sed -i 's/double \*$/SMP_REAL */g' "$SPSMP"
sed -i 's/double RHSsolution\[\]/SMP_REAL RHSsolution[]/g' "$SPSMP"
sed -i 's/double iRHSsolution\[\]/SMP_REAL iRHSsolution[]/g' "$SPSMP"
echo "  spsmp.c fixed"

echo "--- Fix 4: spsolve.c add stdlib.h ---"
sed -i '1s/^/#include <stdlib.h>\n/' "$BASE/src/maths/sparse/spsolve.c"

echo "--- Configure + Build with SINGLE_PRECISION ---"
cd "$BASE"
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/cfg_p3.log 2>&1

echo "  Building..."
if make -j$(nproc) > /tmp/build_p3.log 2>&1; then
    echo "  BUILD OK!"
else
    echo "  BUILD FAILED — errors:"
    grep "error:" /tmp/build_p3.log | head -20
fi
