* Single NMOS DC Operating Point — 45nm LP PTM BSIM4
* Validates basic BSIM4v5 evaluation on a single transistor

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 1.1
VG  G   0 0.55
M1  D G 0 0 nmos W=1u L=45n

VD D 0 1.1

.op

Vdd VDD 0 DC 1.8
Vss VSS 0 DC 0
.option gmin=1e-12
.control
  echo "=== 01_single_nmos_45nm DC ==="
  op
  print v(d)
  let gm  = @m1[gm]
  let gds = @m1[gds]
  let vth = @m1[vth]
  let id  = @m1[id]
  print gm gds vth id
.endc
.end
