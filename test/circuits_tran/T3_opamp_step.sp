* T3: 2-Stage Miller Op-Amp — Closed-Loop Unity-Gain Buffer Step Response
* Technology: PTM 45nm LP, BSIM4 level=54, VDD=1.1V
* TRAN Analysis: Large-signal step response (0.55V -> 0.65V, 100mV step)
* Metrics: settling time, overshoot, slew rate
* Hardest TRAN test: 2-stage + Miller compensation -> multi-pole closed-loop

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 20u

VDD VDD 0 DC {VDD}

* Bias
MBIAS VBIAS VBIAS 0    0   nmos W=4u L=0.18u
IBIAS VDD VBIAS DC {ibias}

* Stage 1: PMOS diff pair + NMOS mirror — CLOSED LOOP: INN = OUT
M1 neta  INP tail1 0   nmos W=2u L=0.18u
M2 netb  OUT tail1 0   nmos W=2u L=0.18u
M3 neta neta VDD VDD   pmos W=4u L=0.18u
M4 netb neta VDD VDD   pmos W=4u L=0.18u
M5 tail1 VBIAS 0   0   nmos W=4u L=0.18u

* Stage 2: Common-source PMOS + NMOS current source
M6 OUT  netb VDD VDD   pmos W=8u L=0.18u
M7 OUT  VBIAS 0   0    nmos W=4u L=0.18u

* Miller compensation
Cc netb OUT 0.5p
CL OUT 0 2p

* Step input: 100mV large-signal step
VIN INP 0 PWL(0 0.55 20n 0.55 20.01n 0.65 200n 0.65)

.options gmin=1e-12 reltol=1e-5 method=gear
.tran 0.1n 200n

* Measures
.meas TRAN vout_final AVG v(out) FROM=180n TO=200n
.meas TRAN overshoot MAX v(out) FROM=20n TO=60n
.meas TRAN slew_rate DERIV v(out) AT=25n

.save v(out) v(inp) v(netb)

.control
run
print vout_final settle_1p overshoot
.endc
.end
