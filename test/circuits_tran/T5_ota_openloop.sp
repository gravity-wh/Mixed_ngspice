* T5: OTA Open-Loop Step Response
* Technology: PTM 45nm LP, BSIM4 L54, VDD=1.1V
* TRAN: Differential input step → measure output slew
* Open-loop avoids feedback convergence issues

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* Bias
MBIAS VBIAS VBIAS 0 0 nmos W=4u L=0.18u
IBIAS VDD VBIAS DC 10u

* OTA core (open-loop)
M1 OUT  INP TAIL 0 nmos W=2u L=0.18u
M2 NETD INN TAIL 0 nmos W=2u L=0.18u
M3 OUT  NETD VDD VDD pmos W=4u L=0.18u
M4 NETD NETD VDD VDD pmos W=4u L=0.18u
M5 TAIL VBIAS 0 0 nmos W=4u L=0.18u

CL OUT 0 0.5p

* Differential input: INN fixed at 0.55V, INP steps from 0.55V to 0.56V (10mV step)
VINP INP 0 PWL(0 0.55 5n 0.55 5.1n 0.56 50n 0.56)
VINN INN 0 DC 0.55

.tran 0.1n 50n
.options gmin=1e-10 sollim reltol=1e-5 method=gear

.save v(INP) v(OUT)

.control
run
.endc
.end
