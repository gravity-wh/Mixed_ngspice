* T7: CMOS Inverter Chain — Propagation Delay
* Technology: PTM 45nm LP, BSIM4 L54, VDD=1.1V
* TRAN: Pulse through 5-inverter chain → measure delay

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

VDD VDD 0 DC 1.1

* 5-stage inverter chain
.subckt inv in out vdd
Mp out in vdd vdd pmos W=2u L=45n
Mn out in 0   0   nmos W=1u L=45n
.ends inv

X1 in  n1 VDD inv
X2 n1  n2 VDD inv
X3 n2  n3 VDD inv
X4 n3  n4 VDD inv
X5 n4 out VDD inv

* Load caps on each node
C1 n1 0 1f
C2 n2 0 1f
C3 n3 0 1f
C4 n4 0 1f
CL out 0 5f

* Input pulse
VIN in 0 PULSE(0 1.1 1n 100p 100p 2n 5n)

.tran 1p 5n
.options gmin=1e-10 sollim reltol=1e-5

.save v(in) v(n1) v(n3) v(out)

.control
run
.endc
.end
