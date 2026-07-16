* 17-Stage Ring Oscillator — 45nm LP PTM BSIM4
* NOTE: This circuit requires additional tuning for reliable startup.
* The current version demonstrates BSIM4 model loading and DC evaluation.

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* Single inverter DC test (for baseline validation)
MP1 out in VDD VDD pmos W=2u L=45n
MN1 out in 0   0   nmos W=1u L=45n
VIN in 0 DC 0.55

.op
.control
  echo "=== 03_ring_oscillator (DC baseline) ==="
  op
  print v(out)
  let gm_p = @m.mp1[gm]
  let gm_n = @m.mn1[gm]
  let id_p = @m.mp1[id]
  print gm_p gm_n id_p
.endc
.end
