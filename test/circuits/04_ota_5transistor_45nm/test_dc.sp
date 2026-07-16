* Five-Transistor OTA DC — 45nm LP PTM BSIM4
* Classic analog sizing benchmark: differential pair + current mirror load + tail current source

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 10u
.param l_in = 0.18u
.param w_in = 2u
.param l_load = 0.18u
.param w_load = 4u
.param l_tail = 0.18u
.param w_tail = 4u

VDD VDD 0 DC {VDD}
VINP INP 0 DC 0.55
VINN INN 0 DC 0.55

* Diode-connected NMOS for bias generation
MBIAS VBIAS VBIAS 0   0   nmos W={w_tail} L={l_tail}
IBIAS VDD VBIAS DC {ibias}

* Differential pair
M1 OUT  INP  TAIL 0 nmos W={w_in}  L={l_in}
M2 NETD INN  TAIL 0 nmos W={w_in}  L={l_in}

* PMOS current-mirror load
M3 OUT  NETD VDD VDD pmos W={w_load} L={l_load}
M4 NETD NETD VDD VDD pmos W={w_load} L={l_load}

* Tail current source
M5 TAIL VBIAS 0   0   nmos W={w_tail} L={l_tail}

.op
.control
  echo "=== 04_ota_5t DC ==="
  op
  print v(out) v(netd) v(tail)
  let gm_in   = @m1[gm]
  let gm_load = @m3[gm]
  let gds_out = @m3[gds]
  let id_tail = @m5[id]
  let vth_in  = @m1[vth]
  print gm_in gm_load gds_out id_tail vth_in
.endc
.end
