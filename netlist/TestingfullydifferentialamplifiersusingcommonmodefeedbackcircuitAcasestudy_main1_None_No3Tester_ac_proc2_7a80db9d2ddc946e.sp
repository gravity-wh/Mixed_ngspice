* SPICE netlist — converted from Spectre SCS (ngspice)

.model _ideal_switch_ sw vt=1e-3 roff=1e12 ron=1
.param l_origin=1e-06
.param l_M2=4e-07
.param w_M2=1.8e-05
.param m_M2=10
.param l_M7=3.9e-06
.param w_M7=1.1e-06
.param m_M7=6
.param l_M6=4e-06
.param w_M6=1.7e-05
.param m_M6=2
.param m_M5=18
.param l_MPB=4.6e-06
.param w_MPB=1.3e-05
.param m_MPB=6
.param l_MCM4=4e-06
.param w_MCM4=1.3e-06
.param m_MCM4=2
.param l_MCM6=3.5e-06
.param w_MCM6=9.4e-06
.param m_MCM6=6
.param i_I0=7e-06
* TestingfullydifferentialamplifiersusingcommonmodefeedbackcircuitAcasestudy_main1_None_No3Tester_6de6e4cf71f8fe24
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
.include "/share/project/TEDprocess/SMIC/smic18mse_1833_1P6M_5Ia_1TMa1_MIM20_oa_cds_2019_01_15_v1.11_4/models/spectre/ms018_enhanced_v1p11_spe.lib"
* stdcell_inc is None, skip
.global 0 0 vdd
* _v0_ _vss_ 0 resistor r=0
* _v2_ _vdd_ __root_VDD__ resistor r=0
.subckt MosfetFromVirtuoso_5fd2840cdd170db d g s b
.ends
.subckt VSource_7f335e536b4a09a a b
.ends
.subckt Resistor_b5e11dc0ae64f4e a b
.ends
.subckt Mos_261b891664d645ad g d s vdd 0
Nmosfetfromvirtuoso_1 d g s 0 n18 L=l_M6 W=w_M6 M=m_M6 nf=1   $ model=nch, l=l_M6, w=w_M6, m=int(m_M6)
.ends
.subckt Mos_28e1557692f42451 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M6 W=w_M6 M=m_M5   $ model=n18, w=w_M6, l=l_M6, m=int(m_M5), nf=None
.ends
.subckt MosfetLvs_2a91f6f61442d7f2 d g s b
.ends
.subckt Mosfet_2cdcb11705ef7110 d g s b
.ends
.subckt PMOS_2d8fb5265f9e82ba g d s vdd 0
xmos g d s vdd 0 Mos_c2b3ffeb6cf9c8cf   $ l=l_M7, w=w_M7, m=int(m_M7), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_330a6d17f8a4d980 d g s b
.ends
.subckt MosfetLvs_36f896a09545fbcd d g s b
.ends
.subckt MosfetLvs_38dd11c73b393412 d g s b
.ends
.subckt Capacitor_455ff18989871c65 a b
.ends
.subckt TestingfullydifferentialamplifiersusingcommonmodefeedbackcircuitAcasestudy_main1_wrapper_4c45699a9e466534 VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0
xdut VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0 TestingfullydifferentialamplifiersusingcommonmodefeedbackcircuitAcasestudy_main1_4ca2133072e5be37   $ 
.ends
.subckt TestingfullydifferentialamplifiersusingcommonmodefeedbackcircuitAcasestudy_main1_4ca2133072e5be37 VCM vinp vinn Vop Von vop_cmfb von_cmfb vdd 0
xdifferentialpair_1 vinn vinp Vop Von n9_0 vdd 0 DifferentialPair_740087b4bf30eeba   $ l=l_M2, w=w_M2, model=nch, m=int(m_M2), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xpmos_1 n9_1 n9_1 vdd vdd 0 PMOS_2d8fb5265f9e82ba   $ w=w_M7, l=l_M7, m=int(m_M7), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
xpmos_2 n9_1 Vop vdd vdd 0 PMOS_2d8fb5265f9e82ba   $ w=w_M7, l=l_M7, m=int(m_M7), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
xpmos_3 n9_1 Von vdd vdd 0 PMOS_2d8fb5265f9e82ba   $ w=w_M7, l=l_M7, m=int(m_M7), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
xnmos_1 n9_2 n9_0 0 vdd 0 NMOS_711abe49df8444fd   $ w=w_M6, l=l_M6, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_2 n9_3 n9_0 0 vdd 0 NMOS_711abe49df8444fd   $ w=w_M6, l=l_M6, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_3 n9_2 n9_1 0 vdd 0 NMOS_711abe49df8444fd   $ w=w_M6, l=l_M6, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_4 n9_2 n9_2 0 vdd 0 NMOS_93169e72b6468bb0   $ w=w_M6, l=l_M6, m=int(m_M6), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
iisource_1 vdd n9_2 DC i_I0   $ dc=i_I0, ac=0, model=isource, mode=None
xpmos_4 n178_0 n178_0 vdd vdd 0 PMOS_d17c1f6b5ccfad06   $ w=w_MPB, l=l_MPB, m=int(m_MPB), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
xpmos_5 n178_0 n178_1 vdd vdd 0 PMOS_d17c1f6b5ccfad06   $ w=w_MPB, l=l_MPB, m=int(m_MPB), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
xpmos_6 n178_0 n178_2 vdd vdd 0 PMOS_d17c1f6b5ccfad06   $ w=w_MPB, l=l_MPB, m=int(m_MPB), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, num=1, nf=None, obs=None, builtin=True
iisource_2 n178_0 0 DC i_I0   $ dc=i_I0, ac=0, model=isource, mode=None
xdifferentialpair_2 vop_cmfb VCM n178_3 n9_3 n178_1 vdd 0 DifferentialPair_bc2298d6b950dba5   $ l=l_MCM4, w=w_MCM4, model=pch, m=int(m_MCM4), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xdifferentialpair_3 von_cmfb VCM n178_3 n9_3 n178_2 vdd 0 DifferentialPair_bc2298d6b950dba5   $ l=l_MCM4, w=w_MCM4, model=pch, m=int(m_MCM4), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xpmos_7 n178_3 n178_3 0 vdd 0 PMOS_88c016728713940a   $ w=w_M6, l=l_M6, m=int(m_M6), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-130, model=nch, num=1, nf=None, obs=None, builtin=True
xpmos_8 n178_3 n9_3 0 vdd 0 PMOS_88c016728713940a   $ w=w_M6, l=l_M6, m=int(m_M6), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-130, model=nch, num=1, nf=None, obs=None, builtin=True
.ends
.subckt MosfetFromVirtuosoLvs_59c81e71eddf3d44 d g s b
.ends
.subckt VSource_5ff421cce4089485 a b
.ends
.subckt MosfetLvs_639426d1e37c7998 d g s b
.ends
.subckt MosfetFromVirtuosoLvs_6e8b26bacf610867 d g s b
.ends
.subckt NMOS_711abe49df8444fd g d s vdd 0
xmos g d s vdd 0 Mos_28e1557692f42451   $ l=l_M6, w=w_M6, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt DifferentialPair_740087b4bf30eeba g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s 0 n18 L=l_M2 W=w_M2 M=m_M2   $ model=n18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
mmosfet_2 d2 g2 s 0 n18 L=l_M2 W=w_M2 M=m_M2   $ model=n18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
.ends
.subckt ISource_77aca09e94fee1e2 a b
.ends
.subckt Mos_7df651dac79c1276 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M6 W=w_M6 M=m_M6   $ model=n18, w=w_M6, l=l_M6, m=int(m_M6), nf=None
.ends
.subckt PMOS_88c016728713940a g d s vdd 0
xmos g d s vdd 0 Mos_261b891664d645ad   $ l=l_M6, w=w_M6, m=int(m_M6), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-130, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetFromVirtuoso_898b39366554ba01 d g s b
.ends
.subckt MosfetFromVirtuosoLvs_8c0fb9c3dea9db17 d g s b
.ends
.subckt VSource_8da258eb2acfcb15 a b
.ends
.subckt NMOS_93169e72b6468bb0 g d s vdd 0
xmos g d s vdd 0 Mos_7df651dac79c1276   $ l=l_M6, w=w_M6, m=int(m_M6), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mos_ae7564ea3f08bf8d g d s vdd 0
Pmosfetfromvirtuoso_1 d g s vdd p18 L=l_MPB W=w_MPB M=m_MPB nf=1   $ model=pch, l=l_MPB, w=w_MPB, m=int(m_MPB)
.ends
.subckt DifferentialPair_bc2298d6b950dba5 g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s vdd p18 L=l_MCM4 W=w_MCM4 M=m_MCM4   $ model=p18, w=w_MCM4, l=l_MCM4, m=int(m_MCM4), nf=None
mmosfet_2 d2 g2 s vdd p18 L=l_MCM4 W=w_MCM4 M=m_MCM4   $ model=p18, w=w_MCM4, l=l_MCM4, m=int(m_MCM4), nf=None
.ends
.subckt Mos_c2b3ffeb6cf9c8cf g d s vdd 0
Pmosfetfromvirtuoso_1 d g s vdd p18 L=l_M7 W=w_M7 M=m_M7 nf=1   $ model=pch, l=l_M7, w=w_M7, m=int(m_M7)
.ends
.subckt PMOS_d17c1f6b5ccfad06 g d s vdd 0
xmos g d s vdd 0 Mos_ae7564ea3f08bf8d   $ l=l_MPB, w=w_MPB, m=int(m_MPB), from_virtuoso=True, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=-210, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetFromVirtuoso_d7fa5e31e98cccb8 d g s b
.ends
.subckt Mosfet_e8f4cf179ae40f4b d g s b
.ends
.subckt Mosfet_fff39d34cd70422b d g s b
.ends
vVD v_dd vdd DC 0   $ dc=0, ac=None, mode=None, model=vsource
vVS v_ss 0 DC 0   $ dc=0, ac=None, mode=None, model=vsource
cCload1 v_outp v_ss 1e-12   $ c=1e-12, model=capacitor
cCload2 v_outn v_ss 1e-12   $ c=1e-12, model=capacitor
vVCM v_inn1 v_ss DC 0.9   $ dc=0.9, ac=None, mode=None, model=vsource
xdut v_inn1 v_inp v_inn v_outp v_outn v_outp v_outn vdd 0 TestingfullydifferentialamplifiersusingcommonmodefeedbackcircuitAcasestudy_main1_wrapper_4c45699a9e466534   $ 
vVDD v_dd v_ss SIN(1.8 1 1k)   $ dc=1.8, ac=1, mode=None, model=vsource
rRf1 v_outp v_inn 10000.0   $ r=1e4, model=resistor, modelstr=None
rRf2 v_outn v_inp 10000.0   $ r=1e4, model=resistor, modelstr=None
rRin1 v_inp v_inn1 10000.0   $ r=1e4, model=resistor, modelstr=None
rRin2 v_inn v_inn1 10000.0   $ r=1e4, model=resistor, modelstr=None
.options gmin=1e-12 iabstol=1e-12 reltol=0.001 temp=27 tnom=27 vabstol=1e-06
* saveOptions options save=allpub
.ac dec 10 1.0 1000000000.0
* Sweep point 0: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8700e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.3600e-06, w_MPB=1.1200e-05, m_MPB=4.0000e+00, l_MCM4=3.0000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=5.0000e-06, w_MCM6=5.3400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 1: l_origin=3.8000e-07, l_M2=1.1800e-06, w_M2=1.8700e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.3600e-06, w_MPB=1.1200e-05, m_MPB=4.0000e+00, l_MCM4=2.7000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=4.5000e-07, w_MCM6=5.3400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 2: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8700e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=1.7100e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.3600e-06, w_MPB=1.1200e-05, m_MPB=4.0000e+00, l_MCM4=3.0000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=2.9500e-06, w_MCM6=6.6400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 3: l_origin=1.8000e-07, l_M2=1.1800e-06, w_M2=1.8700e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=4.2000e-06, w_M6=1.6200e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.8600e-06, w_MPB=1.1200e-05, m_MPB=4.0000e+00, l_MCM4=3.0000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=3.7500e-06, w_MCM6=5.3400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 4: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8800e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.4600e-06, w_MPB=1.1100e-05, m_MPB=4.0000e+00, l_MCM4=2.1000e-06, w_MCM4=3.8000e-06, m_MCM4=4.0000e+00, l_MCM6=1.8500e-06, w_MCM6=4.9400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 5: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8800e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.3000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.6600e-06, w_MPB=1.1200e-05, m_MPB=2.0000e+00, l_MCM4=3.0000e-06, w_MCM4=3.2000e-06, m_MCM4=4.0000e+00, l_MCM6=1.8500e-06, w_MCM6=4.3400e-06, m_MCM6=4.0000e+00, i_I0=8.7000e-06
* Sweep point 6: l_origin=4.8000e-07, l_M2=1.1800e-06, w_M2=1.8600e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.1600e-06, w_MPB=1.2100e-05, m_MPB=8.0000e+00, l_MCM4=3.0000e-06, w_MCM4=4.5000e-06, m_MCM4=4.0000e+00, l_MCM6=3.5000e-07, w_MCM6=7.3400e-06, m_MCM6=8.0000e+00, i_I0=8.7000e-06
* Sweep point 7: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8700e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.3600e-06, w_MPB=1.1400e-05, m_MPB=6.0000e+00, l_MCM4=3.8000e-06, w_MCM4=4.4000e-06, m_MCM4=4.0000e+00, l_MCM6=1.2500e-06, w_MCM6=6.3400e-06, m_MCM6=4.0000e+00, i_I0=8.7000e-06
* Sweep point 8: l_origin=4.8000e-07, l_M2=1.1800e-06, w_M2=1.8400e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.1600e-06, w_MPB=1.2300e-05, m_MPB=6.0000e+00, l_MCM4=5.0000e-06, w_MCM4=4.0000e-06, m_MCM4=4.0000e+00, l_MCM6=4.5000e-07, w_MCM6=7.4400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 9: l_origin=1.8000e-07, l_M2=1.1800e-06, w_M2=1.8500e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.2000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.2600e-06, w_MPB=1.2100e-05, m_MPB=8.0000e+00, l_MCM4=4.4000e-06, w_MCM4=4.4000e-06, m_MCM4=4.0000e+00, l_MCM6=2.8500e-06, w_MCM6=7.3400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* Sweep point 10: l_origin=3.8000e-07, l_M2=1.1800e-06, w_M2=1.8500e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.1000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.6600e-06, w_MPB=1.2100e-05, m_MPB=8.0000e+00, l_MCM4=5.0000e-06, w_MCM4=4.2000e-06, m_MCM4=4.0000e+00, l_MCM6=1.7500e-06, w_MCM6=7.3400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* Sweep point 11: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8500e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.6000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.6600e-06, w_MPB=1.2100e-05, m_MPB=8.0000e+00, l_MCM4=4.4000e-06, w_MCM4=4.4000e-06, m_MCM4=4.0000e+00, l_MCM6=1.3500e-06, w_MCM6=7.3400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 12: l_origin=3.8000e-07, l_M2=1.1800e-06, w_M2=1.8300e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=4.0000e-06, w_M6=1.6400e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.3600e-06, w_MPB=1.2700e-05, m_MPB=2.0000e+00, l_MCM4=2.0000e-06, w_MCM4=2.0000e-06, m_MCM4=4.0000e+00, l_MCM6=2.0500e-06, w_MCM6=5.0400e-06, m_MCM6=8.0000e+00, i_I0=8.7000e-06
* Sweep point 13: l_origin=1.8000e-07, l_M2=1.1800e-06, w_M2=1.8600e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=4.1000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.6600e-06, w_MPB=1.2100e-05, m_MPB=2.0000e+00, l_MCM4=4.4000e-06, w_MCM4=4.4000e-06, m_MCM4=4.0000e+00, l_MCM6=2.0500e-06, w_MCM6=7.3400e-06, m_MCM6=8.0000e+00, i_I0=8.7000e-06
* Sweep point 14: l_origin=3.8000e-07, l_M2=1.1800e-06, w_M2=1.8300e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=4.4000e-06, w_M6=2.0000e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.2600e-06, w_MPB=1.2300e-05, m_MPB=2.0000e+00, l_MCM4=2.0000e-06, w_MCM4=2.0000e-06, m_MCM4=4.0000e+00, l_MCM6=1.0500e-06, w_MCM6=5.4400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 15: l_origin=5.8000e-07, l_M2=1.1800e-06, w_M2=1.8400e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.8000e-06, w_M6=1.8300e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.1600e-06, w_MPB=1.1400e-05, m_MPB=6.0000e+00, l_MCM4=5.0000e-06, w_MCM4=4.2000e-06, m_MCM4=4.0000e+00, l_MCM6=4.1500e-06, w_MCM6=8.0400e-06, m_MCM6=6.0000e+00, i_I0=8.7000e-06
* Sweep point 16: l_origin=4.8000e-07, l_M2=9.8000e-07, w_M2=1.8500e-05, m_M2=1.4000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.3000e-06, w_M6=1.8400e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.0600e-06, w_MPB=1.1900e-05, m_MPB=2.0000e+00, l_MCM4=3.2000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=3.1500e-06, w_MCM6=7.7400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* Sweep point 17: l_origin=4.8000e-07, l_M2=1.1800e-06, w_M2=1.8500e-05, m_M2=1.6000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.3000e-06, w_M6=1.8400e-05, m_M6=2.0000e+00, m_M5=2.0000e+01, l_MPB=3.0600e-06, w_MPB=1.1900e-05, m_MPB=4.0000e+00, l_MCM4=3.8000e-06, w_MCM4=4.1000e-06, m_MCM4=4.0000e+00, l_MCM6=3.1500e-06, w_MCM6=7.7400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* Sweep point 18: l_origin=4.8000e-07, l_M2=1.1800e-06, w_M2=1.8500e-05, m_M2=2.0000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.3000e-06, w_M6=1.8400e-05, m_M6=6.0000e+00, m_M5=2.0000e+01, l_MPB=3.0600e-06, w_MPB=1.1900e-05, m_MPB=4.0000e+00, l_MCM4=3.2000e-06, w_MCM4=3.4000e-06, m_MCM4=4.0000e+00, l_MCM6=3.4500e-06, w_MCM6=7.7400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* Sweep point 19: l_origin=4.8000e-07, l_M2=1.6800e-06, w_M2=1.8500e-05, m_M2=1.8000e+01, l_M7=4.9900e-06, w_M7=3.0200e-06, m_M7=2.0000e+00, l_M6=3.3000e-06, w_M6=1.8400e-05, m_M6=2.0000e+00, m_M5=1.6000e+01, l_MPB=3.0600e-06, w_MPB=1.1900e-05, m_MPB=4.0000e+00, l_MCM4=3.2000e-06, w_MCM4=6.5000e-06, m_MCM4=4.0000e+00, l_MCM6=3.1500e-06, w_MCM6=7.7400e-06, m_MCM6=2.0000e+00, i_I0=8.7000e-06
* ^^^^ ngspice: use .step param or .data for sweep
.save all

.end