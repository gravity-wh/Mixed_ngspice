* OF sim_7 — RC Low-Pass Filter Testbench
.include /mnt/e/MyResearch/Mixed_ngspice/test/models/45nm_LP_BSIM4/ptm45lp.lib
.option gmin=1e-12

* Power supply
VDD VDD 0 DC 1.8
VSS VSS 0 DC 0

* RC network with DC bias
R1 VIN VOUT 5k
C1 VOUT VSS 5
Rload VOUT VSS 1e9

* Input with DC bias
VIN VIN VSS DC 0.9 AC 1

.control
op
ac dec 10 1 1MEG
print vdb(vout) vp(vout)
.endc
.end
