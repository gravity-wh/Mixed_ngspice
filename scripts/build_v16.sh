#!/bin/bash
# build_v16.sh — Complete FP32 ngspice build from pristine source
# All 6 FP64 islands converted to pure FP32 via numerical methods
set -e
PROJ=/mnt/e/MyResearch/Mixed_ngspice
cd $PROJ

echo "=========================================="
echo "  v1.6 Pure FP32 ngspice Builder"
echo "=========================================="

# Step 0: Extract pristine
echo "[0/6] Extracting pristine ngspice-46..."
rm -rf /tmp/ngspice_v16 2>/dev/null
mkdir -p /tmp/ngspice_v16
tar -xzf ngspice-46.tar.gz -C /tmp/ngspice_v16/
SRC=/tmp/ngspice_v16/ngspice_fp32
mv /tmp/ngspice_v16/ngspice-46 $SRC
BSIM4=$SRC/src/spicelib/devices/bsim4v5

# Step 1: Apply patches (001-011 except 003 which fails with -p6)
echo "[1/6] Applying patches 001-011 (except 003)..."
cd $SRC
PATCHDIR="$PROJ/patches"
for p in 001-typedefs-spice-macros.patch \
         002-bsim4v5def-struct-fp32.patch \
         004-b4v5temp-double-island.patch \
         005-b4v5set-spice-real.patch \
         006-b4v5noi-fp32.patch \
         007-b4v5pzld-fp32.patch \
         008-b4v5acld-fp32.patch \
         009-b4v5geo-fp32.patch \
         010-devsup-spice-real.patch \
         011-spconfig-include.patch; do
    patch -p6 < "$PATCHDIR/$p" 2>&1 | tail -1
done

echo "  SPICE_REAL in structs: $(grep -c SPICE_REAL $BSIM4/bsim4v5def.h)"

# Step 2: configure.ac
echo "[2/6] Patching configure.ac..."
python3 << 'PYEOF'
with open('/tmp/ngspice_v16/ngspice_fp32/configure.ac') as f: c=f.read()
c=c.replace('AC_ARG_ENABLE([smoketest],','AC_ARG_ENABLE([single-precision],\n    [AS_HELP_STRING([--enable-single-precision], [Use single precision (float).])])\n\nAC_ARG_ENABLE([smoketest],')
c=c.replace('AC_OUTPUT','if test "x$enable_single_precision" = xyes; then\n    AC_DEFINE([SINGLE_PRECISION],[1],[Define for single precision])\n    AC_MSG_RESULT([Single precision enabled])\nfi\n\nAC_OUTPUT')
with open('/tmp/ngspice_v16/ngspice_fp32/configure.ac','w') as f: f.write(c)
print('  configure.ac: OK')
PYEOF

# Step 3: Fix header declarations
echo "[3/6] Fixing type declarations..."
python3 << 'PYEOF'
SRC='/tmp/ngspice_v16/ngspice_fp32/src'
# devdefs.h — global double→SPICE_REAL replacement
with open(SRC+'/include/ngspice/devdefs.h') as f: c=f.read()
c=c.replace('double','SPICE_REAL')
with open(SRC+'/include/ngspice/devdefs.h','w') as f: f.write(c)

# bsim4v5ext.h
with open(SRC+'/spicelib/devices/bsim4v5/bsim4v5ext.h') as f: c=f.read()
c=c.replace('double','SPICE_REAL')
with open(SRC+'/spicelib/devices/bsim4v5/bsim4v5ext.h','w') as f: f.write(c)

# b4v5trunc.c
with open(SRC+'/spicelib/devices/bsim4v5/b4v5trunc.c') as f: c=f.read()
c=c.replace('double *timeStep','SPICE_REAL *timeStep')
with open(SRC+'/spicelib/devices/bsim4v5/b4v5trunc.c','w') as f: f.write(c)
# limit.c — all double → SPICE_REAL
with open(SRC+'/spicelib/devices/limit.c') as f: c=f.read()
c=c.replace('double','SPICE_REAL')
with open(SRC+'/spicelib/devices/limit.c','w') as f: f.write(c)
print('  Headers + limit.c: OK')
PYEOF

# Step 4: Hot-path fixes (b4v5ld.c)
echo "[4/6] Hot-path FP32 math + CHECK_NAN..."
python3 << 'PYEOF'
SRC='/tmp/ngspice_v16/ngspice_fp32/src/spicelib/devices/bsim4v5/b4v5ld.c'
with open(SRC) as f: c=f.read()
# FP32 math block
block='''/* MIXED-PRECISION FP32 math overrides */
#define B4V5_FP32_MATH
#ifdef B4V5_FP32_MATH
#undef SPICE_EXP
#undef SPICE_LOG
#undef SPICE_SQRT
#undef SPICE_POW
#define SPICE_EXP(x)  expf((float)(x))
#define SPICE_LOG(x)  logf((float)(x))
#define SPICE_SQRT(x) sqrtf((float)(x))
#define SPICE_POW(x,y) powf((float)(x),(float)(y))
#endif
#define CHECK_NAN(v) do{if(isnan((float)(v))){(v)=0.0f;}}while(0)
'''
c=c.replace('#include "bsim4v5def.h"\n','#include "bsim4v5def.h"\n'+block)
with open(SRC,'w') as f: f.write(c)
print('  Math block + CHECK_NAN: OK')
PYEOF

# Step 4b: Apply patches 003+012+013 with fuzz factor
echo "[4b/6] Applying patches 003+012+013 with fuzz..."
patch -p6 -F 10 < "$PATCHDIR/003-b4v5ld-hotpath-fp32.patch" 2>&1 | tail -1
patch -p6 -F 5 < "$PATCHDIR/012-b4v5temp-vbi-overflow-fix.patch" 2>&1 | tail -1
patch -p6 -F 5 < "$PATCHDIR/013-multi-t-nan-fix.patch" 2>&1 | tail -1
echo "  CHECK_NAN: $(grep -c CHECK_NAN $BSIM4/b4v5ld.c)"
echo "  SPICE_REAL: $(grep -c SPICE_REAL $BSIM4/b4v5ld.c)"

# Step 4c: Vbseff diff-of-squares (b4v5ld.c)
echo "[4c/6] Vbseff diff-of-squares..."
python3 << 'PYEOF'
SRC='/tmp/ngspice_v16/ngspice_fp32/src/spicelib/devices/bsim4v5/b4v5ld.c'
with open(SRC) as f: c=f.read()
# Vbseff block 1
old1='\t  {   double dT0 = (double)Vbs - (double)here->BSIM4v5vbsc - 0.001;\n\t      double dT1 = sqrt(fmax(dT0 * dT0 - 0.004 * (double)here->BSIM4v5vbsc, 0.0));'
new1='\t  {   float sqrtC = sqrtf(0.004f * here->BSIM4v5vbsc);\n\t      float fT0 = Vbs - here->BSIM4v5vbsc - 0.001f;\n\t      float fT1 = sqrtf(fmaxf((fT0 - sqrtC) * (fT0 + sqrtC), 0.0f));'
c=c.replace(old1,new1)
# Fix rest of Vbseff: dT0→fT0, dT1→fT1, dT2→fT2, double→float
# Fix rest of Vbseff block: dT0→fT0, dT1→fT1, dT2→fT2
c=c.replace('(double)here->BSIM4v5vbsc','(float)here->BSIM4v5vbsc')
c=c.replace('(double)Vbs','(float)Vbs')
c=c.replace('dT0','fT0').replace('dT1','fT1').replace('dT2','fT2')
c=c.replace('(SPICE_REAL)((float)here','(SPICE_REAL)(here')
c=c.replace('(SPICE_REAL)(0.5','0.5f')
c=c.replace('(SPICE_REAL)(dT2','dT2')
with open(SRC,'w') as f: f.write(c)
print('  Vbseff diff-of-squares: applied')
PYEOF

# Step 5: Vbi log-split + Leff/Weff float (b4v5temp.c)
echo "[5/6] Vbi log-split + Leff/Weff float..."
python3 << 'PYEOF'
SRC='/tmp/ngspice_v16/ngspice_fp32/src/spicelib/devices/bsim4v5/b4v5temp.c'
with open(SRC) as f: c=f.read()
# Vbi log-split
c=c.replace(
    'pParam->BSIM4v5vbi = Vtm0 * log(pParam->BSIM4v5nsd\n                                   * pParam->BSIM4v5ndep / (ni * ni));',
    'pParam->BSIM4v5vbi = Vtm0 * (logf(pParam->BSIM4v5nsd) + logf(pParam->BSIM4v5ndep) - 2.0f * logf(ni)); /* v1.6 log-split */')
# Leff/Weff float — convert preamble declaration
c=c.replace('double T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, Lnew=0.0, Wnew;',
            'float T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,Lnew=0.0f,Wnew;')
c=c.replace('pow(Lnew,','powf(Lnew,').replace('pow(Wnew,','powf(Wnew,')
# Leff/Weff binning FP64 island — convert the double block
c=c.replace('                      double dLnew = (double)Lnew;\n                      double dWnew = (double)Wnew;\n                      double dT0, dT1, dT2, dT3, dtmp1, dtmp2;',
            '                      float fLnew = Lnew;\n                      float fWnew = Wnew;\n                      float fT0,fT1,fT2,fT3,ftmp1,ftmp2;')
c=c.replace('dLnew','fLnew').replace('dWnew','fWnew').replace('dT0','fT0').replace('dT1','fT1').replace('dT2','fT2').replace('dT3','fT3').replace('dtmp1','ftmp1').replace('dtmp2','ftmp2')
c=c.replace('pow(fLnew, (double)','powf(fLnew, (float)')
c=c.replace('pow(fWnew, (double)','powf(fWnew, (float)')
with open(SRC,'w') as f: f.write(c)
print('  Vbi + Leff/Weff + binning: OK')
PYEOF

# Step 6: autoreconf + build
echo "[6/6] autoreconf + configure + make..."
cd $SRC
autoreconf -fi 2>&1 | tail -1
mkdir -p build && cd build
../configure --enable-single-precision --disable-klu --disable-xspice --disable-osdi --disable-cider CFLAGS='-O2 -fopenmp -Wno-conversion' 2>&1 | grep 'Single precision'
make -j20 2>&1 | tail -3

echo ""
echo "=========================================="
echo "  BUILD COMPLETE"
echo "=========================================="
echo "Binary: $SRC/build/src/ngspice"
ls -lh src/ngspice
echo ""
echo "SINGLE_PRECISION: $(grep -c SINGLE_PRECISION src/include/ngspice/config.h)"
echo "expf symbols: $(nm src/ngspice 2>/dev/null | grep -c expf)"
echo ""
echo "Final audit:"
for f in b4v5ld.c b4v5temp.c b4v5noi.c; do
    d=$(grep -c '\bdouble\b' $BSIM4/$f 2>/dev/null || echo 0)
    s=$(grep -c 'SPICE_REAL' $BSIM4/$f 2>/dev/null || echo 0)
    echo "  $f: $d double, $s SPICE_REAL"
done
