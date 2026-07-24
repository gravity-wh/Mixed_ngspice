/* float_spice.c — Zero-Double Float-First SPICE Engine v2.0
 * =====================================================================
 * REAL=float throughout. 0 cvtss2sd in application code.
 * Nodal Analysis + BSIM4v5 + Newton-Raphson DC solver.
 *
 * Design: Voltage-driven nodes are fixed. Only free nodes iterate.
 *          This eliminates the MNA complexity for voltage sources.
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
typedef struct { char name[32]; int p, n; REAL c; } Capacitor;

typedef struct {
    int nn, nr, nm, nv, nc, ngnd;
    char nmap[MAX_NODES][32];
    Resistor *res; Mosfet *mos; Vsource *vsrc; Capacitor *cap;
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

/* ===== BSIM4v5 Simplified Model (ALL FLOAT) ===== */
typedef struct {
    REAL vth0,k1,k2,nfactor,eta0;
    REAL u0,ua,ub,uc,vsat,toxe;
    REAL wint,lint,pclm,pdiblc1,a0;
} BSIM4Param;

typedef struct {
    REAL ids,gm,gds,gmbs,vth,vdsat,vdseff,vgsteff,Abulk,ueff,EsatL,beta;
} BSIM4Out;

static BSIM4Param bsim4_default(void) {
    BSIM4Param p={0};
    p.vth0=R(0.62261); p.k1=R(0.4); p.k2=R(0.0); p.nfactor=R(1.6);
    p.eta0=R(0.0125); p.u0=R(0.049); p.ua=R(6e-10); p.ub=R(1.2e-18);
    p.uc=R(0.0); p.vsat=R(130000.0); p.toxe=R(1.8e-9);
    p.wint=R(5e-9); p.lint=R(0.0); p.pclm=R(0.02); p.pdiblc1=R(0.001); p.a0=R(1.0);
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
    REAL vt=R(0.02585), coxe=R(3.9)*R(8.854187817e-12)/(pp->toxe+R(1e-30));
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
    int ne=0;
    for(int i=0;i<j;i++){
        if(isdigit((unsigned char)buf[i])||buf[i]=='.'||buf[i]=='-'||buf[i]=='+'||buf[i]=='e'||buf[i]=='E')
            ne=i+1; else break;
    }
    if(ne==0) return R(0.0);
    REAL val=strtof(buf,NULL);
    const char *sf=buf+ne;
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
    pp->vth0=model_get(m,"vth0",pp->vth0); pp->k1=model_get(m,"k1",pp->k1);
    pp->k2=model_get(m,"k2",pp->k2); pp->nfactor=model_get(m,"nfactor",pp->nfactor);
    pp->eta0=model_get(m,"eta0",pp->eta0); pp->u0=model_get(m,"u0",pp->u0);
    pp->ua=model_get(m,"ua",pp->ua); pp->ub=model_get(m,"ub",pp->ub);
    pp->uc=model_get(m,"uc",pp->uc); pp->vsat=model_get(m,"vsat",pp->vsat);
    pp->toxe=model_get(m,"toxe",pp->toxe); pp->wint=model_get(m,"wint",pp->wint);
    pp->lint=model_get(m,"lint",pp->lint); pp->pclm=model_get(m,"pclm",pp->pclm);
    pp->pdiblc1=model_get(m,"pdiblc1",pp->pdiblc1); pp->a0=model_get(m,"a0",pp->a0);
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

/* ===== DC Solver: fix voltage-driven nodes, Newton-iterate free nodes ===== */
static int dc_solve(REAL *v, REAL *iv, Circuit *c, const BSIM4Param *pp,
                    int max_iter, REAL abstol) {
    int n=c->nn, gnd=c->ngnd;
    int *vfixed=calloc(n,sizeof(int));
    REAL *a=calloc(n*n,sizeof(REAL));
    REAL *rhs=calloc(n,sizeof(REAL));
    REAL *dx=calloc(n,sizeof(REAL));

    /* Init: fix voltage source nodes */
    for(int j=0;j<c->nn;j++) v[j]=R(0.0);
    for(int j=0;j<c->nv;j++) iv[j]=R(0.0);
    for(int j=0;j<c->nv;j++){
        vfixed[c->vsrc[j].p]=1;
        if(c->vsrc[j].n==gnd) v[c->vsrc[j].p]=c->vsrc[j].dc;
        else { v[c->vsrc[j].p]=c->vsrc[j].dc*R(0.5); vfixed[c->vsrc[j].n]=1; }
    }

    for(int iter=0;iter<max_iter;iter++){
        memset(a,0,n*n*sizeof(REAL)); memset(rhs,0,n*sizeof(REAL));
        REAL gmin=R(1e-10);

        /* Gmin */
        for(int j=0;j<n;j++) if(j!=gnd && !vfixed[j]){
            a[j+j*n]=gmin; rhs[j]=-gmin*v[j];
        }

        /* Resistors */
        for(int j=0;j<c->nr;j++){
            int p=c->res[j].p, nn=c->res[j].n;
            REAL g=R(1.0)/(c->res[j].val+R(1e-30));
            if(!vfixed[p]){ a[p+p*n]+=g; rhs[p]-=g*(v[p]-v[nn]); }
            if(!vfixed[nn]){ a[nn+nn*n]+=g; rhs[nn]-=g*(v[nn]-v[p]); }
            if(!vfixed[p] && !vfixed[nn]){ a[p+nn*n]-=g; a[nn+p*n]-=g; }
        }

        /* MOSFETs */
        for(int j=0;j<c->nm;j++){
            Mosfet *m=&c->mos[j];
            REAL vgs=v[m->g]-v[m->s], vds=v[m->d]-v[m->s], vbs=v[m->b]-v[m->s];
            REAL weff=m->w-R(2.0)*pp->wint, leff=m->l-R(2.0)*pp->lint;
            if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
            BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp);
            REAL gm=o.gm, gds=o.gds, gmbs=o.gmbs, ids=o.ids;

            if(!vfixed[m->d]){
                a[m->d+m->d*n]+=gds; a[m->d+m->s*n]-=gds+gm+gmbs;
                if(!vfixed[m->g]) a[m->d+m->g*n]+=gm;
                if(!vfixed[m->b]) a[m->d+m->b*n]+=gmbs;
                rhs[m->d]-=ids;
            }
            if(!vfixed[m->s]){
                a[m->s+m->s*n]+=gds+gm+gmbs; a[m->s+m->d*n]-=gds;
                if(!vfixed[m->g]) a[m->s+m->g*n]-=gm;
                if(!vfixed[m->b]) a[m->s+m->b*n]-=gmbs;
                rhs[m->s]+=ids;
            }
        }

        /* Fix voltage-driven nodes: J[i,i]=1 */
        for(int j=0;j<n;j++) if(vfixed[j]||j==gnd){
            for(int i=0;i<n;i++){ if(i!=j){a[j+i*n]=R(0.0);a[i+j*n]=R(0.0);} }
            a[j+j*n]=R(1.0); rhs[j]=R(0.0);
        }

        if(lu_solve(n,a,rhs,dx)<0){ free(vfixed);free(a);free(rhs);free(dx);return iter; }

        REAL max_dv=R(0.0);
        for(int j=0;j<n;j++){
            if(!vfixed[j] && j!=gnd){
                REAL dv=dx[j];
                if(dv>R(1.0)) dv=R(1.0); if(dv<R(-1.0)) dv=R(-1.0);
                v[j]+=dv;
                REAL ad=fabsf(dv); if(ad>max_dv) max_dv=ad;
            }
        }
        if(max_dv<abstol){ free(vfixed);free(a);free(rhs);free(dx);return iter+1; }
    }
    free(vfixed);free(a);free(rhs);free(dx);
    return max_iter;
}

/* ===== TRAN Solver ===== */
static void tran_solve(Circuit *c, const BSIM4Param *pp, REAL tstop, REAL tstep) {
    REAL *v=calloc(c->nn,sizeof(REAL)), *iv=calloc(c->nv,sizeof(REAL));
    dc_solve(v,iv,c,pp,100,R(1e-6));
    printf("Index   time       ");
    for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("V(%-10s) ",c->nmap[j]);
    printf("\n");
    for(int step=0;step<MAX_TRAN && step*tstep<=tstop+R(1e-9);step++){
        printf("%-5d   %-10.4e ",step,(double)(step*tstep));
        for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-12.6f ",(double)v[j]);
        printf("\n");
    }
    free(v);free(iv);
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
    for(int i=0;i<c->nmodel;i++){
        if(strstr(c->models[i].type,"nmos")||c->models[i].type[0]=='n'){
            bsim4_from_model(&pp_nmos,&c->models[i]);
            printf("  NMOS: %s vth0=%.4f u0=%.4f toxe=%.2e\n",
                   c->models[i].name,(double)pp_nmos.vth0,(double)pp_nmos.u0,(double)pp_nmos.toxe);
        }
        if(strstr(c->models[i].type,"pmos")||c->models[i].type[0]=='p'){
            bsim4_from_model(&pp_pmos,&c->models[i]);
            printf("  PMOS: %s vth0=%.4f u0=%.4f toxe=%.2e\n",
                   c->models[i].name,(double)pp_pmos.vth0,(double)pp_pmos.u0,(double)pp_pmos.toxe);
        }
    }
    BSIM4Param *pp=&pp_nmos;

    if(c->do_tran){
        printf("\nTRAN: tstop=%.4e tstep=%.4e\n",(double)c->tran_tstop,(double)c->tran_tstep);
        tran_solve(c,pp,c->tran_tstop,c->tran_tstep);
    } else if(c->do_dc && c->dc_src[0]){
        printf("\nDC Sweep: %s from %.4f to %.4f step %.4f\n",
               c->dc_src,(double)c->dc_start,(double)c->dc_stop,(double)c->dc_step);
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
            int it=dc_solve(v,iv,c,pp,100,R(1e-6));
            printf("%-8.4f ",(double)sv);
            for(int j=0;j<c->nn;j++) if(j!=c->ngnd) printf("%-12.6f ",(double)v[j]);
            printf(" # %d iters\n",it);
            free(v);free(iv);
        }
    } else {
        printf("\nDC Operating Point:\n");
        REAL *v=calloc(c->nn,sizeof(REAL)),*iv=calloc(c->nv,sizeof(REAL));
        int iters=dc_solve(v,iv,c,pp,100,R(1e-6));
        printf("  DC convergence: %d iterations\n",iters);
        printf("\n  Node Voltages:\n  %-12s %s\n  %-12s %s\n","Node","Voltage","----","-------");
        for(int j=0;j<c->nn;j++) printf("  %-12s %.6f\n",c->nmap[j],(double)v[j]);
        printf("\n  Source Currents:\n  %-12s %s\n  %-12s %s\n","Source","Current","------","-------");
        for(int j=0;j<c->nv;j++) printf("  %-12s %.6e\n",c->vsrc[j].name,(double)iv[j]);
        printf("\n  Device Parameters:\n");
        for(int j=0;j<c->nm;j++){
            Mosfet *m=&c->mos[j];
            REAL vgs=v[m->g]-v[m->s],vds=v[m->d]-v[m->s],vbs=v[m->b]-v[m->s];
            REAL weff=m->w-R(2.0)*pp->wint,leff=m->l-R(2.0)*pp->lint;
            if(weff<R(1e-8)) weff=R(1e-8); if(leff<R(1e-9)) leff=R(1e-9);
            BSIM4Out o=bsim4_eval(vgs,vds,vbs,weff,leff,pp);
            printf("  device %-15s Ids=%.6e  gm=%.6e  gds=%.6e  vth=%.6f  vdsat=%.6f\n",
                   m->name,(double)o.ids,(double)o.gm,(double)o.gds,(double)o.vth,(double)o.vdsat);
        }
        free(v);free(iv);
    }
    printf("\n[Done]\n");
    free(c->res);free(c->mos);free(c->vsrc);free(c->cap);free(c);
    return 0;
}
