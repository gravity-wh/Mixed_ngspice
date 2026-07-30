* CMOS inverter VIN=VDD — NMOS ON, PMOS OFF, OUT→0
.include ../test/models/45nm_LP_BSIM4/ptm45lp.lib
VDD VDD 0 1.1
VIN IN 0 1.1
M1 OUT IN VDD VDD pmos W=2u L=45n
M2 OUT IN 0 0 nmos W=1u L=45n
.op
.end
