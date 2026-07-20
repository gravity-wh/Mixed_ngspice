* Two-Stage Miller Op-Amp Noise Analysis — PTM 45nm LP BSIM4 level=54
* Validates: multi-stage noise accumulation, 1/f in feedback amplifier
* 8 transistors: PMOS diff pair + NMOS mirror + 2nd stage
* Key difference from OTA: two gain stages → noise from both stages
* Pure FP32 expectation: onoise_spectrum = 0 below ~100kHz
*
* Usage: ngspice --batch test_noise.sp

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 20u

VDD VDD 0 DC {VDD}
VINP INP 0 DC 0.55 AC 1
VINN INN 0 DC 0.55

MBIAS PBIAS PBIAS VDD VDD pmos W=4u L=0.18u
IBIAS PBIAS 0 DC {ibias}

M5 TAIL PBIAS VDD VDD pmos W=4u L=0.18u
M1 A INN  TAIL VDD pmos W=4u L=0.18u
M2 B INP  TAIL VDD pmos W=4u L=0.18u
M3 A A 0 0 nmos W=2u L=0.18u
M4 B A 0 0 nmos W=2u L=0.18u

M6 OUT PBIAS VDD VDD pmos W=8u L=0.18u
M7 OUT B     0   0   nmos W=4u L=0.18u

CC B OUT 0.5p
CL OUT 0 1p

.op
.noise v(out) vinn dec 10 1 10G

.control
  echo "=== 05_opamp_2stage NOISE ANALYSIS ==="
  op
  noise v(out) vinn dec 10 1 10G
  print onoise_spectrum
  meas noise total_rms INTEG onoise_spectrum FROM=1 TO=10e6
  print total_rms
  meas noise hf_rms INTEG onoise_spectrum FROM=1e6 TO=10e6
  print hf_rms
.endc
.end
