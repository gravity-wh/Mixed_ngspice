* T4: StrongARM Comparator — Clocked Regenerative Latch TRAN
* Technology: PTM 45nm HP, BSIM4 level=54, VDD=1.0V
* TRAN: 1GHz clock, 50ps edges, differential ramp input
* Metric: output switching verified by waveform

.include ../models/45nm_HP_BSIM4/ptm45hp.lib

VDD VDD 0 DC 1.0

* Clock: 1GHz, 100ps edges (relaxed for FP32 stability)
VCLK CLK 0 PULSE(0 1.0 1n 100p 100p 0.5n 1n)

* Differential input: 1mV offset
VINP INP 0 DC 0.5005
VINN INN 0 DC 0.4995

* StrongARM comparator — Direct transistor-level (no subcircuit, avoids body node issues)
* Reset PMOS (CLK=0 -> pull high)
M7  VXP CLK VDD VDD pmos W=1.0u L=45n
M8  VXN CLK VDD VDD pmos W=1.0u L=45n
M9  VLP CLK VDD VDD pmos W=1.0u L=45n
M10 VLN CLK VDD VDD pmos W=1.0u L=45n

* Tail NMOS (CLK=1 -> enable)
M0 VS CLK 0 0 nmos W=4.0u L=45n

* Input differential pair
M1 VXP INP VS 0 nmos W=4.0u L=45n
M2 VXN INN VS 0 nmos W=4.0u L=45n

* NMOS cross-coupled latch
M3 VLP VLN VXP 0 nmos W=1.0u L=45n
M4 VLN VLP VXN 0 nmos W=1.0u L=45n

* PMOS cross-coupled latch
M5 VLP VLN VDD VDD pmos W=2.0u L=45n
M6 VLN VLP VDD VDD pmos W=2.0u L=45n

* Output inverters
M11 OUTP VLP VDD VDD pmos W=2.0u L=45n
M12 OUTP VLP 0   0   nmos W=1.0u L=45n
M13 OUTN VLN VDD VDD pmos W=2.0u L=45n
M14 OUTN VLN 0   0   nmos W=1.0u L=45n

* Load
CP OUTP 0 1f
CN OUTN 0 1f

.options gmin=1e-10 sollim reltol=1e-5 method=gear
.tran 1p 4n uic

.ic v(VXP)=1.0 v(VXN)=1.0 v(VLP)=1.0 v(VLN)=1.0 v(VS)=0

.save v(CLK) v(INP) v(OUTP) v(OUTN) v(VXP) v(VXN)

.control
run
.endc
.end
