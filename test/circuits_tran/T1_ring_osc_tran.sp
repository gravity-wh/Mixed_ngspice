* T1: 17-Stage Ring Oscillator — Frequency Measurement
* Technology: PTM 45nm LP, BSIM4 level=54, VDD=1.1V
* TRAN Analysis: Free-running oscillation with startup injection
* Metrics: period, frequency (FP32 vs FP64 deviation < 0.5%)

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1

VDD VDD 0 DC {VDD}

* 17-stage inverter chain
.subckt inv in out vdd
Mp out in vdd vdd pmos W=2u L=45n
Mn out in 0   0   nmos W=1u L=45n
.ends inv

X1  n1  n2  VDD inv
X2  n2  n3  VDD inv
X3  n3  n4  VDD inv
X4  n4  n5  VDD inv
X5  n5  n6  VDD inv
X6  n6  n7  VDD inv
X7  n7  n8  VDD inv
X8  n8  n9  VDD inv
X9  n9  n10 VDD inv
X10 n10 n11 VDD inv
X11 n11 n12 VDD inv
X12 n12 n13 VDD inv
X13 n13 n14 VDD inv
X14 n14 n15 VDD inv
X15 n15 n16 VDD inv
X16 n16 n17 VDD inv
X17 n17 n1  VDD inv

* Startup injection: NMOS shorts n1 to GND for first 5ns
Mstart n1 start 0 0 nmos W=0.5u L=45n
Vstart start 0 PULSE(1.1 0 0 10p 10p 5n 100n)

* Initial condition: break symmetry
.ic v(n1)=0 v(n2)=1.1

.options gmin=1e-12 reltol=1e-5 method=gear
.tran 1p 10n uic

* Measure frequency
.meas TRAN period TRIG v(n1) VAL=0.55 RISE=3 TARG v(n1) VAL=0.55 RISE=4
.meas TRAN freq PARAM='1/period'

* Save key node for waveform comparison
.save v(n1) v(n9) v(n17)

.control
run
print period freq
.endc
.end
