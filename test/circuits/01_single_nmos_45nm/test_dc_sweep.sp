* Single NMOS ID-VDS Characteristic — 45nm LP PTM BSIM4
* DC sweep of drain voltage at multiple gate voltages

.include ../../models/45nm_LP_BSIM4/ptm45lp.lib

M1  D G 0 0 nmos W=1u L=45n
VD D 0 0
VG G 0 0

.control
  dc vd 0 1.1 0.01 vg 0 1.1 0.2
  plot -i(vd)
  let vth0 = @m1[vth]
  echo "Vth at VGS=1.1V:"
  print vth0
.endc
.end
