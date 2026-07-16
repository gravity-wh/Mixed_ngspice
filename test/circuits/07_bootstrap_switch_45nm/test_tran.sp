* Bootstrap Switch — 45nm HP PTM BSIM4
* Clock-boosted sampling switch for high-linearity analog sampling

.include ../../models/45nm_HP_BSIM4/ptm45hp.lib

.param VDD = 1.0
.param fclk = 100e6
.param tclk = 10n

* Supply
VVDD VDD 0 DC {VDD}

* Clock: 100MHz
VCLK CLKS 0 PULSE(0 {VDD} 0 100p 100p 4.9n {tclk})

* Input: 10MHz sine, 0.5V common-mode, 0.3V amplitude
VIN VIN 0 SIN(0.5 0.3 10e6 0 0)

* ── Bootstrap Switch Core ──
* M1: Main sampling switch (NMOS)
M1 VSAMPLED VGATE VIN 0 nmos W=2u L=0.045u

* M2: Clock switch — connects CB to VDD during reset
M2 CB_TOP CLKN VDD VDD pmos W=1u L=0.045u

* M3: Discharge switch — pulls VGATE low during reset
M3 VGATE CLKS 0 0 nmos W=0.5u L=0.045u

* M4: Bootstrap enable — connects CB_TOP to VGATE during evaluation
M4 VGATE CLKN CB_TOP VDD pmos W=2u L=0.045u

* M5: Charge switch — precharges CB during reset
M5 CB_BOT CLKS VDD VDD pmos W=1u L=0.045u

* Bootstrap capacitor
CB CB_TOP CB_BOT 0.2p

* Clock inverter (for CLKN)
MPinv CLKN CLKS VDD VDD pmos W=1u L=0.045u
MNinv CLKN CLKS 0   0   nmos W=0.5u L=0.045u

* Sampling capacitor
CS VSAMPLED 0 0.5p

.control
  echo "=== 07_bootstrap_switch TRAN ==="
  tran 10p 100n
  plot v(vin) v(vsampled)
  let gm_m1 = @m1[gm]
  echo "Sampling switch gm:"
  print gm_m1
.endc
.end
