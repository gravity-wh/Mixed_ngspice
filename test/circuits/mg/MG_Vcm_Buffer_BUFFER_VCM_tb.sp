* Auto TB for BUFFER_VCM_schematic
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VCM_schematic gnd vbias vdd vout vref
xm0 vout net93 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm2 net019 net019 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm22 net99 net99 gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm23 net103 net103 gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm24 net107 net103 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm25 net114 net99 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm26 net111 net019 net107 gnd sky130_fd_pr__nfet_01v8 w=w4 l=l0
xm27 net96 net019 net114 gnd sky130_fd_pr__nfet_01v8 w=w4 l=l0
xm31 net93 net93 gnd gnd sky130_fd_pr__nfet_01v8 w=w5 l=l0
xm3 net019 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm17 net102 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm18 net96 vout net102 net102 sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm19 net103 vout net102 net102 sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm20 net111 vref net102 net102 sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm21 net99 vref net102 net102 sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm29 vbias vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm30 net93 vbias vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm32 net111 net96 vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l0
xm33 net96 net96 vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l0
xm1 vout net111 vdd vdd sky130_fd_pr__pfet_01v8 w=w10 l=l0
c1 net107 vout 5e-12
c0 vout gnd 1e-12
.ends BUFFER_VCM_schematic



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd vbias vdd vout vref BUFFER_VCM_schematic
.op
.control
op
.endc
.end
