* SPICE netlist — converted from Spectre SCS (ngspice)

.model _ideal_switch_ sw vt=1e-3 roff=1e12 ron=1
.param l_origin=1e-06
.param l_M2=1.2e-06
.param w_M2=4.8e-05
.param m_M2=2
.param c_CLrepeat0=2e-12
.param l_M4=8e-07
.param w_M4=1e-05
.param m_M4=2
.param l_M7=8e-07
.param w_M7=2.64e-05
.param m_M7=2
.param l_M9=3e-06
.param w_M9=3.6e-05
.param m_M9=2
.param l_M11=3e-07
.param w_M11=1.44e-05
.param m_M11=2
.param l_M5=3e-06
.param w_M5=1.8e-06
.param m_M5=2
.param r_R2=100000.0
.param l_M26=2e-06
.param w_M26=4e-06
.param m_M26=1
.param l_M22=1e-06
.param w_M22=1e-05
.param m_M22=2
.param l_M23=2e-06
.param w_M23=6e-06
.param m_M23=1
.param i_Ip1=5e-06
.param i_Ip=2e-05
* OptimizingPowerConsumptionvsLinearizationinCMFBAmplifierswithSourceDegeneration_main1_None_No6Tester_7e656674b3631635
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
.subckt NMOS_96c2247a5f871a g d s vdd 0
xmos g d s vdd 0 Mos_41fc1667291e9350   $ l=l_M5, w=w_M5, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_14fca161ffdb6a7 d g s b
.ends
.subckt OptimizingPowerConsumptionvsLinearizationinCMFBAmplifierswithSourceDegeneration_main1_2600eeae3962018 Vcm VINN VINP VOUTN VOUTP OUTP_CMFB OUTN_CMFB vdd 0
xdifferentialpair_1 VINN VINP n9_4 n9_5 n9_0 vdd 0 DifferentialPair_740087b4bf30eeba   $ l=l_M2, w=w_M2, model=nch, m=int(m_M2), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
ccapacitor_1 VOUTP 0 c_CLrepeat0   $ c=2e-12, model=capacitor
ccapacitor_2 VOUTN 0 c_CLrepeat0   $ c=2e-12, model=capacitor
xpmos_1 n9_12 n9_5 vdd vdd 0 PMOS_8871922644e2f858   $ w=w_M4, l=l_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_1 n9_8 n9_2 0 vdd 0 NMOS_dd303b9005062fcc   $ w=w_M11, l=l_M11, m=int(m_M11), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_2 n9_7 VOUTN n9_2 vdd 0 NMOS_544525508e4498a7   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xpmos_2 n9_6 VOUTN n9_5 vdd 0 PMOS_86f5e1721e50a6ec   $ w=w_M7, l=l_M7, m=int(m_M7), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xnmos_3 n9_7 VOUTP n9_1 vdd 0 NMOS_544525508e4498a7   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xpmos_3 n9_12 n9_4 vdd vdd 0 PMOS_8871922644e2f858   $ w=w_M4, l=l_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_4 n9_8 n9_1 0 vdd 0 NMOS_dd303b9005062fcc   $ w=w_M11, l=l_M11, m=int(m_M11), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xnmos_5 n9_9 n9_3 0 vdd 0 NMOS_96c2247a5f871a   $ w=w_M5, l=l_M5, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xpmos_4 n9_6 VOUTP n9_4 vdd 0 PMOS_86f5e1721e50a6ec   $ w=w_M7, l=l_M7, m=int(m_M7), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xnmos_6 n9_10 n9_0 n9_3 vdd 0 NMOS_f61e13f7571a3fd7   $ w=w_M5, l=l_M5, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
vvsource_1 n9_6 0 DC 0.5   $ dc=0.5, ac=None, mode=None, model=vsource
vvsource_2 n9_7 0 DC 1.2   $ dc=1.2, ac=None, mode=None, model=vsource
vvsource_3 n9_8 0 DC 0.8   $ dc=0.8, ac=None, mode=None, model=vsource
vvsource_4 n9_9 0 DC 0.8   $ dc=0.8, ac=None, mode=None, model=vsource
vvsource_5 n9_10 0 DC 1.2   $ dc=1.2, ac=None, mode=None, model=vsource
ccapacitor_3 VOUTP VINP 3e-12   $ c=3e-12, model=capacitor
ccapacitor_4 VOUTN VINN 3e-12   $ c=3e-12, model=capacitor
xpmos_5 n9_11 n9_11 vdd vdd 0 PMOS_7ac8b8a9c244c625   $ w=w_M26, l=l_M26, m=int(m_M26), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xpmos_6 n9_11 n9_12 vdd vdd 0 PMOS_7ac8b8a9c244c625   $ w=w_M26, l=l_M26, m=int(m_M26), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xdifferentialpair_2 Vcm n9_15 n9_12 n9_11 n9_13 vdd 0 DifferentialPair_285bede8993664da   $ l=l_M22, w=w_M22, model=nch, m=int(m_M22), nf=None, mode=abba, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xnmos_7 n9_14 n9_13 0 vdd 0 NMOS_360d5b04259913b1   $ w=w_M23, l=l_M23, m=int(m_M23), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_8 n9_14 n9_14 0 vdd 0 NMOS_360d5b04259913b1   $ w=w_M23, l=l_M23, m=int(m_M23), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
r_rhrpo_1 OUTN_CMFB n9_15 r_R2   $ model=rhrpo   $ r=r_R2
r_rhrpo_2 OUTP_CMFB n9_15 r_R2   $ model=rhrpo   $ r=r_R2
ccapacitor_5 VOUTP n9_12 2e-12   $ c=2e-12, model=capacitor
ccapacitor_6 VOUTN n9_12 2e-12   $ c=2e-12, model=capacitor
iisource_1 vdd n9_14 DC i_Ip1   $ dc=i_Ip1, ac=0, model=isource, mode=None
.ends
.subckt MosfetLvs_4c4cc77eb93fccd d g s b
.ends
.subckt VSource_5c674318fdc56f6 a b
.ends
.subckt VSource_7f335e536b4a09a a b
.ends
.subckt VSource_a9b722f785f5c77 a b
.ends
.subckt rhrpo_f000470245f9d5e n0 n1
.ends
.subckt Mosfet_fc10e6663cac7ad d g s b
.ends
.subckt VSource_1446abbd77ff695d a b
.ends
.subckt MosfetLvs_1c6d6bc4d4ec8dbf d g s b
.ends
.subckt VSource_1db28cdfd7642c17 a b
.ends
.subckt Capacitor_22f39a48932239d0 a b
.ends
.subckt DifferentialPair_285bede8993664da g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s 0 n18 L=l_M22 W=w_M22 M=m_M22   $ model=n18, w=w_M22, l=l_M22, m=int(m_M22), nf=None
mmosfet_2 d2 g2 s 0 n18 L=l_M22 W=w_M22 M=m_M22   $ model=n18, w=w_M22, l=l_M22, m=int(m_M22), nf=None
mmosfet_3 0 0 d1 0 n18 L=9e-07 W=w_M22 M=1   $ model=n18, w=w_M22, l=9e-7, m=1, nf=None
mmosfet_4 d1 0 0 0 n18 L=9e-07 W=w_M22 M=1   $ model=n18, w=w_M22, l=9e-7, m=1, nf=None
.ends
.subckt Mos_2935b7173e8dac5d g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M9 W=w_M9 M=m_M9   $ model=n18, w=w_M9, l=l_M9, m=int(m_M9), nf=None
.ends
.subckt MosfetLvs_2a91f6f61442d7f2 d g s b
.ends
.subckt VSource_2cfdb437549897d2 a b
.ends
.subckt NMOS_360d5b04259913b1 g d s vdd 0
xmos g d s vdd 0 Mos_a9152153212e9c06   $ l=l_M23, w=w_M23, m=int(m_M23), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetLvs_36d10d96da76f591 d g s b
.ends
.subckt Mosfet_3a28cbdbae1123dc d g s b
.ends
.subckt Mos_41fc1667291e9350 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M5 W=w_M5 M=m_M5   $ model=n18, w=w_M5, l=l_M5, m=int(m_M5), nf=None
.ends
.subckt Capacitor_455ff18989871c65 a b
.ends
.subckt ISource_480e6a6e22b53dbf a b
.ends
.subckt NMOS_544525508e4498a7 g d s vdd 0
xmos g d s vdd 0 Mos_2935b7173e8dac5d   $ l=l_M9, w=w_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_579b69af56716726 d g s b
.ends
.subckt Capacitor_57bbc9dd713d4350 a b
.ends
.subckt Mos_5cd04b5d3e6e7274 g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M7 W=w_M7 M=m_M7   $ model=p18, w=w_M7, l=l_M7, m=int(m_M7), nf=None
.ends
.subckt Capacitor_5cf216a64f88c635 a b
.ends
.subckt VSource_5ff421cce4089485 a b
.ends
.subckt Mos_661396d6356097ce g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M5 W=w_M5 M=m_M5   $ model=n18, w=w_M5, l=l_M5, m=int(m_M5), nf=None
.ends
.subckt DifferentialPair_740087b4bf30eeba g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s 0 n18 L=l_M2 W=w_M2 M=m_M2   $ model=n18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
mmosfet_2 d2 g2 s 0 n18 L=l_M2 W=w_M2 M=m_M2   $ model=n18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
.ends
.subckt PMOS_7ac8b8a9c244c625 g d s vdd 0
xmos g d s vdd 0 Mos_d20435b2094c751e   $ l=l_M26, w=w_M26, m=int(m_M26), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt PMOS_86f5e1721e50a6ec g d s vdd 0
xmos g d s vdd 0 Mos_5cd04b5d3e6e7274   $ l=l_M7, w=w_M7, m=int(m_M7), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetLvs_8730e2fef0490f5c d g s b
.ends
.subckt PMOS_8871922644e2f858 g d s vdd 0
xmos g d s vdd 0 Mos_dba25d8b6d1a3b4d   $ l=l_M4, w=w_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_8959872d471aaca8 d g s b
.ends
.subckt Mosfet_8d47b4bd30b39795 d g s b
.ends
.subckt MosfetLvs_8d5cc0261bbd28f1 d g s b
.ends
.subckt OptimizingPowerConsumptionvsLinearizationinCMFBAmplifierswithSourceDegeneration_main1_wrapper_9080990592a485d6 VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0
xdut VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0 OptimizingPowerConsumptionvsLinearizationinCMFBAmplifierswithSourceDegeneration_main1_2600eeae3962018   $ 
.ends
.subckt Mosfet_95e29e2a298423d3 d g s b
.ends
.subckt Mos_a9152153212e9c06 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M23 W=w_M23 M=m_M23   $ model=n18, w=w_M23, l=l_M23, m=int(m_M23), nf=None
.ends
.subckt Mos_ac18818ad7e597e9 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M11 W=w_M11 M=m_M11   $ model=n18, w=w_M11, l=l_M11, m=int(m_M11), nf=None
.ends
.subckt Mosfet_b5c7239ed707bcf7 d g s b
.ends
.subckt MosfetLvs_bd290894a4949477 d g s b
.ends
.subckt MosfetLvs_be92dd0a81622a27 d g s b
.ends
.subckt VSource_cbb725a418ee2ae5 a b
.ends
.subckt MosfetLvs_cd85a93124348682 d g s b
.ends
.subckt MosfetLvs_ce917e8e88f0ca6d d g s b
.ends
.subckt Mos_d20435b2094c751e g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M26 W=w_M26 M=m_M26   $ model=p18, w=w_M26, l=l_M26, m=int(m_M26), nf=None
.ends
.subckt Mosfet_d5353e833fae3833 d g s b
.ends
.subckt Mosfet_db38a22f264de596 d g s b
.ends
.subckt Mos_dba25d8b6d1a3b4d g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M4 W=w_M4 M=m_M4   $ model=p18, w=w_M4, l=l_M4, m=int(m_M4), nf=None
.ends
.subckt NMOS_dd303b9005062fcc g d s vdd 0
xmos g d s vdd 0 Mos_ac18818ad7e597e9   $ l=l_M11, w=w_M11, m=int(m_M11), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetLvs_f143813bd1ba9e86 d g s b
.ends
.subckt NMOS_f61e13f7571a3fd7 g d s vdd 0
xmos g d s vdd 0 Mos_661396d6356097ce   $ l=l_M5, w=w_M5, m=int(m_M5), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_fff39d34cd70422b d g s b
.ends
vVD v_dd vdd DC 0   $ dc=0, ac=None, mode=None, model=vsource
vVS v_ss 0 DC 0   $ dc=0, ac=None, mode=None, model=vsource
vVDD v_dd v_ss DC 1.8   $ dc=1.8, ac=None, mode=None, model=vsource
vVcm VCM v_ss DC 0.9   $ dc=0.9, ac=None, mode=None, model=vsource
vV1 v_inp v_ss PULSE(0 1.8 10e-6 10e-12 10e-12 20e-6 40e-6)   $ dc=0, ac=None, mode=None, model=vsource
vV2 v_inn v_ss PULSE(1.8 0 10e-6 10e-12 10e-12 20e-6 40e-6)   $ dc=0, ac=None, mode=None, model=vsource
cCload_p v_outp v_ss 1e-12   $ c=1e-12, model=capacitor
cCload_n v_outn v_ss 1e-12   $ c=1e-12, model=capacitor
xdut VCM v_inp v_inn v_outp v_outn v_outp v_outn vdd 0 OptimizingPowerConsumptionvsLinearizationinCMFBAmplifierswithSourceDegeneration_main1_wrapper_9080990592a485d6   $ 
.options gmin=1e-12 iabstol=1e-12 reltol=0.001 temp=27 tnom=27 vabstol=1e-06
* saveOptions options save=allpub
.tran 1e-10 4e-05
* Sweep point 0: l_origin=6.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.7140e-05, m_M7=1.0000e+01, l_M9=5.8000e-06, w_M9=1.5700e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.7700e-05, m_M11=2.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=3.7000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=2.2000e-06, w_M22=8.6000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=5.9000e-05
* Sweep point 1: l_origin=7.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=5.2000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.6840e-05, m_M7=1.2000e+01, l_M9=1.0000e-05, w_M9=1.4400e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.6900e-05, m_M11=6.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.1000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=2.0000e-06, w_M22=8.2000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.1000e-05
* Sweep point 2: l_origin=5.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=2.4000e-12, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.8040e-05, m_M7=1.2000e+01, l_M9=8.4000e-06, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=1.6000e-06, w_M11=1.7200e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.0000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=2.4000e-06, w_M22=8.1000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=7.8000e-05
* Sweep point 3: l_origin=8.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=8.8000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.6240e-05, m_M7=1.2000e+01, l_M9=5.9000e-06, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.6800e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.0000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=1.8000e-06, w_M22=8.8000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.4000e-05
* Sweep point 4: l_origin=7.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=3.5000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.7140e-05, m_M7=1.2000e+01, l_M9=1.0000e-05, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.7100e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.0000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=2.2000e-06, w_M22=8.1000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.4000e-05
* Sweep point 5: l_origin=8.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=3.5000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.7140e-05, m_M7=1.2000e+01, l_M9=4.4000e-06, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.6800e-05, m_M11=6.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.0000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=2.2000e-06, w_M22=8.1000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.4000e-05
* Sweep point 6: l_origin=7.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=3.5000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=3.8000e-07, w_M7=1.7140e-05, m_M7=1.2000e+01, l_M9=1.0000e-05, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.7400e-05, m_M11=6.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.0000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=2.2000e-06, w_M22=8.9000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.4000e-05
* Sweep point 7: l_origin=7.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.2000e+01, c_CLrepeat0=3.5000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=1.8000e-07, w_M7=1.7140e-05, m_M7=1.2000e+01, l_M9=1.0000e-05, w_M9=1.4800e-05, m_M9=4.0000e+00, l_M11=3.7000e-06, w_M11=1.6800e-05, m_M11=6.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=4.0000e-06, w_M26=4.5000e-06, m_M26=2.0000e+00, l_M22=2.0000e-06, w_M22=8.1000e-06, m_M22=6.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=8.0000e-06, i_Ip=6.4000e-05
* Sweep point 8: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7550e-05, m_M4=1.8000e+01, l_M7=2.8000e-07, w_M7=1.8040e-05, m_M7=1.0000e+01, l_M9=9.9000e-06, w_M9=1.7900e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.2000e+01, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=1.7000e-06, w_M22=7.8000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.7000e-05, i_Ip=4.7000e-05
* Sweep point 9: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7450e-05, m_M4=1.8000e+01, l_M7=2.8000e-07, w_M7=1.8040e-05, m_M7=1.0000e+01, l_M9=9.9000e-06, w_M9=1.7900e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.2000e+01, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=1.7000e-06, w_M22=7.9000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.7000e-05, i_Ip=4.7000e-05
* Sweep point 10: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7550e-05, m_M4=1.8000e+01, l_M7=2.8000e-07, w_M7=2.0000e-05, m_M7=1.0000e+01, l_M9=9.9000e-06, w_M9=1.7900e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.2000e+01, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=1.7000e-06, w_M22=7.6000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.7000e-05, i_Ip=4.7000e-05
* Sweep point 11: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7550e-05, m_M4=1.8000e+01, l_M7=2.8000e-07, w_M7=1.8040e-05, m_M7=1.0000e+01, l_M9=9.9000e-06, w_M9=1.7900e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.2000e+01, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=1.8000e-06, w_M22=7.6000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.5000e-05, i_Ip=4.7000e-05
* Sweep point 12: l_origin=5.8000e-07, l_M2=1.8000e-07, w_M2=1.9500e-05, m_M2=1.2000e+01, c_CLrepeat0=3.7000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=4.8000e-07, w_M7=1.8540e-05, m_M7=8.0000e+00, l_M9=3.0000e-07, w_M9=1.7900e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=2.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=8.0000e+00, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.8000e-06, m_M26=2.0000e+00, l_M22=1.7000e-06, w_M22=1.0000e-05, m_M22=2.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.7000e-05, i_Ip=4.7000e-05
* Sweep point 13: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=1.9500e-05, m_M2=1.0000e+01, c_CLrepeat0=1.0000e-11, l_M4=7.8000e-07, w_M4=1.7550e-05, m_M4=1.6000e+01, l_M7=2.8000e-07, w_M7=1.8040e-05, m_M7=8.0000e+00, l_M9=9.9000e-06, w_M9=2.0000e-05, m_M9=6.0000e+00, l_M11=6.5000e-06, w_M11=1.7900e-05, m_M11=2.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.2000e+01, r_R2=1.0000e+04, l_M26=4.8000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=1.7000e-06, w_M22=7.6000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.7000e-05, i_Ip=4.7000e-05
* Sweep point 14: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=1.9500e-05, m_M2=1.0000e+01, c_CLrepeat0=1.6000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.6000e+01, l_M7=5.8000e-07, w_M7=2.0000e-05, m_M7=8.0000e+00, l_M9=2.8000e-06, w_M9=2.0000e-05, m_M9=2.0000e+00, l_M11=2.9000e-06, w_M11=1.8900e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.1000e-06, w_M26=5.4000e-06, m_M26=2.0000e+00, l_M22=2.1000e-06, w_M22=9.1000e-06, m_M22=2.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=7.3000e-05
* Sweep point 15: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=1.9500e-05, m_M2=1.2000e+01, c_CLrepeat0=4.4000e-12, l_M4=6.8000e-07, w_M4=1.7150e-05, m_M4=1.6000e+01, l_M7=4.8000e-07, w_M7=2.0000e-05, m_M7=1.0000e+01, l_M9=4.5000e-06, w_M9=2.0000e-05, m_M9=2.0000e+00, l_M11=2.9000e-06, w_M11=1.5800e-05, m_M11=2.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.9000e-06, w_M26=4.3000e-06, m_M26=2.0000e+00, l_M22=2.4000e-06, w_M22=9.1000e-06, m_M22=2.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.2000e-05, i_Ip=7.2000e-05
* Sweep point 16: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=2.4000e-12, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=9.8000e-07, w_M7=1.8040e-05, m_M7=1.2000e+01, l_M9=8.4000e-06, w_M9=1.8900e-05, m_M9=2.0000e+00, l_M11=1.6000e-06, w_M11=1.7500e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.0000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=2.4000e-06, w_M22=8.2000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=7.4000e-05
* Sweep point 17: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=2.4000e-12, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=3.8000e-07, w_M7=1.8040e-05, m_M7=1.2000e+01, l_M9=8.4000e-06, w_M9=1.8900e-05, m_M9=2.0000e+00, l_M11=1.6000e-06, w_M11=1.7200e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.0000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=2.0000e-06, w_M22=8.2000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=6.9000e-05
* Sweep point 18: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=2.4000e-12, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=3.8000e-07, w_M7=1.8040e-05, m_M7=1.2000e+01, l_M9=8.4000e-06, w_M9=1.8900e-05, m_M9=2.0000e+00, l_M11=1.6000e-06, w_M11=1.7200e-05, m_M11=2.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.4000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=2.4000e-06, w_M22=8.2000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=7.4000e-05
* Sweep point 19: l_origin=1.8000e-07, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=1.0000e+01, c_CLrepeat0=2.1000e-12, l_M4=7.8000e-07, w_M4=1.7150e-05, m_M4=1.8000e+01, l_M7=3.8000e-07, w_M7=1.6340e-05, m_M7=1.2000e+01, l_M9=8.4000e-06, w_M9=1.9100e-05, m_M9=2.0000e+00, l_M11=1.6000e-06, w_M11=1.7200e-05, m_M11=4.0000e+00, l_M5=3.0000e-07, w_M5=1.8000e-05, m_M5=1.0000e+01, r_R2=1.0000e+04, l_M26=2.0000e-06, w_M26=4.6000e-06, m_M26=2.0000e+00, l_M22=2.4000e-06, w_M22=8.2000e-06, m_M22=4.0000e+00, l_M23=2.0000e-06, w_M23=6.0000e-06, m_M23=1.0000e+00, i_Ip1=1.0000e-05, i_Ip=7.4000e-05
* ^^^^ ngspice: use .step param or .data for sweep
.save all

.end