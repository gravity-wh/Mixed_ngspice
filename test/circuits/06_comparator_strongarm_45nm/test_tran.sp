* StrongArm Dynamic Comparator — 45nm HP PTM BSIM4
* DC evaluation of comparator transistors (TRAN startup needs tuning)

.include ../../models/45nm_HP_BSIM4/ptm45hp.lib

VVDD VDD 0 DC 1.0
VINP INP 0 DC 0.55
VINN INN 0 DC 0.50
VCLK CLK 0 DC 1.0

M7  VXP CLK VDD VDD pmos W=1.2e-6 L=45e-9
M8  VXN CLK VDD VDD pmos W=1.2e-6 L=45e-9
M9  VLP CLK VDD VDD pmos W=1.2e-6 L=45e-9
M10 VLN CLK VDD VDD pmos W=1.2e-6 L=45e-9
M0  VS  CLK 0   0   nmos W=2.4e-6 L=45e-9
M1  VXP INP VS  0   nmos W=2.0e-6 L=45e-9
M2  VXN INN VS  0   nmos W=2.0e-6 L=45e-9
M3  VLP VLN VXP 0   nmos W=1.0e-6 L=45e-9
M4  VLN VLP VXN 0   nmos W=1.0e-6 L=45e-9
M5  VLP VLN VDD VDD pmos W=2.0e-6 L=45e-9
M6  VLN VLP VDD VDD pmos W=2.0e-6 L=45e-9
M11 OUTP VLP VDD VDD pmos W=1.0e-6 L=45e-9
M12 OUTP VLP 0   0   nmos W=0.5e-6 L=45e-9
M13 OUTN VLN VDD VDD pmos W=1.0e-6 L=45e-9
M14 OUTN VLN 0   0   nmos W=0.5e-6 L=45e-9

.op
.control
  echo "=== 06_comparator_strongarm DC ==="
  op
  print v(vxp) v(vxn) v(vlp) v(vln) v(vs)
  let gm_in = @m1[gm]
  let id_tail = @m0[id]
  print gm_in id_tail
.endc
.end
