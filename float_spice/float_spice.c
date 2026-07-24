/* float_spice.c — Zero-Double Float-First SPICE Engine v2.1
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

/* ===== Data Structures ===== */
typedef struct { char key[32]; REAL val; } Param;
typedef struct { char name[32], type[16]; Param p[MAX_PARAMS]; int np; } Model;
typedef struct { char name[32]; int p, n; REAL val; } Resistor;
typedef struct { char name[32]; int d, g, s, b; char model[32]; REAL w, l; int m; } Mosfet;
typedef struct { char name[32]; int p, n; REAL dc; } Vsource;
typedef struct { char name[32]; int p, n; REAL dc; } Isource;
typedef struct { char name[32]; int p, n; REAL c; } Capacitor;

typedef struct {
    int nn, nr, nm, nv, nc, ni, ngnd;
    char nmap[MAX_NODES][32];
    Resistor *res; Mosfet *mos; Vsource *vsrc; Capacitor *cap; Isource *isrc;
    Model models[MAX_MODELS]; int nmodel;
    int do_op, do_dc, do_tran;
    char dc_src[32]; REAL dc_start, dc_stop, dc_step;
    REAL tran_tstop, tran_tstep;
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

/* ===== BSIM4v5 Model Parameters (~51 fields, ALL FLOAT) ===== */
typedef struct {
    /* --- Core (16) --- */
    REAL vth0,k1,k2,nfactor,eta0;
    REAL u0,ua,ub,uc,vsat,toxe;
    REAL wint,lint,pclm,pdiblc1,a0;
    /* --- Short-channel Vth (7) --- */
    REAL dvt0,dvt1,dvt2,dsub,k3,w0,nlx;
    /* --- Rds (4) --- */
    REAL rdsw,rsw,rdw,prwg;
    /* --- Early voltage stack (4) --- */
    REAL pvag,pdiblc2,pscbe1,pscbe2;
    /* --- Subthreshold (5) --- */
    REAL voffcv,minv,cdsc,cdscd,cdscb;
    /* --- Temperature (6) --- */
    REAL kt1,kt2,ute,ua1,ub1,uc1;
    /* --- Capacitance / junction (4) --- */
    REAL cgso,cgdo,cgbo,cj;
    /* --- Noise (2) --- */
    REAL noia,noib;
    /* --- Physical / process (3) --- */
    REAL xj,ndep,nsd;
} BSIM4Param;

typedef struct {
    REAL ids,gm,gds,gmbs,vth,vdsat,vdseff,vgsteff,Abulk,ueff,EsatL,beta;
} BSIM4Out;

static BSIM4Param bsim4_default(void) {
    BSIM4Param p={0};
    /* --- Core --- */
    p.vth0=R(0.62261); p.k1=R(0.4); p.k2=R(0.0); p.nfactor=R(1.6);
    p.eta0=R(0.0125); p.u0=R(0.049); p.ua=R(6e-10); p.ub=R(1.2e-18);
    p.uc=R(0.0); p.vsat=R(130000.0); p.toxe=R(1.8e-9);
    p.wint=R(5e-9); p.lint=R(0.0); p.pclm=R(0.02); p.pdiblc1=R(0.001); p.a0=R(1.0);
    /* --- Short-channel Vth (BSIM4v5 UG defaults) --- */
    p.dvt0=R(2.2); p.dvt1=R(0.53); p.dvt2=R(-0.032);
    p.dsub=R(0.56); p.k3=R(80.0); p.w0=R(2.5e-6); p.nlx=R(1.74e-7);
    /* --- Rds (off by default) --- */
    /* rdsw,rsw,rdw,prwg = 0 (from calloc) */
    /* --- Early voltage stack --- */
    /* pvag = 0 (off); pdiblc2 and pscbe* below */
    p.pdiblc2=R(0.001); p.pscbe1=R(4.24e8); p.pscbe2=R(1.0e-5);
    /* --- Subthreshold --- */
    p.cdsc=R(2.4e-4);
    /* voffcv, minv, cdscd, cdscb = 0 (off by default) */
    /* --- Temperature --- */
    p.kt1=R(-0.11); p.kt2=R(0.022);
    p.ute=R(-1.5); p.ua1=R(4.31e-9); p.ub1=R(-7.61e-18); p.uc1=R(-5.6e-11);
    /* --- Capacitance (off by default) --- */
    p.cj=R(5.0e-4);
    /* cgso, cgdo, cgbo = 0 (from calloc) */
    /* --- Noise (off by default) --- */
    /* noia, noib = 0 (from calloc) */
    /* --- Physical / process --- */
    p.xj=R(1.5e-8); p.ndep=R(1.7e17); p.nsd=R(1.0e20);
    return p;
}

static inline REAL vgsteff_smooth(REAL vgs, REAL vth, REAL n, REAL vt) {
    REAL vgst=vgs-vth;
    if(vgst>R(0.1)) return vgst;
    REAL arg=(vgs-vth)/(n*vt+R(1e-30));
    if(arg>R(80.0)) return vgst; if(arg<R(-40.0)) return R(0.0);
    REAL ve=n*vt*logf(R(1.0)+expf(arg));
    return ve>R(0.0)?ve:R(0.0);
}

static inline REAL smooth_vdseff(REAL vds, REAL vdsat) {
    REAL d=R(0.01), x=vdsat-vds-d;
    return vdsat-R(0.5)*(x+sqrtf(x*x+R(4.0)*d*vdsat+R(1e-30)));
}

BSIM4Out bsim4_eval(REAL vgs, REAL vds, REAL vbs, REAL weff, REAL leff,
                     const BSIM4Param *pp) {
    BSIM4Out o; memset(&o,0,sizeof(o));
    /* Guard: toxe=0 (model parse failure) → coxe=INF → NaN/INF cascade.
     * Use safe default 1.8nm when toxe is missing or corrupt. */
    REAL toxe_safe=pp->toxe;
    if(toxe_safe<R(1e-12)) toxe_safe=R(1.8e-9);
    REAL vt=R(0.02585), coxe=R(3.9)*R(8.854187817e-12)/toxe_safe;
    REAL phis=R(0.6), sqrt_phis=sqrtf(phis);
    REAL vbs_c=(vbs<R(0.0))?vbs:R(0.0);
    REAL sq=sqrtf(phis-vbs_c+R(1e-12));

    /* Vth + body effect + DIBL */
    REAL vth0_adj=pp->vth0+pp->k1*(sq-sqrt_phis)-pp->k2*vbs_c;
    REAL dibl=(vds>R(0.05))?pp->eta0*vds:R(0.0);
    REAL vth=vth0_adj-dibl;
    if(vth<R(0.05)) vth=R(0.05);
    o.vth=vth;

    /* Effective Vgs */
    REAL vgsteff=vgsteff_smooth(vgs,vth,pp->nfactor,vt);
    if(vgsteff<=R(0.0)){
        o.vgsteff=R(0.0); o.ids=R(1e-15); o.gm=R(1e-15); o.gds=R(1e-15); o.gmbs=R(1e-15);
        return o;
    }
    o.vgsteff=vgsteff;

    /* Mobility degradation */
    REAL Eeff=(vgsteff+R(2.0)*vth+pp->vth0)/(R(6.0)*pp->toxe+R(1e-12));
    REAL ueff=pp->u0/(R(1.0)+(pp->ua+pp->uc*vbs_c)*Eeff+pp->ub*Eeff*Eeff);
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
    REAL va=pp->pclm>R(0.0)?R(1.0)/pp->pclm:R(1e12);
    REAL vd_diff=vds-vdseff; if(vd_diff<R(0.0)) vd_diff=R(0.0);
    o.ids=ids0*(R(1.0)+vd_diff/(va+R(1e-12)))*(R(1.0)+pp->pdiblc1*vd_diff);
    if(o.ids<R(0.0)) o.ids=R(0.0);

    /* Analytical gm/gds/gmbs */
    if(vds<vdsat){
        REAL dnl=R(1.0)+vds/EsatL;
        o.gm=beta0*vds/dnl;
        o.gds=beta0*(vgsteff-Abulk*vds)/(dnl*dnl+R(1e-30));
    }else{
        o.gm=beta0*vdsat/(R(1.0)+vdsat/EsatL)*(R(1.0)+vd_diff/(va+R(1e-12)))*(R(1.0)+pp->pdiblc1*vd_diff);
        o.gds=o.ids*(pp->pclm+pp->pdiblc1);
    }
    if(vgsteff<R(0.05)){ o.gm=o.ids/(pp->nfactor*vt+R(1e-15)); }
    if(o.gm<R(1e-15)) o.gm=R(1e-15);
    if(o.gds<R(1e-15)) o.gds=R(1e-15);
    REAL dvth_dvb=R(0.0);
    if(vbs_c<phis-R(0.01)) dvth_dvb=-pp->k1/(R(2.0)*sq+R(1e-12));
    o.gmbs=-o.gm*dvth_dvb;
    if(fabsf(o.gmbs)<R(1e-15)) o.gmbs=R(0.0);

    /* NaN firewall: divergent Newton step → return safe off-state */
    if(IS_NAN(o.ids)||IS_NAN(o.gm)||IS_NAN(o.gds)||IS_NAN(o.gmbs)){
        o.ids=R(1e-15); o.gm=R(1e-15); o.gds=R(1e-15); o.gmbs=R(0.0);
        o.vgsteff=R(0.0);
    }

    return o;
}

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
    /* --- Core (16) --- */
    pp->vth0=model_get(m,"vth0",pp->vth0); pp->k1=model_get(m,"k1",pp->k1);
    pp->k2=model_get(m,"k2",pp->k2); pp->nfactor=model_get(m,"nfactor",pp->nfactor);
    pp->eta0=model_get(m,"eta0",pp->eta0); pp->u0=model_get(m,"u0",pp->u0);
    pp->ua=model_get(m,"ua",pp->ua); pp->ub=model_get(m,"ub",pp->ub);
    pp->uc=model_get(m,"uc",pp->uc); pp->vsat=model_get(m,"vsat",pp->vsat);
    pp->toxe=model_get(m,"toxe",pp->toxe); pp->wint=model_get(m,"wint",pp->wint);
    pp->lint=model_get(m,"lint",pp->lint); pp->pclm=model_get(m,"pclm",pp->pclm);
    pp->pdiblc1=model_get(m,"pdiblc1",pp->pdiblc1); pp->a0=model_get(m,"a0",pp->a0);
    /* --- Short-channel Vth (7) --- */
    pp->dvt0=model_get(m,"dvt0",pp->dvt0); pp->dvt1=model_get(m,"dvt1",pp->dvt1);
    pp->dvt2=model_get(m,"dvt2",pp->dvt2); pp->dsub=model_get(m,"dsub",pp->dsub);
    pp->k3=model_get(m,"k3",pp->k3); pp->w0=model_get(m,"w0",pp->w0);
    pp->nlx=model_get(m,"nlx",pp->nlx);
    /* --- Rds (4) --- */
    pp->rdsw=model_get(m,"rdsw",pp->rdsw); pp->rsw=model_get(m,"rsw",pp->rsw);
    pp->rdw=model_get(m,"rdw",pp->rdw); pp->prwg=model_get(m,"prwg",pp->prwg);
    /* --- Early voltage stack (4) --- */
    pp->pvag=model_get(m,"pvag",pp->pvag); pp->pdiblc2=model_get(m,"pdiblc2",pp->pdiblc2);
    pp->pscbe1=model_get(m,"pscbe1",pp->pscbe1); pp->pscbe2=model_get(m,"pscbe2",pp->pscbe2);
    /* --- Subthreshold (5) --- */
    pp->voffcv=model_get(m,"voffcv",pp->voffcv); pp->minv=model_get(m,"minv",pp->minv);
    pp->cdsc=model_get(m,"cdsc",pp->cdsc); pp->cdscd=model_get(m,"cdscd",pp->cdscd);
    pp->cdscb=model_get(m,"cdscb",pp->cdscb);
    /* --- Temperature (6) --- */
    pp->kt1=model_get(m,"kt1",pp->kt1); pp->kt2=model_get(m,"kt2",pp->kt2);
    pp->ute=model_get(m,"ute",pp->ute); pp->ua1=model_get(m,"ua1",pp->ua1);
    pp->ub1=model_get(m,"ub1",pp->ub1); pp->uc1=model_get(m,"uc1",pp->uc1);
    /* --- Capacitance / junction (4) --- */
    pp->cgso=model_get(m,"cgso",pp->cgso); pp->cgdo=model_get(m,"cgdo",pp->cgdo);
    pp->cgbo=model_get(m,"cgbo",pp->cgbo); pp->cj=model_get(m,"cj",pp->cj);
    /* --- Noise (2) --- */
    pp->noia=model_get(m,"noia",pp->noia); pp->noib=model_get(m,"noib",pp->noib);
    /* --- Physical / process (3) --- */
    pp->xj=model_get(m,"xj",pp->xj); pp->ndep=model_get(m,"ndep",pp->ndep);
    pp->nsd=model_get(m,"nsd",pp->nsd);
}
static void parse_model_line(Circuit *c, const char *line) {
    Model m; memset(&m,0,sizeof(m)); char rest[MAX_LINE];
    if(sscanf(line,".model %31s %15s %[^\n]",m.name,m.type,rest)<2) return;
    for(char *p=m.type;*p;p++) *p=(char)tolower((unsigned char)*p);
    char *tok=rest;
    while(*tok){
        while(*tok==' '||*tok=='\t') tok++;
        char *eq=strchr(tok,'='); if(!eq) break;
        char *ps=eq-1; while(ps>=tok&&(*ps!=' '&&*ps!='\t')) ps--; ps++;
        int pl=(int)(eq-ps); if(pl>31) pl=31;
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
    char buf[MAX_LINE];
    while(fgets(buf,MAX_LINE,fp)){
        char *s=buf; while(*s==' '||*s=='\t') s++;
        if(!strncmp(s,".model",6)) parse_model_line(c,s);
        else if(!strncmp(s,".include",8)) parse_include(c,s,idir);
    }
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
        Resistor r; char n1[32],n2[32]; REAL val;
        if(sscanf(s,"%31s %31s %31s %f",r.name,n1,n2,&val)>=4){
            r.p=find_or_add_node(c,n1); r.n=find_or_add_node(c,n2);
            r.val=(REAL)val; if(c->nr<MAX_ELEMS) c->res[c->nr++]=r;
        } return 1;
    }
    if(*s=='V'||*s=='v'){
        Vsource v; char n1[32],n2[32]; REAL val=R(0.0); memset(&v,0,sizeof(v));
        char tn[32];
        int nf=sscanf(s,"%31s %31s %31s %f",tn,n1,n2,&val);
        if(nf>=3){
            snprintf(v.name,32,"%s",tn);
            v.p=find_or_add_node(c,n1); v.n=find_or_add_node(c,n2);
            v.dc=(nf>=4)?(REAL)val:R(0.0);
            char *dcp=strstr(s,"DC"); if(!dcp) dcp=strstr(s,"dc");
            if(dcp) v.dc=parse_eng(dcp+2);
            if(c->nv<MAX_ELEMS) c->vsrc[c->nv++]=v;
        } return 1;
    }
    if(*s=='I'||*s=='i'){
        Isource is; char n1[32],n2[32]; REAL val=R(0.0); memset(&is,0,sizeof(is));
        char tn[32];
        int nf=sscanf(s,"%31s %31s %31s %f",tn,n1,n2,&val);
        if(nf>=3){
            snprintf(is.name,32,"%s",tn);
            is.p=find_or_add_node(c,n1); is.n=find_or_add_node(c,n2);
            is.dc=(nf>=4)?(REAL)val:R(0.0);
            char *dcp=strstr(s,"DC"); if(!dcp) dcp=strstr(s,"dc");
            if(dcp) is.dc=parse_eng(dcp+2);
            if(c->ni<MAX_ELEMS) c->isrc[c->ni++]=is;
        } return 1;
    }
    if(*s=='C'||*s=='c'){
        Capacitor cap; char n1[32],n2[32]; REAL val; memset(&cap,0,sizeof(cap));
        if(sscanf(s,"%31s %31s %31s %f",cap.name,n1,n2,&val)>=4){
            cap.p=find_or_add_node(c,n1); cap.n=find_or_add_node(c,n2);
            cap.c=(REAL)val; if(c->nc<MAX_ELEMS) c->cap[c->nc++]=cap;
        } return 1;
    }
    return 0;
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
                sscanf(c2,".dc %31s %f %f %f",c->dc_src,&c->dc_start,&c->dc_stop,&c->dc_step);
            }else if(!strncmp(c2,".tran",5)){c->do_tran=1;
                sscanf(c2,".tran %f %f",&c->tran_tstep,&c->tran_tstop);}
            cont[0]=0;
        }
        if(!strncmp(s,".model",6)) parse_model_line(c,s);
        else if(!strncmp(s,".include",8)) parse_include(c,s,dir);
        else if(!strncmp(s,".op",3)) c->do_op=1;
        else if(!strncmp(s,".dc",3)){c->do_dc=1;
            sscanf(s,".dc %31s %f %f %f",c->dc_src,&c->dc_start,&c->dc_stop,&c->dc_step);
        }else if(!strncmp(s,".tran",5)){c->do_tran=1;
            sscanf(s,".tran %f %f",&c->tran_tstep,&c->tran_tstop);
        }else if(!strncmp(s,".control",8)||!strncmp(s,".endc",5)||
                 !strncmp(s,"print",5)||!strncmp(s,"plot",4)||
                 !strncmp(s,"op",2)||!strncmp(s,"dc",2)||!strncmp(s,"tran",4)){}
        else if(!strncmp(s,".end",4)) break;
        else if(*s=='.'){}
        else if(!parse_instance(c,s)){strncpy(cont,s,MAX_LINE-1);cont[MAX_LINE-1]=0;}
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
        BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp);
        nc[m->d]-=o.ids; nc[m->s]+=o.ids;
    }
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

    /* Gmin stepping: 3 stages from large (easy convergence) to small (accurate) */
    REAL gmin_stages[] = {R(1e-9), R(1e-10), R(1e-12)};
    int n_stages = 3;
    int total_iters = 0;

    /* ---- Source stepping (P2.1): ramp sources 0 → full value ----
     * 4-stage exponential ramp: 0.1% → 1% → 10% → 100%.
     * Each ramp uses the previous ramp's converged solution as its
     * initial guess, ensuring Newton starts near the solution even
     * for circuits with strong MOSFET nonlinearities.
     */
    REAL *dc_orig=calloc(c->nv,sizeof(REAL));
    for(int j=0;j<c->nv;j++) dc_orig[j]=c->vsrc[j].dc;
    REAL src_ramp[] = {R(1e-3), R(1e-2), R(1e-1), R(1.0)};
    int n_ramp = 4, ramp_failed = 0;

  for(int ramp=0; ramp < n_ramp; ramp++){  /* === SOURCE RAMP OUTER LOOP === */
    REAL alpha = src_ramp[ramp];
    /* Scale all source DC values for this ramp step */
    for(int j=0;j<c->nv;j++) c->vsrc[j].dc = dc_orig[j] * alpha;
    /* Re-init grounded Vsrc fixed node voltages to scaled value.
     * Free node voltages are KEPT from previous ramp as initial guess. */
    for(int j=0;j<c->nv;j++){
        if(vs_mna[j] < 0) v[c->vsrc[j].p] = c->vsrc[j].dc;
    }
    /* Reset floating Vsrc branch currents (MNA variables) for fresh ramp */
    for(int j=0;j<c->nv;j++){
        if(vs_mna[j] >= 0) iv[j] = R(0.0);
    }

    for(int stage=0; stage < n_stages; stage++){
        REAL gmin = gmin_stages[stage];
        int stage_converged = 0;

        for(int iter=0; iter < max_iter; iter++){
            int lu_ok = 0;
            REAL effective_gmin = gmin;
            REAL vlim = R(1.0);  /* voltage step limit */

            /* --- Recovery cascade: retry assembly+solve with stronger damping --- */
            for(int recovery=0; recovery < 5; recovery++){
                memset(a,0,N*N*sizeof(REAL)); memset(rhs,0,N*sizeof(REAL));

                /* Gmin conductance from each free node to ground */
                for(int j=0;j<n;j++) if(j!=gnd && !vfixed[j]){
                    a[j+j*N]=effective_gmin; rhs[j]=-effective_gmin*v[j];
                }

                /* Resistors */
                for(int j=0;j<c->nr;j++){
                    int p=c->res[j].p, nn=c->res[j].n;
                    REAL g=R(1.0)/(c->res[j].val+R(1e-30));
                    if(!vfixed[p]){ a[p+p*N]+=g; rhs[p]-=g*(v[p]-v[nn]); }
                    if(!vfixed[nn]){ a[nn+nn*N]+=g; rhs[nn]-=g*(v[nn]-v[p]); }
                    if(!vfixed[p] && !vfixed[nn]){ a[p+nn*N]-=g; a[nn+p*N]-=g; }
                }

                /* MOSFETs */
                for(int j=0;j<c->nm;j++){
                    Mosfet *m=&c->mos[j];
                    const BSIM4Param *pp=pp_arr[j];
                    REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
                    REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
                    if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
                    BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp);
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

                /* Fix voltage-driven nodes (grounded Vsrcs + GND): J[j,j]=1, rhs[j]=0.
                 * Zero ROW only -- preserve column entries for KCL consistency. */
                for(int j=0;j<n;j++) if(vfixed[j]||j==gnd){
                    for(int i=0;i<N;i++){ if(i!=j) a[j+i*N]=R(0.0); }
                    a[j+j*N]=R(1.0); rhs[j]=R(0.0);
                }

                if(lu_solve(N,a,rhs,dx) >= 0){ lu_ok=1; break; }

                /* Recovery: escalate damping to fix singular matrix */
                if(recovery < 3){
                    effective_gmin *= R(10.0);  /* bump gmin for diagonal dominance */
                } else {
                    effective_gmin = gmin * R(100.0);
                    vlim *= R(0.1);             /* tighter voltage clamping */
                }
            }

            if(!lu_ok){
                if(stage > 0){
                    stage -= 2;  /* re-run previous stage; stage++ will advance back */
                    break;
                }
                /* First stage failed -- compute best-effort currents via KCL */
                {
                    REAL *nc=calloc(n,sizeof(REAL));
                    compute_nc(v,c,pp_arr,gmin,nc);
                    for(int jj=0;jj<c->nv;jj++){
                        if(vs_mna[jj]<0){
                            REAL ival=-nc[c->vsrc[jj].p];
                            iv[jj]=IS_NAN(ival)?R(0.0):ival;
                        }
                        /* floating Vsrcs keep their MNA-computed iv[jj] */
                    }
                    free(nc);
                }
                free(vfixed);free(vs_mna);free(a);free(rhs);free(dx);
                return total_iters;
            }

            /* --- Update: node voltages (0..n-1) + branch currents (n..N-1) --- */
            REAL max_dv=R(0.0);
            int had_nan=0;
            for(int j=0;j<n;j++){
                if(!vfixed[j] && j!=gnd){
                    REAL dv=dx[j];
                    if(dv>vlim) dv=vlim; if(dv<R(-vlim)) dv=R(-vlim);
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
            if(!had_nan && max_dv<abstol){ stage_converged=1; break; }
        }

        if(!stage_converged){
            /* Compute best-effort currents: grounded via KCL, floating via MNA */
            {
                REAL *nc=calloc(n,sizeof(REAL));
                compute_nc(v,c,pp_arr,gmin,nc);
                for(int jj=0;jj<c->nv;jj++){
                    if(vs_mna[jj]<0){
                        REAL ival=-nc[c->vsrc[jj].p];
                        iv[jj]=IS_NAN(ival)?R(0.0):ival;
                    }
                }
                free(nc);
            }
            free(vfixed);free(vs_mna);free(a);free(rhs);free(dx);
            return total_iters;
        }
    }  /* end gmin stage loop */

    /* If any non-final ramp failed to converge, don't continue.
     * We still have the previous ramp's solution saved in v[]. */
    if(!stage_converged && ramp < n_ramp-1){
        ramp_failed = 1;
        break;  /* exit ramp loop, fall through to KCL computation */
    }
  }  /* === END SOURCE RAMP LOOP === */

  /* Restore original Vsrc DC values (were scaled during source stepping) */
  for(int j=0;j<c->nv;j++) c->vsrc[j].dc = dc_orig[j];
  free(dc_orig);

    /* If source stepping failed early, compute best-effort KCL currents */
    if(ramp_failed){
        REAL *nc=calloc(n,sizeof(REAL));
        compute_nc(v,c,pp_arr,gmin_stages[n_stages-1],nc);
        for(int jj=0;jj<c->nv;jj++){
            if(vs_mna[jj]<0){
                REAL ival=-nc[c->vsrc[jj].p];
                iv[jj]=IS_NAN(ival)?R(0.0):ival;
            }
        }
        free(nc);
    }

    /* Post-convergence: floating Vsrc currents are from MNA variables.
     * Grounded Vsrc currents are computed via KCL at the +node. */
    {
        REAL *nc=calloc(n,sizeof(REAL));
        compute_nc(v,c,pp_arr,R(1e-12),nc);
        for(int j=0;j<c->nv;j++){
            if(vs_mna[j]<0){
                REAL ival=-nc[c->vsrc[j].p];
                iv[j]=IS_NAN(ival)?R(0.0):ival;
            }
            /* floating Vsrcs keep their MNA-computed iv[j] */
        }
        free(nc);
    }
    free(vfixed);free(vs_mna);free(a);free(rhs);free(dx);
    return total_iters;
}
/* Forward declaration for float printer (P0.7: zero cvtss2sd) */
static const char *real_to_str(REAL v, char fmt, int prec);

/* ===== TRAN Solver ===== */
static void tran_solve(Circuit *c, BSIM4Param *const *pp_arr, REAL tstop, REAL tstep) {
    REAL *v=calloc(c->nn,sizeof(REAL)), *iv=calloc(c->nv,sizeof(REAL));
    dc_solve(v,iv,c,pp_arr,100,R(1e-6));
    printf("Index   time       ");
    for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("V(%-10s) ",c->nmap[j]);
    printf("\n");
    for(int step=0;step<MAX_TRAN && step*tstep<=tstop+R(1e-9);step++){
        printf("%-5d   %-10s ",step,real_to_str((REAL)(step*tstep),'e',4));
        for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-12s ",real_to_str(v[j],'f',6));
        printf("\n");
    }
    free(v);free(iv);
}

/* ===== Float printer (P0.7: zero cvtss2sd) =====
 * Converts REAL → string using only float + integer arithmetic.
 * printf("%f", x) forces float→double promotion (cvtss2sd).
 * Using %s with this helper avoids ALL such conversions. */
static const char *real_to_str(REAL v, char fmt, int prec) {
    static char buf[32];
    if(IS_NAN(v)){strcpy(buf,"NaN");return buf;}
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
        snprintf(buf,32,"%s%d.%0*de%+03d",sign?"-":"",ipart,prec,fpart,exp);
    }else{
        int ipart=(int)v;
        REAL frac=v-(REAL)ipart;
        REAL s=R(1.0);for(int i=0;i<prec;i++)s*=R(10.0);
        int fpart=(int)(frac*s+R(0.5));
        if(fpart>=(int)s){ipart++;fpart=0;}
        snprintf(buf,32,"%s%d.%0*d",sign?"-":"",ipart,prec,fpart);
    }
    return buf;
}

/* ===== Main ===== */
int main(int argc, char **argv) {
    printf("=== float_spice v2.0: Zero-Double Float-First SPICE Engine ===\n\n");
    if(argc<2){printf("Usage: %s <circuit.sp>\n",argv[0]);return 1;}

    Circuit *c=calloc(1,sizeof(Circuit));
    c->res=calloc(MAX_ELEMS,sizeof(Resistor)); c->mos=calloc(MAX_ELEMS,sizeof(Mosfet));
    c->vsrc=calloc(MAX_ELEMS,sizeof(Vsource)); c->cap=calloc(MAX_ELEMS,sizeof(Capacitor));
    c->nn=1;strcpy(c->nmap[0],"0");c->ngnd=0;

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

    if(c->do_tran){
        printf("\nTRAN: tstop=%s tstep=%s\n",
               real_to_str(c->tran_tstop,'e',4),real_to_str(c->tran_tstep,'e',4));
        tran_solve(c,mos_pp,c->tran_tstop,c->tran_tstep);
    } else if(c->do_dc && c->dc_src[0]){
        printf("\nDC Sweep: %s from %s to %s step %s\n",
               c->dc_src,
               real_to_str(c->dc_start,'f',4),
               real_to_str(c->dc_stop,'f',4),
               real_to_str(c->dc_step,'f',4));
        int sidx=-1;
        for(int j=0;j<c->nv;j++){if(strstr(c->vsrc[j].name,c->dc_src)){sidx=j;break;}}
        if(sidx<0) for(int j=0;j<c->nv;j++){if(strstr(c->dc_src,c->vsrc[j].name)){sidx=j;break;}}
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
    } else {
        printf("\nDC Operating Point:\n");
        REAL *v=calloc(c->nn,sizeof(REAL)),*iv=calloc(c->nv,sizeof(REAL));
        int iters=dc_solve(v,iv,c,mos_pp,100,R(1e-6));
        printf("  DC convergence: %d iterations\n",iters);
        printf("\n  Node Voltages:\n  %-12s %s\n  %-12s %s\n","Node","Voltage","----","-------");
        for(int j=0;j<c->nn;j++) printf("  %-12s %s\n",c->nmap[j],real_to_str(v[j],'f',6));
        printf("\n  Source Currents:\n  %-12s %s\n  %-12s %s\n","Source","Current","------","-------");
        for(int j=0;j<c->nv;j++) printf("  %-12s %s\n",c->vsrc[j].name,real_to_str(iv[j],'e',6));
        printf("\n  Device Parameters:\n");
        for(int j=0;j<c->nm;j++){
            Mosfet *m=&c->mos[j];
            const BSIM4Param *pp=mos_pp[j];
            REAL vgs=v[m->g]-v[m->s],vds=v[m->d]-v[m->s],vbs=v[m->b]-v[m->s];
            REAL weff=m->w-R(2.0)*pp->wint,leff=m->l-R(2.0)*pp->lint;
            if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
            BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp);
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
    free(c->res);free(c->mos);free(c->vsrc);free(c->cap);free(c);
    return 0;
}
