* NMOS DC matching FP64 golden: Vgs=0.55V, Vds=1.1V
.include ../test/models/45nm_LP_BSIM4/ptm45lp.lib
VG G 0 0.55
VD D 0 1.1
VB B 0 0
M1 D G 0 B nmos W=1u L=45n
.op
.end
