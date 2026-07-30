* SKY130 NMOS DC Characterization
.include ./sky130_tt.lib
Vgs g 0 DC 0.9
Vds d 0 DC 1.8
M1 d g 0 0 sky130_nmos W=1.26u L=0.15u
.control
op
print v(d) i(Vds) @m1[gm] @m1[gds] @m1[vth] @m1[vdsat]
.endc
.end
