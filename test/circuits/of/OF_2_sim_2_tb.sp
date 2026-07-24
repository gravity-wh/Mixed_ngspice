* Auto TB for TEST_NETLIST
.include /mnt/e/MyResearch/Mixed_ngspice/test/models/45nm_LP_BSIM4/ptm45lp.lib
.option gmin=1e-12


.OPTION temp = 5

.subckt TEST_NETLIST V1 V2
C1 V1 V0 C=5
R1 V0 V2 R=5k
.ends

X0 V1 0 TEST_NETLIST

VPOWER V1 0 AC SIN(0 1 1k 0 0 0)

.TRAN 0.01 1

.MEAS tran vrms RMS par('V(V1)')
.MEAS tran irms RMS par('I(VPOWER)')

.END


Vdd V1 0 DC 1.8
Vss V2 0 DC 0
X1 V1 V2 TEST_NETLIST
.op
.control
op
.endc
.end
