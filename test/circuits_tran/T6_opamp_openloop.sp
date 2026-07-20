* T6: OpAmp Open-Loop Step Response
* Technology: PTM 45nm LP, BSIM4 L54, VDD=1.1V
* TRAN: Differential input step → measure output slew + settling
* Open-loop avoids feedback convergence issues

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* Bias
MBIAS VBIAS VBIAS 0 0 nmos W=4u L=0.18u
IBIAS VDD VBIAS DC 20u

* Stage 1: PMOS diff pair + NMOS mirror
M1 neta INP tail1 0 nmos W=2u L=0.18u
M2 netb INN tail1 0 nmos W=2u L=0.18u
M3 neta neta VDD VDD pmos W=4u L=0.18u
M4 netb neta VDD VDD pmos W=4u L=0.18u
M5 tail1 VBIAS 0 0 nmos W=4u L=0.18u

* Stage 2: Common-source PMOS + NMOS current source
M6 OUT netb VDD VDD pmos W=8u L=0.18u
M7 OUT VBIAS 0 0 nmos W=4u L=0.18u

* Miller compensation
Cc netb OUT 0.5p
CL OUT 0 2p

* Input: INN=0.55V, INP steps 0.55→0.551V (1mV small-signal)
VINP INP 0 PWL(0 0.55 10n 0.55 10.1n 0.551 200n 0.551)
VINN INN 0 DC 0.55

.tran 0.1n 200n
.options gmin=1e-10 sollim reltol=1e-5 method=gear

.save v(INP) v(OUT) v(netb)

.control
run
.endc
.end
