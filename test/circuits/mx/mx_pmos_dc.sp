* PMOS DC OP — PTM45 LP BSIM4
.include ../../models/45nm_LP_BSIM4/ptm45lp.lib
VDD VDD 0 1.1
VG  G   0 0.55
M1  D G VDD VDD pmos W=2u L=45n
VD  D 0 0
.control
op
print v(d) i(vd)
.endc
.end
