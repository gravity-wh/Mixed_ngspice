* Five-Transistor OTA AC — 45nm LP PTM BSIM4
* Frequency response: gain, bandwidth, phase margin

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 10u
.param l_in = 0.18u w_in = 2u
.param l_load = 0.18u w_load = 4u
.param l_tail = 0.18u w_tail = 4u

VDD VDD 0 DC {VDD}
VINP INP 0 DC 0.55 AC 1
VINN INN 0 DC 0.55

MBIAS VBIAS VBIAS 0   0   nmos W={w_tail} L={l_tail}
IBIAS VDD VBIAS DC {ibias}

M1 OUT  INP  TAIL 0 nmos W={w_in}  L={l_in}
M2 NETD INN  TAIL 0 nmos W={w_in}  L={l_in}
M3 OUT  NETD VDD VDD pmos W={w_load} L={l_load}
M4 NETD NETD VDD VDD pmos W={w_load} L={l_load}
M5 TAIL VBIAS 0   0   nmos W={w_tail} L={l_tail}

CL OUT 0 0.5p

.ac dec 10 1k 10G

.control
  echo "=== 04_ota_5t AC ==="
  ac dec 10 1k 10G
  plot vdb(out)
  meas ac gain_max MAX vdb(out)
  meas ac ugbw WHEN vdb(out)=0
  echo "DC gain (dB), Unity-gain bandwidth:"
  print gain_max ugbw
.endc
.end
