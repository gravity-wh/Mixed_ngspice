* 17-Stage Ring Oscillator — 45nm LP PTM BSIM4
* Frequency measurement + temperature sweep
* Adapted from ngspice official examples/mos/ro_17_4.cir

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param vdd_val = 1.1

VDD VDD 0 DC {vdd_val}

* 17-stage ring oscillator (inverter chain with feedback)
X1  1 2  inv
X2  2 3  inv
X3  3 4  inv
X4  4 5  inv
X5  5 6  inv
X6  6 7  inv
X7  7 8  inv
X8  8 9  inv
X9  9 10 inv
X10 10 11 inv
X11 11 12 inv
X12 12 13 inv
X13 13 14 inv
X14 14 15 inv
X15 15 16 inv
X16 16 17 inv
X17 17 1  inv

* Inverter subcircuit
.subckt inv in out
MP1 out in VDD VDD pmos W=2u L=45n
MN1 out in 0   0   nmos W=1u L=45n
.ends inv

.tran 1p 10n

.control
  tran 1p 10n
  plot v(1) v(9)
  * Measure frequency at node 1
  meas tran period TRIG v(1) VAL=0.55 RISE=1 TARG v(1) VAL=0.55 RISE=2
  let freq = 1.0 / period
  echo "Ring oscillator frequency:"
  print freq
  
  * Extract device parameters
  let gm_p = @m.x1.mp1[gm]
  let gm_n = @m.x1.mn1[gm]
  let id_p = @m.x1.mp1[id]
  echo "Inverter MP1 gm, MN1 gm, MP1 id:"
  print gm_p gm_n id_p
.endc
.end
