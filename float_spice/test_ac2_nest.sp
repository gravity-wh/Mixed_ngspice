* AC2: Nested .lib with .include inside section
.lib 'test_nested_lib.lib' include_section
VDD VDD 0 1.1
VG  G   0 0.55
M1  D G 0 0 nmos_inc W=1u L=45n
VD D 0 1.1
.op
.control
  op
  print v(d)
.endc
.end
