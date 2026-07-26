#!/bin/bash
set -e
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_phase1
rm -rf "$BUILD" && mkdir -p "$BUILD"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
cd "$BUILD/ngspice-46"

# Patch 001
patch -p1 -N -s < "$REPO/patches/clean/001-typedefs.patch" 2>/dev/null || true

# spmatrix.h
sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' src/include/ngspice/spmatrix.h

# spdefs.h
sed -i 's|^#define spREAL  double|#ifndef spREAL\n#define spREAL  SPICE_REAL\n#endif|' src/maths/sparse/spdefs.h

# spsolve.c
sed -i '1s/^/#include <stdlib.h>\n/' src/maths/sparse/spsolve.c

# smpdefs.h and spsmp.c via python
python3 << "PYEOF"
import re, os
base = "/tmp/build_phase1/ngspice-46"

# smpdefs.h
with open(os.path.join(base, "src/include/ngspice/smpdefs.h"), "w") as f:
    f.write("""#ifndef ngspice_SMPDEFS_H
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
""")

# spsmp.c
with open(os.path.join(base, "src/maths/sparse/spsmp.c")) as f:
    c = f.read()
for old, new in [
    ("double Value","SMP_REAL Value"),("double PivTol","SMP_REAL PivTol"),
    ("double Gmin","SMP_REAL Gmin"),("double PivRel","SMP_REAL PivRel"),
    ("double constant","SMP_REAL constant"),(r"double RHS\[\]","SMP_REAL RHS[]"),
    (r"double iRHS\[\]","SMP_REAL iRHS[]"),(r"double Spare\[\]","SMP_REAL Spare[]"),
    (r"double iSpare\[\]","SMP_REAL iSpare[]"),(r"double RHSsolution\[\]","SMP_REAL RHSsolution[]"),
    (r"double iRHSsolution\[\]","SMP_REAL iRHSsolution[]"),
    (r"double \*RHS\b","SMP_REAL *RHS"),(r"double \*Solution\b","SMP_REAL *Solution"),
    (r"double \*iRHS\b","SMP_REAL *iRHS"),(r"double \*iSolution\b","SMP_REAL *iSolution"),
    ("double re, im","SMP_REAL re, im")]:
    c = re.sub(old, new, c)
c = c.replace("\ndouble *\nSMPmakeElt", "\nSMP_REAL *\nSMPmakeElt")
with open(os.path.join(base, "src/maths/sparse/spsmp.c"), "w") as f:
    f.write(c)
print("smpdefs.h + spsmp.c fixed")
PYEOF

# Build
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/cfg_p1.log 2>&1

make -j$(nproc) > /tmp/build_p1.log 2>&1
echo "errors: $(grep -c 'error:' /tmp/build_p1.log || echo 0)"
ls -la src/ngspice 2>/dev/null && echo "BINARY OK"
