#!/usr/bin/env python3
"""Fix smpdefs.h and spsmp.c for SINGLE_PRECISION"""
import re, sys

base = sys.argv[1] if len(sys.argv) > 1 else '/tmp/build_phase1/ngspice-46'

# Write smpdefs.h
with open(f'{base}/src/include/ngspice/smpdefs.h', 'w') as f:
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

# Fix spsmp.c
with open(f'{base}/src/maths/sparse/spsmp.c') as f:
    c = f.read()
for old, new in [
    ("double Value","SMP_REAL Value"),("double PivTol","SMP_REAL PivTol"),
    ("double Gmin","SMP_REAL Gmin"),("double PivRel","SMP_REAL PivRel"),
    ("double constant","SMP_REAL constant"),("double RHS[]","SMP_REAL RHS[]"),
    ("double iRHS[]","SMP_REAL iRHS[]"),("double Spare[]","SMP_REAL Spare[]"),
    ("double iSpare[]","SMP_REAL iSpare[]"),("double RHSsolution[]","SMP_REAL RHSsolution[]"),
    ("double iRHSsolution[]","SMP_REAL iRHSsolution[]"),
    ("double *RHS","SMP_REAL *RHS"),("double *Solution","SMP_REAL *Solution"),
    ("double *iRHS","SMP_REAL *iRHS"),("double *iSolution","SMP_REAL *iSolution"),
    ("double re, im","SMP_REAL re, im")]:
    c = re.sub(old, new, c)
c = re.sub(r"^double \*$\n(SMPmakeElt)", r"SMP_REAL *\n\1", c, flags=re.MULTILINE)
with open(f'{base}/src/maths/sparse/spsmp.c', 'w') as f:
    f.write(c)

print("smpdefs.h + spsmp.c fixed")
