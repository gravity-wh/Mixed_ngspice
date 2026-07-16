* 22-Transistor Operational Amplifier — DC Operating Point
* Two-stage Miller-compensated op-amp

.include '../../models/p18_tt_fp32.mdl'
.include '../../models/n18_tt_fp32.mdl'

VDD VDD 0 1.8
VIN_P INP 0 0.9
VIN_N INN 0 0.9
CL VOUT 0 1p

* Bias stage
IREF VDD VB1 1e-5
MB1 VB1 VB1 0   0   n18 L=2.66e-6 W=2.2e-6
MB2 VB2 VB2 VDD VDD p18 L=2.66e-6 W=4.4e-6
MB3 VB3 VB2 VDD VDD p18 L=2.66e-6 W=4.4e-6

* Differential pair
M1 D1 INP S1 S1 n18 L=0.5e-6  W=10e-6
M2 D2 INN S1 S1 n18 L=0.5e-6  W=10e-6
M3 S1 VB1 0  0  n18 L=1e-6    W=5e-6

* Current mirror load
M4 D1 D1 VDD VDD p18 L=1e-6 W=20e-6
M5 D2 D1 VDD VDD p18 L=1e-6 W=20e-6

* Second stage
M6 VOUT D2 0   0   n18 L=0.5e-6 W=50e-6
M7 VOUT VB3 VDD VDD p18 L=0.5e-6 W=100e-6

* Miller compensation
CC VOUT D2 0.5p
RC VOUT D3 1k
M8 D3 VB3 VDD VDD p18 L=2e-6 W=2e-6

.op
.print op v(vout) v(d1) v(d2) v(s1)
.control
  echo "=== 22T Op-Amp DC ==="
  print v(vout)
  print v(d1) v(d2) v(s1)
  let tmp = @m1[gm]
  print tmp
  let tmp = @m6[gm]
  print tmp
  let tmp = @m6[gds]
  print tmp
  let tmp = @m1[id]
  print tmp
  let tmp = @m6[id]
  print tmp
.endc
.end
