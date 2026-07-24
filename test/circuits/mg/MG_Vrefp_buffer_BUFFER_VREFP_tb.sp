* Auto TB for BUFFER_VREFP
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
* PDK-swapped for SKY130 ngspice
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt BUFFER_VREFP gnd ibias vdd vref vrefp
xm60 vrefp vrefp vrefp vdd pfet_lvt w=w0 l=l0
xm37 vdd net057 vdd vdd pfet_lvt w=w1 l=l1
xm29 net052 net057 vrefp vdd pfet_lvt w=w2 l=l0
xm27 net057 net057 net049 vdd pfet_lvt w=w3 l=l0
xm28 vrefp net052 vdd vdd pfet_lvt w=w4 l=l0
xm15 net049 net036 vdd vdd pfet_lvt w=w5 l=l0
xm59 net057 net057 net057 vdd pfet_lvt w=w6 l=l0
xm57 vdd vdd vdd vdd pfet_lvt w=w7 l=l0
xm58 net049 net049 net049 vdd pfet_lvt w=w6 l=l0
xm55 vdd vdd vdd vdd pfet_lvt w=w8 l=l0
xm54 net049 net049 net049 vdd pfet_lvt w=w8 l=l0
xm38 vdd net036 vdd vdd pfet_lvt w=w6 l=l2
xm63 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w9 l=l0
xm62 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w10 l=l0
xm61 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w9 l=l0
xm56 net057 net057 net057 gnd sky130_fd_pr__nfet_01v8 w=w9 l=l0
xm30 net052 ibias gnd gnd sky130_fd_pr__nfet_01v8 w=w11 l=l0
xm21 net057 ibias gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l0
xm12 net051 vref net212 gnd sky130_fd_pr__nfet_01v8 w=w13 l=l0
xm11 net211 vref net212 gnd sky130_fd_pr__nfet_01v8 w=w13 l=l0
xm10 net054 net049 net212 gnd sky130_fd_pr__nfet_01v8 w=w13 l=l0
xm8 net215 net049 net212 gnd sky130_fd_pr__nfet_01v8 w=w13 l=l0
xm5 net204 ibias gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l0
xm4 ibias ibias gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l0
xm3 net212 ibias gnd gnd sky130_fd_pr__nfet_01v8 w=w10 l=l0
xm1 net207 net207 gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm6 net036 net207 gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm43 net211 net211 net211 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm53 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm52 net036 net036 net036 gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm51 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm47 net212 net212 net212 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm50 net207 net207 net207 gnd sky130_fd_pr__nfet_01v8 w=w12 l=l3
xm45 net051 net051 net051 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm49 gnd gnd gnd gnd sky130_fd_pr__nfet_01v8 w=w10 l=l0
xm48 net212 net212 net212 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm40 net204 net204 net204 gnd sky130_fd_pr__nfet_01v8 w=w9 l=l0
xm46 net054 net054 net054 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm44 net215 net215 net215 gnd sky130_fd_pr__nfet_01v8 w=w14 l=l0
xm39 ibias ibias ibias gnd sky130_fd_pr__nfet_01v8 w=w9 l=l0
xm42 net051 net051 net051 vdd sky130_fd_pr__pfet_01v8 w=w15 l=l0
xm35 net211 net211 net211 vdd sky130_fd_pr__pfet_01v8 w=w16 l=l0
xm33 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w17 l=l0
xm26 net054 net211 vdd vdd sky130_fd_pr__pfet_01v8 w=w17 l=l0
xm25 net211 net211 vdd vdd sky130_fd_pr__pfet_01v8 w=w14 l=l0
xm24 net051 net215 vdd vdd sky130_fd_pr__pfet_01v8 w=w17 l=l0
xm23 net215 net215 vdd vdd sky130_fd_pr__pfet_01v8 w=w14 l=l0
xm22 net204 net204 vdd vdd sky130_fd_pr__pfet_01v8 w=w18 l=l4
xm41 net054 net054 net054 vdd sky130_fd_pr__pfet_01v8 w=w15 l=l0
xm32 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w18 l=l4
xm14 net207 net204 net054 vdd sky130_fd_pr__pfet_01v8 w=w10 l=l0
xm13 net036 net204 net051 vdd sky130_fd_pr__pfet_01v8 w=w10 l=l0
xm34 vdd vdd vdd vdd sky130_fd_pr__pfet_01v8 w=w17 l=l0
xm36 net215 net215 net215 vdd sky130_fd_pr__pfet_01v8 w=w16 l=l0
xm31 net204 net204 net204 vdd sky130_fd_pr__pfet_01v8 w=w18 l=l4
.ends BUFFER_VREFP



Vdd vdd 0 DC 1.8
Vss gnd 0 DC 0
X1 gnd ibias vdd vref vrefp BUFFER_VREFP
.op
.control
op
.endc
.end
