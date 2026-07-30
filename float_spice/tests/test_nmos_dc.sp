* Single NMOS DC test — VGS=1.0V, VDS=1.0V (strong inversion)
.include ../test/models/45nm_LP_BSIM4/ptm45lp.lib
VGS G 0 1.0
VDS D 0 1.0
VBS B 0 0
M1 D G 0 B nmos W=1u L=45n
.op
.end
