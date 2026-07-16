* Single NMOS smoke test — Mixed_ngspice
* Tests basic diode-connected NMOS DC operating point

.include '../../models/n18_tt_fp32.mdl'

VDD VDD 0 1.8
MN1 vb1 vb1 0   0   n18 L=2.66e-6 W=4.4e-6

.op
.print op v(vb1)
.control
  echo "=== Single NMOS DC ==="
  print v(vb1)
  let tmp = @m1[gm]
  print tmp
  let tmp = @m1[gds]
  print tmp
  let tmp = @m1[vth]
  print tmp
  let tmp = @m1[id]
  print tmp
.endc
.end
