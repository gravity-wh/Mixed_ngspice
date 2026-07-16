* 22-Transistor Op-Amp — Transient Test
* Step response with unity-gain feedback

.include '../../models/p18_tt_fp32.mdl'
.include '../../models/n18_tt_fp32.mdl'

VDD VDD 0 1.8
VIN INP 0 PWL(0 0.9 1u 0.9 1.001u 0.91 8u 0.91)
CL VOUT 0 1p

* Bias stage
IREF VDD VB1 1e-5
MB1 VB1 VB1 0   0   n18 L=2.66e-6 W=2.2e-6
MB2 VB2 VB2 VDD VDD p18 L=2.66e-6 W=4.4e-6
MB3 VB3 VB2 VDD VDD p18 L=2.66e-6 W=4.4e-6

* Differential pair
M1 D1 VB2 S1 S1 n18 L=0.5e-6  W=10e-6
M2 VOUT INN S1 S1 n18 L=0.5e-6  W=10e-6
M3 S1 VB1 0  0  n18 L=1e-6    W=5e-6

* Current mirror load
M4 D1 D1 VDD VDD p18 L=1e-6 W=20e-6
M5 VOUT D1 VDD VDD p18 L=1e-6 W=20e-6

* Second stage
M6 VOUT D2 0   0   n18 L=0.5e-6 W=50e-6
M7 VOUT VB3 VDD VDD p18 L=0.5e-6 W=100e-6

* Miller compensation
CC VOUT D2 0.5p

* Unity gain feedback
RIN INN INP 1k
RF INN VOUT 100k

.tran 0.01u 8u
.control
  echo "=== 22T Op-Amp Transient ==="
  print v(vout)
.endc
.end
