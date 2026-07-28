* AC1: Basic .lib section parsing test
.lib '../test/models/45nm_LP_BSIM4/test_section.lib' nmos_section
VDD VDD 0 1.1
VG  G   0 0.55
M1  D G 0 0 nmos W=1u L=45n
VD D 0 1.1
.op
.control
  op
  print v(d)
.endc
.end
