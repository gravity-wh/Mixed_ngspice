* 5T OTA Noise Analysis — PTM 45nm LP BSIM4 level=54
* Validates: 1/f flicker noise (fnoimod=1) + thermal noise
* Key FP32 sensitivity: oxideTrapDensity defaults exceed FLT_MAX
* Pure FP32 expectation: onoise_spectrum = 0 at low frequencies (underflow)
*
* Usage: ngspice --batch test_noise.sp

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
M4 NETD NETD VDD VDD pmos W={w_load} L={w_load}
M5 TAIL VBIAS 0   0   nmos W={w_tail} L={l_tail}

CL OUT 0 0.5p

* DC OP first (required for noise analysis)
.op

* Noise analysis: 1Hz to 10GHz, 10 points per decade
* Output noise at v(out), input-referred to vinn
.noise v(out) vinn dec 10 1 10G

.control
  echo "=== 04_ota_5t NOISE ANALYSIS ==="
  op
  noise v(out) vinn dec 10 1 10G
  * Print spot noise spectrum for key inspection
  print onoise_spectrum
  * Measure integrated noise (1Hz to 10MHz for audio/analog band)
  meas noise total_rms INTEG onoise_spectrum FROM=1 TO=10e6
  print total_rms
  * Also measure high-frequency integrated noise (thermal only, should be correct)
  meas noise hf_rms INTEG onoise_spectrum FROM=1e6 TO=10e6
  print hf_rms
.endc
.end
