* T5: Bootstrap Switch — Enhanced TRAN Validation with Waveform Comparison
* Base: test/circuits/07_bootstrap_switch_45nm/test_tran.sp
* Technology: PTM 45nm HP, BSIM4 level=54, VDD=1.0V
* TRAN Analysis: 10MHz sine sampled at 500MHz clock -> compare sampled waveform
* Metrics: NRMSE, max deviation, step count ratio
* Enhanced with: .save for rawfile output, .meas for automated timing extraction

.include ../models/45nm_HP_BSIM4/ptm45hp.lib

.param VDD = 1.0

* Supplies
VVDD VDD 0 DC 1.0
VCLK CLK 0 PULSE(0 1.0 0 50p 50p 1n 2n)
VIN  IN  0 SIN(0.5 0.4 10MEG)

* Bootstrap Switch NMOS (M1)
M1 IN gate vsampled 0 nmos W=2u L=45n

* Bootstrap capacitor Cb (precharge to VDD)
Cb gate CLK 0.2p

* Bootstrap precharge switch M2 (PMOS)
M2 gate CLK VDD VDD pmos W=0.5u L=45n

* Gate cutoff switch M3 (NMOS)
M3 VDD CLK gate 0 nmos W=0.5u L=45n

* Clock buffer inverter for bootstrap action
M4 nclk CLK VDD VDD pmos W=1u L=45n
M5 nclk CLK 0   0   nmos W=0.5u L=45n

* Sampling capacitor
Cs vsampled 0 0.5p

* Load for sampled output
Rload vsampled 0 1MEG

* Reset: hold vsampled to VDD initially
Mreset vsampled rst 0 0 nmos W=1u L=45n
Vrst rst 0 PULSE(1.0 0 0 10p 10p 0.5n 100n)

.options gmin=1e-12 reltol=1e-5 method=gear
.tran 2p 20n uic

.ic v(gate)=1.0 v(vsampled)=1.0

* Measure sampling accuracy
.meas TRAN vsampled_mean AVG v(vsampled) FROM=5n TO=20n
.meas TRAN vsampled_pp  PP v(vsampled) FROM=5n TO=20n

.save v(in) v(clk) v(gate) v(vsampled)

.control
run
print vsampled_mean vsampled_pp
.endc
.end
