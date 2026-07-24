* Auto TB for VCM4
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt VCM4 gnd ibias vcm vdd vfb
xm0 vfb net84 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm2 net84 net80 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm3 net80 net80 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm1 vfb ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w2 l=l0
xm17 net022 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w3 l=l0
xm19 net84 vcm net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm21 net80 vfb net022 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm29 ibias ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm4 vfb net84 vfb vfb sky130_fd_pr__pfet_01v8 w=w6 l=l1
.ends VCM4



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vcm vdd vfb VCM4
.op
.control
op
.endc
.end
