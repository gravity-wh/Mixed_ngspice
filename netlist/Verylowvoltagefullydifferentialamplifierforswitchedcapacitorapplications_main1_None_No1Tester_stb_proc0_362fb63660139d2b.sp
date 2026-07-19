* SPICE netlist — converted from Spectre SCS (ngspice)

.model _ideal_switch_ sw vt=1e-3 roff=1e12 ron=1
.param l_origin=1e-06
.param l_M13=6e-07
.param w_M13=4e-06
.param m_M13=2
.param l_M2=6e-07
.param w_M2=1.6e-05
.param m_M2=2
.param l_M4=6e-07
.param w_M4=8e-06
.param m_M4=2
.param l_M62=6e-07
.param w_M62=4e-06
.param m_M62=2
.param c_CCp=1.4e-12
.param l_M9=6e-07
.param w_M9=8e-06
.param m_M9=2
.param l_M12=6e-07
.param w_M12=8e-06
.param m_M12=2
.param i_Ib=2e-05
.param l_MCM4=6e-07
.param w_MCM4=8e-06
.param m_MCM4=2
.param l_MCM3=6e-07
.param w_MCM3=8e-06
.param m_MCM3=2
* Verylowvoltagefullydifferentialamplifierforswitchedcapacitorapplications_main1_None_No1Tester_d282633ae6ce0b15
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
.subckt MosfetLvs_3f4417978b1ff12 d g s b
.ends
.subckt VSource_5c674318fdc56f6 a b
.ends
.subckt MosfetLvs_9d449a1b7f3e735 d g s b
.ends
.subckt Mos_b5777710649bf36 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_MCM3 W=w_MCM3 M=m_MCM3   $ model=n18, w=w_MCM3, l=l_MCM3, m=int(m_MCM3), nf=None
.ends
.subckt Resistor_b5e11dc0ae64f4e a b
.ends
.subckt Mosfet_b7c53393d589035 d g s b
.ends
.subckt MosfetLvs_de4bb73fde83eae d g s b
.ends
.subckt PCCCS_1f34a85d6db6993b a b
.ends
.subckt DifferentialPair_28ed545ca26f3b6a g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s vdd p18 L=l_M2 W=w_M2 M=m_M2   $ model=p18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
mmosfet_2 d2 g2 s vdd p18 L=l_M2 W=w_M2 M=m_M2   $ model=p18, w=w_M2, l=l_M2, m=int(m_M2), nf=None
.ends
.subckt Capacitor_316eb0b44a36e4be a b
.ends
.subckt ISource_437238510c8f9f07 a b
.ends
.subckt IProbe_4a3be06f99e1d42b a b
.ends
.subckt MosfetLvs_53e2fd5532e64b71 d g s b
.ends
.subckt VCVS_54646efb10a9bd8d a b c d
.ends
.subckt DifferentialPair_595ffcac6a4de7fd g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s 0 n18 L=l_MCM4 W=w_MCM4 M=m_MCM4   $ model=n18, w=w_MCM4, l=l_MCM4, m=int(m_MCM4), nf=None
mmosfet_2 d2 g2 s 0 n18 L=l_MCM4 W=w_MCM4 M=m_MCM4   $ model=n18, w=w_MCM4, l=l_MCM4, m=int(m_MCM4), nf=None
.ends
.subckt PMOS_5dcb8bac48a21d85 g d s vdd 0
xmos g d s vdd 0 Mos_b6f1275f61439445   $ l=l_M12, w=w_M12, m=int(m_M12), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt VSource_5ff421cce4089485 a b
.ends
.subckt Verylowvoltagefullydifferentialamplifierforswitchedcapacitorapplications_main1_wrapper_675ae03f2d2bf0d6 VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0
xdut VCM VINP VINN VOUTP VOUTN OUTP_CMFB OUTN_CMFB vdd 0 Verylowvoltagefullydifferentialamplifierforswitchedcapacitorapplications_main1_938dfe47b0ac2530   $ 
.ends
.subckt Mosfet_6bc28c733ffd7f15 d g s b
.ends
.subckt Mos_6bf709ac44d3ef0f g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M9 W=w_M9 M=m_M9   $ model=p18, w=w_M9, l=l_M9, m=int(m_M9), nf=None
.ends
.subckt PMOS_758e636fccef44bb g d s vdd 0
xmos g d s vdd 0 Mos_fb8ef577b3ba90aa   $ l=l_M9, w=w_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt PMOS_8d7e6885a5042031 g d s vdd 0
xmos g d s vdd 0 Mos_6bf709ac44d3ef0f   $ l=l_M9, w=w_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_91de1101fcaf3753 d g s b
.ends
.subckt Verylowvoltagefullydifferentialamplifierforswitchedcapacitorapplications_main1_938dfe47b0ac2530 VCM Vinp Vinn Outp Outn Outp_CMFB Outn_CMFB vdd 0
xdifferentialpair_1 n9_7 n9_6 Outn Outp 0 vdd 0 DifferentialPair_b70e55fea2da452d   $ l=l_M13, w=w_M13, model=nch, m=int(m_M13), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xdifferentialpair_2 Vinn Vinp n9_5 n9_4 n9_0 vdd 0 DifferentialPair_28ed545ca26f3b6a   $ l=l_M2, w=w_M2, model=pch, m=int(m_M2), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xnmos_1 vdd n9_6 n9_4 vdd 0 NMOS_ab0fb751101a476a   $ w=w_M4, l=l_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_2 vdd n9_7 n9_5 vdd 0 NMOS_ab0fb751101a476a   $ w=w_M4, l=l_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_3 n9_6 n9_4 0 vdd 0 NMOS_f2c79f194969b130   $ w=w_M62, l=l_M62, m=int(m_M62), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_4 n9_7 n9_4 0 vdd 0 NMOS_f2c79f194969b130   $ w=w_M62, l=l_M62, m=int(m_M62), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_5 n9_7 n9_5 0 vdd 0 NMOS_f2c79f194969b130   $ w=w_M62, l=l_M62, m=int(m_M62), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_6 n9_6 n9_5 0 vdd 0 NMOS_f2c79f194969b130   $ w=w_M62, l=l_M62, m=int(m_M62), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
ccapacitor_1 n9_5 Outn c_CCp   $ c=1.4e-12, model=capacitor
ccapacitor_2 Outp n9_4 c_CCp   $ c=1.4e-12, model=capacitor
xpmos_1 n9_1 n9_0 vdd vdd 0 PMOS_8d7e6885a5042031   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xpmos_2 n9_1 n9_1 vdd vdd 0 PMOS_8d7e6885a5042031   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
iisource_1 n9_1 n9_2 DC i_Ib   $ dc=i_Ib, ac=0, model=isource, mode=None
xpmos_3 n9_1 n9_6 vdd vdd 0 PMOS_758e636fccef44bb   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xpmos_4 n9_1 n9_7 vdd vdd 0 PMOS_758e636fccef44bb   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xpmos_5 n9_3 Outp vdd vdd 0 PMOS_5dcb8bac48a21d85   $ w=w_M12, l=l_M12, m=int(m_M12), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xpmos_6 n9_3 Outn vdd vdd 0 PMOS_5dcb8bac48a21d85   $ w=w_M12, l=l_M12, m=int(m_M12), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, nf=None, model=None, obs=None, builtin=True
xdifferentialpair_3 Outp_CMFB VCM n153_0 n9_3 n153_2 vdd 0 DifferentialPair_595ffcac6a4de7fd   $ l=l_MCM4, w=w_MCM4, model=nch, m=int(m_MCM4), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xdifferentialpair_4 VCM Outn_CMFB n9_3 n153_0 n153_3 vdd 0 DifferentialPair_595ffcac6a4de7fd   $ l=l_MCM4, w=w_MCM4, model=nch, m=int(m_MCM4), mode=cross, nf=None, dummy_l=None, dummy_m=0, y_spacing=1000, builtin=True, d_via=1
xpmos_7 n153_0 n9_3 vdd vdd 0 PMOS_8d7e6885a5042031   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xpmos_8 n153_0 n153_0 vdd vdd 0 PMOS_8d7e6885a5042031   $ w=w_M9, l=l_M9, m=int(m_M9), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=pch, nf=None, obs=None, builtin=True
xnmos_7 n9_2 n9_2 0 vdd 0 NMOS_d1fe5cd54ba911f6   $ w=w_MCM3, l=l_MCM3, m=int(m_MCM3), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_8 n9_2 n153_2 0 vdd 0 NMOS_d1fe5cd54ba911f6   $ w=w_MCM3, l=l_MCM3, m=int(m_MCM3), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
xnmos_9 n9_2 n153_3 0 vdd 0 NMOS_d1fe5cd54ba911f6   $ w=w_MCM3, l=l_MCM3, m=int(m_MCM3), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, nf=None, obs=None, builtin=True
.ends
.subckt Mos_9516ec8b2a3afd19 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M62 W=w_M62 M=m_M62   $ model=n18, w=w_M62, l=l_M62, m=int(m_M62), nf=None
.ends
.subckt VSource_9584980d461704d6 a b
.ends
.subckt Mosfet_958dc9814ab23da5 d g s b
.ends
.subckt Mosfet_9afe2caac24002c4 d g s b
.ends
.subckt MosfetLvs_a33bd54015429807 d g s b
.ends
.subckt Mosfet_a91fd76766ddfa6b d g s b
.ends
.subckt NMOS_ab0fb751101a476a g d s vdd 0
xmos g d s vdd 0 Mos_c8a901242b6c58b6   $ l=l_M4, w=w_M4, m=int(m_M4), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_ab2285934bbd2343 d g s b
.ends
.subckt MosfetLvs_adb5ebd9fb88794f d g s b
.ends
.subckt Mos_b6f1275f61439445 g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M12 W=w_M12 M=m_M12   $ model=p18, w=w_M12, l=l_M12, m=int(m_M12), nf=None
.ends
.subckt DifferentialPair_b70e55fea2da452d g1 g2 d1 d2 s vdd 0
mmosfet_1 d1 g1 s 0 n18 L=l_M13 W=w_M13 M=m_M13   $ model=n18, w=w_M13, l=l_M13, m=int(m_M13), nf=None
mmosfet_2 d2 g2 s 0 n18 L=l_M13 W=w_M13 M=m_M13   $ model=n18, w=w_M13, l=l_M13, m=int(m_M13), nf=None
.ends
.subckt Cmdmprobe1_c4f0e055e41d31f5 In1 In2 out1 out2 vdd 0
Eevinj In2 out2 In1 out1 -1   $ gain=-1, model=vcvs
Viinj inout In1 DC 0   $ r=1.0, model=iprobe
Viprb inout out1 DC 0   $ r=1.0, model=iprobe
Ffiinj 0 out2 -1   $ gain=-1, probes=iprb iinj, coeffs=0 1 1, model=pcccs
.ends
.subckt Mos_c8a901242b6c58b6 g d s vdd 0
mmosfet_1 d g s 0 n18 L=l_M4 W=w_M4 M=m_M4   $ model=n18, w=w_M4, l=l_M4, m=int(m_M4), nf=None
.ends
.subckt Capacitor_c92d32655e8d4758 a b
.ends
.subckt NMOS_d1fe5cd54ba911f6 g d s vdd 0
xmos g d s vdd 0 Mos_b5777710649bf36   $ l=l_MCM3, w=w_MCM3, m=int(m_MCM3), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt Mosfet_de381c6d06b42332 d g s b
.ends
.subckt MosfetLvs_e7a658b805dd8418 d g s b
.ends
.subckt Mosfet_e990df02bad416ff d g s b
.ends
.subckt NMOS_f2c79f194969b130 g d s vdd 0
xmos g d s vdd 0 Mos_9516ec8b2a3afd19   $ l=l_M62, w=w_M62, m=int(m_M62), from_virtuoso=False, drain_width=260, source_width=260, drain_aa_spacing=80, source_aa_spacing=80, drain_gate_spacing=140, source_gate_spacing=140, gate_extrude_height=220, model=nch, obs=None, builtin=True, nf=None, left_dummy_gate=0, right_dummy_gate=0, connect_gate=None, confine=None
.ends
.subckt MosfetLvs_f5042f4c5848430f d g s b
.ends
.subckt MosfetLvs_fa4a3218946e21c7 d g s b
.ends
.subckt Mos_fb8ef577b3ba90aa g d s vdd 0
mmosfet_1 d g s vdd p18 L=l_M9 W=w_M9 M=m_M9   $ model=p18, w=w_M9, l=l_M9, m=int(m_M9), nf=None
.ends
vVD v_dd vdd DC 0   $ dc=0, ac=None, mode=None, model=vsource
vVS v_ss 0 DC 0   $ dc=0, ac=None, mode=None, model=vsource
vVDD v_dd v_ss DC 1   $ dc=1, ac=None, mode=None, model=vsource
rRf_n X1_outn v_inn 10000.0   $ r=1e4, model=resistor, modelstr=None
rRf_p X1_outp v_inp 10000.0   $ r=1e4, model=resistor, modelstr=None
rRin_p v_inn1 v_inp 10000.0   $ r=1e4, model=resistor, modelstr=None
rRin_n v_inn1 v_inn 10000.0   $ r=1e4, model=resistor, modelstr=None
cCload_p X1_outp v_ss 5e-12   $ c=5e-12, model=capacitor
cCload_n X1_outn v_ss 5e-12   $ c=5e-12, model=capacitor
vVcm v_inn1 v_ss DC 0.5   $ dc=0.5, ac=None, mode=None, model=vsource
vVcm2 VCM v_ss DC 0.5   $ dc=0.5, ac=None, mode=None, model=vsource
xcmdmprobe0 v_outn v_outp X1_outp X1_outn vdd 0 Cmdmprobe1_c4f0e055e41d31f5   $ cmdm=-1
xdut VCM v_inp v_inn v_outp v_outn v_outp v_outn vdd 0 Verylowvoltagefullydifferentialamplifierforswitchedcapacitorapplications_main1_wrapper_675ae03f2d2bf0d6   $ 
.options gmin=1e-12 iabstol=1e-12 reltol=0.001 temp=27 tnom=27 vabstol=1e-06
* saveOptions options save=allpub
.ac dec 10 1.0 1000000000.0   $ STB→AC
* Sweep point 0: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=4.6000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=6.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.1000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.2800e-06, w_M9=1.5800e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=3.8000e-06, m_M12=4.0000e+00, i_Ib=7.0000e-06, l_MCM4=1.8000e-07, w_MCM4=6.0000e-06, m_MCM4=2.0000e+00, l_MCM3=1.8000e-07, w_MCM3=1.2200e-05, m_MCM3=8.0000e+00
* Sweep point 1: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=3.7000e-06, m_M13=4.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=2.0000e+00, l_M4=3.2800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.1000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.8000e-07, w_M9=1.6100e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=2.3000e-06, m_M12=4.0000e+00, i_Ib=8.1000e-06, l_MCM4=1.8000e-07, w_MCM4=9.0000e-06, m_MCM4=4.0000e+00, l_MCM3=1.8000e-07, w_MCM3=5.1000e-06, m_MCM3=6.0000e+00
* Sweep point 2: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=3.2000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9500e-05, m_M2=4.0000e+00, l_M4=3.0800e-06, w_M4=1.8000e-06, m_M4=2.0000e+00, l_M62=2.5800e-06, w_M62=9.7000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=2.8000e-07, w_M9=1.6800e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=3.3000e-06, m_M12=4.0000e+00, i_Ib=8.3000e-06, l_MCM4=1.8000e-07, w_MCM4=9.0000e-06, m_MCM4=4.0000e+00, l_MCM3=1.8000e-07, w_MCM3=4.2000e-06, m_MCM3=6.0000e+00
* Sweep point 3: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=4.2000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=6.0000e+00, l_M4=2.6800e-06, w_M4=2.1000e-06, m_M4=2.0000e+00, l_M62=2.5800e-06, w_M62=9.1000e-06, m_M62=2.0000e+00, c_CCp=6.4000e-13, l_M9=1.7800e-06, w_M9=1.4600e-05, m_M9=4.0000e+00, l_M12=4.8000e-07, w_M12=3.5000e-06, m_M12=4.0000e+00, i_Ib=8.1000e-06, l_MCM4=1.8000e-07, w_MCM4=1.1700e-05, m_MCM4=2.0000e+00, l_MCM3=1.8000e-07, w_MCM3=1.1100e-05, m_MCM3=4.0000e+00
* Sweep point 4: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=4.2000e-06, m_M13=4.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=2.0000e+00, l_M4=3.1800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.5800e-06, w_M62=8.6000e-06, m_M62=2.0000e+00, c_CCp=5.4000e-13, l_M9=1.7800e-06, w_M9=1.7400e-05, m_M9=1.0000e+01, l_M12=4.8000e-07, w_M12=2.5000e-06, m_M12=4.0000e+00, i_Ib=8.5000e-06, l_MCM4=1.8000e-07, w_MCM4=1.6100e-05, m_MCM4=2.0000e+00, l_MCM3=1.8000e-07, w_MCM3=1.1900e-05, m_MCM3=8.0000e+00
* Sweep point 5: l_origin=3.8000e-07, l_M13=1.8000e-07, w_M13=3.6000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=4.0000e+00, l_M4=3.0800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.5800e-06, w_M62=8.6000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.9800e-06, w_M9=1.6600e-05, m_M9=8.0000e+00, l_M12=3.8000e-07, w_M12=2.9000e-06, m_M12=4.0000e+00, i_Ib=7.7000e-06, l_MCM4=1.8000e-07, w_MCM4=8.0000e-06, m_MCM4=2.0000e+00, l_MCM3=1.8000e-07, w_MCM3=1.1800e-05, m_MCM3=6.0000e+00
* Sweep point 6: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=4.2000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=6.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.0000e-06, m_M62=2.0000e+00, c_CCp=6.4000e-13, l_M9=4.8000e-07, w_M9=1.6400e-05, m_M9=6.0000e+00, l_M12=6.8000e-07, w_M12=3.5000e-06, m_M12=4.0000e+00, i_Ib=6.9000e-06, l_MCM4=2.8000e-07, w_MCM4=3.5000e-06, m_MCM4=2.0000e+00, l_MCM3=1.8000e-07, w_MCM3=1.0300e-05, m_MCM3=6.0000e+00
* Sweep point 7: l_origin=3.8000e-07, l_M13=1.8000e-07, w_M13=4.5000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=6.0000e+00, l_M4=1.8800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.9800e-06, w_M62=9.3000e-06, m_M62=2.0000e+00, c_CCp=9.4000e-13, l_M9=1.2800e-06, w_M9=1.5900e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=3.8000e-06, m_M12=4.0000e+00, i_Ib=7.1000e-06, l_MCM4=1.8000e-07, w_MCM4=5.6000e-06, m_MCM4=2.0000e+00, l_MCM3=4.8000e-07, w_MCM3=1.1500e-05, m_MCM3=6.0000e+00
* Sweep point 8: l_origin=6.8000e-07, l_M13=1.8000e-07, w_M13=3.8000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9900e-05, m_M2=4.0000e+00, l_M4=3.0800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.2000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.7800e-06, w_M9=1.6000e-05, m_M9=4.0000e+00, l_M12=4.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.1000e-06, l_MCM4=1.8000e-07, w_MCM4=1.0300e-05, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.2700e-05, m_MCM3=6.0000e+00
* Sweep point 9: l_origin=6.8000e-07, l_M13=1.8000e-07, w_M13=3.8000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9900e-05, m_M2=6.0000e+00, l_M4=3.0800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.2000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.6800e-06, w_M9=1.6000e-05, m_M9=2.0000e+00, l_M12=4.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.0000e-06, l_MCM4=1.8000e-07, w_MCM4=1.0300e-05, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.0000e-05, m_MCM3=6.0000e+00
* Sweep point 10: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=4.1000e-06, m_M13=4.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.4000e-06, m_M62=2.0000e+00, c_CCp=8.4000e-13, l_M9=1.7800e-06, w_M9=1.6700e-05, m_M9=6.0000e+00, l_M12=4.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.1000e-06, l_MCM4=2.8000e-07, w_MCM4=9.4000e-06, m_MCM4=4.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.1700e-05, m_MCM3=8.0000e+00
* Sweep point 11: l_origin=6.8000e-07, l_M13=1.8000e-07, w_M13=3.8000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=2.0000e-05, m_M2=6.0000e+00, l_M4=3.0800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.2000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=2.1800e-06, w_M9=1.6000e-05, m_M9=4.0000e+00, l_M12=4.8000e-07, w_M12=2.6000e-06, m_M12=4.0000e+00, i_Ib=6.9000e-06, l_MCM4=1.8000e-07, w_MCM4=1.0300e-05, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.2500e-05, m_MCM3=6.0000e+00
* Sweep point 12: l_origin=6.8000e-07, l_M13=1.8000e-07, w_M13=3.8000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9900e-05, m_M2=6.0000e+00, l_M4=3.0800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.2000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.7800e-06, w_M9=1.6000e-05, m_M9=6.0000e+00, l_M12=4.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.1000e-06, l_MCM4=1.8000e-07, w_MCM4=1.0300e-05, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.2700e-05, m_MCM3=8.0000e+00
* Sweep point 13: l_origin=6.8000e-07, l_M13=1.8000e-07, w_M13=3.8000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9900e-05, m_M2=6.0000e+00, l_M4=3.0800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.1000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.9800e-06, w_M9=1.6000e-05, m_M9=4.0000e+00, l_M12=4.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=6.9000e-06, l_MCM4=2.8000e-07, w_MCM4=1.0300e-05, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=1.2500e-05, m_MCM3=6.0000e+00
* Sweep point 14: l_origin=5.8000e-07, l_M13=1.8000e-07, w_M13=4.5000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.2800e-06, w_M4=1.1000e-06, m_M4=2.0000e+00, l_M62=2.7800e-06, w_M62=9.6000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.3800e-06, w_M9=1.6000e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=4.4000e-06, m_M12=4.0000e+00, i_Ib=7.9000e-06, l_MCM4=2.8000e-07, w_MCM4=1.0000e-05, m_MCM4=2.0000e+00, l_MCM3=7.8000e-07, w_MCM3=1.0400e-05, m_MCM3=6.0000e+00
* Sweep point 15: l_origin=4.8000e-07, l_M13=1.8000e-07, w_M13=3.7000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.8800e-06, w_M4=1.0000e-06, m_M4=2.0000e+00, l_M62=2.7800e-06, w_M62=9.4000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=1.3800e-06, w_M9=1.6600e-05, m_M9=4.0000e+00, l_M12=5.8000e-07, w_M12=3.8000e-06, m_M12=4.0000e+00, i_Ib=7.7000e-06, l_MCM4=2.8000e-07, w_MCM4=1.0600e-05, m_MCM4=2.0000e+00, l_MCM3=6.8000e-07, w_MCM3=1.0400e-05, m_MCM3=6.0000e+00
* Sweep point 16: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=5.7000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=2.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.4000e-06, m_M62=2.0000e+00, c_CCp=7.4000e-13, l_M9=7.8000e-07, w_M9=1.6700e-05, m_M9=6.0000e+00, l_M12=5.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.2000e-06, l_MCM4=1.8000e-07, w_MCM4=9.4000e-06, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=9.6000e-06, m_MCM3=1.0000e+01
* Sweep point 17: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=3.4000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.4000e-06, m_M62=2.0000e+00, c_CCp=1.5400e-12, l_M9=1.0800e-06, w_M9=1.6700e-05, m_M9=6.0000e+00, l_M12=5.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.2000e-06, l_MCM4=1.8000e-07, w_MCM4=9.4000e-06, m_MCM4=2.0000e+00, l_MCM3=3.8000e-07, w_MCM3=9.6000e-06, m_MCM3=1.0000e+01
* Sweep point 18: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=3.4000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.5000e-06, m_M62=4.0000e+00, c_CCp=7.4000e-13, l_M9=7.8000e-07, w_M9=1.6700e-05, m_M9=6.0000e+00, l_M12=6.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.2000e-06, l_MCM4=1.8000e-07, w_MCM4=7.6000e-06, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=9.6000e-06, m_MCM3=1.0000e+01
* Sweep point 19: l_origin=1.8000e-07, l_M13=1.8000e-07, w_M13=3.4000e-06, m_M13=6.0000e+00, l_M2=1.8000e-07, w_M2=1.9600e-05, m_M2=4.0000e+00, l_M4=2.5800e-06, w_M4=8.0000e-07, m_M4=2.0000e+00, l_M62=2.6800e-06, w_M62=9.4000e-06, m_M62=2.0000e+00, c_CCp=1.4000e-13, l_M9=7.8000e-07, w_M9=1.6700e-05, m_M9=6.0000e+00, l_M12=5.8000e-07, w_M12=3.4000e-06, m_M12=4.0000e+00, i_Ib=7.2000e-06, l_MCM4=6.8000e-07, w_MCM4=9.4000e-06, m_MCM4=2.0000e+00, l_MCM3=2.8000e-07, w_MCM3=9.5000e-06, m_MCM3=1.0000e+01
* ^^^^ ngspice: use .step param or .data for sweep
.save all

.end