* Auto TB for BUFFER_VCM_FINAL1
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VCM_FINAL1 gnd ibias vcm_in vdd vout
xm2 net123 net123 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm0 vout net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm24 net065 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm25 net125 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm26 net138 net123 net065 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm27 net128 net123 net125 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm31 net132 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm6 net122 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm10 vout net065 vout vout sky130_fd_pr__pfet_01v8 w=w4 l=l1
xm4 net138 net122 net051 vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm5 net128 net122 net052 vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm3 net123 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm1 vout net138 vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm17 net028 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm19 net065 vcm_in net028 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm21 net125 vout net028 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm29 ibias ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm30 net132 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm32 net051 net128 vdd vdd sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm33 net052 net128 vdd vdd sky130_fd_pr__pfet_01v8 w=w8 l=l0
xm7 net122 net122 vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l0
.ends BUFFER_VCM_FINAL1



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vcm_in vdd vout BUFFER_VCM_FINAL1
.op
.control
op
.endc
.end
