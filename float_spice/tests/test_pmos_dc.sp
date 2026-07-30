* Single PMOS DC test — |VGS|=1.0V, |VDS|=1.0V
.include ../test/models/45nm_LP_BSIM4/ptm45lp.lib
VDD VDD 0 1.0
M1 0 G VDD VDD pmos W=2u L=45n
VG G 0 0
.op
.end
