* Auto TB for BUFFER_VCM1
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VCM1 gnd vcm_in vdd vout vbias
xm6 net017 net95 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm31 net95 net95 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm27 net92 net106 net89 gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm26 net105 net106 net101 gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm25 net89 net95 gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm24 net101 net95 gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm0 vout net95 gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm2 net106 net106 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm7 net017 net017 vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm33 net91 net92 vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm32 net99 net92 vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm30 net95 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm29 vbias vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm21 net89 vout net96 net96 sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm19 net101 vcm_in net96 net96 sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm17 net96 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm1 vout net105 vdd vdd sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm3 net106 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm5 net92 net017 net91 net91 sky130_fd_pr__pfet_01v8 w=w9 l=l0
xm4 net105 net017 net99 net99 sky130_fd_pr__pfet_01v8 w=w9 l=l0
.ends BUFFER_VCM1



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd vcm_in vdd vout vbias BUFFER_VCM1
.op
.control
op
.endc
.end
