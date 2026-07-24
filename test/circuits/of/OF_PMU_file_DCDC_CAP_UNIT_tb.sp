* Auto TB for DCDC_CAP_UNIT
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.option gmin=1e-12
.subckt DCDC_CAP_UNIT BOT TOP
x0 TOP BOT sky130_fd_pr__cap_mim_m3_1 w=7 l=19
.ends DCDC_CAP_UNIT


Vdd BOT 0 DC 1.8
Vss TOP 0 DC 0
X1 BOT TOP DCDC_CAP_UNIT
.op
.control
op
.endc
.end
