* Single PMOS DC Operating Point — 45nm LP PTM BSIM4
* Validates basic BSIM4v5 evaluation on a single PMOS

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 1.1
VG  G   0 0.55
M1  D G VDD VDD pmos W=2u L=45n

VD D 0 0

.op
.control
  echo "=== 02_single_pmos_45nm DC ==="
  op
  print v(d)
  let gm  = @m1[gm]
  let gds = @m1[gds]
  let vth = @m1[vth]
  let id  = @m1[id]
  print gm gds vth id
.endc
.end
