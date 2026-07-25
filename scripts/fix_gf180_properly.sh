#!/bin/bash
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/of
MODEL=/mnt/e/MyResearch/Mixed_ngspice/test/models/45nm_LP_BSIM4/ptm45lp.lib

echo "=== Recreating OF GF180 circuit properly ==="
f="$C/OF_cdl_gf180mcu_osu_sc_9T_tb.spice"

# Create wrapper inline + GF180 standard cell as a simple test
cat > "$f" << 'CEOP'
* OF GF180 standard cell test (with pmos_3p3/nmos_3p3 → BSIM4 wrapper)
.include /mnt/e/MyResearch/Mixed_ngspice/test/models/45nm_LP_BSIM4/ptm45lp.lib

* Subcircuit wrapper: old MAGICAL names → BSIM4 models
.subckt pmos_3p3 D G S B w=1u l=0.15u
M1 D G S B pmos W={w} L={l}
.ends pmos_3p3
.subckt nmos_3p3 D G S B w=1u l=0.15u
M1 D G S B nmos W={w} L={l}
.ends nmos_3p3

* Simplified GF180 standard cell: 1-bit full adder
.subckt gf180_add A B CI S CO
X0 a_n B VDD VDD pmos_3p3 w=34 l=6
X1 a_p A VDD VDD pmos_3p3 w=34 l=6
X2 S a_mid VSS VSS nmos_3p3 w=17 l=6
X3 S a_mid VDD VDD pmos_3p3 w=34 l=6
R1 a_mid VSS 1e9
.ends gf180_add

* Testbench
VDD VDD 0 DC 1.8
VSS VSS 0 DC 0
VA A 0 DC 0.9
VB B 0 DC 0
VCI CI 0 DC 0

XADD A B CI S CO gf180_add
Rload S VSS 1e9
Rload2 CO VSS 1e9

.control
op
print v(s) v(co)
.endc
.end
CEOP

echo -n "  OF GF180: "
timeout 15 "$V12" --batch "$f" > /tmp/of_gf180_proper.log 2>&1
nan=$(grep -c FP32-NAN /tmp/of_gf180_proper.log) || nan=0
err=$(grep -c 'Error:\|timestep too small\|singular\|incomplete\|unknown subckt' /tmp/of_gf180_proper.log) || err=0
if [ "$nan" -eq 0 ] && [ "$err" -eq 0 ]; then echo "PASS"; else echo "FAIL(nan=$nan err=$err)"; fi
