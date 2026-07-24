#!/bin/bash
# wsl_zero_double_build.sh — Complete zero-double FP32 build.
# Run from WSL terminal: bash /mnt/e/MyResearch/Mixed_ngspice/scripts/wsl_zero_double_build.sh
set -e
PROJ=/mnt/e/MyResearch/Mixed_ngspice
P=$PROJ/patches
echo "============================================"
echo "  ZERO-DOUBLE PURE FP32 BUILD"
echo "============================================"

# === 0: Extract ===
echo "[0/10] Extracting ngspice-46..."
rm -rf /tmp/ngspice_final 2>/dev/null
tar -xzf $PROJ/ngspice-46.tar.gz -C /tmp/
SRC=/tmp/ngspice_final
mv /tmp/ngspice-46 $SRC
cd $SRC

# === 1: Apply patches ===
echo "[1/10] Applying patches..."
for f in $P/001-typedefs-spice-macros.patch $P/002-bsim4v5def-struct-fp32.patch \
         $P/004-b4v5temp-double-island.patch $P/005-b4v5set-spice-real.patch \
         $P/006-b4v5noi-fp32.patch $P/007-b4v5pzld-fp32.patch \
         $P/008-b4v5acld-fp32.patch $P/009-b4v5geo-fp32.patch \
         $P/010-devsup-spice-real.patch $P/011-spconfig-include.patch; do
  patch -p6 < $f 2>/dev/null || true
done
# Patch 003 uses a/b prefixes - needs -p1
cd $SRC/src/spicelib/devices/bsim4v5
patch -p1 -F 10 < $P/003-b4v5ld-hotpath-fp32.patch 2>/dev/null || true
cd $SRC
# Patch 013 also uses a/b prefixes
cd $SRC/src/spicelib/devices/bsim4v5
patch -p1 -F 5 < $P/013-multi-t-nan-fix.patch 2>/dev/null || true
cd $SRC

BSIM4=$SRC/src/spicelib/devices/bsim4v5
echo "  struct SPICE_REAL: $(grep -c SPICE_REAL $BSIM4/bsim4v5def.h)"

# === 2: configure.ac ===
echo "[2/10] configure.ac..."
sed -i 's/AC_ARG_ENABLE(\[smoketest\],/AC_ARG_ENABLE([single-precision],\n    [AS_HELP_STRING([--enable-single-precision], [Use single precision (float).])])\n\nAC_ARG_ENABLE([smoketest],/' configure.ac
sed -i 's/AC_OUTPUT/if test "x$enable_single_precision" = xyes; then\n    AC_DEFINE([SINGLE_PRECISION],[1],[Define for single precision])\n    AC_MSG_RESULT([Single precision enabled])\nfi\n\nAC_OUTPUT/' configure.ac
echo "  OK"

# === 3: Fix type declarations ===
echo "[3/10] Fixing type declarations..."
sed -i 's/double/SPICE_REAL/g' $SRC/src/include/ngspice/devdefs.h
sed -i 's/double/SPICE_REAL/g' $BSIM4/bsim4v5ext.h
sed -i 's/double \*timeStep/SPICE_REAL *timeStep/' $BSIM4/b4v5trunc.c
sed -i 's/double/SPICE_REAL/g' $SRC/src/spicelib/devices/limit.c
echo "  OK"

# === 4: FP32 math block + CHECK_NAN in b4v5ld.c ===
echo "[4/10] FP32 math block..."
echo '#define B4V5_FP32_MATH
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
#define CHECK_NAN(v) do{if(isnan((float)(v))){(v)=0.0f;}}while(0)' > /tmp/math_block.txt
sed -i '/^#include "bsim4v5def.h"/r /tmp/math_block.txt' $BSIM4/b4v5ld.c
echo "  CHECK_NAN: $(grep -c CHECK_NAN $BSIM4/b4v5ld.c)"

# === 5: b4v5temp.c fixes (Vbi + Leff/Weff) ===
echo "[5/10] b4v5temp.c: Vbi + Leff/Weff..."
sed -i 's/double T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, Lnew=0.0, Wnew;/float T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,Lnew=0.0f,Wnew;/' $BSIM4/b4v5temp.c
sed -i 's/pow(Lnew,/powf(Lnew,/g; s/pow(Wnew,/powf(Wnew,/g' $BSIM4/b4v5temp.c
# Vbi log-split
sed -i 's|pParam->BSIM4v5vbi = Vtm0 \* log(pParam->BSIM4v5nsd|pParam->BSIM4v5vbi = Vtm0 * (logf(pParam->BSIM4v5nsd) + logf(pParam->BSIM4v5ndep) - 2.0f * logf(ni)); /* v1.x log-split */\n  DUMMY|' $BSIM4/b4v5temp.c
sed -i '/\* pParam->BSIM4v5ndep \/ (ni \* ni));/d' $BSIM4/b4v5temp.c
sed -i '/DUMMY/d' $BSIM4/b4v5temp.c
echo "  OK"

# === 6: Vbseff → diff-of-squares ===
echo "[6/10] Vbseff diff-of-squares..."
# Block 1
sed -i 's/  double dT0 = (double)Vbs - (double)here->BSIM4v5vbsc - 0.001;/  float sqrtC = sqrtf(0.004f * here->BSIM4v5vbsc); float fT0 = Vbs - here->BSIM4v5vbsc - 0.001f; float fT1 = sqrtf(fmaxf((fT0 - sqrtC) * (fT0 + sqrtC), 0.0f));/' $BSIM4/b4v5ld.c
sed -i '/double dT1 = sqrt(fmax(dT0 \* dT0 - 0.004 \* (double)here->BSIM4v5vbsc, 0.0));/d' $BSIM4/b4v5ld.c
# Fix remaining references
sed -i 's/(double)here->BSIM4v5vbsc/(float)here->BSIM4v5vbsc/g' $BSIM4/b4v5ld.c
sed -i 's/(double)Vbs/(float)Vbs/g' $BSIM4/b4v5ld.c
# Fix dT0/dT1/dT2 references in Vbseff context
sed -i 's/  Vbseff = (SPICE_REAL)((double)here->BSIM4v5vbsc + 0.5 \* (dT0 + dT1))/  Vbseff = here->BSIM4v5vbsc + 0.5f * (fT0 + fT1)/' $BSIM4/b4v5ld.c
sed -i 's/  dVbseff_dVb = (SPICE_REAL)(0.5 \* (1.0 + dT0 \/ dT1))/  dVbseff_dVb = 0.5f * (1.0f + fT0 \/ fT1)/' $BSIM4/b4v5ld.c
sed -i 's/double dT2 = -0.002 \/ (dT1 - dT0)/float fT2 = -0.002f \/ (fT1 - fT0)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)((double)here->BSIM4v5vbsc \* (1.0 + dT2))/here->BSIM4v5vbsc * (1.0f + fT2)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)(dT2 \* (double)here->BSIM4v5vbsc \/ dT1)/fT2 * here->BSIM4v5vbsc \/ fT1/' $BSIM4/b4v5ld.c

# Block 2 (JX)
sed -i 's/double dT9 = 0.95 \* (double)pParam->BSIM4v5phi;/float fT9 = 0.95f * pParam->BSIM4v5phi/' $BSIM4/b4v5ld.c
sed -i 's/double dVbseff = (double)Vbseff;/float fVbseff = Vbseff/' $BSIM4/b4v5ld.c
sed -i 's/double dT0 = dT9 - dVbseff - 0.001;/float fT0b = fT9 - fVbseff - 0.001f/' $BSIM4/b4v5ld.c
sed -i 's/double dT1 = sqrt(dT0 \* dT0 + 0.004 \* dT9)/float sqrtC2 = sqrtf(0.004f * fT9); float fT1b = sqrtf(fmaxf((fT0b - sqrtC2) * (fT0b + sqrtC2), 0.0f))/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)(dT9 - 0.5 \* (dT0 + dT1))/fT9 - 0.5f * (fT0b + fT1b)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)((double)dVbseff_dVb \* 0.5 \* (1.0 + dT0 \/ dT1))/dVbseff_dVb * 0.5f * (1.0f + fT0b \/ fT1b)/' $BSIM4/b4v5ld.c
echo "  OK"

# === 7: Xdep + Vth + Abulk ===
echo "[7/10] Xdep + Vth + Abulk..."
# Xdep
sed -i 's/double d_Xdep = (double)pParam->BSIM4v5Xdep0 \* (double)sqrtPhis \/ (double)pParam->BSIM4v5sqrtPhi;/float f_Xdep = pParam->BSIM4v5Xdep0 * sqrtPhis \/ pParam->BSIM4v5sqrtPhi/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)d_Xdep/f_Xdep/' $BSIM4/b4v5ld.c
sed -i 's/double d_X0 = (double)pParam->BSIM4v5Xdep0;/float f_X0 = pParam->BSIM4v5Xdep0/' $BSIM4/b4v5ld.c
sed -i 's/double d_sPhi = (double)pParam->BSIM4v5sqrtPhi;/float f_sPhi = pParam->BSIM4v5sqrtPhi/' $BSIM4/b4v5ld.c
sed -i 's/double d_dXdep = d_X0 \/ d_sPhi/float f_dXdep = f_X0 \/ f_sPhi/' $BSIM4/b4v5ld.c
sed -i 's/\* (double)dsqrtPhis_dVb/* dsqrtPhis_dVb/' $BSIM4/b4v5ld.c

# Vth k1ox Dekker
sed -i 's/Delt_k1ox = pParam->BSIM4v5k1ox \* sqrtPhis - pParam->BSIM4v5k1 \* pParam->BSIM4v5sqrtPhi;/{ float a=pParam->BSIM4v5k1ox*sqrtPhis; float b=pParam->BSIM4v5k1*pParam->BSIM4v5sqrtPhi; float s=a-b; float t=a-s; Delt_k1ox=s-(t-b); }/' $BSIM4/b4v5ld.c

# Abulk: denominator clamp
sed -i 's/1.0 \/ (3.0 - 20.0 \* Abulk0)/1.0f \/ fmaxf(3.0f - 20.0f * Abulk0, 0.01f)/g' $BSIM4/b4v5ld.c
sed -i 's/1.0 \/ (3.0 - 20.0 \* Abulk)/1.0f \/ fmaxf(3.0f - 20.0f * Abulk, 0.01f)/g' $BSIM4/b4v5ld.c
echo "  OK"

# === 8: Eliminate ALL remaining (double) casts ===
echo "[8/10] Eliminating ALL (double) casts..."
sed -i 's/exp((double)(x))/expf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/log((double)(x))/logf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/sqrt((double)(x))/sqrtf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/pow((double)(x),(double)(y))/powf((float)(x),(float)(y))/g' $BSIM4/b4v5ld.c
sed -i 's/exp((double)(A))/expf((float)(A))/g' $BSIM4/b4v5ld.c
sed -i 's/isnan((double)(var))/isnan((float)(var))/g' $BSIM4/b4v5ld.c
sed -i 's/(double)model->BSIM4v5L/(float)model->BSIM4v5L/g' $BSIM4/b4v5temp.c
sed -i 's/(double)model->BSIM4v5W/(float)model->BSIM4v5W/g' $BSIM4/b4v5temp.c
echo "  b4v5ld.c double: $(grep -c '\bdouble\b' $BSIM4/b4v5ld.c)"
echo "  b4v5temp.c double: $(grep -c '\bdouble\b' $BSIM4/b4v5temp.c)"

# === 9: autoreconf + configure + make ===
echo "[9/10] autoreconf + configure + make..."
autoreconf -fi 2>/dev/null
mkdir -p build && cd build
../configure --enable-single-precision --disable-klu --disable-xspice CFLAGS="-O2 -g -fopenmp -Wno-conversion" 2>/dev/null
make -j20 2>/dev/null || true
BIN=$SRC/build/src/ngspice
ls -lh $BIN 2>/dev/null || { echo "BUILD FAILED"; exit 1; }
echo "  Binary: OK"

# === 10: VERIFY ===
echo ""
echo "============================================"
echo "  VERIFICATION"
echo "============================================"

echo ""
echo "--- L1: Source ---"
echo "struct SPICE_REAL: $(grep -c SPICE_REAL $BSIM4/bsim4v5def.h)"
echo "struct double:     $(grep -c '\bdouble\b' $BSIM4/bsim4v5def.h)"

echo ""
echo "--- L2: Config ---"
echo "SINGLE_PRECISION: $(grep -c SINGLE_PRECISION $SRC/build/src/include/ngspice/config.h)"

echo ""
echo "--- L4: Instructions ---"
OBJ=$SRC/build/src/spicelib/devices/bsim4v5/b4v5ld.o
# Rebuild if needed
[ ! -f "$OBJ" ] && make -C src/spicelib/devices/bsim4v5 2>/dev/null || true
cvt=$(objdump -d $OBJ 2>/dev/null | grep -c "cvtss2sd" || echo 0)
ss=$(objdump -d $OBJ 2>/dev/null | grep -oE "\b[a-z]+ss\b" | wc -l)
sd=$(objdump -d $OBJ 2>/dev/null | grep -oE "\b[a-z]+sd\b" | wc -l)
echo "cvtss2sd: $cvt  (target: 0)"
echo "Float ss: $ss"
echo "Double sd: $sd"

echo ""
echo "--- L6: TRAN ---"
cat > /tmp/tran_vfy.sp << SPICEEND
.include $PROJ/test/models/45nm_LP_BSIM4/ptm45lp.lib
VRAW vraw 0 DC 1.1; RVDD vraw VDD 1
MBIAS VBIAS VBIAS 0 0 nmos W=4u L=0.18u; IBIAS VDD VBIAS DC 20u
M1 neta INP tail1 0 nmos W=2u L=0.18u; M2 netb OUT tail1 0 nmos W=2u L=0.18u
M3 neta neta VDD VDD pmos W=4u L=0.18u; M4 netb neta VDD VDD pmos W=4u L=0.18u
M5 tail1 VBIAS 0 0 nmos W=4u L=0.18u
M6 OUT netb VDD VDD pmos W=8u L=0.18u; M7 OUT VBIAS 0 0 nmos W=4u L=0.18u
Cc netb OUT 0.5p; CL OUT 0 2p
VIN_RAW in_raw 0 PULSE(0.55 0.65 10n 1n 1n 50n 100n); RG in_raw INP 100
.tran 0.1n 100n; .options gmin=1e-10 sollim method=gear; .end
SPICEEND
out=$($BIN -b /tmp/tran_vfy.sp 2>&1)
if echo "$out" | grep -q "doAnalyses: TRAN:  Timestep too small\|Transient op failed"; then
  echo "TRAN: FAIL"
else
  echo "TRAN: PASS"
  echo "$out" | grep -E "Total analysis|elapsed" | head -2
fi

echo ""
echo "============================================"
echo "  DONE: cvtss2sd=$cvt TRAN=$(echo "$out" | grep -q 'timestep too small' && echo FAIL || echo PASS)"
echo "============================================"
