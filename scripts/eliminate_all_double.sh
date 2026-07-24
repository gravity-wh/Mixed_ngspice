#!/bin/bash
# eliminate_all_double.sh — Remove every last (double) cast from BSIM4v5 hot path
SRC=/tmp/ngspice_final/ngspice_fp32/src/spicelib/devices/bsim4v5

echo "=== Eliminating all remaining (double) casts ==="

# 1. SPICE_EXP/LOG/SQRT/POW macros — the biggest source
sed -i 's/exp((double)(x))/expf((float)(x))/g' $SRC/b4v5ld.c
sed -i 's/log((double)(x))/logf((float)(x))/g' $SRC/b4v5ld.c
sed -i 's/sqrt((double)(x))/sqrtf((float)(x))/g' $SRC/b4v5ld.c
sed -i 's/pow((double)(x),(double)(y))/powf((float)(x),(float)(y))/g' $SRC/b4v5ld.c

# 2. DEXP macro
sed -i 's/exp((double)(A))/expf((float)(A))/g' $SRC/b4v5ld.c
sed -i 's/(SPICE_REAL)exp((double)(A))/expf((float)(A))/g' $SRC/b4v5ld.c

# 3. CHECK_NAN — isnan works fine on float
sed -i 's/isnan((double)(var))/isnan((float)(var))/g' $SRC/b4v5ld.c

# 4. b4v5temp.c Leff/Weff block — model param casts
sed -i 's/(double)model->BSIM4v5L/(float)model->BSIM4v5L/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5W/(float)model->BSIM4v5W/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5Lint/(float)model->BSIM4v5Lint/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5Wint/(float)model->BSIM4v5Wint/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5dlc/(float)model->BSIM4v5dlc/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5dwc/(float)model->BSIM4v5dwc/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5dwj/(float)model->BSIM4v5dwj/g' $SRC/b4v5temp.c

# Also convert the lcdsc/wcdsc/pcdsc inv_L/Inv_W casts
sed -i 's/(double)model->BSIM4v5lcdsc/(float)model->BSIM4v5lcdsc/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5wcdsc/(float)model->BSIM4v5wcdsc/g' $SRC/b4v5temp.c
sed -i 's/(double)model->BSIM4v5pcdsc/(float)model->BSIM4v5pcdsc/g' $SRC/b4v5temp.c

# 5. Verify
echo ""
echo "Remaining double in b4v5ld.c: $(grep -c '\bdouble\b' $SRC/b4v5ld.c)"
echo "Remaining double in b4v5temp.c: $(grep -c '\bdouble\b' $SRC/b4v5temp.c)"

echo ""
echo "=== Rebuild b4v5ld.o ==="
cd /tmp/ngspice_final/ngspice_fp32/build
make -C src/spicelib/devices/bsim4v5 2>&1 | grep -c 'error:' || echo "0 errors"
ls -lh src/spicelib/devices/bsim4v5/b4v5ld.o 2>/dev/null && echo "OBJECT OK"

echo ""
echo "=== L4: Final instruction audit ==="
OBJ=src/spicelib/devices/bsim4v5/b4v5ld.o
if [ -f "$OBJ" ]; then
  cvt=$(objdump -d $OBJ 2>/dev/null | grep -c "cvtss2sd")
  ss=$(objdump -d $OBJ 2>/dev/null | grep -oE "\b[a-z]+ss\b" | wc -l)
  sd=$(objdump -d $OBJ 2>/dev/null | grep -oE "\b[a-z]+sd\b" | wc -l)
  echo "  cvtss2sd: $cvt"
  echo "  Float ss: $ss"
  echo "  Double sd: $sd"
fi
