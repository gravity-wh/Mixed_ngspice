* Two-Stage Miller Op-Amp DC — 45nm LP PTM BSIM4
* PMOS input pair + NMOS current mirror + PMOS second stage + Miller compensation

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 20u

VDD VDD 0 DC {VDD}
VINP INP 0 DC 0.55
VINN INN 0 DC 0.55

* Bias: diode-connected PMOS
MBIAS PBIAS PBIAS VDD VDD pmos W=4u L=0.18u
IBIAS PBIAS 0 DC {ibias}

* First stage: PMOS differential pair
M5 TAIL PBIAS VDD VDD pmos W=4u L=0.18u
M1 A INN  TAIL VDD pmos W=4u L=0.18u
M2 B INP  TAIL VDD pmos W=4u L=0.18u

* NMOS current-mirror load
M3 A A 0 0 nmos W=2u L=0.18u
M4 B A 0 0 nmos W=2u L=0.18u

* Second stage: common-source NMOS with PMOS current load
M6 OUT PBIAS VDD VDD pmos W=8u L=0.18u
M7 OUT B     0   0   nmos W=4u L=0.18u

* Miller compensation
CC B OUT 0.5p

.op
.control
  echo "=== 05_opamp_2stage DC ==="
  op
  print v(out) v(a) v(b) v(tail)
  let gm1  = @m1[gm]
  let gm7  = @m7[gm]
  let gds7 = @m7[gds]
  let id5  = @m5[id]
  print gm1 gm7 gds7 id5
.endc
.end
