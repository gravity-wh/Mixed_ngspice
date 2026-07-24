* Auto TB for VCM5
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt VCM5 gnd ibias vcm vdd vout
xm22 net80 net80 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm23 net84 net84 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm24 net92 net84 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm25 net91 net80 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm26 vout net039 net92 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm27 net77 net039 net91 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm31 net039 net039 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l1
xm17 net022 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w3 l=l0
xm18 net77 vcm net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm19 net84 vcm net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm20 vout vout net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm21 net80 vout net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm29 ibias ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm30 net039 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm32 vout net77 vdd vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm33 net77 net77 vdd vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
.ends VCM5



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vcm vdd vout VCM5
.op
.control
op
.endc
.end
