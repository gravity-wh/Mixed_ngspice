* T2: PMOS Gate Step Response — Switching Transient
* Technology: PTM 45nm LP, BSIM4 L54, VDD=1.1V
* TRAN: VGS pulse VDD→0.4V, measure drain pull-up switching

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* PMOS with resistive pull-down
M1 d g VDD VDD pmos W=4u L=45n
RD d 0 10k
CL d 0 10f

* Gate pulse: VDD→0.4V step at 1ns (turns PMOS ON)
VG g 0 PULSE(1.1 0.4 1n 100p 50p 5n 10n)

.tran 1p 10n
.options gmin=1e-10 sollim reltol=1e-5

.save v(g) v(d)

.control
run
.endc
.end
