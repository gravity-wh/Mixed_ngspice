* Single PMOS smoke test — Mixed_ngspice
* Tests basic diode-connected PMOS DC operating point

.include '../../models/p18_tt_fp32.mdl'

VDD VDD 0 1.8
MP1 vb2 vb2 VDD VDD p18 L=2.66e-6 W=4.4e-6

.op
.print op v(vb2)
.control
  echo "=== Single PMOS DC ==="
  print v(vb2)
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
