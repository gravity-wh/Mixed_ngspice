/* float_spice.c — Zero-Double Float-First SPICE Engine v2.5
 * =====================================================================
 * REAL=float throughout. 0 cvtss2sd in application code.
 * Nodal Analysis + MNA (floating Vsrcs) + BSIM4v5 + Newton DC solver.
 *
 * Design: Grounded Vsrcs fix their +node.  Floating Vsrcs (neither
 *          terminal at GND) use MNA branch current variables so the
 *          constraint v[p]-v[n]=Vdc is enforced exactly.      (B8 fix)
 *
 * Build:  gcc -O2 -o float_spice float_spice.c -lm
 * Verify: objdump -d float_spice | grep -c cvtss2sd
 * Usage:  ./float_spice circuit.sp
 * =====================================================================
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <float.h>

#define REAL float
#define R(x) x##f
#define IS_NAN(x) ((x)!=(x))

#define MAX_LINE  4096
#define MAX_NODES 256
#define MAX_ELEMS 2048
#define MAX_MODELS 64
#define MAX_PARAMS 256
#define MAX_SWEEP 10000
#define MAX_TRAN  5000
#define MAX_SUBCKT 64
#define MAX_SUBCKT_LINES 512

/* ===== Data Structures ===== */
typedef struct {
    char name[32];
    char nodes[32][32]; int nnode;
    char lines[MAX_SUBCKT_LINES][MAX_LINE]; int nline;
} Subckt;
typedef struct { char key[32]; REAL val; } Param;
typedef struct { char name[32], type[16]; Param p[MAX_PARAMS]; int np; } Model;
typedef struct { char name[32]; int p, n; REAL val; } Resistor;
typedef struct { char name[32]; int d, g, s, b; char model[32]; REAL w, l; int m; } Mosfet;
/* Waveform types for voltage sources (P3.4) */
#define WF_DC    0
#define WF_SIN   1
#define WF_PULSE 2
#define WF_PWL   3
typedef struct {
    char name[32]; int p, n; REAL dc;
    int  wf_type;          /* WF_DC / WF_SIN / WF_PULSE / WF_PWL */
    /* SIN: vo+va*sin(2π*freq*(t-td))*exp(-(t-td)*theta) for t>td */
    REAL vo, va, freq, td_sin, theta;
    /* PULSE: v1↔v2 with td,tr,tf,pw,per */
    REAL v1, v2, td_pulse, tr, tf, pw, per;
    /* PWL: (ti,vi) pairs */
    int   pwl_n;
    REAL *pwl_t, *pwl_v;
    /* P5.2: AC analysis source parameters */
    REAL ac_mag, ac_phase;
} Vsource;
typedef struct { char name[32]; int p, n; REAL dc; } Isource;
typedef struct { char name[32]; int p, n; REAL c; } Capacitor;
/* P5.5: Diode device — exponential I-V model */
typedef struct { char name[32]; int p, n; char model[32]; REAL area; } Diode;

typedef struct {
    int nn, nr, nm, nv, nc, ni, ngnd;
    char nmap[MAX_NODES][32];
    Resistor *res; Mosfet *mos; Vsource *vsrc; Capacitor *cap; Isource *isrc; Diode *dio;
    int nd;  /* P5.5: diode count */
    Model models[MAX_MODELS]; int nmodel;
    Subckt subckts[MAX_SUBCKT]; int nsubckt;
    int do_op, do_dc, do_tran, dc_nested;
    char dc_src[32], dc_src2[32]; REAL dc_start, dc_stop, dc_step;
    REAL dc_start2, dc_stop2, dc_step2;
    REAL tran_tstop, tran_tstep;
    /* Options (P3.2): defaults match SPICE convention */
    REAL opt_gmin, opt_abstol, opt_reltol;
    int  opt_maxiter;
    /* Temperature (P3.2): Kelvin, default 300.15K (27°C) */
    REAL temp;
    /* Parameters (P3.2): simple name=value store for {} substitution */
    char param_names[256][32];
    REAL param_vals[256];
    int  nparam;
    int in_control;  /* P3.1: inside .control block */
    /* Print requests (P3.1) from .control block */
    #define MAX_PRINTS 64
    struct { char what[4]; char name[32]; } prints[MAX_PRINTS];
    int nprint;
    /* TRAN state (P4.1): capacitor companion model history.
     * tran_dt=0 → DC mode; >0 → TRAN with trapezoidal integration. */
    REAL tran_dt;
    REAL *tran_v_prev;   /* node voltages at previous time step  [nn] */
    REAL *tran_cap_i;    /* capacitor currents at previous step  [nc] */
    /* P4.2: MOSFET intrinsic capacitance TRAN history.
     * Stored as [nm*3] arrays: (gs,gd,gb) per MOSFET.
     * mos_v_prev: V(g)-V(x) at previous step for Cgs/Cgd/Cgb.
     * mos_cap_i:  capacitor currents at previous step. */
    REAL *tran_mos_v_prev;  /* [nm*3] gate-source/drain/body voltages */
    REAL *tran_mos_cap_i;   /* [nm*3] Cgs/Cgd/Cgb currents */
    /* P5.1: .control let variables + device parameter cache */
    #define MAX_LETS 64
    char let_names[MAX_LETS][32];
    REAL let_vals[MAX_LETS];
    char let_exprs[MAX_LETS][MAX_LINE];  /* expression text for re-eval */
    int nlet;
    #define MAX_DEVICE_PARAMS 1024
    char dev_param_names[MAX_DEVICE_PARAMS][64];
    REAL dev_param_vals[MAX_DEVICE_PARAMS];
    int ndev_param;
    /* P5.2: AC analysis */
    int  do_ac;
    char ac_type[8];      /* "dec" / "lin" / "oct" */
    int  ac_n;
    REAL ac_fstart, ac_fstop;
    /* P5.4: .ic initial conditions */
    #define MAX_IC 64
    int nic;
    int ic_nodes[MAX_IC];
    REAL ic_vals[MAX_IC];
    int tran_uic;  /* .tran uic flag */
} Circuit;

/* ===== Dense Matrix + Float LU ===== */
static int lu_solve(int n, REAL *a, REAL *b, REAL *x) {
    int *ipiv=calloc(n,sizeof(int)); int i,j,k;
    for(i=0;i<n;i++) ipiv[i]=i;
    for(k=0;k<n;k++) {
        REAL piv=R(0.0); int pr=k;
        for(i=k;i<n;i++){ REAL av=fabsf(a[i+k*n]); if(av>piv){piv=av;pr=i;} }
        if(piv<R(1e-30)){free(ipiv);return -1;}
        if(pr!=k){
            int ti=ipiv[k];ipiv[k]=ipiv[pr];ipiv[pr]=ti;
            for(j=0;j<n;j++){REAL t=a[k+j*n];a[k+j*n]=a[pr+j*n];a[pr+j*n]=t;}
        }
        REAL pk=a[k+k*n];
        for(i=k+1;i<n;i++){ REAL f=a[i+k*n]/pk; for(j=k;j<n;j++) a[i+j*n]-=f*a[k+j*n]; }
    }
    for(i=0;i<n;i++){ x[i]=b[ipiv[i]]; for(j=0;j<i;j++) x[i]-=a[i+j*n]*x[j]; }
    for(i=n-1;i>=0;i--){ for(j=i+1;j<n;j++) x[i]-=a[i+j*n]*x[j]; x[i]/=a[i+i*n]; }
    free(ipiv); return 0;
}

/* P5.2: Complex dense LU solver with interleaved real/imag arrays.
 * ar[N*N], ai[N*N] — interleaved real and imaginary parts.
 * br[N], bi[N] — RHS real and imag.  xr[N], xi[N] — solution.
 * Partial pivoting on magnitude sqrt(ar²+ai²). All FP32 arithmetic. */
static int lu_solve_complex(int n, REAL *ar, REAL *ai, REAL *br, REAL *bi,
                            REAL *xr, REAL *xi) {
    int *ipiv=calloc(n,sizeof(int)); int i,j,k;
    for(i=0;i<n;i++) ipiv[i]=i;
    for(k=0;k<n;k++) {
        /* Pivot: max magnitude */
        REAL piv=R(0.0); int pr=k;
        for(i=k;i<n;i++){
            REAL mag=ar[i+k*n]*ar[i+k*n]+ai[i+k*n]*ai[i+k*n];
            if(mag>piv){piv=mag;pr=i;}
        }
        if(piv<R(1e-30)){free(ipiv);return -1;}
        if(pr!=k){
            int ti=ipiv[k];ipiv[k]=ipiv[pr];ipiv[pr]=ti;
            for(j=0;j<n;j++){ REAL tr=ar[k+j*n]; ar[k+j*n]=ar[pr+j*n]; ar[pr+j*n]=tr;
                              REAL ti2=ai[k+j*n]; ai[k+j*n]=ai[pr+j*n]; ai[pr+j*n]=ti2; }
        }
        /* Elimination */
        REAL pkr=ar[k+k*n], pki=ai[k+k*n];
        REAL denom=pkr*pkr+pki*pki+R(1e-30);
        for(i=k+1;i<n;i++){
            REAL fr=ar[i+k*n], fi=ai[i+k*n];
            REAL qr=(fr*pkr+fi*pki)/denom, qi=(fi*pkr-fr*pki)/denom;
            for(j=k;j<n;j++){
                ar[i+j*n]-=qr*ar[k+j*n]-qi*ai[k+j*n];
                ai[i+j*n]-=qr*ai[k+j*n]+qi*ar[k+j*n];
            }
        }
    }
    /* Forward substitution */
    for(i=0;i<n;i++){ xr[i]=br[ipiv[i]]; xi[i]=bi[ipiv[i]];
        for(j=0;j<i;j++){
            xr[i]-=ar[i+j*n]*xr[j]-ai[i+j*n]*xi[j];
            xi[i]-=ar[i+j*n]*xi[j]+ai[i+j*n]*xr[j];
        }
    }
    /* Back substitution */
    for(i=n-1;i>=0;i--){
        for(j=i+1;j<n;j++){
            xr[i]-=ar[i+j*n]*xr[j]-ai[i+j*n]*xi[j];
            xi[i]-=ar[i+j*n]*xi[j]+ai[i+j*n]*xr[j];
        }
        REAL den=ar[i+i*n]*ar[i+i*n]+ai[i+i*n]*ai[i+i*n]+R(1e-30);
        REAL tx=(xr[i]*ar[i+i*n]+xi[i]*ai[i+i*n])/den;
        xi[i]=(xi[i]*ar[i+i*n]-xr[i]*ai[i+i*n])/den;
        xr[i]=tx;
    }
    free(ipiv); return 0;
}

/* ===== BSIM4v5 Model Parameters (74 fields, ALL FLOAT) ===== */
typedef struct {
    /* --- Core (19) --- */
    REAL vth0,k1,k2,nfactor,eta0;
    REAL u0,ua,ub,uc,vsat,toxe;
    REAL mobmod,ud,eu; /* mobility model selector + Coulomb scattering */
    REAL pclm;
    /* --- Short-channel Vth (13) --- */
    REAL dvt0,dvt1,dvt2,dvt0w,dvt1w,dvt2w;
    REAL dsub,k3,k3b,w0,nlx;
    REAL etab;          /* DIBL body-bias coefficient */
    /* --- Rds (7) --- */
    REAL rdsw,rsw,rdw,prwg,prwb,prt,wr;
    /* --- Early voltage stack (7) --- */
    REAL pvag,pdiblc1,pdiblc2,pdiblcb,drout,pscbe1,pscbe2;
    /* --- Subthreshold (7) --- */
    REAL voff,voffcv,minv,cdsc,cdscd,cdscb,cit;
    /* --- Saturation / Vdsat (5) --- */
    REAL a0,a1,a2,ags,delta;
    /* --- Temperature (7) --- */
    REAL kt1,kt1l,kt2,ute,ua1,ub1,uc1;
    /* --- Geometry offsets (4) --- */
    REAL wint,lint,dwg,dwb;
    /* --- Capacitance / junction (4) --- */
    REAL cgso,cgdo,cgbo,cj;
    /* --- Intrinsic capacitance model (9) --- */
    REAL capmod,acde,moin,noff,cgsl,cgdl,ckappas,ckappad,cf;
    /* --- Junction diode (13) --- */
    REAL jss,jsws,jswgs,njs,bvs,xjbvs;  /* source-side */
    REAL jsd,jswd,jswgd,njd,bvd,xjbvd;  /* drain-side */
    REAL mj;  /* junction grading coefficient */
    /* --- Noise (4) --- */
    REAL noia,noib,fnoimod,tnoimod;
    /* --- Physical / process (4) --- */
    REAL xj,ndep,nsd,at;
    /* --- Gate resistance (1) --- */
    REAL rgatemod;
    /* --- Body resistance network (6) --- */
    REAL rbodymod, rbdb, rbsb, rbpb, rbps, rbpd;
} BSIM4Param;

typedef struct {
    REAL ids,gm,gds,gmbs,vth,vdsat,vdseff,vgsteff,Abulk,ueff,EsatL,beta;
    /* P4.2: Intrinsic capacitances for TRAN (Meyer model + overlap) */
    REAL cgs,cgd,cgb;
    REAL ibs,ibd,gbs,gbd;  /* junction currents + conductances */
    REAL rbody;  /* equivalent body resistance Ω (simplified single-resistor model) */
} BSIM4Out;

static BSIM4Param bsim4_default(void) {
    BSIM4Param p={0};
    /* --- Core --- */
    p.vth0=R(0.62261); p.k1=R(0.4); p.k2=R(0.0); p.nfactor=R(1.6);
    p.eta0=R(0.0125); p.u0=R(0.049); p.ua=R(6e-10); p.ub=R(1.2e-18);
    p.uc=R(0.0); p.vsat=R(130000.0); p.toxe=R(1.8e-9);
    p.mobmod=R(0.0); p.ud=R(0.0); p.eu=R(1.0); /* mobMod=0; Coulomb off by default */
    p.pclm=R(0.02);
    /* --- Short-channel Vth (BSIM4v5 UG defaults) --- */
    p.dvt0=R(2.2); p.dvt1=R(0.53); p.dvt2=R(-0.032);
    p.dvt0w=R(0.0); p.dvt1w=R(5.3e6); p.dvt2w=R(-0.032);
    p.dsub=R(0.56); p.k3=R(80.0); p.k3b=R(0.0); p.w0=R(2.5e-6); p.nlx=R(1.74e-7);
    p.etab=R(-0.07);
    /* --- Rds --- */
    /* rdsw,rsw,rdw,prwg,prwb,prt = 0 (from calloc) */
    p.wr=R(1.0);
    /* --- Early voltage stack --- */
    p.pdiblc1=R(0.001); p.pdiblc2=R(0.001);
    p.pdiblcb=R(0.0); p.drout=R(0.56);
    p.pscbe1=R(4.24e8); p.pscbe2=R(1.0e-5);
    /* pvag = 0 (off by default) */
    /* --- Subthreshold --- */
    p.voff=R(-0.08); p.cdsc=R(2.4e-4); p.cit=R(0.0);
    /* voffcv, minv, cdscd, cdscb = 0 (off by default) */
    /* --- Saturation / Vdsat --- */
    p.a0=R(1.0); p.a1=R(0.0); p.a2=R(1.0);
    p.ags=R(0.0); p.delta=R(0.01);
    /* --- Temperature --- */
    p.kt1=R(-0.11); p.kt1l=R(0.0); p.kt2=R(0.022);
    p.ute=R(-1.5); p.ua1=R(4.31e-9); p.ub1=R(-7.61e-18); p.uc1=R(-5.6e-11);
    /* --- Geometry offsets --- */
    p.wint=R(5e-9); p.lint=R(0.0);
    /* dwg, dwb = 0 (from calloc) */
    /* --- Capacitance (off by default) --- */
    p.cj=R(5.0e-4);
    /* cgso, cgdo, cgbo = 0 (from calloc) */
    /* --- Intrinsic capacitance model --- */
    p.capmod=R(0.0); /* Meyer by default */
    /* acde, moin, noff, cgsl, cgdl, ckappas, ckappad, cf = 0 (from calloc) */
    /* --- Junction diode (off by default) ---
     * jss/jsws/jswgs/bvs/bvd/xjbvs/xjbvd = 0 (from calloc)
     * jsd/jswd/jswgd likewise zero; njs/njd=1.0, mj=0.5 (nonzero defaults) */
    p.njs=R(1.0); p.njd=R(1.0); p.mj=R(0.5);
    /* --- Noise (off by default) --- */
    /* noia, noib, fnoimod, tnoimod = 0 (from calloc);
     * fnoimod=1 (PTM 默认) — 由 bsim4_from_model() 从 .lib 覆盖 */
    /* --- Physical / process --- */
    p.xj=R(1.5e-8); p.ndep=R(1.7e17); p.nsd=R(1.0e20);
    p.at=R(3.3e4);
    /* rgatemod = 0 (off by default, from calloc) */
    /* rbodymod/rbdb/rbsb/rbpb/rbps/rbpd = 0 (off by default, from calloc) */
    return p;
}

static inline REAL smooth_vdseff(REAL vds, REAL vdsat) {
    REAL d=R(0.01), x=vdsat-vds-d;
    return vdsat-R(0.5)*(x+sqrtf(x*x+R(4.0)*d*vdsat+R(1e-30)));
}

BSIM4Out bsim4_eval(REAL vgs, REAL vds, REAL vbs, REAL weff, REAL leff,
                     const BSIM4Param *pp, REAL temp) {
    BSIM4Out o; memset(&o,0,sizeof(o));
    /* Guard: toxe=0 (model parse failure) → coxe=INF → NaN/INF cascade.
     * Use safe default 1.8nm when toxe is missing or corrupt. */
    REAL toxe_safe=pp->toxe;
    if(toxe_safe<R(1e-12)) toxe_safe=R(1.8e-9);
    /* P5.4: Temperature-dependent thermal voltage + parameter corrections */
    REAL Tnom=R(300.15);
    REAL vt=R(8.617333e-5)*temp;  /* k_B/q * T */
    REAL T_ratio=temp/Tnom;
    REAL dT_Tnom=T_ratio-R(1.0);  /* T/Tnom - 1 */
    REAL vth0_T=pp->vth0 + pp->kt1*dT_Tnom + pp->kt2*dT_Tnom*dT_Tnom;
    REAL u0_T=pp->u0 * powf(T_ratio, pp->ute);
    REAL ua_T=pp->ua + pp->ua1*dT_Tnom;
    REAL ub_T=pp->ub + pp->ub1*dT_Tnom;
    REAL uc_T=pp->uc + pp->uc1*dT_Tnom;
    REAL coxe=R(3.9)*R(8.854187817e-12)/toxe_safe;
    REAL phis=R(0.6), sqrt_phis=sqrtf(phis);
    REAL vbs_c=(vbs<R(0.0))?vbs:R(0.0);
    REAL sq=sqrtf(phis-vbs_c+R(1e-12));

    /* === BSIM4v5 Full Threshold Voltage (P1.2) ===
     * Vth = vth0 + body - SCE - DIBL + narrow-width + nlx
     *
     * SCE:  short-channel roll-off via dvt0,dvt1  (lowers Vth)
     * DIBL: drain-induced barrier lowering via dsub,eta0  (lowers Vth)
     * NW:   narrow-width increase via k3,w0  (raises Vth)
     * nlx:  pocket-implant body-effect correction
     */
    {
        /* Physical constants (cm-based for BSIM4 compatibility) */
        REAL eps_si =R(1.035e-12);  /* F/cm */
        REAL eps_ox =R(3.453e-13);  /* F/cm = 3.9*ε0 in F/cm */
        REAL q_el   =R(1.602e-19);
        REAL ni_si  =R(1.45e10);    /* cm^-3 */
        REAL NSUB   =pp->ndep>R(1e10)?pp->ndep:R(6.0e16);
        REAL NSD    =pp->nsd >R(1e15)?pp->nsd :R(1.0e20);
        REAL Vbi=vt*logf(NSUB*NSD/(ni_si*ni_si+R(1e-30)));
        if(Vbi<R(0.5))Vbi=R(0.5); if(Vbi>R(1.2))Vbi=R(1.2);

        /* Depletion width & characteristic lengths (cm) */
        REAL toxe_cm=toxe_safe*R(100.0);
        REAL xdep=sqrtf(R(2.0)*eps_si*(phis-vbs_c+R(0.01))
                         /(q_el*NSUB+R(1e-30)));
        if(xdep<R(1e-10))xdep=R(1e-10);
        REAL lt=sqrtf(eps_si*toxe_cm*xdep/(eps_ox+R(1e-30)));
        if(lt<R(1e-10))lt=R(1e-10);
        REAL lto=sqrtf(eps_si*toxe_cm
                        *sqrtf(R(2.0)*eps_si*phis/(q_el*NSUB+R(1e-30)))
                        /(eps_ox+R(1e-30)));
        if(lto<R(1e-10))lto=R(1e-10);
        REAL Lcm=leff*R(100.0);

        /* SCE: BSIM4v5 short-channel Vth roll-off
         * θ = DVT0 * exp(-DVT1 * Leff / lt)
         * ΔVth = -θ * (Vbi - phis)                      */
        REAL L_lt=Lcm/(lt+R(1e-30));
        REAL dVth_sce=pp->dvt0*expf(-pp->dvt1*L_lt)*(Vbi-phis);
        /* P5.5: dvt2 body-bias dependence of SCE */
        dVth_sce*=(R(1.0)+pp->dvt2*vbs_c);

        /* DIBL: θ_dibl = exp(-DSUB * Leff / lto)
         * ΔVth = -θ_dibl * eta0 * Vds  (etab≈0)       */
        REAL L_lto=Lcm/(lto+R(1e-30));
        REAL dVth_dibl=expf(-pp->dsub*L_lto)*pp->eta0*vds;

        /* Narrow-width: ΔVth = (K3+K3b*Vbs)*toxe/(Weff+W0)*phis */
        REAL k3b=pp->k2*R(0.5);
        REAL dVth_nw=(pp->k3+k3b*vbs_c)
                     *(toxe_safe/(weff+pp->w0+R(1e-30)))*phis;

        /* LPE / pocket implant: nlx correction inside body-effect sqrt */
        REAL nlx_r=pp->nlx/(leff+R(1e-30));
        REAL dVth_nlx=pp->k1*(sqrtf(R(1.0)+nlx_r)-R(1.0))*sqrt_phis;

        /* Full Vth */
        REAL vth_body=vth0_T+pp->k1*(sq-sqrt_phis)-pp->k2*vbs_c;
        REAL vth=vth_body-dVth_sce-dVth_dibl+dVth_nw+dVth_nlx;
        if(vth<R(0.02))vth=R(0.02);
        o.vth=vth;
    }
    REAL vth=o.vth;  /* lift out of Vth block for use in Vgsteff calc */

    REAL vgsteff;
    /* === BSIM4v5 Effective Vgs with subthreshold (P1.6) ===
     * n_eff = nfactor + cdsc*Vds + cdscd*Vds^2 + cdscb*Vbs
     * Vgst  = Vgs - Vth - voffcv                   (voffcv shifts threshold)
     * Vgsteff = smooth(Vgst, n_eff*vt) — dual-branch for weak→strong inversion
     *
     * Without minv, uses the standard BSIM4 subthreshold slope.
     * With minv>0, adds moderate-inversion linear region bridging.
     */
    {
        /* Effective ideality factor with drain/body coupling */
        REAL n_eff = pp->nfactor
                   + pp->cdsc  * vds
                   + pp->cdscd * vds * vds
                   + pp->cdscb * vbs_c;
        if(n_eff < R(1.0)) n_eff = R(1.0);
        if(n_eff > R(10.0)) n_eff = R(10.0);

        /* Gate overdrive shifted by voffcv (corrects subthreshold I-V) */
        REAL Vgst = vgs - vth - pp->voffcv;

        /* BSIM4v5 dual-branch Vgsteff:
         * Strong inversion (Vgst > 0): direct linear → Vgsteff ≈ Vgst
         * Subthreshold (Vgst < 0): exponential → Ids ∝ exp(Vgst/(n*vt))
         * Transition region: smooth via log(1+exp)                      */
        if(Vgst > R(0.1)) {
            /* Strong inversion — use Vgst directly (no smoothing needed) */
            vgsteff = Vgst;
        } else {
            REAL arg = Vgst / (n_eff * vt + R(1e-30));
            if(arg > R(80.0)) {
                vgsteff = Vgst;
            } else if(arg < R(-40.0)) {
                vgsteff = R(0.0);
            } else {
                /* Classical subthreshold → strong inversion smooth transition */
                vgsteff = n_eff * vt * logf(R(1.0) + expf(arg));
                if(vgsteff < R(0.0)) vgsteff = R(0.0);

                /* P5.5: minv>0 moderate-inversion dual-branch smoothing.
                 * When minv>0, blend classical single-exp with linear Vgst branch
                 * using a sigmoid weight for smooth transition. */
                if(pp->minv>R(0.0)){
                    REAL Vgst_hi=R(2.0)*n_eff*vt;  /* strong inversion reference */
                    REAL denom=R(0.5)*n_eff*vt+R(1e-30);
                    REAL minv_w=R(1.0)/(R(1.0)+expf(-(Vgst-Vgst_hi)/denom));
                    REAL vg_classic=vgsteff;
                    REAL vg_linear=fmaxf(Vgst,R(0.0));
                    vgsteff=minv_w*vg_classic+(R(1.0)-minv_w)*vg_linear;
                }
            }
        }
    }
    if(vgsteff<=R(0.0)){
        o.vgsteff=R(0.0); o.ids=R(1e-15); o.gm=R(1e-15); o.gds=R(1e-15); o.gmbs=R(1e-15);
        return o;
    }
    o.vgsteff=vgsteff;

    /* Mobility degradation (P1.5: mobMod=0/1/2 + Coulomb scattering) */
    REAL Eeff=(vgsteff+R(2.0)*vth+pp->vth0)/(R(6.0)*pp->toxe+R(1e-12));
    REAL ueff;
    /* P5.4: temperature-corrected ua/ub/uc */
    REAL Ua_total=ua_T+uc_T*vbs_c+R(1e-30);
    /* Base denominator: mobility degradation from vertical field */
    REAL denom=R(1.0)+Ua_total*Eeff+ub_T*Eeff*Eeff;
    if(pp->mobmod>R(1.5)){
        /* mobMod=2: same as mobMod=0 base but with EU-controlled Coulomb term */
        denom=R(1.0)+Ua_total*Eeff+ub_T*Eeff*Eeff;
    }else if(pp->mobmod>R(0.5)){
        /* mobMod=1: linear degradation U0/(1+Ua*Eeff) — simplified, no UB term */
        denom=R(1.0)+Ua_total*Eeff;
    }
    /* Coulomb scattering (ud): adds remote-charge impurity scattering term.
     * Active when ud>0 regardless of mobMod.  Typical: ud~0.5, eu~1.0 */
    if(pp->ud>R(0.0)){
        REAL Ec=Eeff/R(1e6);
        denom+=pp->ud*powf(Ec,pp->eu);
    }
    ueff=u0_T/denom;
    if(ueff<R(1e-4)) ueff=R(1e-4);
    o.ueff=ueff;

    /* Abulk */
    REAL Ab0=R(1.0)+pp->k1/(R(2.0)*sqrt_phis+R(1e-12));
    REAL Abulk=Ab0+pp->a0*leff/(leff+R(2.0)*sqrtf(R(1.4e-8)*pp->toxe+R(1e-24)));
    if(Abulk<R(1.0)) Abulk=R(1.0);
    o.Abulk=Abulk;

    /* EsatL */
    REAL EsatL=R(2.0)*pp->vsat/ueff*leff;
    o.EsatL=EsatL;

    /* Vdsat */
    REAL vdsat=vgsteff*EsatL/(Abulk*(vgsteff+EsatL+R(1e-12)));
    if(vdsat<R(1e-6)) vdsat=R(1e-6);
    o.vdsat=vdsat;

    /* Vdseff */
    REAL vdseff=smooth_vdseff(vds,vdsat);
    o.vdseff=vdseff;

    /* Beta */
    REAL beta0=ueff*coxe*weff/leff;
    o.beta=beta0;

    /* Ids */
    REAL dn=R(1.0)+vdseff/(EsatL+R(1e-12));
    REAL ids0=beta0*(vgsteff-Abulk*vdseff*R(0.5))*vdseff/dn;
    if(ids0<R(0.0)) ids0=R(0.0);
    /* ===== P1.4: 5-part Early voltage stack =====
     * Vasat  — velocity saturation / finite Rout at Vdsat
     * VACLM  — channel length modulation (pclm)
     * VADIBL — DIBL effect on Rout (pdiblc2)
     * VADITS — drain-induced threshold shift (pdiblc1)
     * VASCBE — substrate current body effect (pscbe1, pscbe2)
     * Combined via harmonic sum: 1/Vaeff = Σ 1/Vi */
    REAL vd_diff=vds-vdseff; if(vd_diff<R(0.0)) vd_diff=R(0.0);
    {
        /* Physical constants (local; originals from Vth scope are out of scope) */
        REAL ev_epsi=R(1.035e-12), ev_epox=R(3.453e-13);
        REAL ev_toxe_cm=toxe_safe*R(100.0);
        REAL ev_xj_cm=pp->xj*R(100.0);
        if(ev_xj_cm<R(1e-8)) ev_xj_cm=R(1.5e-7);
        REAL ev_Lcm=leff*R(100.0);
        /* xdep for lt estimate */
        REAL ev_q=R(1.602e-19);
        REAL ev_NSUB=pp->ndep>R(1e10)?pp->ndep:R(6.0e16);
        REAL ev_xdep=sqrtf(R(2.0)*ev_epsi*(phis-vbs_c+R(0.01))
                          /(ev_q*ev_NSUB+R(1e-30)));
        if(ev_xdep<R(1e-10)) ev_xdep=R(1e-10);

        /* litl: CLM characteristic length sqrt(epsi*Toxe*Xj/epox) */
        REAL litl=sqrtf(ev_epsi*ev_toxe_cm*ev_xj_cm/(ev_epox+R(1e-30)));
        if(litl<R(1e-10)) litl=R(1e-10);
        /* lt_est: thermal length sqrt(epsi*Toxe*Xdep/epox) */
        REAL lt_est=sqrtf(ev_epsi*ev_toxe_cm*ev_xdep/(ev_epox+R(1e-30)));
        if(lt_est<R(1e-10)) lt_est=R(1e-10);

        /* Vasat: EsatL*Leff + Vdsat + 2*Vgsteff/Abulk */
        REAL Vasat=EsatL+vdsat+R(2.0)*vgsteff/(Abulk+R(1e-30));
        /* P5.5: pvag gate-bias dependent Early enhancement */
        if(pp->pvag>R(0.0)){
            REAL EsatLeff=EsatL*leff;
            Vasat+=pp->pvag*vgsteff*EsatLeff/(vgsteff+EsatLeff+R(1e-30));
        }
        if(Vasat<R(1e-6)) Vasat=R(1e-6);

        /* VACLM: channel length modulation */
        REAL VACLM=R(1e12);
        if(pp->pclm>R(1e-20)){
            REAL Fp=Abulk*EsatL*leff+vgsteff;
            VACLM=Fp*litl/(pp->pclm*Abulk*EsatL*leff+R(1e-30));
            if(VACLM<R(1e-6)) VACLM=R(1e-6);
        }

        /* VADIBL: DIBL effect on Rout */
        REAL VADIBL=R(1e12);
        if(pp->pdiblc2>R(1e-20)){
            REAL L2lt=ev_Lcm/(R(2.0)*lt_est+R(1e-30));
            REAL theta_rout=pp->pdiblc2
                *(expf(-pp->dsub*L2lt)+R(2.0)*expf(-pp->dsub*L2lt*R(2.0)));
            if(theta_rout<R(1e-20)) theta_rout=R(1e-20);
            REAL Vgst2Vt=vgsteff+R(2.0)*vt;
            REAL F_dibl=R(1.0)
                -Abulk*vdsat/(Abulk*vdsat+Vgst2Vt+R(1e-30));
            if(F_dibl<R(1e-6)) F_dibl=R(1e-6);
            VADIBL=Vgst2Vt/theta_rout*F_dibl;
            if(VADIBL<R(1e-6)) VADIBL=R(1e-6);
        }

        /* VADITS: drain-induced threshold shift (absorbs pdiblc1) */
        REAL VADITS=R(1e12);
        if(pp->pdiblc1>R(1e-20)){
            VADITS=R(1.0)/(pp->pdiblc1+R(1e-30));
            if(VADITS<R(1e-6)) VADITS=R(1e-6);
        }

        /* VASCBE: substrate current induced body effect */
        REAL VASCBE=R(1e12);
        if(pp->pscbe1>R(0.0)&&pp->pscbe2>R(1e-30)&&vd_diff>R(1e-6)){
            REAL exp_arg=pp->pscbe1*litl/(vd_diff+R(1e-30));
            if(exp_arg<R(80.0)){
                VASCBE=leff*expf(exp_arg)/(pp->pscbe2+R(1e-30));
                if(VASCBE<R(1e-6)) VASCBE=R(1e-6);
            }
        }

        /* Harmonic combination: 1/Vaeff = sum(1/Vi) */
        REAL va_inv=R(1.0)/(Vasat+R(1e-30))
                  +R(1.0)/(VACLM+R(1e-30))
                  +R(1.0)/(VADIBL+R(1e-30))
                  +R(1.0)/(VADITS+R(1e-30))
                  +R(1.0)/(VASCBE+R(1e-30));
        REAL Vaeff=R(1.0)/(va_inv+R(1e-30));
        if(Vaeff<R(1e-3)) Vaeff=R(1e-3);

        /* Ids with unified Early voltage */
        o.ids=ids0*(R(1.0)+vd_diff/(Vaeff+R(1e-30)));
        if(o.ids<R(0.0)) o.ids=R(0.0);

        /* Analytical gm/gds/gmbs */
        if(vds<vdsat){
            REAL dnl=R(1.0)+vds/EsatL;
            o.gm=beta0*vds/dnl;
            o.gds=beta0*(vgsteff-Abulk*vds)/(dnl*dnl+R(1e-30));
        }else{
            o.gm=beta0*vdsat/(R(1.0)+vdsat/EsatL)
                 *(R(1.0)+vd_diff/(Vaeff+R(1e-30)));
            o.gds=o.ids/(Vaeff+R(1e-30));
        }
    }
    if(vgsteff<R(0.05)){ o.gm=o.ids/(pp->nfactor*vt+R(1e-15)); }
    if(o.gm<R(1e-15)) o.gm=R(1e-15);
    if(o.gds<R(1e-15)) o.gds=R(1e-15);
    REAL dvth_dvb=R(0.0);
    if(vbs_c<phis-R(0.01)) dvth_dvb=-pp->k1/(R(2.0)*sq+R(1e-12));
    o.gmbs=-o.gm*dvth_dvb;
    if(fabsf(o.gmbs)<R(1e-15)) o.gmbs=R(0.0);

    /* ===== Rds: source/drain series resistance (P1.3) =====
     * Bias-dependent Rds reduces intrinsic Vgs/Vds when Ids flows.
     * First-order correction: source degeneration for gm/gmbs,
     * drain+source feedback for Ids/gds.  Disabled when rdsw==0. */
    if(pp->rdsw>R(0.0)||pp->rsw>R(0.0)||pp->rdw>R(0.0)){
        REAL weff_clamp=weff>R(1e-9)?weff:R(1e-9);
        REAL vgst4rds=vgsteff>R(0.0)?vgsteff:R(0.0);
        /* Base rdsw per-side with gate-bias dependence */
        REAL rs_rdsw=pp->rdsw/(weff_clamp*(R(1.0)+pp->prwg*vgst4rds)+R(1e-30));
        /* P5.5: rsw/rdw — independent source/drain resistance.
         * Use max of rdsw-based and rsw/rdw per terminal. */
        REAL rs_source=fmaxf(rs_rdsw, pp->rsw/(weff_clamp+R(1e-30)));
        REAL rd_drain =fmaxf(rs_rdsw, pp->rdw/(weff_clamp+R(1e-30)));
        REAL rout=rs_source+rd_drain;
        /* Source degeneration: gm and gmbs reduced */
        REAL src_degen=R(1.0)+o.gm*rs_source;
        o.gm/=src_degen;
        o.gmbs/=src_degen;
        /* Drain feedback: gds reduced */
        REAL drain_fb=R(1.0)+o.gds*rout;
        o.gds/=drain_fb;
        /* Ids correction: Vds_int = Vds - Ids*Rout */
        REAL ids_corr=R(1.0)+o.ids*rout/(vdseff+R(1e-15));
        o.ids/=ids_corr;
        if(o.ids<R(0.0)) o.ids=R(0.0);
    }

    /* ===== P4.2 / P2.6: BSIM4 intrinsic capacitances =====
     * capmod==0: Meyer piecewise model (Cgs/Cgd/Cgb 三段式)
     * capmod==2: simplified charge-conserving model
     *   Qg = Cox*(Vgsteff - 0.5*Abulk*Vdseff)
     *   Cgs/d/gb via finite difference, cgsl/cgdl linear terms, noff tanh */
    {
        REAL Cox=coxe*weff*leff;
        if(Cox<R(0.0)) Cox=R(0.0);
        if(pp->capmod==R(0.0)){
            /* === Meyer model (capmod=0) === */
            if(vgsteff<=R(0.0)){
                o.cgs=R(0.0); o.cgd=R(0.0); o.cgb=Cox;
            }else if(vds<vdsat){
                o.cgs=Cox*R(0.5); o.cgd=Cox*R(0.5); o.cgb=R(0.0);
            }else{
                o.cgs=Cox*R(0.6666667); o.cgd=R(0.0); o.cgb=R(0.0);
            }
        }else{
            /* === capmod==2: simplified charge-conserving model === */
            REAL Ab=o.Abulk; if(Ab<R(0.01)) Ab=R(0.01);
            REAL Vde=o.vdseff;
            REAL delta=R(1e-6);
            REAL vt_c=R(8.617333e-5)*temp; if(vt_c<R(1e-6)) vt_c=R(0.02585);
            REAL n_eff=pp->nfactor+pp->cdsc*vds+pp->cdscd*vds*vds+pp->cdscb*vbs_c;
            if(n_eff<R(1.0)) n_eff=R(1.0); if(n_eff>R(10.0)) n_eff=R(10.0);
            /* vgsteff helper for perturbed Vgs (keeping Vth/Abulk/Vdseff fixed) */
            #define VGSTP(vgs_p) ( \
             ((vgs_p-o.vth-pp->voffcv)>R(0.1))?(vgs_p-o.vth-pp->voffcv): \
             ((vgs_p-o.vth-pp->voffcv)<R(-0.1))?n_eff*vt_c*expf((vgs_p-o.vth-pp->voffcv)/(n_eff*vt_c+R(1e-15))): \
             n_eff*vt_c*logf(R(1.0)+expf((vgs_p-o.vth-pp->voffcv)/(n_eff*vt_c+R(1e-15)))) )
            /* Cgs = dQg/dVgs */
            {REAL vp=VGSTP(vgs+delta),vm=VGSTP(vgs-delta);
             o.cgs=Cox*((vp-R(0.5)*Ab*Vde)-(vm-R(0.5)*Ab*Vde))/(R(2.0)*delta);
             if(pp->cgsl>R(0.0)) o.cgs+=pp->cgsl*weff*(vgs-o.vth);}
            /* Cgd = dQg/dVds via Vdseff perturbation */
            {REAL dp=vds+delta,dm=vds-delta;
             REAL vp=smooth_vdseff(dp,vdsat),vm=smooth_vdseff(dm,vdsat);
             o.cgd=Cox*R(0.5)*Ab*((vgsteff-R(0.5)*Ab*vm)-(vgsteff-R(0.5)*Ab*vp))/(R(2.0)*delta);
             REAL vgd=vgs-vds;
             if(pp->cgdl>R(0.0)) o.cgd+=pp->cgdl*weff*(vgd-o.vth);}
            /* Cgb = dQg/dVbs via Vth + Abulk perturbation */
            {REAL vbp=vbs+delta,vbm=vbs-delta;
             REAL vcp=(vbp<R(0.0))?vbp:R(0.0),vcm=(vbm<R(0.0))?vbm:R(0.0);
             REAL sqp=sqrtf(phis-vcp+R(1e-12)),sqm=sqrtf(phis-vcm+R(1e-12));
             REAL vthp=pp->vth0+pp->k1*(sqp-sqrt_phis)-pp->k2*vcp;
             REAL vthm=pp->vth0+pp->k1*(sqm-sqrt_phis)-pp->k2*vcm;
             REAL Vgstp=vgs-vthp-pp->voffcv,Vgstm=vgs-vthm-pp->voffcv;
             REAL vgp,vgm;
             if(Vgstp>R(0.1)) vgp=Vgstp; else if(Vgstp<R(-0.1)) vgp=n_eff*vt_c*expf(Vgstp/(n_eff*vt_c+R(1e-15))); else vgp=n_eff*vt_c*logf(R(1.0)+expf(Vgstp/(n_eff*vt_c+R(1e-15))));
             if(Vgstm>R(0.1)) vgm=Vgstm; else if(Vgstm<R(-0.1)) vgm=n_eff*vt_c*expf(Vgstm/(n_eff*vt_c+R(1e-15))); else vgm=n_eff*vt_c*logf(R(1.0)+expf(Vgstm/(n_eff*vt_c+R(1e-15))));
             REAL Abp=Ab*(sqp+sqrt_phis)/(sqm+sqrt_phis+R(1e-12))*R(0.5)+Ab*R(0.5);
             REAL Abm=Ab*(sqm+sqrt_phis)/(sqp+sqrt_phis+R(1e-12))*R(0.5)+Ab*R(0.5);
             REAL Qp=Cox*(vgp-R(0.5)*Abp*Vde),Qm=Cox*(vgm-R(0.5)*Abm*Vde);
             o.cgb=(Qp-Qm)/(R(2.0)*delta);}
            /* noff>0 subthreshold: tanh smoothing transition */
            if(pp->noff>R(0.0)&&vgsteff<=R(0.0)){
             REAL sm=R(0.5)*(tanhf((vgsteff+R(0.05))/R(0.02))+R(1.0));
             o.cgs=o.cgs*sm; o.cgd=o.cgd*sm;
             o.cgb=Cox*(R(1.0)-sm)+o.cgb*sm;}
            #undef VGSTP
        }
        /* Overlap/fringing capacitances (both models) */
        o.cgs+=pp->cgso*weff; o.cgd+=pp->cgdo*weff; o.cgb+=pp->cgbo*leff;
        /* cf: additional fixed fringe cap */
        o.cgs+=pp->cf*weff*R(0.5); o.cgd+=pp->cf*weff*R(0.5);
        if(o.cgs<R(0.0)) o.cgs=R(0.0);
        if(o.cgd<R(0.0)) o.cgd=R(0.0);
        if(o.cgb<R(0.0)) o.cgb=R(0.0);
    }

    /* ===== P2.3: BSIM4 body-source/drain junction diode currents =====
     * Source side: Ibs = Is_src*(exp(Vbs/(njs*Vt))-1), gbs = dIbs/dVbs
     * Drain side:  Ibd = Is_drn*(exp(Vbd/(njd*Vt))-1), gbd = dIbd/dVbd
     * Vbd = Vbs-Vds (reuse existing terminal voltages).
     * Breakdown: if(|Vbx|>bvx) multiply by exp((|Vbx|-bvx)/xjbvx).
     * Clamp exp arg to [-80,80] for FP32 safety.
     * Default jss=jsd=0 → Is_src/Is_drn < 1e-30 → skip → zero regression. */
    {
        REAL Vt=temp*R(8.617333262145e-5);  /* kT/q */
        if(Vt<R(1e-6)) Vt=R(0.02585);
        REAL vbd=vbs-vds;  /* body-drain voltage */

        /* --- Source junction --- */
        REAL Is_src=pp->jss*weff*leff + pp->jsws*(weff+leff) + pp->jswgs*weff;
        if(Is_src>R(1e-30)){
            REAL arg_s=vbs/(pp->njs*Vt+R(1e-30));
            if(arg_s>R(80.0)) arg_s=R(80.0);
            if(arg_s<R(-80.0)) arg_s=R(-80.0);
            REAL exp_s=expf(arg_s);
            o.ibs=Is_src*(exp_s-R(1.0));
            o.gbs=Is_src*exp_s/(pp->njs*Vt+R(1e-30));
            /* Breakdown: if |Vbs| > bvs, multiply by exp((|Vbs|-bvs)/xjbvs) */
            if(pp->bvs>R(1e-6)){
                REAL abs_vbs=fabsf(vbs);
                if(abs_vbs>pp->bvs){
                    REAL brk_arg=(abs_vbs-pp->bvs)/(pp->xjbvs+R(1e-30));
                    if(brk_arg>R(80.0)) brk_arg=R(80.0);
                    if(brk_arg<R(-80.0)) brk_arg=R(-80.0);
                    REAL brk_mul=expf(brk_arg);
                    REAL sign_vbs=(vbs>R(0.0))?R(1.0):((vbs<R(0.0))?R(-1.0):R(0.0));
                    o.gbs=o.gbs*brk_mul + o.ibs*sign_vbs/(pp->xjbvs+R(1e-30));
                    o.ibs*=brk_mul;
                }
            }
        }else{ o.ibs=R(0.0); o.gbs=R(0.0); }

        /* --- Drain junction --- */
        REAL Is_drn=pp->jsd*weff*leff + pp->jswd*(weff+leff) + pp->jswgd*weff;
        if(Is_drn>R(1e-30)){
            REAL arg_d=vbd/(pp->njd*Vt+R(1e-30));
            if(arg_d>R(80.0)) arg_d=R(80.0);
            if(arg_d<R(-80.0)) arg_d=R(-80.0);
            REAL exp_d=expf(arg_d);
            o.ibd=Is_drn*(exp_d-R(1.0));
            o.gbd=Is_drn*exp_d/(pp->njd*Vt+R(1e-30));
            /* Breakdown: if |Vbd| > bvd, multiply by exp((|Vbd|-bvd)/xjbvd) */
            if(pp->bvd>R(1e-6)){
                REAL abs_vbd=fabsf(vbd);
                if(abs_vbd>pp->bvd){
                    REAL brk_arg=(abs_vbd-pp->bvd)/(pp->xjbvd+R(1e-30));
                    if(brk_arg>R(80.0)) brk_arg=R(80.0);
                    if(brk_arg<R(-80.0)) brk_arg=R(-80.0);
                    REAL brk_mul=expf(brk_arg);
                    REAL sign_vbd=(vbd>R(0.0))?R(1.0):((vbd<R(0.0))?R(-1.0):R(0.0));
                    o.gbd=o.gbd*brk_mul + o.ibd*sign_vbd/(pp->xjbvd+R(1e-30));
                    o.ibd*=brk_mul;
                }
            }
        }else{ o.ibd=R(0.0); o.gbd=R(0.0); }

        /* NaN/small-value guard: clamp near-zero */
        if(fabsf(o.ibs)<R(1e-18)) o.ibs=R(0.0);
        if(fabsf(o.ibd)<R(1e-18)) o.ibd=R(0.0);
        if(fabsf(o.gbs)<R(1e-18)) o.gbs=R(0.0);
        if(fabsf(o.gbd)<R(1e-18)) o.gbd=R(0.0);
    }

    /* === P2.4: Body resistance network ===
     * Simplified single-resistor model: rbody = rbdb||rbsb||rbpb
     * PTM LP: rbdb=15, rbsb=15, rbpb=5 → rbody ≈ 3.75Ω
     * Provides finite-impedance path from body to internal nodes,
     * improving convergence for NMOS inverter body tied to GND/VDD. */
    if(pp->rbodymod > R(0.5)) {
        o.rbody = R(1.0) / (R(1.0)/(pp->rbdb + R(1e-30))
                          + R(1.0)/(pp->rbsb + R(1e-30))
                          + R(1.0)/(pp->rbpb + R(1e-30)));
    } else {
        o.rbody = R(0.0);
    }

    /* NaN firewall: divergent Newton step → return safe off-state */
    if(IS_NAN(o.ids)||IS_NAN(o.gm)||IS_NAN(o.gds)||IS_NAN(o.gmbs)
        ||IS_NAN(o.ibs)||IS_NAN(o.ibd)||IS_NAN(o.gbs)||IS_NAN(o.gbd)){
        o.ids=R(1e-15); o.gm=R(1e-15); o.gds=R(1e-15); o.gmbs=R(0.0);
        o.vgsteff=R(0.0);
        o.ibs=R(0.0); o.ibd=R(0.0); o.gbs=R(0.0); o.gbd=R(0.0);
        o.rbody=R(0.0);
    }

    return o;
}

/* P5.1: emit device parameter table after DC solve.
 * Iterates all MOSFETs, evaluates BSIM4 at converged voltages,
 * stores key params keyed as "M1.gm", "M2.ids", etc. */
static void emit_device_param_table(Circuit *c, REAL *v, BSIM4Param *const *pp_arr) {
    c->ndev_param=0;
    for(int j=0;j<c->nm && c->ndev_param+8 <= MAX_DEVICE_PARAMS;j++){
        Mosfet *m=&c->mos[j];
        const BSIM4Param *pp=pp_arr[j];
        REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
        REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
        if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
        BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
        /* Store 8 params per device: ids, gm, gds, gmbs, vth, vdsat, vgsteff, beta */
        const char *keys[]={"ids","gm","gds","gmbs","vth","vdsat","vgsteff","beta"};
        REAL vals[]={o.ids,o.gm,o.gds,o.gmbs,o.vth,o.vdsat,o.vgsteff,o.beta};
        for(int k=0;k<8;k++){
            snprintf(c->dev_param_names[c->ndev_param],63,"%s.%s",m->name,keys[k]);
            c->dev_param_vals[c->ndev_param]=vals[k];
            c->ndev_param++;
        }
    }
}

/* P5.1: Forward declarations for functions defined later */
static REAL eval_expr(const char **p, Circuit *c, REAL *v, REAL *iv,
                      BSIM4Param *const *pp_arr, REAL t);
static REAL parse_eng(const char *s);
static const char *real_to_str(REAL v, char fmt, int prec);  /* P0.4: zero cvtss2sd */

/* P5.1: Re-evaluate all let expressions with actual voltages/device params.
 * Called after dc_solve and emit_device_param_table. */
static void re_eval_lets(Circuit *c, REAL *v, REAL *iv,
                         BSIM4Param *const *pp_arr, REAL t) {
    for(int i=0;i<c->nlet;i++){
        const char *ep=c->let_exprs[i];
        c->let_vals[i]=eval_expr(&ep,c,v,iv,pp_arr,t);
    }
}

/* P5.1: Expression evaluator — recursive descent, flat structure (no nested fns).
 * Terminals: number (parse_eng), v(node), i(vsrc), @device[param],
 *            variable (let_names then param_names), time.
 * Operators: + - * / ^ (unary -).  Returns 0.0f on parse failure. */

/* ---- helper: skip whitespace ---- */
#define SKIP_WS(p) while(*(p)==' '||*(p)=='\t') (p)++

/* ---- eval_primary: terminals + '(' expr ')' + unary +/- ---- */
static REAL eval_primary(const char **pp, Circuit *c, REAL *v, REAL *iv,
                         BSIM4Param *const *pp_arr, REAL t) {
    const char *p=*pp; SKIP_WS(p);
    /* parentheses */
    if(*p=='('){ p++; REAL val=eval_expr(&p,c,v,iv,pp_arr,t); SKIP_WS(p);
                 if(*p==')') p++; *pp=p; return val; }
    if(*p=='-'){ p++; return -eval_primary(&p,c,v,iv,pp_arr,t); }
    if(*p=='+'){ p++; return eval_primary(&p,c,v,iv,pp_arr,t); }
    /* v(node) */
    if((*p=='v'||*p=='V')&&(p[1]=='('||p[1]==' ')){
        while(*p&&*p!='(') p++; if(*p=='(') p++;
        char nbuf[32]; int ni=0;
        while(*p&&*p!=')'&&ni<31) nbuf[ni++]=*p++;
        nbuf[ni]=0; if(*p==')') p++;
        for(int j=0;j<c->nn;j++) if(!strcmp(c->nmap[j],nbuf)){*pp=p;return v[j];}
        *pp=p; return R(0.0);
    }
    /* i(vsrc) */
    if((*p=='i'||*p=='I')&&(p[1]=='('||p[1]==' ')){
        while(*p&&*p!='(') p++; if(*p=='(') p++;
        char nbuf[32]; int ni=0;
        while(*p&&*p!=')'&&ni<31) nbuf[ni++]=*p++;
        nbuf[ni]=0; if(*p==')') p++;
        for(int j=0;j<c->nv;j++) if(!strcmp(c->vsrc[j].name,nbuf)){*pp=p;return iv[j];}
        for(int j=0;j<c->ni;j++) if(!strcmp(c->isrc[j].name,nbuf)){*pp=p;return c->isrc[j].dc;}
        *pp=p; return R(0.0);
    }
    /* @device[param] */
    if(*p=='@'){ p++;
        char dname[32]; int di=0;
        while(*p&&*p!='['&&di<31) dname[di++]=*p++;
        dname[di]=0; if(*p=='[') p++;
        char pname[32]; int pi=0;
        while(*p&&*p!=']'&&pi<31) pname[pi++]=*p++;
        pname[pi]=0; if(*p==']') p++;
        char full[64]; snprintf(full,63,"%s.%s",dname,pname);
        for(int j=0;j<c->ndev_param;j++)
            if(!strcmp(c->dev_param_names[j],full)){*pp=p;return c->dev_param_vals[j];}
        *pp=p; return R(0.0);
    }
    /* time keyword */
    if(!strncmp(p,"time",4)&&(!p[4]||p[4]==' '||p[4]==')'||p[4]=='+'||p[4]=='-'||p[4]=='*'||p[4]=='/'||p[4]=='^'))
        {*pp=p+4; return t;}
    /* number */
    if(isdigit(*p)||*p=='.'){
        REAL val=parse_eng(p); int has_exp=0;
        while(1){ char ch=*p;
            if(isdigit(ch)||ch=='.') p++;
            else if((ch=='e'||ch=='E')&&!has_exp){p++;has_exp=1;if(*p=='+'||*p=='-')p++;}
            else break;
        }
        while(*p=='k'||*p=='K'||*p=='m'||*p=='u'||*p=='n'||*p=='p'||*p=='f'||*p=='M'||*p=='E'||*p=='G'){
            if(!strncmp(p,"meg",3)||!strncmp(p,"MEG",3)){p+=3;break;}
            if(!strncmp(p,"mil",3)){p+=3;break;} p++;
        }
        *pp=p; return val;
    }
    /* identifier */
    if(isalpha(*p)||*p=='_'){
        char ident[32]; int ii=0;
        while((isalnum(*p)||*p=='_'||*p=='!')&&ii<31) ident[ii++]=*p++;
        ident[ii]=0;
        for(int j=0;j<c->nlet;j++) if(!strcmp(c->let_names[j],ident)){*pp=p;return c->let_vals[j];}
        for(int j=0;j<c->nparam;j++) if(!strcmp(c->param_names[j],ident)){*pp=p;return c->param_vals[j];}
        *pp=p; return R(0.0);
    }
    if(*p) p++; *pp=p; return R(0.0);
}

/* ---- eval_power: primary ('^' power)? ---- */
static REAL eval_power(const char **pp, Circuit *c, REAL *v, REAL *iv,
                       BSIM4Param *const *pp_arr, REAL t) {
    REAL val=eval_primary(pp,c,v,iv,pp_arr,t); const char *p=*pp; SKIP_WS(p);
    if(*p=='^'){ p++; REAL expo=eval_power(&p,c,v,iv,pp_arr,t); *pp=p; return powf(val,expo); }
    *pp=p; return val;
}

/* ---- eval_term: power (('*'|'/') power)* ---- */
static REAL eval_term(const char **pp, Circuit *c, REAL *v, REAL *iv,
                      BSIM4Param *const *pp_arr, REAL t) {
    REAL val=eval_power(pp,c,v,iv,pp_arr,t); const char *p=*pp; SKIP_WS(p);
    while(*p=='*'||*p=='/'){
        char op=*p++; REAL rhs=eval_power(&p,c,v,iv,pp_arr,t); SKIP_WS(p);
        if(op=='*') val*=rhs; else {if(fabsf(rhs)>R(1e-30))val/=rhs;else val=R(0.0);}
    }
    *pp=p; return val;
}

/* ---- eval_expr: term (('+'|'-') term)* ---- */
static REAL eval_expr(const char **pp, Circuit *c, REAL *v, REAL *iv,
                      BSIM4Param *const *pp_arr, REAL t) {
    REAL val=eval_term(pp,c,v,iv,pp_arr,t); const char *p=*pp; SKIP_WS(p);
    while(*p=='+'||*p=='-'){
        char op=*p++; REAL rhs=eval_term(&p,c,v,iv,pp_arr,t); SKIP_WS(p);
        val=(op=='+')?val+rhs:val-rhs;
    }
    *pp=p; return val;
}
#undef SKIP_WS

/* ===== SPICE Netlist Parser ===== */
static Model* find_model(Circuit *c, const char *name) {
    for(int i=0;i<c->nmodel;i++) if(!strcmp(c->models[i].name,name)) return &c->models[i];
    return NULL;
}
static int find_or_add_node(Circuit *c, const char *name) {
    if(!strcmp(name,"0")||!strcmp(name,"gnd")||!strcmp(name,"GND")) return 0;
    for(int i=0;i<c->nn;i++) if(!strcmp(c->nmap[i],name)) return i;
    if(c->nn>=MAX_NODES) return -1;
    strncpy(c->nmap[c->nn],name,31); c->nmap[c->nn][31]=0;
    return c->nn++;
}
static REAL parse_eng(const char *s) {
    while(*s==' '||*s=='\t') s++;
    char buf[64]; int j=0;
    for(const char *p=s;*p&&j<62;p++) if(*p!=' ') buf[j++]=*p;
    buf[j]=0; if(j==0) return R(0.0);
    char *endptr=NULL;
    REAL val=strtof(buf,&endptr);
    if(endptr==buf) return R(0.0);
    const char *sf=endptr;
    if(!strcmp(sf,"k")||!strcmp(sf,"K")) val*=R(1e3);
    else if(!strcmp(sf,"meg")||!strcmp(sf,"MEG")) val*=R(1e6);
    else if(!strcmp(sf,"m")) val*=R(1e-3);
    else if(!strcmp(sf,"u")) val*=R(1e-6);
    else if(!strcmp(sf,"n")) val*=R(1e-9);
    else if(!strcmp(sf,"p")) val*=R(1e-12);
    else if(!strcmp(sf,"f")) val*=R(1e-15);
    else if(!strcmp(sf,"mil")) val*=R(2.54e-5);
    return val;
}
static REAL model_get(const Model *m, const char *key, REAL def) {
    for(int i=0;i<m->np;i++) if(!strcmp(m->p[i].key,key)) return m->p[i].val;
    return def;
}
static void bsim4_from_model(BSIM4Param *pp, const Model *m) {
    *pp=bsim4_default();
    /* --- Core (15) --- */
    pp->vth0=model_get(m,"vth0",pp->vth0); pp->k1=model_get(m,"k1",pp->k1);
    pp->k2=model_get(m,"k2",pp->k2); pp->nfactor=model_get(m,"nfactor",pp->nfactor);
    pp->eta0=model_get(m,"eta0",pp->eta0); pp->u0=model_get(m,"u0",pp->u0);
    pp->ua=model_get(m,"ua",pp->ua); pp->ub=model_get(m,"ub",pp->ub);
    pp->uc=model_get(m,"uc",pp->uc); pp->vsat=model_get(m,"vsat",pp->vsat);
    pp->toxe=model_get(m,"toxe",pp->toxe);
    pp->mobmod=model_get(m,"mobmod",pp->mobmod);
    pp->ud=model_get(m,"ud",pp->ud); pp->eu=model_get(m,"eu",pp->eu);
    pp->pclm=model_get(m,"pclm",pp->pclm);
    /* --- Short-channel Vth (12) --- */
    pp->dvt0=model_get(m,"dvt0",pp->dvt0); pp->dvt1=model_get(m,"dvt1",pp->dvt1);
    pp->dvt2=model_get(m,"dvt2",pp->dvt2);
    pp->dvt0w=model_get(m,"dvt0w",pp->dvt0w); pp->dvt1w=model_get(m,"dvt1w",pp->dvt1w);
    pp->dvt2w=model_get(m,"dvt2w",pp->dvt2w);
    pp->dsub=model_get(m,"dsub",pp->dsub); pp->k3=model_get(m,"k3",pp->k3);
    pp->k3b=model_get(m,"k3b",pp->k3b); pp->w0=model_get(m,"w0",pp->w0);
    pp->nlx=model_get(m,"nlx",pp->nlx); pp->etab=model_get(m,"etab",pp->etab);
    /* --- Rds (7) --- */
    pp->rdsw=model_get(m,"rdsw",pp->rdsw); pp->rsw=model_get(m,"rsw",pp->rsw);
    pp->rdw=model_get(m,"rdw",pp->rdw); pp->prwg=model_get(m,"prwg",pp->prwg);
    pp->prwb=model_get(m,"prwb",pp->prwb); pp->prt=model_get(m,"prt",pp->prt);
    pp->wr=model_get(m,"wr",pp->wr);
    /* --- Early voltage stack (7) --- */
    pp->pvag=model_get(m,"pvag",pp->pvag);
    pp->pdiblc1=model_get(m,"pdiblc1",pp->pdiblc1);
    pp->pdiblc2=model_get(m,"pdiblc2",pp->pdiblc2);
    pp->pdiblcb=model_get(m,"pdiblcb",pp->pdiblcb);
    pp->drout=model_get(m,"drout",pp->drout);
    pp->pscbe1=model_get(m,"pscbe1",pp->pscbe1);
    pp->pscbe2=model_get(m,"pscbe2",pp->pscbe2);
    /* --- Subthreshold (7) --- */
    pp->voff=model_get(m,"voff",pp->voff);
    pp->voffcv=model_get(m,"voffcv",pp->voffcv);
    pp->minv=model_get(m,"minv",pp->minv);
    pp->cdsc=model_get(m,"cdsc",pp->cdsc); pp->cdscd=model_get(m,"cdscd",pp->cdscd);
    pp->cdscb=model_get(m,"cdscb",pp->cdscb); pp->cit=model_get(m,"cit",pp->cit);
    /* --- Saturation / Vdsat (5) --- */
    pp->a0=model_get(m,"a0",pp->a0); pp->a1=model_get(m,"a1",pp->a1);
    pp->a2=model_get(m,"a2",pp->a2); pp->ags=model_get(m,"ags",pp->ags);
    pp->delta=model_get(m,"delta",pp->delta);
    /* --- Temperature (7) --- */
    pp->kt1=model_get(m,"kt1",pp->kt1); pp->kt1l=model_get(m,"kt1l",pp->kt1l);
    pp->kt2=model_get(m,"kt2",pp->kt2);
    pp->ute=model_get(m,"ute",pp->ute); pp->ua1=model_get(m,"ua1",pp->ua1);
    pp->ub1=model_get(m,"ub1",pp->ub1); pp->uc1=model_get(m,"uc1",pp->uc1);
    /* --- Geometry offsets (4) --- */
    pp->wint=model_get(m,"wint",pp->wint); pp->lint=model_get(m,"lint",pp->lint);
    pp->dwg=model_get(m,"dwg",pp->dwg); pp->dwb=model_get(m,"dwb",pp->dwb);
    /* --- Capacitance / junction (4) --- */
    pp->cgso=model_get(m,"cgso",pp->cgso); pp->cgdo=model_get(m,"cgdo",pp->cgdo);
    pp->cgbo=model_get(m,"cgbo",pp->cgbo); pp->cj=model_get(m,"cj",pp->cj);
    /* --- Intrinsic capacitance model (9) --- */
    pp->capmod =model_get(m,"capmod", pp->capmod);
    pp->acde   =model_get(m,"acde",   pp->acde);
    pp->moin   =model_get(m,"moin",   pp->moin);
    pp->noff   =model_get(m,"noff",   pp->noff);
    pp->cgsl   =model_get(m,"cgsl",   pp->cgsl);
    pp->cgdl   =model_get(m,"cgdl",   pp->cgdl);
    pp->ckappas=model_get(m,"ckappas",pp->ckappas);
    pp->ckappad=model_get(m,"ckappad",pp->ckappad);
    pp->cf     =model_get(m,"cf",     pp->cf);
    /* --- Junction diode (13) --- */
    pp->jss  =model_get(m,"jss",  pp->jss);   pp->jsws =model_get(m,"jsws", pp->jsws);
    pp->jswgs=model_get(m,"jswgs",pp->jswgs); pp->njs  =model_get(m,"njs",  pp->njs);
    pp->bvs  =model_get(m,"bvs",  pp->bvs);   pp->xjbvs=model_get(m,"xjbvs",pp->xjbvs);
    pp->jsd  =model_get(m,"jsd",  pp->jsd);   pp->jswd =model_get(m,"jswd", pp->jswd);
    pp->jswgd=model_get(m,"jswgd",pp->jswgd); pp->njd  =model_get(m,"njd",  pp->njd);
    pp->bvd  =model_get(m,"bvd",  pp->bvd);   pp->xjbvd=model_get(m,"xjbvd",pp->xjbvd);
    pp->mj   =model_get(m,"mj",   pp->mj);
    /* --- Noise (4) --- */
    pp->noia=model_get(m,"noia",pp->noia); pp->noib=model_get(m,"noib",pp->noib);
    pp->fnoimod=model_get(m,"fnoimod",pp->fnoimod);
    pp->tnoimod=model_get(m,"tnoimod",pp->tnoimod);
    /* --- Physical / process (4) --- */
    pp->xj=model_get(m,"xj",pp->xj); pp->ndep=model_get(m,"ndep",pp->ndep);
    pp->nsd=model_get(m,"nsd",pp->nsd); pp->at=model_get(m,"at",pp->at);
    /* --- Gate resistance (1) --- */
    pp->rgatemod=model_get(m,"rgatemod",pp->rgatemod);
    /* --- Body resistance network (6) --- */
    pp->rbodymod=model_get(m,"rbodymod",pp->rbodymod);
    pp->rbdb    =model_get(m,"rbdb",    pp->rbdb);
    pp->rbsb    =model_get(m,"rbsb",    pp->rbsb);
    pp->rbpb    =model_get(m,"rbpb",    pp->rbpb);
    pp->rbps    =model_get(m,"rbps",    pp->rbps);
    pp->rbpd    =model_get(m,"rbpd",    pp->rbpd);
}
static void parse_model_line(Circuit *c, const char *line) {
    Model m; memset(&m,0,sizeof(m)); char rest[MAX_LINE];
    if(sscanf(line,".model %31s %15s %[^\n]",m.name,m.type,rest)<2) return;
    for(char *p=m.type;*p;p++) *p=(char)tolower((unsigned char)*p);
    char *tok=rest;
    while(*tok){
        while(*tok==' '||*tok=='\t') tok++;
        char *eq=strchr(tok,'='); if(!eq) break;
        /* P0.3: skip whitespace between key and '=' (PTM .lib format key  =val) */
        char *ke=eq-1; while(ke>=tok&&(*ke==' '||*ke=='\t')) ke--;
        char *ps=ke; while(ps>=tok&&(*ps!=' '&&*ps!='\t')) ps--; ps++;
        int pl=(int)(ke-ps+1); if(pl>31) pl=31;
        strncpy(m.p[m.np].key,ps,pl); m.p[m.np].key[pl]=0;
        for(char *k=m.p[m.np].key;*k;k++) *k=(char)tolower((unsigned char)*k);
        eq++; m.p[m.np].val=parse_eng(eq); m.np++;
        tok=eq; while(*tok&&*tok!=' ') tok++;
    }
    if(c->nmodel<MAX_MODELS) c->models[c->nmodel++]=m;
}
static void parse_include(Circuit *c, const char *line, const char *pdir) {
    char fn[512]; if(sscanf(line,".include %511s",fn)!=1) return;
    char full[1024];
    if(fn[0]=='/'||(fn[0]&&fn[1]==':')){strncpy(full,fn,1023);full[1023]=0;}
    else{snprintf(full,1023,"%s/%s",pdir,fn);}
    FILE *fp=fopen(full,"r"); if(!fp) fp=fopen(fn,"r"); if(!fp) return;
    char idir[1024]; strncpy(idir,full,1023);idir[1023]=0;
    char *sl=strrchr(idir,'/'); if(sl) *sl=0; else strcpy(idir,".");
    char buf[MAX_LINE], acc[MAX_LINE*2]=""; /* accumulated multi-line .model */
    int in_model=0;
    while(fgets(buf,MAX_LINE,fp)){
        char *s=buf; while(*s==' '||*s=='\t') s++;
        /* P0.3: handle continuation lines (+ prefix) inside .model blocks */
        if(*s=='+'){
            if(in_model){
                int alen=strlen(acc);
                while(alen>0&&(acc[alen-1]=='\n'||acc[alen-1]=='\r')) acc[--alen]=0;
                /* copy continuation content, strip trailing whitespace/newline */
                char cont[MAX_LINE]; strncpy(cont,s+1,MAX_LINE-1);cont[MAX_LINE-1]=0;
                int clen=strlen(cont);
                while(clen>0&&(cont[clen-1]=='\n'||cont[clen-1]=='\r'||cont[clen-1]==' '||cont[clen-1]=='\t'))cont[--clen]=0;
                snprintf(acc+alen,sizeof(acc)-alen," %s",cont);
            }
        }else if(!strncmp(s,".model",6)){
            if(in_model&&acc[0]) parse_model_line(c,acc);
            /* copy model line, strip trailing newline for clean accumulation */
            int slen=(int)strlen(s);
            while(slen>0&&(s[slen-1]=='\n'||s[slen-1]=='\r')) slen--;
            memcpy(acc,s,slen); acc[slen]=0;
            in_model=1;
        }else if(!strncmp(s,".include",8)){
            if(in_model&&acc[0]){parse_model_line(c,acc);in_model=0;}
            parse_include(c,s,idir);
        }else{
            /* comment, blank, or other non-model line: flush pending model */
            if(in_model&&acc[0]){parse_model_line(c,acc);in_model=0;}
        }
    }
    if(in_model&&acc[0]) parse_model_line(c,acc); /* flush model at EOF */
    fclose(fp);
}
static int parse_instance(Circuit *c, const char *s) {
    if(*s=='M'||*s=='m'){
        Mosfet m; memset(&m,0,sizeof(m)); m.m=1;
        char mod[32],dn[32],gn[32],sn[32],bn[32];
        if(sscanf(s,"%31s %31s %31s %31s %31s %31s",m.name,dn,gn,sn,bn,mod)>=6){
            strncpy(m.model,mod,31); m.model[31]=0;
            char *wp=strstr(s,"W="); if(!wp) wp=strstr(s,"w=");
            char *lp=strstr(s,"L="); if(!lp) lp=strstr(s,"l=");
            if(wp) m.w=parse_eng(wp+2); if(lp) m.l=parse_eng(lp+2);
            if(m.w<R(1e-9)) m.w=R(1e-6); if(m.l<R(1e-9)) m.l=R(4.5e-8);
            m.d=find_or_add_node(c,dn); m.g=find_or_add_node(c,gn);
            m.s=find_or_add_node(c,sn); m.b=find_or_add_node(c,bn);
            if(c->nm<MAX_ELEMS) c->mos[c->nm++]=m;
        } return 1;
    }
    if(*s=='R'||*s=='r'){
        Resistor r; char n1[32],n2[32],vs[32];
        if(sscanf(s,"%31s %31s %31s %31s",r.name,n1,n2,vs)>=4){
            r.p=find_or_add_node(c,n1); r.n=find_or_add_node(c,n2);
            r.val=parse_eng(vs); if(c->nr<MAX_ELEMS) c->res[c->nr++]=r;
        } return 1;
    }
    if(*s=='V'||*s=='v'){
        Vsource v; char n1[32],n2[32],vs[32]; memset(&v,0,sizeof(v));
        char tn[32];
        int nf=sscanf(s,"%31s %31s %31s %31s",tn,n1,n2,vs);
        if(nf>=3){
            snprintf(v.name,32,"%s",tn);
            v.p=find_or_add_node(c,n1); v.n=find_or_add_node(c,n2);
            /* Waveform detection (P3.4) */
            v.wf_type=WF_DC; v.dc=R(0.0);
            char *wf=(nf>=4)?strstr(s,vs):NULL;
            if(wf&&!strcmp(vs,"SIN")){
                v.wf_type=WF_SIN;
                float fo,fa,ff,ftd,fth;int wn=sscanf(wf,"%*s ( %f %f %f %f %f",&fo,&fa,&ff,&ftd,&fth);
                v.vo=(REAL)fo;v.va=(REAL)fa;v.freq=(REAL)ff;
                v.td_sin=(REAL)(wn>=4?ftd:0);v.theta=(REAL)(wn>=5?fth:0);v.dc=v.vo;
            }else if(wf&&!strcmp(vs,"PULSE")){
                v.wf_type=WF_PULSE;
                float f1,f2,ftd,ftr,ftf,fpw,fper;int wn=sscanf(wf,"%*s ( %f %f %f %f %f %f %f",&f1,&f2,&ftd,&ftr,&ftf,&fpw,&fper);
                v.v1=(REAL)f1;v.v2=(REAL)f2;v.td_pulse=(REAL)(wn>=3?ftd:0);
                v.tr=(REAL)(wn>=4?ftr:1e-12f);v.tf=(REAL)(wn>=5?ftf:1e-12f);
                v.pw=(REAL)(wn>=6?fpw:1e30f);v.per=(REAL)(wn>=7?fper:1e30f);v.dc=v.v1;
            }else if(wf&&!strcmp(vs,"PWL")){
                v.wf_type=WF_PWL;char *pp=wf+3;int cap=32,np=0;
                v.pwl_t=calloc(cap,sizeof(REAL));v.pwl_v=calloc(cap,sizeof(REAL));
                while(*pp&&*pp!=')'){
                    while(*pp==' '||*pp=='\t'||*pp=='(')pp++;if(*pp==')'||*pp==0)break;
                    if(np>=cap){cap*=2;v.pwl_t=realloc(v.pwl_t,cap*sizeof(REAL));v.pwl_v=realloc(v.pwl_v,cap*sizeof(REAL));}
                    v.pwl_t[np]=parse_eng(pp);while(*pp&&*pp!=' '&&*pp!='\t'&&*pp!=')')pp++;
                    while(*pp==' '||*pp=='\t')pp++;v.pwl_v[np]=parse_eng(pp);
                    while(*pp&&*pp!=' '&&*pp!='\t'&&*pp!=')')pp++;np++;
                }
                v.pwl_n=np;v.dc=(np>0)?v.pwl_v[0]:R(0.0);
            }else if(wf&&!strcmp(vs,"DC")){
                v.wf_type=WF_DC;v.dc=parse_eng(wf+2);
            }else{
                v.wf_type=WF_DC;v.dc=(nf>=4)?parse_eng(vs):R(0.0);
            }
            {char *dcp=strstr(s,"DC");if(!dcp)dcp=strstr(s,"dc");
             if(dcp&&dcp>wf)v.dc=parse_eng(dcp+2);}
            /* P5.2: AC magnitude and optional phase */
            v.ac_mag=R(0.0); v.ac_phase=R(0.0);
            {char *acp=strstr(s,"AC");if(!acp)acp=strstr(s,"ac");
             if(acp){ v.ac_mag=parse_eng(acp+2);
                 char *php=acp+2; while(*php&&*php!=' '&&*php!='\t') php++;
                 while(*php==' '||*php=='\t') php++;
                 if(*php&&*php!=')'&&*php!='\n'&&*php!='\r') v.ac_phase=parse_eng(php);
             }}
            if(c->nv<MAX_ELEMS) c->vsrc[c->nv++]=v;
        } return 1;
    }
    if(*s=='I'||*s=='i'){
        Isource is; char n1[32],n2[32],vs[32]; memset(&is,0,sizeof(is));
        char tn[32];
        int nf=sscanf(s,"%31s %31s %31s %31s",tn,n1,n2,vs);
        if(nf>=3){
            snprintf(is.name,32,"%s",tn);
            is.p=find_or_add_node(c,n1); is.n=find_or_add_node(c,n2);
            is.dc=(nf>=4)?parse_eng(vs):R(0.0);
            char *dcp=strstr(s,"DC"); if(!dcp) dcp=strstr(s,"dc");
            if(dcp) is.dc=parse_eng(dcp+2);
            if(c->ni<MAX_ELEMS) c->isrc[c->ni++]=is;
        } return 1;
    }
    if(*s=='C'||*s=='c'){
        Capacitor cap; char n1[32],n2[32],vs[32]; memset(&cap,0,sizeof(cap));
        if(sscanf(s,"%31s %31s %31s %31s",cap.name,n1,n2,vs)>=4){
            cap.p=find_or_add_node(c,n1); cap.n=find_or_add_node(c,n2);
            cap.c=parse_eng(vs); if(c->nc<MAX_ELEMS) c->cap[c->nc++]=cap;
        } return 1;
    }
    /* P5.5: Diode — Dname n+ n- modelname [area=val] */
    if(*s=='D'||*s=='d'){
        Diode d; char n1[32],n2[32],mod[32]; memset(&d,0,sizeof(d));
        int nf=sscanf(s,"%31s %31s %31s %31s",d.name,n1,n2,mod);
        if(nf>=4){
            d.p=find_or_add_node(c,n1); d.n=find_or_add_node(c,n2);
            strncpy(d.model,mod,31); d.model[31]=0; d.area=R(1.0);
            char *ap=strstr(s,"area="); if(!ap) ap=strstr(s,"AREA=");
            if(ap) d.area=parse_eng(ap+5);
            if(c->nd<MAX_ELEMS) c->dio[c->nd++]=d;
        } return 1;
    }
    return 0;
}
/* ===== P3.2: {} substitution for .param values ===== */
static void param_subst(Circuit *c, char *s) {
    char *open=strchr(s,'{');
    while(open){
        char *close=strchr(open,'}');
        if(!close) break;
        int kn=(int)(close-(open+1));
        if(kn>0 && kn<32){
            char key[32]; strncpy(key,open+1,kn); key[kn]=0;
            for(int i=0;i<c->nparam;i++){
                if(!strcmp(c->param_names[i],key)){
                    char rep[32]; snprintf(rep,32,"%s",real_to_str(c->param_vals[i],'e',6));
                    int rl=(int)strlen(rep);
                    int rest=(int)strlen(close+1);
                    int oldl=(int)(close-s+1);
                    if(rl>oldl) memmove(open+rl,close+1,rest+1);
                    else if(rl<oldl) memmove(open+rl,close+1,rest+1);
                    memcpy(open,rep,rl);
                    s[open-s+rl+rest]=0;
                    open=open+rl-1;
                    break;
                }
            }
        }
        open=strchr(open+1,'{');
    }
}
/* ===== P3.2: .option parser ===== */
static void parse_option(Circuit *c, const char *s) {
    char name[64]; REAL val;
    while(*s && *s!=' ') s++;
    while(*s==' '||*s=='\t') s++;
    while(*s){
        while(*s==' '||*s=='\t') s++;
        if(sscanf(s,"%63[^=]=%f",name,&val)==2){
            if(!strcmp(name,"gmin")) c->opt_gmin=val;
            else if(!strcmp(name,"abstol")) c->opt_abstol=val;
            else if(!strcmp(name,"reltol")) c->opt_reltol=val;
            else if(!strcmp(name,"maxiter")||!strcmp(name,"itl1")) c->opt_maxiter=(int)val;
            const char *eq=strchr(s,'='); if(eq) s=eq+1;
            while(*s && *s!=' ') s++;
        }else break;
    }
}
/* ===== P3.2: .param parser ===== */
static void parse_param(Circuit *c, const char *s) {
    while(*s && *s!=' ') s++;
    while(*s==' '||*s=='\t') s++;
    while(*s && c->nparam<256){
        while(*s==' '||*s=='\t') s++;
        const char *eq=strchr(s,'='); if(!eq) break;
        int kl=(int)(eq-s); if(kl>31) kl=31;
        if(kl>0){
            strncpy(c->param_names[c->nparam],s,kl);
            c->param_names[c->nparam][kl]=0;
            c->param_vals[c->nparam]=parse_eng(eq+1);
            c->nparam++;
        }
        s=eq+1; while(*s&&*s!=' ') s++;
    }
}
/* ===== P3.2: .temp parser (Celsius → Kelvin) ===== */
static void parse_temp(Circuit *c, const char *s) {
    REAL tc; if(sscanf(s,".temp %f",&tc)==1) c->temp=R(tc+273.15);
}
/* ===== P3.3: .subckt parser — capture body lines until .ends ===== */
static void parse_subckt(Circuit *c, const char *filename, const char *first_line) {
    if(c->nsubckt>=MAX_SUBCKT) return;
    Subckt *sk=&c->subckts[c->nsubckt]; memset(sk,0,sizeof(Subckt));
    char rest[MAX_LINE]; int nf=sscanf(first_line,".subckt %31s %[^\n]",sk->name,rest);
    if(nf<1) return;
    char *rp=rest; sk->nnode=0;
    while(*rp && sk->nnode<32){
        while(*rp==' '||*rp=='\t') rp++; if(!*rp) break;
        int nn=0; while(rp[nn]&&rp[nn]!=' '&&rp[nn]!='\t') nn++;
        if(nn>31) nn=31; if(nn>0){
            strncpy(sk->nodes[sk->nnode],rp,nn); sk->nodes[sk->nnode][nn]=0; sk->nnode++;
        }
        rp+=nn;
    }
    FILE *fp=fopen(filename,"r"); if(!fp) return;
    char buf[MAX_LINE]; int in_sub=0;
    while(fgets(buf,MAX_LINE,fp)){
        int bl=(int)strlen(buf); while(bl>0&&(buf[bl-1]=='\n'||buf[bl-1]=='\r')) buf[--bl]=0;
        char *s=buf; while(*s==' '||*s=='\t') s++;
        if(!in_sub){ if(!strncmp(s,".subckt",7)&&strstr(s,sk->name)) in_sub=1; continue; }
        if(!strncmp(s,".ends",5)){fclose(fp);c->nsubckt++;return;}
        if(*s=='*'||*s==0) continue;
        if(sk->nline<MAX_SUBCKT_LINES){
            strncpy(sk->lines[sk->nline],s,MAX_LINE-1);sk->lines[sk->nline][MAX_LINE-1]=0; sk->nline++;
        }
    }
    fclose(fp);
}
/* ===== P3.3: expand X-line — node substitution + name prefix ===== */
static int expand_subckt(Circuit *c, const char *s) {
    char xname[32], nodes[32][32]; int nn=0;
    int nf=sscanf(s,"%31s",xname); if(nf<1) return 0;
    const char *p=s+strlen(xname);
    while(*p==' '||*p=='\t') p++;
    while(*p && nn<32){
        while(*p==' '||*p=='\t') p++; if(!*p) break;
        int nl=0; while(p[nl]&&p[nl]!=' '&&p[nl]!='\t') nl++;
        if(nl>31) nl=31;
        if(nn<32){strncpy(nodes[nn],p,nl);nodes[nn][nl]=0;nn++;}
        p+=nl;
    }
    if(nn<2) return 0;
    char skname[32]; strncpy(skname,nodes[nn-1],31);skname[31]=0; nn--;
    Subckt *sk=NULL; for(int i=0;i<c->nsubckt;i++){
        if(!strcmp(c->subckts[i].name,skname)){sk=&c->subckts[i];break;}
    }
    if(!sk||sk->nnode!=nn) return 0;
    char nodemap[32][32]; for(int i=0;i<nn;i++) strncpy(nodemap[i],nodes[i],31);
    for(int i=0;i<sk->nline;i++){
        char eline[MAX_LINE]; strncpy(eline,sk->lines[i],MAX_LINE-1);eline[MAX_LINE-1]=0;
        char tok[32], rest[MAX_LINE]; rest[0]=0;
        int nscan=sscanf(eline,"%31s %[^\n]",tok,rest);
        if(nscan>=1){
            char newline[MAX_LINE]; snprintf(newline,MAX_LINE,"%s.%s %s",xname,tok,rest);
            char *sp=newline;
            while(*sp){
                if(*sp==' '||*sp=='\t'){sp++;continue;}
                int tl=0; while(sp[tl]&&sp[tl]!=' '&&sp[tl]!='\t') tl++;
                for(int j=0;j<sk->nnode;j++){
                    if(tl==(int)strlen(sk->nodes[j])&&!strncmp(sp,sk->nodes[j],tl)){
                        char suffix[MAX_LINE]; strncpy(suffix,sp+tl,MAX_LINE-1);suffix[MAX_LINE-1]=0;
                        int pfx=(int)(sp-newline); char pbuf[MAX_LINE];
                        strncpy(pbuf,newline,pfx);pbuf[pfx]=0;
                        snprintf(newline,MAX_LINE,"%s%s%s",pbuf,nodemap[j],suffix);
                        sp=newline+pfx+(int)strlen(nodemap[j])-1; break;
                    }
                }
                sp+=tl;
            }
            param_subst(c,newline);
            if(!strncmp(newline,".model",6)) parse_model_line(c,newline);
            else if(newline[0]=='.'){}
            else parse_instance(c,newline);
        }
    }
    return 1;
}
static void parse_netlist(Circuit *c, const char *filename) {
    char dir[1024]="."; const char *sl=strrchr(filename,'/');
    if(sl){int len=(int)(sl-filename);if(len>1023)len=1023;
           strncpy(dir,filename,len);dir[len]=0;}
    FILE *fp=fopen(filename,"r");
    if(!fp){fprintf(stderr,"ERROR: Cannot open %s\n",filename);exit(1);}
    char buf[MAX_LINE],cont[MAX_LINE]="";
    while(fgets(buf,MAX_LINE,fp)){
        int bl=(int)strlen(buf);
        while(bl>0&&(buf[bl-1]=='\n'||buf[bl-1]=='\r')) buf[--bl]=0;
        char *s=buf; while(*s==' '||*s=='\t') s++;
        if(*s=='*'||*s==0) continue;
        if(*s=='+'){
            if(strlen(cont)+strlen(s+1)+2<MAX_LINE){strcat(cont," ");strcat(cont,s+1);}
            continue;
        }
        if(cont[0]){
            char cs[MAX_LINE]; strncpy(cs,cont,MAX_LINE-1);cs[MAX_LINE-1]=0;
            char *c2=cs; while(*c2==' '||*c2=='\t') c2++;
            if(!strncmp(c2,".model",6)) parse_model_line(c,c2);
            else if(!strncmp(c2,".include",8)) parse_include(c,c2,dir);
            else if(!strncmp(c2,".dc",3)){c->do_dc=1;
                int nf=sscanf(c2,".dc %31s %f %f %f %31s %f %f %f",
                       c->dc_src,&c->dc_start,&c->dc_stop,&c->dc_step,
                       c->dc_src2,&c->dc_start2,&c->dc_stop2,&c->dc_step2);
                if(nf>=8) c->dc_nested=1; else c->dc_nested=0;
            }else if(!strncmp(c2,".tran",5)){c->do_tran=1;
                sscanf(c2,".tran %f %f",&c->tran_tstep,&c->tran_tstop);
            }else if(!strncmp(c2,".ac",3)&&(c2[3]==0||c2[3]==' ')){
                c->do_ac=1;
                sscanf(c2,".ac %7s %d %f %f",c->ac_type,&c->ac_n,&c->ac_fstart,&c->ac_fstop);
            }else if(!strncmp(c2,".option",7)) parse_option(c,c2);
            else if(!strncmp(c2,".param",6)) parse_param(c,c2);
            else if(!strncmp(c2,".temp",5)) parse_temp(c,c2);
            else if(!strncmp(c2,".subckt",7)) parse_subckt(c,filename,c2);
            cont[0]=0;
        }
        /* P3.2: expand {} parameters before parsing this line */
        param_subst(c,s);
        if(!strncmp(s,".model",6)){strncpy(cont,s,MAX_LINE-1);cont[MAX_LINE-1]=0;}
        else if(!strncmp(s,".include",8)) parse_include(c,s,dir);
        else if(!strncmp(s,".subckt",7)) parse_subckt(c,filename,s);
        else if(!strncmp(s,".ends",5)){}
        else if(!strncmp(s,".op",3)) c->do_op=1;
        else if(!strncmp(s,".dc",3)){c->do_dc=1;
            int nf=sscanf(s,".dc %31s %f %f %f %31s %f %f %f",
                   c->dc_src,&c->dc_start,&c->dc_stop,&c->dc_step,
                   c->dc_src2,&c->dc_start2,&c->dc_stop2,&c->dc_step2);
            if(nf>=8) c->dc_nested=1; else c->dc_nested=0;
        }else if(!strncmp(s,".tran",5)){c->do_tran=1;
            sscanf(s,".tran %f %f",&c->tran_tstep,&c->tran_tstop);
        }else if(!strncmp(s,".ac",3)&&(s[3]==0||s[3]==' ')){
            /* P5.2: .ac dec/lin/oct N fstart fstop */
            c->do_ac=1;
            sscanf(s,".ac %7s %d %f %f",c->ac_type,&c->ac_n,&c->ac_fstart,&c->ac_fstop);
        }else if(!strncmp(s,".option",7)) parse_option(c,s);
        else if(!strncmp(s,".param",6)) parse_param(c,s);
        else if(!strncmp(s,".temp",5)) parse_temp(c,s);
        else if(!strncmp(s,".ic",3)&&(s[3]==0||s[3]==' ')){
            /* P5.4: .ic v(node)=value ... */
            char *p2=s+3;
            while(*p2){
                while(*p2==' '||*p2=='\t') p2++;
                if(!strncmp(p2,"v(",2)||!strncmp(p2,"V(",2)){
                    p2+=2; char nbuf[32]; int ni=0;
                    while(*p2&&*p2!=')'&&ni<31) nbuf[ni++]=*p2++;
                    nbuf[ni]=0; if(*p2==')') p2++;
                    while(*p2==' '||*p2=='='||*p2=='\t') p2++;
                    REAL val=parse_eng(p2);
                    int nd=find_or_add_node(c,nbuf);
                    if(c->nic<MAX_IC){c->ic_nodes[c->nic]=nd;c->ic_vals[c->nic]=val;c->nic++;}
                    while(*p2&&*p2!=' '&&*p2!='\t'&&*p2!=')') p2++;
                }else break;
            }
        }
        else if(!strncmp(s,".control",8)){ c->in_control=1; }
        else if(!strncmp(s,".endc",5)){ c->in_control=0; }
        else if(c->in_control){
            if(!strncmp(s,"op",2)&&(s[2]==0||s[2]==' ')) c->do_op=1;
            else if(!strncmp(s,"dc",2)&&(s[2]==0||s[2]==' ')){
                c->do_dc=1; int nf=sscanf(s,"dc %31s %f %f %f %31s %f %f %f",
                c->dc_src,&c->dc_start,&c->dc_stop,&c->dc_step,
                c->dc_src2,&c->dc_start2,&c->dc_stop2,&c->dc_step2);
                if(nf>=8) c->dc_nested=1; else c->dc_nested=0;
            }
            else if(!strncmp(s,"tran",4)&&(s[4]==0||s[4]==' ')){
                c->do_tran=1; sscanf(s,"tran %f %f",&c->tran_tstep,&c->tran_tstop);
            }
            else if(!strncmp(s,"ac",2)&&(s[2]==0||s[2]==' ')){
                /* P5.2: ac dec/lin/oct N fstart fstop in .control */
                c->do_ac=1;
                sscanf(s,"ac %7s %d %f %f",c->ac_type,&c->ac_n,&c->ac_fstart,&c->ac_fstop);
            }
            else if(!strncmp(s,"print",5)||!strncmp(s,"plot",4)){
                char *p=s; while(*p){
                /* P5.2: support vdb() / vp() in addition to v() / i() */
                while(*p&&*p!='v'&&*p!='i'&&*p!='V'&&*p!='I') p++;
                if(!*p) break;
                char what=(*p=='v'||*p=='V')?'v':'i'; p++;
                /* check for vdb/vp — need 2 more chars */
                if(what=='v'&&(*p=='d'||*p=='D')&&(*(p+1)=='b'||*(p+1)=='B')){what='d';p+=2;}
                else if(what=='v'&&(*p=='p'||*p=='P')){what='p';p++;}
                if(*p!='(') continue; p++; char *st=p;
                while(*p&&*p!=')') p++;
                int n=(int)(p-st); if(n>31)n=31;
                if(n>0&&c->nprint<MAX_PRINTS){
                c->prints[c->nprint].what[0]=what;c->prints[c->nprint].what[1]=0;
                strncpy(c->prints[c->nprint].name,st,n);
                c->prints[c->nprint].name[n]=0;c->nprint++;}
                if(*p==')')p++;}}
            else if(!strncmp(s,"let",3)&&(s[3]==0||s[3]==' ')){
                /* P5.1: let varname = expression */
                char *eq=strchr(s,'='); if(eq){
                    char vname[32];
                    char *vn_start=s+3; while(*vn_start==' '||*vn_start=='\t') vn_start++;
                    char *vn_end=eq-1; while(vn_end>vn_start&&(*vn_end==' '||*vn_end=='\t')) vn_end--;
                    int vlen=(int)(vn_end-vn_start+1); if(vlen>31) vlen=31;
                    if(vlen>0){ strncpy(vname,vn_start,vlen); vname[vlen]=0;
                        char *expr_start=eq+1; while(*expr_start==' '||*expr_start=='\t') expr_start++;
                        if(c->nlet<MAX_LETS){
                            strncpy(c->let_names[c->nlet],vname,31);
                            strncpy(c->let_exprs[c->nlet],expr_start,MAX_LINE-1);
                            c->let_exprs[c->nlet][MAX_LINE-1]=0;
                            char *te=c->let_exprs[c->nlet];
                            int tl=(int)strlen(te); while(tl>0&&(te[tl-1]==' '||te[tl-1]=='\n'||te[tl-1]=='\r')) te[--tl]=0;
                            c->let_vals[c->nlet]=R(0.0); c->nlet++;
                        }
                    }
                }
            }
            else if(!strncmp(s,"echo",4)&&(s[4]==0||s[4]==' ')){
                char *msg=s+4; while(*msg==' '||*msg=='"') msg++;
                int mlen=(int)strlen(msg); while(mlen>0&&(msg[mlen-1]=='"'||msg[mlen-1]=='\n')) mlen--;
                if(mlen>0) printf("%.*s\n",mlen,msg);
            }
        }
        else if(!strncmp(s,".end",4)) break;
        else if(*s=='X'||*s=='x'){ if(expand_subckt(c,s)){} else {strncpy(cont,s,MAX_LINE-1);cont[MAX_LINE-1]=0;} }
        else if(*s=='.'){}
        else if(!parse_instance(c,s)){strncpy(cont,s,MAX_LINE-1);cont[MAX_LINE-1]=0;}
    }
    /* P0.3: flush pending accumulated model at EOF */
    if(cont[0]){
        char cs[MAX_LINE]; strncpy(cs,cont,MAX_LINE-1);cs[MAX_LINE-1]=0;
        char *c2=cs; while(*c2==' '||*c2=='\t') c2++;
        if(!strncmp(c2,".model",6)) parse_model_line(c,c2);
    }
    fclose(fp);
}

/* ===== KCL helper: compute net current INTO each node from all non-Vsrc elements ===== */
static void compute_nc(REAL *v, Circuit *c, BSIM4Param *const *pp_arr,
                       REAL gfinal, REAL *nc) {
    int n=c->nn, gnd=c->ngnd;
    memset(nc,0,n*sizeof(REAL));
    for(int j=0;j<n;j++) if(j!=gnd){
        nc[j]-=gfinal*v[j]; nc[gnd]+=gfinal*v[j];
    }
    for(int j=0;j<c->nr;j++){
        int p=c->res[j].p, nn=c->res[j].n;
        REAL g=R(1.0)/(c->res[j].val+R(1e-30));
        REAL i=g*(v[p]-v[nn]);
        nc[p]-=i; nc[nn]+=i;
    }
    for(int j=0;j<c->nm;j++){
        Mosfet *m=&c->mos[j];
        const BSIM4Param *pp=pp_arr[j];
        REAL vgs=v[m->g]-v[m->s],vds=v[m->d]-v[m->s],vbs=v[m->b]-v[m->s];
        REAL weff=m->w-R(2.0)*pp->wint,leff=m->l-R(2.0)*pp->lint;
        if(weff<R(1e-8)) weff=R(1e-8);if(leff<R(1e-9)) leff=R(1e-9);
        BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
        nc[m->d]-=o.ids; nc[m->s]+=o.ids;
        /* P2.3: Junction diode currents — KCL check */
        nc[m->b]-=o.ibs+o.ibd; nc[m->s]+=o.ibs; nc[m->d]+=o.ibd;
        /* P4.2: MOSFET intrinsic capacitance currents (TRAN companion model) */
        if(c->tran_dt>R(0.0) && c->tran_mos_v_prev && c->tran_mos_cap_i){
            REAL inv_dt=R(1.0)/c->tran_dt;
            int j3=j*3;
            /* Cgs: gate↔source */
            if(o.cgs>R(1e-18)){
                REAL Geq=R(2.0)*o.cgs*inv_dt;
                REAL v_old_v=c->tran_mos_v_prev[j3+0];
                REAL Ieq=-Geq*v_old_v-c->tran_mos_cap_i[j3+0];
                REAL ic=Geq*(v[m->g]-v[m->s])+Ieq;
                nc[m->g]-=ic; nc[m->s]+=ic;
            }
            /* Cgd: gate↔drain */
            if(o.cgd>R(1e-18)){
                REAL Geq=R(2.0)*o.cgd*inv_dt;
                REAL v_old_v=c->tran_mos_v_prev[j3+1];
                REAL Ieq=-Geq*v_old_v-c->tran_mos_cap_i[j3+1];
                REAL ic=Geq*(v[m->g]-v[m->d])+Ieq;
                nc[m->g]-=ic; nc[m->d]+=ic;
            }
            /* Cgb: gate↔body */
            if(o.cgb>R(1e-18)){
                REAL Geq=R(2.0)*o.cgb*inv_dt;
                REAL v_old_v=c->tran_mos_v_prev[j3+2];
                REAL Ieq=-Geq*v_old_v-c->tran_mos_cap_i[j3+2];
                REAL ic=Geq*(v[m->g]-v[m->b])+Ieq;
                nc[m->g]-=ic; nc[m->b]+=ic;
            }
        }
    }
    /* Current sources: I flows from p to n through source.
     * INTO p: -I (source pulls current from p). INTO n: +I. */
    for(int j=0;j<c->ni;j++){
        Isource *is=&c->isrc[j];
        nc[is->p]-=is->dc;
        nc[is->n]+=is->dc;
    }
    /* Capacitors (P4.1): companion model current.
     * i_c = Geq*(v[p]-v[nn]) + Ieq.  INTO p = -i_c, INTO nn = +i_c. */
    if(c->tran_dt>R(0.0) && c->tran_v_prev && c->tran_cap_i){
        REAL inv_dt=R(1.0)/c->tran_dt;
        for(int j=0;j<c->nc;j++){
            Capacitor *cap=&c->cap[j];
            int p=cap->p, nn=cap->n;
            REAL Geq=R(2.0)*cap->c*inv_dt;
            REAL v_old=c->tran_v_prev[p]-c->tran_v_prev[nn];
            REAL Ieq=-Geq*v_old-c->tran_cap_i[j];
            REAL ic=Geq*(v[p]-v[nn])+Ieq;
            nc[p]-=ic; nc[nn]+=ic;
        }
    }
}

/* ===== Waveform evaluator (P3.4): SIN / PULSE / PWL =====
 * Returns v(t) for a voltage source at simulation time t.
 * DC sources return their fixed dc value regardless of t. */
static REAL vsrc_waveform(const Vsource *vs, REAL t) {
    switch(vs->wf_type){
    case WF_SIN: {
        if(t<vs->td_sin) return vs->vo;
        REAL arg=R(2.0)*R(3.141592653589793)*(vs->freq)*(t-vs->td_sin);
        return vs->vo+vs->va*sinf(arg)*expf(-(t-vs->td_sin)*vs->theta);
    }
    case WF_PULSE: {
        if(vs->per<R(1e-30)){  /* single-shot */
            if(t<vs->td_pulse) return vs->v1;
            REAL te=t-vs->td_pulse;
            if(te<vs->tr) return vs->v1+(vs->v2-vs->v1)*te/(vs->tr+R(1e-30));
            te-=vs->tr; if(te<vs->pw) return vs->v2;
            te-=vs->pw; if(te<vs->tf) return vs->v2+(vs->v1-vs->v2)*te/(vs->tf+R(1e-30));
            return vs->v1;
        }
        REAL tmod=fmodf(t,vs->per); if(tmod<R(0.0)) tmod+=vs->per;
        if(tmod<vs->td_pulse) return vs->v1;
        REAL te=tmod-vs->td_pulse;
        if(te<vs->tr) return vs->v1+(vs->v2-vs->v1)*te/(vs->tr+R(1e-30));
        te-=vs->tr; if(te<vs->pw) return vs->v2;
        te-=vs->pw; if(te<vs->tf) return vs->v2+(vs->v1-vs->v2)*te/(vs->tf+R(1e-30));
        return vs->v1;
    }
    case WF_PWL: {
        if(vs->pwl_n<1) return R(0.0);
        if(t<=vs->pwl_t[0]) return vs->pwl_v[0];
        if(t>=vs->pwl_t[vs->pwl_n-1]) return vs->pwl_v[vs->pwl_n-1];
        for(int i=1;i<vs->pwl_n;i++){
            if(t<=vs->pwl_t[i]){
                REAL dt=vs->pwl_t[i]-vs->pwl_t[i-1];
                REAL frac=(t-vs->pwl_t[i-1])/(dt+R(1e-30));
                return vs->pwl_v[i-1]+(vs->pwl_v[i]-vs->pwl_v[i-1])*frac;
            }
        }
        return vs->pwl_v[vs->pwl_n-1];
    }
    default: return vs->dc;  /* WF_DC */
    }
}

/* P5.5: Lookup diode model parameter with defaults.
 * Defaults: IS=1e-14, N=1.0, RS=0, CJO=0, VJ=0.7, M=0.5, BV=inf, IBV=1e-3 */
static REAL dio_model_get(Model *m, const char *key, REAL def) {
    if(!m) return def;
    for(int i=0;i<m->np;i++) if(!strcmp(m->p[i].key,key)) return m->p[i].val;
    return def;
}

/* P5.5: Diode exponential I-V stamp into MNA matrix.
 * Id = IS * area * (exp(Vd/(N*Vt)) - 1),  gd = dId/dVd
 * Stamps 2x2 conductance block at (p,n). Returns 0 on success. */
static int diode_stamp(REAL *a, REAL *rhs, int p, int n, REAL Vd,
                       REAL IS, REAL N, REAL Vt, REAL area,
                       int Ndim, const int *vfixed) {
    REAL safe_exp=Vd/(N*Vt+R(1e-30));
    if(safe_exp>R(80.0)) safe_exp=R(80.0);  /* prevent expf overflow */
    if(safe_exp<-R(80.0)) safe_exp=-R(80.0);
    REAL ev=expf(safe_exp);
    REAL Id=IS*area*(ev-R(1.0));
    REAL gd=IS*area*ev/(N*Vt+R(1e-30));
    /* NaN firewall */
    if(IS_NAN(Id)||IS_NAN(gd)){ Id=R(0.0); gd=R(1e-12); }
    /* Stamp conductance: a[p][p]+=gd, a[p][n]-=gd, a[n][p]-=gd, a[n][n]+=gd */
    if(!vfixed[p]){ a[p+p*Ndim]+=gd; if(!vfixed[n]) a[p+n*Ndim]-=gd; }
    if(!vfixed[n]){ if(!vfixed[p]) a[n+p*Ndim]-=gd; a[n+n*Ndim]+=gd; }
    /* Stamp current source: Id - gd*Vd (Newton linearization) */
    REAL Ieq=Id-gd*Vd;
    if(!vfixed[p]) rhs[p]-=Ieq;
    if(!vfixed[n]) rhs[n]+=Ieq;
    return 0;
}

/* ===== DC Solver: MNA for floating Vsrcs + Gmin-stepped Newton (B8 fix) =====
 * Grounded Vsrcs (n==GND): simple node fixing, current via KCL.
 * Floating Vsrcs (neither terminal at GND): MNA branch current variable
 *   expands the system from n x n to N x N where N = n + n_float.
 *   The constraint v[p] - v[n] = Vdc is enforced exactly.
 *   Branch current I is solved as part of the Newton system.
 */
static int dc_solve(REAL *v, REAL *iv, Circuit *c, BSIM4Param *const *pp_arr,
                    int max_iter, REAL abstol) {
    int n=c->nn, gnd=c->ngnd;
    (void)max_iter; /* P2.8: replaced by per-ramp adaptive max_iter_ramp */

    /* --- Classify Vsrcs: grounded (simple fix) vs floating (MNA) --- */
    int *vfixed=calloc(n,sizeof(int));
    int *vs_mna=calloc(c->nv,sizeof(int));  /* -1=grounded, else MNA row/col index */
    int n_float=0;
    for(int j=0;j<c->nn;j++) v[j]=R(0.0);
    for(int j=0;j<c->nv;j++) iv[j]=R(0.0);
    for(int j=0;j<c->nv;j++){
        if(c->vsrc[j].n==gnd){
            /* Grounded Vsrc: fix +node to Vdc, -node is GND (0V) */
            vfixed[c->vsrc[j].p]=1;
            v[c->vsrc[j].p]=c->vsrc[j].dc;
            vs_mna[j]=-1;
        }else{
            /* Floating Vsrc: MNA branch current variable.
             * Neither terminal is fixed -- MNA equation v[p]-v[n]=Vdc
             * determines the common-mode voltage from the rest of the circuit. */
            vs_mna[j]=n+n_float;
            n_float++;
        }
    }
    int N=n+n_float;  /* total system: node voltages + floating-Vsrc branch currents */

    REAL *a=calloc(N*N,sizeof(REAL));
    REAL *rhs=calloc(N,sizeof(REAL));
    REAL *dx=calloc(N,sizeof(REAL));

    REAL gm_base=c->opt_gmin>R(0.0)?c->opt_gmin:R(1e-12);

    /* Gmin stepping: 3 stages from large (easy convergence) to small (accurate).
     * Cmin stepping (P2.3): diagonal-only damping, no DC bias.  Provides
     * "clean" matrix conditioning complementary to gmin's RHS-biased damping. */
    /* P2.8: 5-stage gmin + cmin stepping.
     * Stage 0 (1e-7 gmin): 10MΩ to GND per node — strong diagonal dominance.
     * Stage 4 (1e-12 gmin): effectively no artificial load — high accuracy.
     * Each stage starts from previous stage's converged solution.
     * Cmin provides "clean" diagonal damping (no DC bias, unlike gmin). */
    REAL gmin_stages[] = {gm_base*R(1e5), gm_base*R(1e4), gm_base*R(1e3),
                          gm_base*R(1e2), gm_base};
    REAL cmin_vals [] = {R(1e-5), R(1e-6), R(1e-7), R(1e-9), R(0.0)};
    int n_stages = 5;
    int total_iters = 0;

    /* ---- Source stepping (P2.1): ramp sources 0 → full value ----
     * 4-stage exponential ramp: 0.1% → 1% → 10% → 100%.
     * Each ramp uses the previous ramp's converged solution as its
     * initial guess, ensuring Newton starts near the solution even
     * for circuits with strong MOSFET nonlinearities.
     */
    REAL *dc_orig=calloc(c->nv,sizeof(REAL));
    REAL *idc_orig=calloc(c->ni,sizeof(REAL));
    for(int j=0;j<c->nv;j++) dc_orig[j]=c->vsrc[j].dc;
    for(int j=0;j<c->ni;j++) idc_orig[j]=c->isrc[j].dc;
    /* P2.8: 9-stage source ramp — ~3× per step for gentle multi-transistor startup.
     * Coarse 10× jumps cause complementary MOSFET pairs to swing wildly → Newton fails.
     * Finer granularity keeps each ramp step within the Newton basin of attraction. */
    REAL src_ramp[] = {R(1e-4), R(3e-4), R(1e-3), R(3e-3), R(1e-2),
                       R(3e-2), R(1e-1), R(3e-1), R(1.0)};
    int n_ramp = 9, ramp_failed = 0;

  for(int ramp=0; ramp < n_ramp; ramp++){  /* === SOURCE RAMP OUTER LOOP === */
    REAL alpha = src_ramp[ramp];
    /* P2.8: Scale ALL sources — Vsrc DC + Isrc DC — for this ramp step.
     * Current sources must scale with voltage sources, otherwise full bias
     * currents fight near-zero supply at low ramp, making convergence
     * impossible for current-biased circuits (OTA, opamp, bandgap). */
    for(int j=0;j<c->nv;j++) c->vsrc[j].dc = dc_orig[j] * alpha;
    for(int j=0;j<c->ni;j++) c->isrc[j].dc = idc_orig[j] * alpha;
    /* Re-init grounded Vsrc fixed node voltages to scaled value.
     * Free node voltages are KEPT from previous ramp as initial guess. */
    for(int j=0;j<c->nv;j++){
        if(vs_mna[j] < 0) v[c->vsrc[j].p] = c->vsrc[j].dc;
    }
    /* Reset floating Vsrc branch currents (MNA variables) for fresh ramp */
    for(int j=0;j<c->nv;j++){
        if(vs_mna[j] >= 0) iv[j] = R(0.0);
    }

    int stage_converged = 0;  /* scoped here for ramp-loop failure check */
    /* P2.8: adaptive max_iter — low ramp needs more iterations to build up solution;
     * high ramp can use tighter limit since starting from near-converged state. */
    int max_iter_ramp = (alpha < R(0.1)) ? 200 : 150;
    REAL vlim_stage = R(0.1);  /* P2.8: start very conservative, iter-based ramp */
    for(int stage=0; stage < n_stages; stage++){
        REAL gmin = gmin_stages[stage];
        REAL cmin_val = cmin_vals[stage];  /* Cmin provides clean diagonal damping (P2.3) */
        stage_converged = 0;

        /* Adaptive voltage limiting (P2.2): start each gmin stage with
         * conservative 0.5V limit. Tighten/relax based on convergence. */
        REAL vlim = vlim_stage;

        for(int iter=0; iter < max_iter_ramp; iter++){
            int lu_ok = 0;
            REAL effective_gmin = gmin;
            REAL effective_cmin = cmin_val;  /* bumped alongside gmin in recovery */

            /* --- Recovery cascade: retry assembly+solve with stronger damping --- */
            for(int recovery=0; recovery < 6; recovery++){  /* P2.8: +1 recovery level for voltage reset */
                /* P2.8: Recovery 5 — reset all free node voltages to 0, restart from scratch */
                if(recovery==5){
                    for(int jj=0;jj<n;jj++) if(jj!=gnd && !vfixed[jj]) v[jj]=R(0.0);
                    for(int jj=0;jj<c->nv;jj++) if(vs_mna[jj]>=0) iv[jj]=R(0.0);
                    effective_gmin = gmin * R(100.0);
                    effective_cmin = cmin_val * R(100.0);
                    vlim = R(0.1);
                }
                memset(a,0,N*N*sizeof(REAL)); memset(rhs,0,N*sizeof(REAL));

                /* Gmin + Cmin (P2.3): diagonal damping from each free node to GND.
                 * Gmin adds both a[j+j*N] AND rhs bias (DC leakage to GND).
                 * Cmin adds ONLY a[j+j*N] — clean diagonal dominance, no DC bias. */
                for(int j=0;j<n;j++) if(j!=gnd && !vfixed[j]){
                    a[j+j*N]=effective_gmin + effective_cmin;
                    rhs[j]=-effective_gmin*v[j];
                }

                /* Resistors */
                for(int j=0;j<c->nr;j++){
                    int p=c->res[j].p, nn=c->res[j].n;
                    REAL g=R(1.0)/(c->res[j].val+R(1e-30));
                    if(!vfixed[p]){ a[p+p*N]+=g; rhs[p]-=g*(v[p]-v[nn]); }
                    if(!vfixed[nn]){ a[nn+nn*N]+=g; rhs[nn]-=g*(v[nn]-v[p]); }
                    if(!vfixed[p] && !vfixed[nn]){ a[p+nn*N]-=g; a[nn+p*N]-=g; }
                }

                /* Current sources (P2.5): constant current, zero Jacobian */
                for(int j=0;j<c->ni;j++){
                    Isource *is=&c->isrc[j];
                    if(!vfixed[is->p]) rhs[is->p]-=is->dc;
                    if(!vfixed[is->n]) rhs[is->n]+=is->dc;
                }

                /* MOSFETs */
                for(int j=0;j<c->nm;j++){
                    Mosfet *m=&c->mos[j];
                    const BSIM4Param *pp=pp_arr[j];
                    REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
                    REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
                    if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
                    BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
                    REAL gm=o.gm, gds=o.gds, gmbs=o.gmbs, ids=o.ids;

                    if(!vfixed[m->d]){
                        a[m->d+m->d*N]+=gds;
                        if(!vfixed[m->s]) a[m->d+m->s*N]-=gds+gm+gmbs;
                        if(!vfixed[m->g]) a[m->d+m->g*N]+=gm;
                        if(!vfixed[m->b]) a[m->d+m->b*N]+=gmbs;
                        rhs[m->d]-=ids;
                    }
                    if(!vfixed[m->s]){
                        a[m->s+m->s*N]+=gds+gm+gmbs;
                        if(!vfixed[m->d]) a[m->s+m->d*N]-=gds;
                        if(!vfixed[m->g]) a[m->s+m->g*N]-=gm;
                        if(!vfixed[m->b]) a[m->s+m->b*N]-=gmbs;
                        rhs[m->s]+=ids;
                    }
                    /* P2.3: Junction diode currents b↔s, b↔d (Newton linearization) */
                    {
                        REAL Vbs=v[m->b]-v[m->s], Vbd=v[m->b]-v[m->d];
                        REAL Ieq_bs=o.ibs-o.gbs*Vbs;
                        REAL Ieq_bd=o.ibd-o.gbd*Vbd;
                        /* Body-Source junction: I flows from body to source */
                        if(fabsf(o.gbs)>R(1e-18)){
                            if(!vfixed[m->b]){
                                a[m->b+m->b*N]+=o.gbs;
                                if(!vfixed[m->s]) a[m->b+m->s*N]-=o.gbs;
                                rhs[m->b]-=Ieq_bs;
                            }
                            if(!vfixed[m->s]){
                                a[m->s+m->s*N]+=o.gbs;
                                if(!vfixed[m->b]) a[m->s+m->b*N]-=o.gbs;
                                rhs[m->s]+=Ieq_bs;
                            }
                        }
                        /* Body-Drain junction: I flows from body to drain */
                        if(fabsf(o.gbd)>R(1e-18)){
                            if(!vfixed[m->b]){
                                a[m->b+m->b*N]+=o.gbd;
                                if(!vfixed[m->d]) a[m->b+m->d*N]-=o.gbd;
                                rhs[m->b]-=Ieq_bd;
                            }
                            if(!vfixed[m->d]){
                                a[m->d+m->d*N]+=o.gbd;
                                if(!vfixed[m->b]) a[m->d+m->b*N]-=o.gbd;
                                rhs[m->d]+=Ieq_bd;
                            }
                        }
                    }
                    /* P2.4: Body resistance network stamping.
                     * When rbodymod>0.5, the body node has a finite-impedance
                     * path to GND through the equivalent body resistance rbody.
                     * This helps convergence for NMOS body tied to GND. */
                    if(o.rbody > R(1e-6)) {
                        REAL gb = R(1.0)/o.rbody;  /* body conductance */
                        if(!vfixed[m->b]) {
                            a[m->b + m->b*N] += gb;
                            rhs[m->b] -= gb * v[m->b];
                        }
                    }
                }
                REAL Vt=R(0.02585);  /* thermal voltage at 300K */
                for(int j=0;j<c->nd;j++){
                    Diode *d=&c->dio[j];
                    REAL Vd=v[d->p]-v[d->n];
                    /* Lookup model params with defaults */
                    Model *dm=find_model(c,d->model);
                    REAL IS=dio_model_get(dm,"IS",R(1e-14));
                    REAL N =dio_model_get(dm,"N",R(1.0));
                    if(IS<R(1e-20)) IS=R(1e-14);
                    if(N<R(1e-6)) N=R(1.0);
                    (void)diode_stamp(a,rhs,d->p,d->n,Vd,IS,N,Vt,d->area,N,vfixed);
                }

                /* --- P4.2: MOSFET intrinsic capacitance companion models ---
                 * Each MOSFET has 3 voltage-dependent caps: Cgs(g↔s), Cgd(g↔d), Cgb(g↔b).
                 * Companion model: Geq=2C/dt, Ieq=-Geq*V_prev - I_prev.
                 * Stamped inside Newton loop because Cgs/Cgd/Cgb change with bias. */
                if(c->tran_dt>R(0.0) && c->tran_mos_v_prev && c->tran_mos_cap_i){
                    REAL inv_dt=R(1.0)/c->tran_dt;
                    for(int j=0;j<c->nm;j++){
                        Mosfet *m=&c->mos[j];
                        const BSIM4Param *pp=pp_arr[j];
                        REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
                        REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
                        if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
                        BSIM4Out ocap=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
                        int j3=j*3;
                        /* Helper: stamp companion for cap between nodes na and nb */
                        #define STAMP_MOSCAP(na,nb,cap_val,idx) do { \
                            if(cap_val>R(1e-18)){ \
                                REAL Geq=R(2.0)*cap_val*inv_dt; \
                                REAL v_old_v=c->tran_mos_v_prev[idx]; \
                                REAL Ieq=-Geq*v_old_v-c->tran_mos_cap_i[idx]; \
                                if(!vfixed[na]&&!vfixed[nb]){ \
                                    a[na+na*N]+=Geq; a[nb+nb*N]+=Geq; \
                                    a[na+nb*N]-=Geq; a[nb+na*N]-=Geq; \
                                    rhs[na]-=Geq*(v[na]-v[nb])+Ieq; \
                                    rhs[nb]-=Geq*(v[nb]-v[na])-Ieq; \
                                }else if(!vfixed[na]){ \
                                    a[na+na*N]+=Geq; \
                                    rhs[na]-=Geq*(v[na]-v[nb])+Ieq; \
                                }else if(!vfixed[nb]){ \
                                    a[nb+nb*N]+=Geq; \
                                    rhs[nb]-=Geq*(v[nb]-v[na])-Ieq; \
                                } \
                            } \
                        } while(0)
                        STAMP_MOSCAP(m->g, m->s, ocap.cgs, j3+0);
                        STAMP_MOSCAP(m->g, m->d, ocap.cgd, j3+1);
                        STAMP_MOSCAP(m->g, m->b, ocap.cgb, j3+2);
                        #undef STAMP_MOSCAP
                    }
                }

                /* --- MNA stamp for floating voltage sources (B8 fix) ---
                 * For each floating Vsrc between nodes p and n with voltage E:
                 *   KCL row p: +I  (branch current flows from p into source)
                 *   KCL row n: -I  (branch current flows from source into n)
                 *   Vsrc row:  v[p] - v[n] = E
                 * Newton system:  [J_nl  B ] [Dv]   [-f_nl - B*I]
                 *                  [B^T   0 ] [DI] = [E - (v[p]-v[n])]
                 */
                if(n_float>0){
                    for(int j=0;j<c->nv;j++){
                        int idx=vs_mna[j];
                        if(idx<0) continue;  /* grounded */
                        int p=c->vsrc[j].p, nn=c->vsrc[j].n;
                        /* B matrix: KCL rows x branch current column */
                        a[p+idx*N]+=R(1.0);
                        a[nn+idx*N]-=R(1.0);
                        /* -B*I contribution to KCL residual */
                        rhs[p]-=iv[j];
                        rhs[nn]+=iv[j];
                        /* B^T: Vsrc equation row x node voltage columns */
                        a[idx+p*N]=R(1.0);
                        a[idx+nn*N]=R(-1.0);
                        /* RHS: E - (v[p]-v[n]) -- drives correction toward constraint */
                        rhs[idx]=c->vsrc[j].dc-(v[p]-v[nn]);
                    }
                }

                /* --- Capacitor companion models (P4.1: trapezoidal TRAN) ---
                 * Trapezoidal: C*dV/dt ≈ (2C/dt)*ΔV + I_hist.
                 * Geq=2C/dt in || with Ieq=-Geq*V_prev - I_prev. */
                if(c->tran_dt>R(0.0) && c->tran_v_prev && c->tran_cap_i){
                    REAL inv_dt=R(1.0)/c->tran_dt;
                    for(int j=0;j<c->nc;j++){
                        Capacitor *cap=&c->cap[j];
                        int p=cap->p, nn=cap->n;
                        REAL Geq=R(2.0)*cap->c*inv_dt;
                        REAL v_old=c->tran_v_prev[p]-c->tran_v_prev[nn];
                        REAL Ieq=-Geq*v_old-c->tran_cap_i[j];
                        if(!vfixed[p]&&!vfixed[nn]){
                            a[p+p*N]+=Geq; a[nn+nn*N]+=Geq;
                            a[p+nn*N]-=Geq; a[nn+p*N]-=Geq;
                            rhs[p]-=Geq*(v[p]-v[nn])+Ieq;
                            rhs[nn]-=Geq*(v[nn]-v[p])-Ieq;
                        }else if(!vfixed[p]){
                            a[p+p*N]+=Geq;
                            rhs[p]-=Geq*(v[p]-v[nn])+Ieq;
                        }else if(!vfixed[nn]){
                            a[nn+nn*N]+=Geq;
                            rhs[nn]-=Geq*(v[nn]-v[p])-Ieq;
                        }
                    }
                }

                /* Fix voltage-driven nodes (grounded Vsrcs + GND): J[j,j]=1, rhs[j]=0.
                 * Zero ROW only -- preserve column entries for KCL consistency. */
                for(int j=0;j<n;j++) if(vfixed[j]||j==gnd){
                    for(int i=0;i<N;i++){ if(i!=j) a[j+i*N]=R(0.0); }
                    a[j+j*N]=R(1.0); rhs[j]=R(0.0);
                }

                if(lu_solve(N,a,rhs,dx) >= 0){ lu_ok=1; break; }

                /* Recovery: escalate damping to fix singular matrix */
                if(recovery==5){
                    /* Already set above (voltage reset + max damping) — no further escalation */
                } else if(recovery < 3){
                    effective_gmin *= R(10.0);
                    effective_cmin *= R(10.0);  /* bump Cmin alongside gmin (P2.3) */
                } else {
                    effective_gmin = gmin * R(100.0);
                    effective_cmin = cmin_val * R(100.0);
                    vlim *= R(0.1);
                }
            }

            if(!lu_ok){
                /* --- Pseudo-transient fallback (P2.3) ---
                 * Last resort: inject Cmin=1e-3 as pseudo-capacitors
                 * to GND.  Provides strong diagonal dominance with zero
                 * DC bias (unlike gmin).  Saved Cmin restored on failure
                 * so next stage starts fresh. */
                {
                    REAL cmin_saved = cmin_val;
                    cmin_val = R(1e-3);
                    effective_gmin = gmin * R(100.0);
                    effective_cmin = cmin_val;
                    vlim *= R(0.05);
                    memset(a,0,N*N*sizeof(REAL)); memset(rhs,0,N*sizeof(REAL));
                    for(int jj=0;jj<n;jj++) if(jj!=gnd && !vfixed[jj]){
                        a[jj+jj*N]=effective_gmin + effective_cmin;
                        rhs[jj]=-effective_gmin*v[jj];
                    }
                    if(lu_solve(N,a,rhs,dx) >= 0){
                        lu_ok = 1;  /* pseudo-transient succeeded */
                        break;
                    }
                    cmin_val = cmin_saved;  /* restore on failure */
                }
                if(!lu_ok){
                    if(stage > 0){
                        stage -= 2;  /* re-run previous stage */
                        break;
                    }
                    /* First stage + pseudo-transient failed — bail */
                    ramp_failed = 1;
                    goto dc_cleanup;
                }
            }

            /* --- Update: node voltages (0..n-1) + branch currents (n..N-1) --- */
            REAL max_dv=R(0.0);
            int had_nan=0;
            for(int j=0;j<n;j++){
                if(!vfixed[j] && j!=gnd){
                    REAL dv=dx[j];
                    if(dv>vlim) dv=vlim; if(dv<-vlim) dv=-vlim;
                    REAL v_new=v[j]+dv;
                    if(IS_NAN(v_new)){
                        v[j]=R(0.0); had_nan=1;
                    } else {
                        v[j]=v_new;
                        REAL ad=fabsf(dv); if(ad>max_dv) max_dv=ad;
                    }
                }
            }
            /* Update floating Vsrc branch currents from MNA variables */
            if(n_float>0){
                for(int j=0;j<c->nv;j++){
                    if(vs_mna[j]>=0){
                        REAL dI=dx[vs_mna[j]];
                        if(!IS_NAN(dI)) iv[j]+=dI;
                    }
                }
            }
            total_iters++;
            /* P2.8: Soft convergence — only at final gmin stages (3+ of 5).
             * Early stages with strong gmin must converge properly to provide
             * a good initial guess.  Accepting loose solutions at early stages
             * propagates garbage through the entire stage cascade.
             * At final stages (near-zero gmin), multi-transistor circuits may
             * oscillate near the solution — relaxed tolerance prevents infinite loops. */
            if(!had_nan && !stage_converged && stage >= 3 && iter > 50
               && max_dv < R(10.0)*abstol){
                stage_converged = 1;
                printf("  [soft_converge] ramp=%.0e stage=%d iter=%d\n",
                       (double)alpha, stage, iter);
                break;
            }
            if(!had_nan && max_dv<abstol){ stage_converged=1; break; }

            /* --- Adaptive voltage limiting (P2.8: iter-based ramp) ---
             * Very conservative early (0.1V) to avoid overshoot in complementary
             * MOSFET circuits. Relaxes as Newton settles into convergence basin.
             * Updates vlim_stage (not local vlim) to persist across iterations.
             * iter < 5:  0.1V — aggressive damping for initial transient
             * iter < 15: 0.2V — moderate damping for approach
             * iter < 30: 0.4V — relaxed for fine convergence
             * else:      0.5V — full step when near solution
             * NaN still triggers aggressive tightening. */
            if(iter < 5)        vlim_stage = R(0.1);
            else if(iter < 15)  vlim_stage = R(0.2);
            else if(iter < 30)  vlim_stage = R(0.4);
            else                vlim_stage = R(0.5);
            if(had_nan) vlim_stage *= R(0.25);
            if(vlim_stage < R(0.01)) vlim_stage = R(0.01);
            if(vlim_stage > R(5.0))  vlim_stage = R(5.0);
        }

        if(!stage_converged){
            ramp_failed = 1;
            goto dc_cleanup;  /* skip remaining stages/ramps → unified cleanup */
        }
    }  /* end gmin stage loop */

    /* If non-final ramp failed to converge, don't continue */
    if(!stage_converged && ramp < n_ramp-1){
        ramp_failed = 1;
        goto dc_cleanup;
    }
  }  /* === END SOURCE RAMP LOOP === */

dc_cleanup:
  /* Restore original source DC values (were scaled during source stepping) */
  for(int j=0;j<c->nv;j++) c->vsrc[j].dc = dc_orig[j];
  for(int j=0;j<c->ni;j++) c->isrc[j].dc = idc_orig[j];
  /* Re-sync grounded Vsrc node voltages to restored DC values.
   * Without this, v[] may hold stale ramp-step voltages → prints VDD=0. */
  for(int j=0;j<c->nv;j++) if(vs_mna[j] < 0) v[c->vsrc[j].p] = c->vsrc[j].dc;
  free(dc_orig); free(idc_orig);

  /* Compute Vsrc currents: best-effort KCL (ramp failed) or
   * full post-convergence KCL (all ramps succeeded).
   * Floating Vsrcs keep their MNA-computed iv[j] in both paths. */
  {
      REAL gfinal = ramp_failed ? gmin_stages[n_stages-1] : gm_base;
      REAL *nc=calloc(n,sizeof(REAL));
      compute_nc(v,c,pp_arr,gfinal,nc);
      for(int j=0;j<c->nv;j++){
          if(vs_mna[j]<0){
              REAL ival=-nc[c->vsrc[j].p];
              iv[j]=IS_NAN(ival)?R(0.0):ival;
          }
      }
      free(nc);
  }
  free(vfixed);free(vs_mna);free(a);free(rhs);free(dx);
  return total_iters;
}
/* Forward declaration for float printer (P0.7: zero cvtss2sd) */
/* P5.2: Forward-declare ac_solve */
static void ac_solve(Circuit *c, BSIM4Param *const *pp_arr, REAL *v, REAL *iv);
static const char *real_to_str(REAL v, char fmt, int prec);

/* P5.2: AC small-signal analysis — complex MNA solver.
 * Freezes gm/gds/caps at DC OP, sweeps frequency, prints vdb/vp.
 * Handles grounded AC Vsrcs as input excitation. */
static void ac_solve(Circuit *c, BSIM4Param *const *pp_arr, REAL *v_dc, REAL *iv_dc) {
    int n=c->nn, gnd=c->ngnd;
    /* Count floating Vsrcs for MNA expansion */
    int n_float=0;
    int *vs_is_float=calloc(c->nv,sizeof(int));
    for(int j=0;j<c->nv;j++){
        if(c->vsrc[j].n!=gnd){ vs_is_float[j]=1; n_float++; }
        else vs_is_float[j]=0;
    }
    int N=n+n_float;
    if(N>256){ free(vs_is_float); printf("AC: matrix too large (%d>256)\n",N); return; }

    /* Compute frequency points */
    REAL fstart=c->ac_fstart, fstop=c->ac_fstop;
    int npts=c->ac_n; if(npts<1) npts=10;
    int is_dec=(!strcmp(c->ac_type,"dec"));
    int is_oct=(!strcmp(c->ac_type,"oct"));
    REAL fstep; int total_pts;
    if(is_dec||is_oct){
        REAL n_per=(REAL)(is_dec?10:2);
        total_pts=(int)((REAL)npts*log10f(fstop/fstart+R(1e-30)))+1;
        fstep=powf(n_per,R(1.0)/(REAL)npts);
    }else{ total_pts=npts; fstep=(fstop-fstart)/(REAL)(npts>1?npts-1:1); }
    if(total_pts>5000) total_pts=5000;

    /* Emit device params at DC OP for AC output reference */
    emit_device_param_table(c,v_dc,pp_arr);

    /* AC frequency sweep */
    printf("\nAC Analysis: %s %d %s %s\n",c->ac_type,c->ac_n,
           real_to_str(fstart,'f',1),real_to_str(fstop,'f',1));
    printf("%-14s ","Frequency");
    for(int j=0;j<c->nn;j++) if(j!=gnd){
        /* check if any print requests for vdb/vp */
        printf("Vdb(%-8s) Vp(%-8s) ",c->nmap[j],c->nmap[j]);
    }
    printf("\n");

    REAL freq=fstart;
    for(int pt=0;pt<total_pts&&freq<=fstop+R(1e-9);pt++){
        REAL omega=R(2.0)*R(3.14159265)*freq;
        REAL *ar=calloc(N*N,sizeof(REAL)),*ai=calloc(N*N,sizeof(REAL));
        REAL *br=calloc(N,sizeof(REAL)),*bi=calloc(N,sizeof(REAL));
        REAL *xr=calloc(N,sizeof(REAL)),*xi=calloc(N,sizeof(REAL));

        /* --- Stamp resistors: G=1/R (real only) --- */
        for(int j=0;j<c->nr;j++){
            int p=c->res[j].p, nn=c->res[j].n;
            REAL g=R(1.0)/(c->res[j].val+R(1e-30));
            if(p!=gnd){ ar[p+p*N]+=g; if(nn!=gnd){ ar[p+nn*N]-=g; ar[nn+p*N]-=g; }}
            if(nn!=gnd) ar[nn+nn*N]+=g;
        }

        /* --- Stamp capacitors: j*omega*C (imag only) --- */
        for(int j=0;j<c->nc;j++){
            int p=c->cap[j].p, nn=c->cap[j].n;
            REAL bc=omega*c->cap[j].c;
            if(p!=gnd){ ai[p+p*N]+=bc; if(nn!=gnd){ ai[p+nn*N]-=bc; ai[nn+p*N]-=bc; }}
            if(nn!=gnd) ai[nn+nn*N]+=bc;
        }

        /* --- Stamp MOSFETs with frozen DC OP gm/gds/gmbs (real only) --- */
        for(int j=0;j<c->nm;j++){
            Mosfet *m=&c->mos[j];
            const BSIM4Param *pp=pp_arr[j];
            REAL vgs=v_dc[m->g]-v_dc[m->s], vds=v_dc[m->d]-v_dc[m->s];
            REAL vbs=v_dc[m->b]-v_dc[m->s];
            REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
            if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
            BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
            REAL gm=o.gm, gds=o.gds, gmbs=o.gmbs;
            if(m->d!=gnd){
                ar[m->d+m->d*N]+=gds;
                if(m->s!=gnd) ar[m->d+m->s*N]-=gds+gm+gmbs;
                if(m->g!=gnd) ar[m->d+m->g*N]+=gm;
                if(m->b!=gnd) ar[m->d+m->b*N]+=gmbs;
            }
            if(m->s!=gnd){
                ar[m->s+m->s*N]+=gds+gm+gmbs;
                if(m->d!=gnd) ar[m->s+m->d*N]-=gds;
                if(m->g!=gnd) ar[m->s+m->g*N]-=gm;
                if(m->b!=gnd) ar[m->s+m->b*N]-=gmbs;
            }
            /* MOSFET caps: j*omega*Cgs/Cgd/Cgb */
            REAL bcgs=omega*o.cgs, bcgd=omega*o.cgd, bcbg=omega*o.cgb;
            if(bcgs>R(1e-18)){ if(m->g!=gnd&&m->s!=gnd){ ai[m->g+m->g*N]+=bcgs; ai[m->s+m->s*N]+=bcgs; ai[m->g+m->s*N]-=bcgs; ai[m->s+m->g*N]-=bcgs; }}
            if(bcgd>R(1e-18)){ if(m->g!=gnd&&m->d!=gnd){ ai[m->g+m->g*N]+=bcgd; ai[m->d+m->d*N]+=bcgd; ai[m->g+m->d*N]-=bcgd; ai[m->d+m->g*N]-=bcgd; }}
            if(bcbg>R(1e-18)){ if(m->g!=gnd&&m->b!=gnd){ ai[m->g+m->g*N]+=bcbg; ai[m->b+m->b*N]+=bcbg; ai[m->g+m->b*N]-=bcbg; ai[m->b+m->g*N]-=bcbg; }}
        }

        /* --- MNA for floating Vsrcs: B and B^T blocks (real only) --- */
        { int mi=0;
        for(int j=0;j<c->nv;j++){
            if(!vs_is_float[j]) continue;
            int p=c->vsrc[j].p, nn=c->vsrc[j].n;
            int row=n+mi;
            if(p!=gnd){ ar[p+row*N]=R(1.0); ar[row+p*N]=R(1.0); }
            if(nn!=gnd){ ar[nn+row*N]=-R(1.0); ar[row+nn*N]=-R(1.0); }
            mi++;
        }}

        /* --- Fixed-node clamping for grounded Vsrcs + GND --- */
        int *vfixed_ac=calloc(n,sizeof(int));
        vfixed_ac[gnd]=1;
        for(int j=0;j<c->nv;j++) if(!vs_is_float[j]) vfixed_ac[c->vsrc[j].p]=1;
        for(int j=0;j<n;j++) if(vfixed_ac[j]){
            for(int k=0;k<N;k++) ar[j+k*N]=ai[j+k*N]=R(0.0);
            ar[j+j*N]=R(1.0);
        }

        /* --- RHS: AC source excitation --- */
        for(int j=0;j<c->nv;j++){
            Vsource *vs=&c->vsrc[j];
            if(vs->ac_mag>R(0.0)){
                if(vs_is_float[j]){
                    /* floating AC source: constraint row RHS */
                    int row=n;
                    for(int j2=0;j2<j;j2++) if(vs_is_float[j2]) row++;
                    br[row]=vs->ac_mag;
                }else{
                    /* grounded AC source: fix +node to ac_mag */
                    br[vs->p]=vs->ac_mag;
                }
            }
        }

        /* Solve complex MNA */
        int ok=lu_solve_complex(N,ar,ai,br,bi,xr,xi);
        if(ok!=0){ free(ar);free(ai);free(br);free(bi);free(xr);free(xi);free(vfixed_ac); break; }

        /* Print results */
        printf("%-14s ",real_to_str(freq,'e',4));
        for(int j=0;j<c->nn;j++) if(j!=gnd){
            REAL mag=sqrtf(xr[j]*xr[j]+xi[j]*xi[j]+R(1e-30));
            REAL phase=atan2f(xi[j],xr[j])*R(180.0)/R(3.14159265);
            REAL vdb=(mag>R(1e-30))?R(20.0)*log10f(mag):-R(600.0);
            printf("%-12s %-12s ",real_to_str(vdb,'f',4),real_to_str(phase,'f',3));
        }
        printf("\n");

        free(ar);free(ai);free(br);free(bi);free(xr);free(xi);free(vfixed_ac);

        /* Next frequency */
        if(is_dec||is_oct) freq*=fstep; else freq+=fstep;
    }
    free(vs_is_float);
}

/* ===== TRAN Solver ===== */
static void tran_solve(Circuit *c, BSIM4Param *const *pp_arr, REAL tstop, REAL tstep) {
    REAL *v=calloc(c->nn,sizeof(REAL)), *iv=calloc(c->nv,sizeof(REAL));
    REAL *v_prev=calloc(c->nn,sizeof(REAL));
    REAL *cap_i=calloc(c->nc>0?c->nc:1,sizeof(REAL));
    /* P4.2: MOSFET intrinsic capacitance TRAN history [nm*3] */
    int nm3=c->nm*3;
    REAL *mos_v_prev=calloc(nm3>0?nm3:1,sizeof(REAL));
    REAL *mos_cap_i=calloc(nm3>0?nm3:1,sizeof(REAL));

    /* DC operating point (tran_dt=0 disables all companion models) */
    c->tran_dt=R(0.0);
    c->tran_v_prev=NULL; c->tran_cap_i=NULL;
    c->tran_mos_v_prev=NULL; c->tran_mos_cap_i=NULL;
    int dc_iters=dc_solve(v,iv,c,pp_arr,c->opt_maxiter,c->opt_abstol);
    printf("# DC OP: %d iterations\n",dc_iters);

    /* Save DC state as previous-step history for fixed capacitors */
    memcpy(v_prev,v,c->nn*sizeof(REAL));
    for(int j=0;j<c->nc;j++){
        Capacitor *cap=&c->cap[j];
        REAL Geq=R(2.0)*cap->c/tstep;
        cap_i[j]=Geq*(v[cap->p]-v[cap->n]);  /* cap current at t=0 */
    }
    /* P4.2: Initialize MOSFET capacitance history at DC operating point */
    for(int j=0;j<c->nm;j++){
        Mosfet *m=&c->mos[j];
        const BSIM4Param *pp=pp_arr[j];
        REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
        REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
        if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
        BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
        int j3=j*3;
        REAL inv_dt=R(1.0)/tstep;
        /* Cgs: gate↔source */
        mos_v_prev[j3+0]=vgs;
        mos_cap_i[j3+0]=R(2.0)*o.cgs*inv_dt*vgs;
        /* Cgd: gate↔drain */
        mos_v_prev[j3+1]=v[m->g]-v[m->d];
        mos_cap_i[j3+1]=R(2.0)*o.cgd*inv_dt*(v[m->g]-v[m->d]);
        /* Cgb: gate↔body */
        mos_v_prev[j3+2]=v[m->g]-v[m->b];
        mos_cap_i[j3+2]=R(2.0)*o.cgb*inv_dt*(v[m->g]-v[m->b]);
    }

    printf("\nIndex   time       ");
    for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("V(%-10s) ",c->nmap[j]);
    printf("\n");

    for(int step=0;step<MAX_TRAN && step*tstep<=tstop+R(1e-9);step++){
        REAL t_now=(REAL)(step+1)*tstep;
        c->tran_dt=tstep;
        c->tran_v_prev=v_prev; c->tran_cap_i=cap_i;
        c->tran_mos_v_prev=mos_v_prev; c->tran_mos_cap_i=mos_cap_i;
        /* P3.4: update time-varying Vsrc waveforms (SIN/PULSE/PWL) */
        for(int j=0;j<c->nv;j++) if(c->vsrc[j].wf_type!=WF_DC)
            c->vsrc[j].dc=vsrc_waveform(&c->vsrc[j], t_now);

        int iters=dc_solve(v,iv,c,pp_arr,c->opt_maxiter,c->opt_abstol);

        /* Update fixed capacitor current history for next step */
        if(c->nc>0){
            REAL inv_dt=R(1.0)/tstep;
            for(int j=0;j<c->nc;j++){
                Capacitor *cap=&c->cap[j];
                REAL Geq=R(2.0)*cap->c*inv_dt;
                REAL v_old=v_prev[cap->p]-v_prev[cap->n];
                REAL Ieq=-Geq*v_old-cap_i[j];
                cap_i[j]=Geq*(v[cap->p]-v[cap->n])+Ieq;
            }
        }
        /* P4.2: Update MOSFET capacitance history for next step */
        {
            REAL inv_dt=R(1.0)/tstep;
            for(int j=0;j<c->nm;j++){
                Mosfet *m=&c->mos[j];
                const BSIM4Param *pp=pp_arr[j];
                REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
                REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
                if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
                BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
                int j3=j*3;
                /* Cgs: gate↔source */
                {
                    REAL v_new=vgs, v_old=mos_v_prev[j3+0];
                    REAL i_old=mos_cap_i[j3+0];
                    REAL Geq=R(2.0)*o.cgs*inv_dt;
                    REAL Ieq=-Geq*v_old-i_old;
                    mos_cap_i[j3+0]=Geq*v_new+Ieq;
                    mos_v_prev[j3+0]=v_new;
                }
                /* Cgd: gate↔drain */
                {
                    REAL v_new=v[m->g]-v[m->d], v_old=mos_v_prev[j3+1];
                    REAL i_old=mos_cap_i[j3+1];
                    REAL Geq=R(2.0)*o.cgd*inv_dt;
                    REAL Ieq=-Geq*v_old-i_old;
                    mos_cap_i[j3+1]=Geq*v_new+Ieq;
                    mos_v_prev[j3+1]=v_new;
                }
                /* Cgb: gate↔body */
                {
                    REAL v_new=v[m->g]-v[m->b], v_old=mos_v_prev[j3+2];
                    REAL i_old=mos_cap_i[j3+2];
                    REAL Geq=R(2.0)*o.cgb*inv_dt;
                    REAL Ieq=-Geq*v_old-i_old;
                    mos_cap_i[j3+2]=Geq*v_new+Ieq;
                    mos_v_prev[j3+2]=v_new;
                }
            }
        }
        memcpy(v_prev,v,c->nn*sizeof(REAL));

        printf("%-5d   %-10s ",step+1,real_to_str(t_now,'e',4));
        for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-12s ",real_to_str(v[j],'f',6));
        printf(" # %d iters\n",iters);
    }

    c->tran_dt=R(0.0);
    c->tran_v_prev=NULL; c->tran_cap_i=NULL;
    c->tran_mos_v_prev=NULL; c->tran_mos_cap_i=NULL;
    free(v);free(iv);free(v_prev);free(cap_i);
    free(mos_v_prev);free(mos_cap_i);
}

/* ===== Float printer (P0.7: zero cvtss2sd) =====
 * Converts REAL → string using only float + integer arithmetic.
 * printf("%f", x) forces float→double promotion (cvtss2sd).
 * Using %s with this helper avoids ALL such conversions. */
static const char *real_to_str(REAL v, char fmt, int prec) {
    static char buf[8][32];  /* ring buffer: 8 slots cover any single printf (max 5) */
    static int idx = 0;
    char *b = buf[idx]; idx = (idx + 1) & 7;  /* round-robin */
    if(IS_NAN(v)){strcpy(b,"NaN");return b;}
    int sign=0;
    if(v<R(0.0)){sign=1;v=-v;}
    if(fmt=='e'){
        int exp=0;
        if(v>R(0.0)){
            while(v>=R(10.0)){v/=R(10.0);exp++;}
            while(v<R(1.0)){v*=R(10.0);exp--;}
        }
        int ipart=(int)v;
        REAL frac=v-(REAL)ipart;
        REAL s=R(1.0);for(int i=0;i<prec;i++)s*=R(10.0);
        int fpart=(int)(frac*s+R(0.5));
        if(fpart>=(int)s){ipart++;fpart=0;if(ipart>=10){ipart=1;exp++;}}
        snprintf(b,32,"%s%d.%0*de%+03d",sign?"-":"",ipart,prec,fpart,exp);
    }else{
        int ipart=(int)v;
        REAL frac=v-(REAL)ipart;
        REAL s=R(1.0);for(int i=0;i<prec;i++)s*=R(10.0);
        int fpart=(int)(frac*s+R(0.5));
        if(fpart>=(int)s){ipart++;fpart=0;}
        snprintf(b,32,"%s%d.%0*d",sign?"-":"",ipart,prec,fpart);
    }
    return b;
}

/* ===== Main ===== */
int main(int argc, char **argv) {
    printf("=== float_spice v2.5: Zero-Double Float-First SPICE Engine ===\n\n");
    if(argc<2){printf("Usage: %s <circuit.sp>\n",argv[0]);return 1;}

    Circuit *c=calloc(1,sizeof(Circuit));
    c->res=calloc(MAX_ELEMS,sizeof(Resistor)); c->mos=calloc(MAX_ELEMS,sizeof(Mosfet));
    c->vsrc=calloc(MAX_ELEMS,sizeof(Vsource)); c->cap=calloc(MAX_ELEMS,sizeof(Capacitor));
    c->isrc=calloc(MAX_ELEMS,sizeof(Isource));
    c->dio =calloc(MAX_ELEMS,sizeof(Diode));
    c->nn=1;strcpy(c->nmap[0],"0");c->ngnd=0;
    /* Default options (overridden by .option lines) */
    c->opt_gmin=R(1e-12); c->opt_abstol=R(1e-6); c->opt_reltol=R(1e-3);
    c->opt_maxiter=200; c->temp=R(300.15);  /* P2.8: 100→200 for multi-transistor circuits */

    parse_netlist(c,argv[1]);
    printf("Circuit: %s\n  Nodes: %d  Res: %d  MOSFETs: %d  Vsrcs: %d  Caps: %d\n",
           argv[1],c->nn,c->nr,c->nm,c->nv,c->nc);

    BSIM4Param pp_nmos=bsim4_default(), pp_pmos=bsim4_default();
    /* PMOS defaults: negate Vth, use hole mobility (SPICE convention) */
    pp_pmos.vth0=R(-0.62261);
    pp_pmos.u0  =R(0.015);
    for(int i=0;i<c->nmodel;i++){
        if(strstr(c->models[i].type,"nmos")||c->models[i].type[0]=='n'){
            bsim4_from_model(&pp_nmos,&c->models[i]);
            printf("  NMOS: %s vth0=%s u0=%s toxe=%s\n",
                   c->models[i].name,
                   real_to_str(pp_nmos.vth0,'f',4),
                   real_to_str(pp_nmos.u0,'f',4),
                   real_to_str(pp_nmos.toxe,'e',2));
        }
        if(strstr(c->models[i].type,"pmos")||c->models[i].type[0]=='p'){
            bsim4_from_model(&pp_pmos,&c->models[i]);
            printf("  PMOS: %s vth0=%s u0=%s toxe=%s\n",
                   c->models[i].name,
                   real_to_str(pp_pmos.vth0,'f',4),
                   real_to_str(pp_pmos.u0,'f',4),
                   real_to_str(pp_pmos.toxe,'e',2));
        }
    }
    /* Resolve per-device model pointers: each MOSFET gets its correct BSIM4Param */
    BSIM4Param *mos_pp[MAX_ELEMS];
    for(int j=0;j<c->nm;j++){
        Model *mod=find_model(c,c->mos[j].model);
        if(mod && (strstr(mod->type,"pmos")||mod->type[0]=='p')){
            mos_pp[j]=&pp_pmos;
        }else{
            mos_pp[j]=&pp_nmos;  /* default to NMOS if model not found */
        }
    }

    if(c->do_ac){
        /* P5.2: AC analysis — DC OP first, then frequency sweep */
        printf("\nDC Operating Point (for AC):\n");
        REAL *v_ac=calloc(c->nn,sizeof(REAL)),*iv_ac=calloc(c->nv,sizeof(REAL));
        int iters=dc_solve(v_ac,iv_ac,c,mos_pp,c->opt_maxiter,c->opt_abstol);
        printf("  DC convergence: %d iterations\n",iters);
        ac_solve(c,mos_pp,v_ac,iv_ac);
        free(v_ac);free(iv_ac);
    }
    if(c->do_tran){
        printf("\nTRAN: tstop=%s tstep=%s\n",
               real_to_str(c->tran_tstop,'e',4),real_to_str(c->tran_tstep,'e',4));
        tran_solve(c,mos_pp,c->tran_tstop,c->tran_tstep);
    } else if(c->do_dc && c->dc_src[0]){
        /* Find sweep source(s) */
        int sidx=-1, sidx2=-1;
        for(int j=0;j<c->nv;j++){if(strstr(c->vsrc[j].name,c->dc_src)){sidx=j;break;}}
        if(sidx<0) for(int j=0;j<c->nv;j++){if(strstr(c->dc_src,c->vsrc[j].name)){sidx=j;break;}}
        if(c->dc_nested && c->dc_src2[0]){
            for(int j=0;j<c->nv;j++){if(strstr(c->vsrc[j].name,c->dc_src2)){sidx2=j;break;}}
            if(sidx2<0) for(int j=0;j<c->nv;j++){if(strstr(c->dc_src2,c->vsrc[j].name)){sidx2=j;break;}}
        }
        if(c->dc_nested && sidx2>=0){
            /* --- Nested DC sweep (P3.5): outer=src1, inner=src2 --- */
            printf("\nNested DC Sweep:\n");
            printf("  Outer: %s from %s to %s step %s\n",
                   c->dc_src, real_to_str(c->dc_start,'f',4),
                   real_to_str(c->dc_stop,'f',4), real_to_str(c->dc_step,'f',4));
            printf("  Inner: %s from %s to %s step %s\n\n",
                   c->dc_src2, real_to_str(c->dc_start2,'f',4),
                   real_to_str(c->dc_stop2,'f',4), real_to_str(c->dc_step2,'f',4));
            printf("%-10s %-10s ",c->dc_src,c->dc_src2);
            for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("V(%-8s) ",c->nmap[j]);
            printf("\n");
            int swcnt=0;
            for(REAL sv1=c->dc_start;sv1<=c->dc_stop+R(1e-9)&&swcnt<MAX_SWEEP;sv1+=c->dc_step){
                c->vsrc[sidx].dc=sv1;
                for(REAL sv2=c->dc_start2;sv2<=c->dc_stop2+R(1e-9)&&swcnt<MAX_SWEEP;sv2+=c->dc_step2,swcnt++){
                    c->vsrc[sidx2].dc=sv2;
                    REAL *v=calloc(c->nn,sizeof(REAL)),*iv=calloc(c->nv,sizeof(REAL));
                    int it=dc_solve(v,iv,c,mos_pp,100,R(1e-6));
                    printf("%-10s %-10s ",real_to_str(sv1,'f',4),real_to_str(sv2,'f',4));
                    for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-10s ",real_to_str(v[j],'f',6));
                    printf(" # %d\n",it);
                    free(v);free(iv);
                }
            }
        }else{
            /* --- Single DC sweep --- */
            printf("\nDC Sweep: %s from %s to %s step %s\n",
                   c->dc_src,
                   real_to_str(c->dc_start,'f',4),
                   real_to_str(c->dc_stop,'f',4),
                   real_to_str(c->dc_step,'f',4));
            printf("Sweep    ");
            for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("V(%-10s) ",c->nmap[j]);
            printf("\n");
            int swcnt=0;
            for(REAL sv=c->dc_start;sv<=c->dc_stop+R(1e-9)&&swcnt<MAX_SWEEP;sv+=c->dc_step,swcnt++){
                if(sidx>=0) c->vsrc[sidx].dc=sv;
                REAL *v=calloc(c->nn,sizeof(REAL)),*iv=calloc(c->nv,sizeof(REAL));
                int it=dc_solve(v,iv,c,mos_pp,100,R(1e-6));
                printf("%-8s ",real_to_str(sv,'f',4));
                for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-12s ",real_to_str(v[j],'f',6));
                printf(" # %d iters\n",it);
                free(v);free(iv);
            }
        }
    } else {
        printf("\nDC Operating Point:\n");
        REAL *v=calloc(c->nn,sizeof(REAL)),*iv=calloc(c->nv,sizeof(REAL));
        int iters=dc_solve(v,iv,c,mos_pp,c->opt_maxiter,c->opt_abstol);
        printf("  DC convergence: %d iterations\n",iters);
        /* P5.1: populate device parameter cache for @device[param] */
        emit_device_param_table(c,v,mos_pp);
        /* P5.1: re-evaluate let expressions with actual voltages */
        re_eval_lets(c,v,iv,mos_pp,R(0.0));
        /* P3.1: print requested values from .control block */
        if(c->nprint>0){
            printf("\n  --- Requested output (.control print) ---\n");
            for(int k=0;k<c->nprint;k++){
                char w=c->prints[k].what[0];
                if(w=='v'||w=='d'||w=='p'){
                    /* P5.2: 'd'=vdb, 'p'=vp; in DC context print raw voltage */
                    int found=0;
                    for(int j=0;j<c->nn;j++){
                        if(!strcmp(c->nmap[j],c->prints[k].name))
                            {printf("  v(%s) = %s\n",c->prints[k].name,
                                    real_to_str(v[j],'f',6));found=1;break;}
                    }
                    if(!found){
                        /* P5.1: check let variables */
                        int lfound=0;
                        for(int j=0;j<c->nlet;j++){
                            if(!strcmp(c->let_names[j],c->prints[k].name))
                                {printf("  %s = %s\n",c->let_names[j],
                                        real_to_str(c->let_vals[j],'f',6));lfound=1;break;}
                        }
                        if(!lfound) printf("  v(%s) = ??\n",c->prints[k].name);
                    }
                }else{
                    int found=0;
                    for(int j=0;j<c->nv;j++){
                        if(!strcmp(c->vsrc[j].name,c->prints[k].name))
                            {printf("  i(%s) = %s\n",c->prints[k].name,
                                    real_to_str(iv[j],'e',6));found=1;break;}
                    }
                    /* also check current sources */
                    if(!found){for(int j=0;j<c->ni;j++){
                        if(!strcmp(c->isrc[j].name,c->prints[k].name))
                            {printf("  i(%s) = %s\n",c->prints[k].name,
                                    real_to_str(c->isrc[j].dc,'e',6));found=1;break;}
                    }}
                    if(!found){
                        /* P5.1: check let variables */
                        int lfound=0;
                        for(int j=0;j<c->nlet;j++){
                            if(!strcmp(c->let_names[j],c->prints[k].name))
                                {printf("  %s = %s\n",c->let_names[j],
                                        real_to_str(c->let_vals[j],'f',6));lfound=1;break;}
                        }
                        if(!lfound) printf("  i(%s) = ??\n",c->prints[k].name);
                    }
                }
            }
        }
        /* P4.3: ngspice-compatible output format.
         * Headers use "Node    Voltage" / "Source    Current" conventions
         * so that compare_fp.py can parse float_spice output with the same
         * regex patterns used for ngspice raw output. */
        printf("\n\tNode\tVoltage\n\t----\t-------\n");
        for(int j=0;j<c->nn;j++) printf("\t%-12s\t%s\n",c->nmap[j],real_to_str(v[j],'f',6));
        printf("\n\tSource\tCurrent\n\t------\t-------\n");
        for(int j=0;j<c->nv;j++) printf("\t%-12s\t%s\n",c->vsrc[j].name,real_to_str(iv[j],'e',6));
        printf("\n\tDevice\tParameters\n\t------\t----------\n");
        for(int j=0;j<c->nm;j++){
            Mosfet *m=&c->mos[j];
            const BSIM4Param *pp=mos_pp[j];
            REAL vgs=v[m->g]-v[m->s],vds=v[m->d]-v[m->s],vbs=v[m->b]-v[m->s];
            REAL weff=m->w-R(2.0)*pp->wint,leff=m->l-R(2.0)*pp->lint;
            if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
            BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp,c->temp);
            printf("  device %-15s Ids=%s  gm=%s  gds=%s  vth=%s  vdsat=%s\n",
                   m->name,
                   real_to_str(o.ids,'e',6),
                   real_to_str(o.gm,'e',6),
                   real_to_str(o.gds,'e',6),
                   real_to_str(o.vth,'f',6),
                   real_to_str(o.vdsat,'f',6));
        }
        free(v);free(iv);
    }
    printf("\n[Done]\n");
    free(c->res);free(c->mos);free(c->vsrc);free(c->cap);free(c->isrc);
    free(c->dio);free(c);
    return 0;
}
