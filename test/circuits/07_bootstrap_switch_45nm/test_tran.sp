* Bootstrap Switch — 45nm HP PTM BSIM4

.include ../../models/45nm_HP_BSIM4/ptm45hp.lib

VVDD VDD 0 DC 1.0
VCLK CLKS 0 PULSE(0 1.0 0 100p 100p 4.9n 10n)
VIN VIN 0 SIN(0.5 0.3 10e6 0 0)

M1 VSAMPLED VGATE VIN 0 nmos W=2e-6 L=45e-9
M2 CB_TOP CLKN VDD VDD pmos W=1e-6 L=45e-9
M3 VGATE CLKS 0 0 nmos W=0.5e-6 L=45e-9
M4 VGATE CLKN CB_TOP VDD pmos W=2e-6 L=45e-9
M5 CB_BOT CLKS VDD VDD pmos W=1e-6 L=45e-9
CB CB_TOP CB_BOT 0.2p
MPinv CLKN CLKS VDD VDD pmos W=1e-6 L=45e-9
MNinv CLKN CLKS 0   0   nmos W=0.5e-6 L=45e-9
CS VSAMPLED 0 0.5p

.control
  echo "=== 07_bootstrap_switch ==="
  tran 10p 20n
  print v(vsampled) v(vin)
.endc
.end
