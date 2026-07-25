#!/bin/bash
# Complete SINGLE_PRECISION build — infrastructure + all device patches
set -euo pipefail
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_sp_complete
rm -rf "$BUILD" && mkdir -p "$BUILD"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
BASE="$BUILD/ngspice-46"
cd "$BASE"

echo "1. Applying ALL patches (001-011)..."
for p in "$REPO"/patches/clean/00[1-9]-*.patch "$REPO"/patches/clean/010-*.patch "$REPO"/patches/clean/011-*.patch; do
    patch -p1 -N -s < "$p" 2>/dev/null && echo "  OK: $(basename $p)" || echo "  SKIP: $(basename $p)"
done

echo "2. Infrastructure fixes..."
sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' src/include/ngspice/spmatrix.h
sed -i 's|^#define spREAL  double|#ifndef spREAL\n#define spREAL  SPICE_REAL\n#endif|' src/maths/sparse/spdefs.h
sed -i '1s/^/#include <stdlib.h>\n/' src/maths/sparse/spsolve.c

echo "3. smpdefs.h..."
python3 -c "
h='''#ifndef ngspice_SMPDEFS_H
#define ngspice_SMPDEFS_H
#include <stdio.h>
#include <math.h>
#include \"ngspice/complex.h\"
#ifdef KLU
#include \"ngspice/klu.h\"
#include \"ngspice/spmatrix.h\"
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
#endif'''
with open('src/include/ngspice/smpdefs.h','w') as f: f.write(h)
"

echo "4. Fix spsmp.c..."
S=src/maths/sparse/spsmp.c
for pat in 'double Value' 'double PivTol' 'double Gmin' 'double PivRel' 'double constant'; do
    new="SMP_REAL ${pat#double }"
    sed -i "s/$pat/$new/g" "$S"
done
for arr in 'double RHS\b' 'double iRHS\b' 'double Spare\b' 'double iSpare\b' 'double RHSsolution\b' 'double iRHSsolution\b'; do
    new=$(echo "$arr" | sed 's/double/SMP_REAL/')
    sed -i "s/$arr/$new/g" "$S"
done
sed -i 's/double \*RHS/SMP_REAL *RHS/g' "$S"
sed -i 's/double \*Solution/SMP_REAL *Solution/g' "$S"
sed -i 's/double \*iRHS/SMP_REAL *iRHS/g' "$S"
sed -i 's/double \*iSolution/SMP_REAL *iSolution/g' "$S"
sed -i '125s/^double \*/SMP_REAL */' "$S"
sed -i 's/double re, im/SMP_REAL re, im/g' "$S"

echo "5. Fix device model function signatures (noise/trunc/eval)..."
# Use Python for robust regex replacement
python3 << 'PYEOF'
import re, os, glob

base = '/tmp/build_sp_complete/ngspice-46/src/spicelib/devices'

def fix_file(fpath):
    with open(fpath, 'r') as f:
        content = f.read()
    orig = content

    # Fix function declarations in headers
    for func_type in ['noise', 'trunc', 'dist', 'mosCap', 'evaluate', 'Evaluate']:
        # extern int XXXnoise(... double*) → SPICE_REAL*
        content = re.sub(
            rf'(extern\s+\w+\s+\w*{func_type}\w*\s*\([^)]*?)\bdouble\s*\*(?=\s*[,)])',
            r'\1SPICE_REAL *', content)

    # Fix function definitions in .c files
    for func_type in ['noise', 'trunc', 'dist', 'mosCap']:
        # XXXnoise(... double* OnDens) → SPICE_REAL*
        content = re.sub(
            rf'^(\w*{func_type}\w*\s*\([^)]*?)\bdouble\s*\*\s*OnDens',
            r'\1SPICE_REAL *OnDens', content, flags=re.MULTILINE)
        # XXXnoise(... double*) → SPICE_REAL*
        content = re.sub(
            rf'^(\w*{func_type}\w*\s*\([^)]*?)\bdouble\s*\*(?=\s*[,)])',
            r'\1SPICE_REAL *', content, flags=re.MULTILINE)

    if content != orig:
        with open(fpath, 'w') as f:
            f.write(content)
        return True
    return False

count = 0
for root, dirs, files in os.walk(base):
    for f in files:
        if f.endswith('.h') or f.endswith('.c'):
            if fix_file(os.path.join(root, f)):
                count += 1
print(f"Fixed {count} files")
PYEOF

echo "6. Configure + Build..."
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/cfg_full.log 2>&1

if make -j$(nproc) > /tmp/build_full.log 2>&1; then
    echo "BUILD SUCCESS!"
    echo "--- cvtss2sd ---"
    objdump -d src/ngspice 2>/dev/null | grep -c cvtss2sd || echo 0
    echo "--- fp32 SSE ---"
    objdump -d src/spicelib/devices/bsim4v5/b4v5ld.o 2>/dev/null | grep -cE 'mulss|addss|subss' || echo 0
else
    echo "Errors: $(grep -c 'error:' /tmp/build_full.log)"
    grep 'error:' /tmp/build_full.log | sed 's/.*error: //' | sort -u | head -15
fi
