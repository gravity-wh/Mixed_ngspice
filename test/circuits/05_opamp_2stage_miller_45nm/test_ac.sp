* Two-Stage Miller Op-Amp AC — 45nm LP PTM BSIM4
* Open-loop gain, phase margin, unity-gain bandwidth

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

.param VDD = 1.1
.param ibias = 20u

VDD VDD 0 DC {VDD}
* AC input on INP, INN at DC bias
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

.ac dec 10 1k 10G

.control
  echo "=== 05_opamp_2stage AC ==="
  ac dec 10 1k 10G
  plot vdb(out) vp(out)
  meas ac gain_max MAX vdb(out)
  meas ac pm FIND vp(out) WHEN vdb(out)=0
  meas ac ugbw WHEN vdb(out)=0
  echo "DC gain (dB), UGBW, Phase margin:"
  print gain_max ugbw pm
.endc
.end
