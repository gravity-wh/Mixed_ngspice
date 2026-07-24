* PMOS DC Sweep — PTM45 LP BSIM4
.include ../../models/45nm_LP_BSIM4/ptm45lp.lib
M1 D G VDD VDD pmos W=2u L=45n
VD D 0 1.1
VG G 0 0
.control
dc vd 0 1.1 0.01 vg 0 1.1 0.2
print i(vd)
.endc
.end
