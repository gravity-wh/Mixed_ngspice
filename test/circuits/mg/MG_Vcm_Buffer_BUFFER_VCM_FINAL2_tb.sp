* Auto TB for BUFFER_VCM_FINAL2
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VCM_FINAL2 gnd ibias vcm_in vdd vout
xm2 net123 net123 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm0 vout net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l1
xm24 net065 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l1
xm25 net125 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l1
xm26 net138 net123 net065 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l1
xm27 net128 net123 net125 gnd sky130_fd_pr__nfet_01v8 w=w2 l=l1
xm31 net132 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l1
xm6 net122 net132 gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l1
xm10 vout net065 vout vout sky130_fd_pr__pfet_01v8 w=w3 l=l2
xm4 net138 net122 net051 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l1
xm5 net128 net122 net052 vdd sky130_fd_pr__pfet_01v8 w=w4 l=l1
xm3 net123 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l1
xm1 vout net138 vdd vdd sky130_fd_pr__pfet_01v8 w=w6 l=l1
xm17 net028 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w7 l=l1
xm19 net065 vcm_in net028 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l1
xm21 net125 vout net028 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l1
xm29 ibias ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w8 l=l1
xm30 net132 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l1
xm32 net051 net128 vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l1
xm33 net052 net128 vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l1
xm7 net122 net122 vdd vdd sky130_fd_pr__pfet_01v8 w=w10 l=l3
.ends BUFFER_VCM_FINAL2



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vcm_in vdd vout BUFFER_VCM_FINAL2
.op
.control
op
.endc
.end
