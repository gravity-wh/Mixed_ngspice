#!/bin/bash
# Step 3: Eliminate ALL double from BSIM4v5 hot path
SRC=/tmp/ngspice_final/ngspice_fp32
BSIM4=$SRC/src/spicelib/devices/bsim4v5
cd $SRC

echo "=== 3a: Apply patch 013 (Vth k1ox + MIN_EXP) ==="
patch -p1 -F 10 < /mnt/e/MyResearch/Mixed_ngspice/patches/013-multi-t-nan-fix.patch 2>/dev/null || true
echo "  CHECK_NAN: $(grep -c CHECK_NAN $BSIM4/b4v5ld.c)"

echo ""
echo "=== 3b: Vbi → log-split ==="
sed -i 's|pParam->BSIM4v5vbi = (SPICE_REAL)((double)Vtm0 \* log((double)pParam->BSIM4v5nsd|pParam->BSIM4v5vbi = Vtm0 * (logf(pParam->BSIM4v5nsd) + logf(pParam->BSIM4v5ndep) - 2.0f * logf(ni)); // v1.7 log-split|' $BSIM4/b4v5temp.c
sed -i '/\* (double)pParam->BSIM4v5ndep \/ ((double)ni \* (double)ni)));/d' $BSIM4/b4v5temp.c
echo "  Vbi: OK"

echo ""
echo "=== 3c: Leff/Weff → float powf ==="
sed -i 's/double T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, Lnew=0.0, Wnew;/float T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,Lnew=0.0f,Wnew;/' $BSIM4/b4v5temp.c
sed -i 's/pow(Lnew,/powf(Lnew,/g; s/pow(Wnew,/powf(Wnew,/g' $BSIM4/b4v5temp.c
echo "  Leff/Weff: OK"

echo ""
echo "=== 3d: Vbseff → diff-of-squares ==="
# Block 1
sed -i 's/  {   double dT0 = (double)Vbs - (double)here->BSIM4v5vbsc - 0.001;/  {   float sqrtC = sqrtf(0.004f * here->BSIM4v5vbsc);\n      float fT0 = Vbs - here->BSIM4v5vbsc - 0.001f;\n      float fT1 = sqrtf(fmaxf((fT0 - sqrtC) * (fT0 + sqrtC), 0.0f));/' $BSIM4/b4v5ld.c
sed -i '/double dT1 = sqrt(fmax(dT0 \* dT0 - 0.004 \* (double)here->BSIM4v5vbsc, 0.0));/d' $BSIM4/b4v5ld.c
sed -i 's/if (dT0 >= 0.0)/if (fT0 >= 0.0f)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)((double)here->BSIM4v5vbsc + 0.5 \* (dT0 + dT1))/here->BSIM4v5vbsc + 0.5f * (fT0 + fT1)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)(0.5 \* (1.0 + dT0 \/ dT1))/0.5f * (1.0f + fT0 \/ fT1)/' $BSIM4/b4v5ld.c
sed -i 's/double dT2 = -0.002 \/ (dT1 - dT0)/float fT2 = -0.002f \/ (fT1 - fT0)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)((double)here->BSIM4v5vbsc \* (1.0 + dT2))/here->BSIM4v5vbsc * (1.0f + fT2)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)(dT2 \* (double)here->BSIM4v5vbsc \/ dT1)/fT2 * here->BSIM4v5vbsc \/ fT1/' $BSIM4/b4v5ld.c

# Block 2 (JX)
sed -i 's/double dT9 = 0.95 \* (double)pParam->BSIM4v5phi;/float fT9 = 0.95f * pParam->BSIM4v5phi/' $BSIM4/b4v5ld.c
sed -i 's/double dVbseff = (double)Vbseff;/float fVbseff = Vbseff/' $BSIM4/b4v5ld.c
sed -i 's/double dT0 = dT9 - dVbseff - 0.001;/float fT0b = fT9 - fVbseff - 0.001f/' $BSIM4/b4v5ld.c
sed -i 's/double dT1 = sqrt(dT0 \* dT0 + 0.004 \* dT9)/float sqrtC2 = sqrtf(0.004f * fT9);\n      float fT1b = sqrtf(fmaxf((fT0b - sqrtC2) * (fT0b + sqrtC2), 0.0f))/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)(dT9 - 0.5 \* (dT0 + dT1))/fT9 - 0.5f * (fT0b + fT1b)/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)((double)dVbseff_dVb \* 0.5 \* (1.0 + dT0 \/ dT1))/dVbseff_dVb * 0.5f * (1.0f + fT0b \/ fT1b)/' $BSIM4/b4v5ld.c
echo "  Vbseff: OK"

echo ""
echo "=== 3e: Xdep → float ==="
sed -i 's/double d_Xdep = (double)pParam->BSIM4v5Xdep0 \* (double)sqrtPhis \/ (double)pParam->BSIM4v5sqrtPhi;/float f_Xdep = pParam->BSIM4v5Xdep0 * sqrtPhis \/ pParam->BSIM4v5sqrtPhi;/' $BSIM4/b4v5ld.c
sed -i 's/(SPICE_REAL)d_Xdep/f_Xdep/' $BSIM4/b4v5ld.c
sed -i 's/double d_X0 = (double)pParam->BSIM4v5Xdep0;/float f_X0 = pParam->BSIM4v5Xdep0/' $BSIM4/b4v5ld.c
sed -i 's/double d_sPhi = (double)pParam->BSIM4v5sqrtPhi;/float f_sPhi = pParam->BSIM4v5sqrtPhi/' $BSIM4/b4v5ld.c
sed -i 's/double d_dXdep = d_X0 \/ d_sPhi/float f_dXdep = f_X0 \/ f_sPhi/' $BSIM4/b4v5ld.c
sed -i 's/        \* (double)dsqrtPhis_dVb/        * dsqrtPhis_dVb/' $BSIM4/b4v5ld.c
echo "  Xdep: OK"

echo ""
echo "=== 3f: Vth k1ox → Dekker ==="
sed -i 's/Delt_k1ox = pParam->BSIM4v5k1ox \* sqrtPhis - pParam->BSIM4v5k1 \* pParam->BSIM4v5sqrtPhi;/{ float a=pParam->BSIM4v5k1ox*sqrtPhis; float b=pParam->BSIM4v5k1*pParam->BSIM4v5sqrtPhi; float s=a-b; float t=a-s; Delt_k1ox=s-(t-b); }/' $BSIM4/b4v5ld.c
echo "  Vth: OK"

echo ""
echo "=== 3g: Abulk → denominator clamp ==="
sed -i 's/1.0 \/ (3.0 - 20.0 \* Abulk0)/1.0f \/ fmaxf(3.0f - 20.0f * Abulk0, 0.01f)/g' $BSIM4/b4v5ld.c
sed -i 's/1.0 \/ (3.0 - 20.0 \* Abulk)/1.0f \/ fmaxf(3.0f - 20.0f * Abulk, 0.01f)/g' $BSIM4/b4v5ld.c
echo "  Abulk: OK"

echo ""
echo "=== 3h: Global (double) cast elimination ==="
sed -i 's/exp((double)(x))/expf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/log((double)(x))/logf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/sqrt((double)(x))/sqrtf((float)(x))/g' $BSIM4/b4v5ld.c
sed -i 's/pow((double)(x),(double)(y))/powf((float)(x),(float)(y))/g' $BSIM4/b4v5ld.c
sed -i 's/isnan((double)(var))/isnan((float)(var))/g' $BSIM4/b4v5ld.c
sed -i 's/exp((double)(A))/expf((float)(A))/g' $BSIM4/b4v5ld.c
sed -i 's/(double)model->BSIM4v5L/(float)model->BSIM4v5L/g' $BSIM4/b4v5temp.c
sed -i 's/(double)model->BSIM4v5W/(float)model->BSIM4v5W/g' $BSIM4/b4v5temp.c
sed -i 's/(double)here->BSIM4v5vbsc/(float)here->BSIM4v5vbsc/g' $BSIM4/b4v5ld.c
sed -i 's/(double)Vbs/(float)Vbs/g' $BSIM4/b4v5ld.c
sed -i 's/(double)Vbseff/(float)Vbseff/g' $BSIM4/b4v5ld.c
sed -i 's/(double)pParam->BSIM4v5phi/(float)pParam->BSIM4v5phi/g' $BSIM4/b4v5ld.c
echo "  Cast elimination: OK"

echo ""
echo "=== Final double count ==="
echo "b4v5ld.c: $(grep -c '\bdouble\b' $BSIM4/b4v5ld.c)"
echo "b4v5temp.c: $(grep -c '\bdouble\b' $BSIM4/b4v5temp.c)"
