* Auto TB for BUFFER_VCM_FINAL4
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VCM_FINAL4 gnd ibias vcm_in vdd vout
xm17 net023 net023 net023 gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm18 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm19 net049 net049 net049 gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm20 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w0 l=l0
xm16 vout net049 gnd gnd sky130_fd_pr__nfet_01v8 w=w1 l=l0
xm21 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w2 l=l0
xm15 net049 net023 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm14 net023 net023 gnd gnd sky130_fd_pr__nfet_01v8 w=w3 l=l0
xm39 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm40 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w5 l=l0
xm41 net048 net048 net048 vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm42 net048 net048 net048 vdd sky130_fd_pr__pfet_01v8 w=w6 l=l0
xm43 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
xm36 net049 vcm_in net048 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm28 vout net049 vout vout sky130_fd_pr__pfet_01v8 w=w8 l=l1
xm38 ibias ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w9 l=l0
xm37 net023 vout net048 vdd sky130_fd_pr__pfet_01v8 w=w7 l=l0
xm35 net048 ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w10 l=l0
xm34 vout ibias vdd vdd sky130_fd_pr__pfet_01v8 w=w4 l=l0
.ends BUFFER_VCM_FINAL4



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vcm_in vdd vout BUFFER_VCM_FINAL4
.op
.control
op
.endc
.end
