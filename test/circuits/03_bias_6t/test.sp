* 6-Transistor Bias Circuit — Mixed_ngspice
* Wide-swing cascode bias generator

.include '../../models/p18_tt_fp32.mdl'
.include '../../models/n18_tt_fp32.mdl'

VDD VDD 0 1.8
IREF VDD vb1 1e-5

MP1 vb2 vb2 VDD VDD p18 L=2.66e-6 W=4.4e-6
MP2 vb3 vb2 vb2  VDD p18 L=2.66e-6 W=8.8e-6
MN1 vb1 vb1 0   0   n18 L=2.66e-6 W=2.2e-6
MN2 vb2 vb1 vb3 0   n18 L=2.66e-6 W=2.2e-6
MN3 vb3 vb2 0   0   n18 L=2.66e-6 W=2.2e-6

.op
.print op v(vb1) v(vb2) v(vb3)
.control
  echo "=== 6T Bias DC ==="
  print v(vb1) v(vb2) v(vb3)
  let tmp = @m1[gm]
  print tmp
  let tmp = @m1[id]
  print tmp
  let tmp = @m2[gm]
  print tmp
  let tmp = @m2[id]
  print tmp
.endc
.end
