* T1: NMOS Gate Step Response — Switching Transient
* Technology: PTM 45nm LP, BSIM4 L54, VDD=1.1V
* TRAN: VGS pulse 0→0.7V, measure drain voltage switching

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* NMOS with resistive load (inverter-like)
M1 d g 0 0 nmos W=2u L=45n
RD VDD d 10k
CL d 0 10f

* Gate pulse: 0→0.7V step at 1ns
VG g 0 PULSE(0 0.7 1n 100p 100p 5n 10n)

.tran 1p 10n
.options gmin=1e-10 sollim reltol=1e-5

.save v(g) v(d)

.control
run
.endc
.end
