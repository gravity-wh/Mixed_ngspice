* Simple CMOS inverter — 2 MOSFETs  
.include ../test/models/45nm_LP_BSIM4/ptm45lp.lib
VDD VDD 0 1.1
VIN IN 0 0.55
M1 OUT IN VDD VDD pmos W=2u L=45n
M2 OUT IN 0 0 nmos W=1u L=45n
.op
.end
