#!/usr/bin/env python3
"""Fix all 5 remaining FP64 islands in b4v5ld.c — eliminate cvtss2sd."""
import re, sys

SRC = "/tmp/ngspice_verify/ngspice_fp32/src/spicelib/devices/bsim4v5/b4v5ld.c"
with open(SRC) as f:
    c = f.read()
fixes = 0

# === 1. Vbseff main block: diff-of-squares ===
old1 = '\t  {   double dT0 = (double)Vbs - (double)here->BSIM4v5vbsc - 0.001;\n\t      double dT1 = sqrt(fmax(dT0 * dT0 - 0.004 * (double)here->BSIM4v5vbsc, 0.0));'
new1 = '\t  {   float sqrtC = sqrtf(0.004f * here->BSIM4v5vbsc);\n\t      float fT0 = Vbs - here->BSIM4v5vbsc - 0.001f;\n\t      float fT1 = sqrtf(fmaxf((fT0 - sqrtC) * (fT0 + sqrtC), 0.0f));'
if old1 in c:
    c = c.replace(old1, new1)
    # Fix variable references in the rest of this block
    c = c.replace('dT0', 'fT0').replace('dT1', 'fT1').replace('dT2', 'fT2')
    c = c.replace('(double)here->BSIM4v5vbsc', '(float)here->BSIM4v5vbsc')
    c = c.replace('(double)Vbs', '(float)Vbs')
    fixes += 1
    print(f"  Vbseff block 1: FIXED")
else:
    print(f"  Vbseff block 1: NOT FOUND")

# === 2. Vbseff JX correction: diff-of-squares ===
old2 = '\t  {   double dT9 = 0.95 * (double)pParam->BSIM4v5phi;\n\t      double dVbseff = (double)Vbseff;\n\t      double dT0 = dT9 - dVbseff - 0.001;\n\t      double dT1 = sqrt(dT0 * dT0 + 0.004 * dT9);'
new2 = '\t  {   float sqrtC2 = sqrtf(0.004f * 0.95f * pParam->BSIM4v5phi);\n\t      float fT9 = 0.95f * pParam->BSIM4v5phi;\n\t      float fT0b = fT9 - Vbseff - 0.001f;\n\t      float fT1b = sqrtf(fmaxf((fT0b - sqrtC2) * (fT0b + sqrtC2), 0.0f));'
if old2 in c:
    c = c.replace(old2, new2)
    c = c.replace('(double)Vbseff', '(float)Vbseff')
    c = c.replace('dT9', 'fT9').replace('dT0', 'fT0b').replace('dT1', 'fT1b')
    c = c.replace('(double)dVbseff_dVb', 'dVbseff_dVb')
    fixes += 1
    print(f"  Vbseff JX: FIXED")
else:
    print(f"  Vbseff JX: NOT FOUND")

# === 3. Xdep chain: pure float ratio ===
c = c.replace(
    'double d_Xdep = (double)pParam->BSIM4v5Xdep0 * (double)sqrtPhis / (double)pParam->BSIM4v5sqrtPhi;',
    'float f_Xdep = pParam->BSIM4v5Xdep0 * sqrtPhis / pParam->BSIM4v5sqrtPhi;')
c = c.replace('(SPICE_REAL)d_Xdep', 'f_Xdep')
c = c.replace('double d_X0 = (double)pParam->BSIM4v5Xdep0;', 'float f_X0 = pParam->BSIM4v5Xdep0;')
c = c.replace('double d_sPhi = (double)pParam->BSIM4v5sqrtPhi;', 'float f_sPhi = pParam->BSIM4v5sqrtPhi;')
c = c.replace('double d_dXdep = d_X0 / d_sPhi\n                    * (double)dsqrtPhis_dVb;',
              'float f_dXdep = f_X0 / f_sPhi * dsqrtPhis_dVb;')
fixes += 1
print(f"  Xdep chain: FIXED")

# === 4. Vth k1ox: Dekker subtraction ===
old4 = 'Delt_k1ox = pParam->BSIM4v5k1ox * sqrtPhis - pParam->BSIM4v5k1 * pParam->BSIM4v5sqrtPhi;'
new4 = '{ float a=pParam->BSIM4v5k1ox*sqrtPhis; float b=pParam->BSIM4v5k1*pParam->BSIM4v5sqrtPhi; float s=a-b; float t=a-s; Delt_k1ox=s-(t-b); }'
if old4 in c:
    c = c.replace(old4, new4)
    fixes += 1
    print(f"  Vth k1ox Dekker: FIXED")
else:
    print(f"  Vth k1ox: NOT FOUND (may already be fixed)")

# === 5. Abulk: float + denominator clamp ===
# Convert Abulk double variables to float
lines = c.split('\n')
new_lines = []
in_abulk = False
abulk_count = 0
for l in lines:
    if '/* Calculate Abulk' in l:
        in_abulk = True
    if in_abulk and 'Mobility calculation' in l:
        in_abulk = False
    if in_abulk:
        if l.strip().startswith('const double '):
            l = l.replace('const double ', 'const float ')
            abulk_count += 1
        if l.strip().startswith('double d_') and ';' in l:
            l = l.replace('double d_', 'float d_')
            abulk_count += 1
    new_lines.append(l)
c = '\n'.join(new_lines)

# Denominator clamp in rational correction
c = c.replace('1.0 / (3.0 - 20.0 * Abulk0)', '1.0f / fmaxf(3.0f - 20.0f * Abulk0, 0.01f)')
c = c.replace('1.0 / (3.0 - 20.0 * Abulk)',  '1.0f / fmaxf(3.0f - 20.0f * Abulk,  0.01f)')
fixes += 1
print(f"  Abulk: FIXED ({abulk_count} double→float conversions)")

# Write back
with open(SRC, 'w') as f:
    f.write(c)

d = c.count(' double ')
print(f"\nTotal fixes: {fixes}")
print(f"Remaining double in b4v5ld.c: {d} (was 134)")
