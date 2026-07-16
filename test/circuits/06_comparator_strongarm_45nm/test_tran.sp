* StrongArm Dynamic Comparator — 45nm HP PTM BSIM4
* 11-transistor dynamic latch comparator
* Rendered from analog-circuit-skills template with fixed parameters

.include ../../models/45nm_HP_BSIM4/ptm45hp.lib

.param VDD = 1.0
.param L = 0.045u
.param W_rst = 1.2
.param W_tail = 2.4
.param W_in = 2.0
.param W_lat_n = 1.0
.param W_lat_p = 2.0
.param W_inv_p = 1.0
.param W_inv_n = 0.5

* Supply and clock
VVDD VDD 0 DC {VDD}
VCLK CLK 0 PULSE(0 {VDD} 0 10p 10p 500p 1n)

* Input: INP = 0.55V, INN = 0.50V (50mV differential)
VINP INP 0 DC 0.55
VINN INN 0 DC 0.50

* ── Reset PMOS (M7-M10): pull internal nodes to VDD when CLK=0 ──
M7  VXP CLK VDD VDD pmos W={W_rst}u L={L}
M8  VXN CLK VDD VDD pmos W={W_rst}u L={L}
M9  VLP CLK VDD VDD pmos W={W_rst}u L={L}
M10 VLN CLK VDD VDD pmos W={W_rst}u L={L}

* ── Tail NMOS (M0): ON when CLK=1, provides evaluation current ──
M0 VS CLK 0 0 nmos W={W_tail}u L={L}

* ── Input differential pair (M1, M2) ──
M1 VXP INP VS 0 nmos W={W_in}u L={L}
M2 VXN INN VS 0 nmos W={W_in}u L={L}

* ── NMOS latch (M3, M4): cross-coupled ──
M3 VLP VLN VXP 0 nmos W={W_lat_n}u L={L}
M4 VLN VLP VXN 0 nmos W={W_lat_n}u L={L}

* ── PMOS latch (M5, M6): cross-coupled ──
M5 VLP VLN VDD VDD pmos W={W_lat_p}u L={L}
M6 VLN VLP VDD VDD pmos W={W_lat_p}u L={L}

* ── Output inverters ──
M11 OUTP VLP VDD VDD pmos W={W_inv_p}u L={L}
M12 OUTP VLP 0   0   nmos W={W_inv_n}u L={L}
M13 OUTN VLN VDD VDD pmos W={W_inv_p}u L={L}
M14 OUTN VLN 0   0   nmos W={W_inv_n}u L={L}

.ic V(vxp)=1.0 V(vxn)=1.0 V(vlp)=1.0 V(vln)=1.0 V(vs)=0

.options RELTOL=1e-4 METHOD=gear

.control
  echo "=== 06_comparator_strongarm TRAN ==="
  tran 1p 2n uic
  plot v(outp) v(outn) v(clk)
  let id_tail = @m0[id]
  let gm_in   = @m1[gm]
  echo "Tail current, Input pair gm:"
  print id_tail gm_in
.endc
.end
