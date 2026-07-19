* T2: 5-Transistor OTA — Closed-Loop Unity-Gain Buffer Step Response
* Technology: PTM 45nm LP, BSIM4 level=54, VDD=1.1V
* TRAN Analysis: Small-signal (1mV) + large-signal (100mV) step response
* Metrics: settling time (1%), overshoot, slew rate

.include ../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 10u
.param l_in = 0.18u w_in = 2u
.param l_load = 0.18u w_load = 4u
.param l_tail = 0.18u w_tail = 4u

VDD VDD 0 DC {VDD}

* Diode-connected NMOS for bias
MBIAS VBIAS VBIAS 0   0   nmos W={w_tail} L={l_tail}
IBIAS VDD VBIAS DC {ibias}

* Differential pair — CLOSED LOOP: INN = OUT (unity-gain buffer)
M1 OUT  INP  TAIL 0 nmos W={w_in}  L={l_in}
M2 NETD OUT  TAIL 0 nmos W={w_in}  L={l_in}

* PMOS current-mirror load
M3 OUT  NETD VDD VDD pmos W={w_load} L={l_load}
M4 NETD NETD VDD VDD pmos W={w_load} L={l_load}

* Tail current source
M5 TAIL VBIAS 0   0   nmos W={w_tail} L={l_tail}

* Load cap
CL OUT 0 1p

* Step input: from mid-rail 0.55V to 0.551V (1mV small-signal step)
VIN INP 0 PWL(0 0.55 10n 0.55 10.01n 0.551 100n 0.551)

.options gmin=1e-12 reltol=1e-5 method=gear
.tran 0.1n 100n

* Measure settling time to 1% of final value
.meas TRAN vout_final AVG v(out) FROM=90n TO=100n
.meas TRAN overshoot MAX v(out) FROM=10n TO=30n

.save v(out) v(inp)

.control
run
print vout_final settle_1p overshoot
.endc
.end
