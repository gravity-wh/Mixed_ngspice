* T3: BGR (Bandgap Reference) Startup Transient
* Technology: MS018 v1.6 SMIC 180nm, BSIM3v3 L49
* TRAN: VDD ramp 0→3.3V in 10µs, measure VREF settling
* Note: Requires MS018 v1.6 PDK extracted to /tmp/smic180/

.include /tmp/smic180/TD-MM18-SP-2001v7R/ms018_v1p6.mdl
.lib '/tmp/smic180/TD-MM18-SP-2001v7R/ms018_v1p6.lib' BJT_TT
.lib '/tmp/smic180/TD-MM18-SP-2001v7R/ms018_v1p6.lib' RES_TT
.include /tmp/smic180/TD-MM18-SP-2001v7R/ms018_v1p6_bjt.mdl
.include /tmp/smic180/TD-MM18-SP-2001v7R/ms018_v1p6_res.mdl

* VDD ramp: 0 → 3.3V in 10µs
VDD vdd 0 PWL(0 0 10u 3.3 100u 3.3)

* Bandgap core: 2 PNP BJTs + resistors
Q1 ve1 ve1 0 pnp18a4
Q2 ve2 ve2 0 pnp18a4 M=8

I1 vdd ve1 DC 5uA
I2 vdd ve2 DC 5uA

R1 ve1 ve2 10.8k
R2 vdd vref 100k
R3 vref ve1 100k

* Load on VREF
CL vref 0 1p

.tran 0.1u 100u
.options gmin=1e-12 reltol=1e-5

.save v(vdd) v(vref) v(ve1)

.control
run
.endc
.end
