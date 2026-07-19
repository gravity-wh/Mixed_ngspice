* T4: StrongARM Comparator — Clocked Regenerative Latch Timing
* Technology: PTM 45nm HP, BSIM4 level=54, VDD=1.0V
* TRAN Analysis: Clock edge -> regenerative latch -> output valid delay
* Metrics: regeneration time (VXP/VXN crossing), propagation delay
* Hardest stress: CLK edge causes matrix condition number spike

.include ../models/45nm_HP_BSIM4/ptm45hp.lib

VDD VDD 0 DC 1.0

* Clock: 1GHz (1ns period), 50ps edges
VCLK CLK 0 PULSE(0 1.0 1n 50p 50p 0.5n 1n)

* Differential input: INP = 0.5005, INN = 0.4995 (1mV differential)
VINP INP 0 DC 0.5005
VINN INN 0 DC 0.4995

* StrongARM comparator subcircuit
.subckt comparator_strongarm INP INN CLK VDD OUTP OUTN
* Reset PMOS
M7  VXP CLK VDD VDD pmos W=1.0u L=45n
M8  VXN CLK VDD VDD pmos W=1.0u L=45n
M9  VLP CLK VDD VDD pmos W=1.0u L=45n
M10 VLN CLK VDD VDD pmos W=1.0u L=45n
* Tail NMOS
M0 VS CLK 0 0 nmos W=4.0u L=45n
* Input pair
M1 VXP INP VS 0 nmos W=4.0u L=45n
M2 VXN INN VS 0 nmos W=4.0u L=45n
* NMOS latch
M3 VLP VLN VXP 0 nmos W=1.0u L=45n
M4 VLN VLP VXN 0 nmos W=1.0u L=45n
* PMOS latch
M5 VLP VLN VDD VDD pmos W=2.0u L=45n
M6 VLN VLP VDD VDD pmos W=2.0u L=45n
* Output inverters
M11 OUTP VLP VDD VDD pmos W=2.0u L=45n
M12 OUTP VLP 0   0   nmos W=1.0u L=45n
M13 OUTN VLN VDD VDD pmos W=2.0u L=45n
M14 OUTN VLN 0   0   nmos W=1.0u L=45n
.ends comparator_strongarm

X1 INP INN CLK VDD OUTP OUTN comparator_strongarm

* Load caps on outputs
CP OUTP 0 1f
CN OUTN 0 1f

.options gmin=1e-12 reltol=1e-5 method=gear
.tran 1p 5n uic

* Initial conditions: reset state
.ic v(x1.vxp)=1.0 v(x1.vxn)=1.0 v(x1.vlp)=1.0 v(x1.vln)=1.0 v(x1.vs)=0

* Measure regeneration time: VXP drops below VXN at clock edge
.meas TRAN vdd_current AVG i(VDD) FROM=2n TO=5n

.save v(clk) v(INP) v(INN) v(x1.vxp) v(x1.vxn) v(outp) v(outn)

.control
run
print regen_time
.endc
.end
