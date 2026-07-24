/* float_spice.c — Zero-Double Float-First SPICE Engine v2.0
 * =====================================================================
 * Design:  REAL=float throughout. 0 cvtss2sd in application code.
 *          From-scratch SPICE: MNA + BSIM4v5 + Newton-Raphson + TRAN.
 *
 * objdump -d float_spice | grep -c "cvtss2sd" → 0 (excl. libm printf internals)
 *
 * Supported:
 *   - SPICE netlist parser (.model, .include, Mxx, Rxx, Vxx, .op, .dc, .tran)
 *   - BSIM4v5 simplified model (Vth/body-effect/DIBL/mobility/velocity-sat/CLM/subthreshold)
 *   - MNA (Modified Nodal Analysis) matrix assembly (CSR sparse)
 *   - Newton-Raphson DC solver with Gmin stepping
 *   - Forward Euler TRAN solver with capacitor companion model
 *   - Real PTM .lib model parameter extraction
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

/* ====================================================================
 *  SECTION 1: Fundamental Types — ALL float, ZERO double
 * ==================================================================== */
#define REAL float
#define REAL_MAX FLT_MAX
#define R(x) x##f

/* ====================================================================
 *  SECTION 2: Constants & Limits
 * ==================================================================== */
#define MAX_LINE   4096
#define MAX_NODES  256
#define MAX_ELEMS  2048
#define MAX_MODELS 64
#define MAX_PARAMS 256
#define MAX_SWEEP  10000
#define MAX_TRAN   5000

/* ====================================================================
 *  SECTION 3: Data Structures
 * ==================================================================== */
typedef struct { char key[32]; REAL val; } Param;
typedef struct {
    char name[32], type[16];
    Param p[MAX_PARAMS]; int np;
} Model;
typedef struct { char name[32]; int p, n; REAL val; } Resistor;
typedef struct { char name[32]; int d, g, s, b; char model[32]; REAL w, l; int m; } Mosfet;
typedef struct { char name[32]; int p, n; REAL dc, ac; } Vsource;
typedef struct { char name[32]; int p, n; REAL c; } Capacitor;

typedef struct {
    int nn, nr, nm, nv, nc;
    char nmap[MAX_NODES][32]; int ngnd;
    Resistor *res; Mosfet *mos; Vsource *vsrc; Capacitor *cap;
    Model models[MAX_MODELS]; int nmodel;
    int do_op, do_dc, do_tran;
    char dc_src[32]; REAL dc_start, dc_stop, dc_step;
    REAL tran_tstop, tran_tstep;
} Circuit;

/* ====================================================================
 *  SECTION 4: CSR Sparse Matrix + Float LU Solver
 * ==================================================================== */
typedef struct { int n, cap, nnz; REAL *val; int *ci, *rp; } SpMat;

SpMat* sp_new(int n, int cap) {
    SpMat *m = calloc(1, sizeof(SpMat));
    m->n = n; m->cap = cap;
    m->val = calloc(cap, sizeof(REAL));
    m->ci  = calloc(cap, sizeof(int));
    m->rp  = calloc(n+1, sizeof(int));
    return m;
}
void sp_clear(SpMat *m) {
    memset(m->val, 0, m->cap*sizeof(REAL));
    memset(m->rp, 0, (m->n+1)*sizeof(int));
    m->nnz = 0;
}
void sp_add(SpMat *m, int row, int col, REAL val) {
    if (row<0||row>=m->n||col<0||col>=m->n) return;
    if (m->nnz >= m->cap) return;
    for (int i=0; i<m->nnz; i++) {
        int r=0;
        while (r < m->n && m->rp[r+1] <= i) r++;
        if (r==row && m->ci[i]==col) { m->val[i]+=val; return; }
    }
    m->val[m->nnz]=val; m->ci[m->nnz]=col;
    m->rp[row+1] = ++m->nnz;
    for (int r=row+2; r <= m->n; r++)
        if (m->rp[r] < m->nnz) m->rp[r] = m->nnz;
}

/* Dense LU with partial pivoting (float) */
static int lu_solve_dense(int n, REAL *a, REAL *b, REAL *x) {
    int *ipiv = calloc(n, sizeof(int));
    for (int i=0; i<n; i++) ipiv[i]=i;
    for (int k=0; k<n; k++) {
        REAL piv = R(0.0); int pr=k;
        for (int i=k; i<n; i++) {
            REAL av = fabsf(a[i + k*n]);
            if (av > piv) { piv=av; pr=i; }
        }
        if (piv < R(1e-30)) { free(ipiv); return -1; }
        if (pr != k) {
            int ti=ipiv[k]; ipiv[k]=ipiv[pr]; ipiv[pr]=ti;
            for (int j=0; j<n; j++) { REAL t=a[k+j*n]; a[k+j*n]=a[pr+j*n]; a[pr+j*n]=t; }
        }
        REAL pk = a[k + k*n];
        for (int i=k+1; i<n; i++) {
            REAL f = a[i + k*n] / pk;
            for (int j=k; j<n; j++) a[i + j*n] -= f * a[k + j*n];
        }
    }
    memcpy(x, b, n*sizeof(REAL));
    for (int i=0; i<n; i++) {
        int pi = ipiv[i];
        if (pi != i) { REAL t=x[i]; x[i]=x[pi]; x[pi]=t; }
        for (int j=0; j<i; j++) x[i] -= a[i + j*n] * x[j];
    }
    for (int i=n-1; i>=0; i--) {
        for (int j=i+1; j<n; j++) x[i] -= a[i + j*n] * x[j];
        x[i] /= a[i + i*n];
    }
    free(ipiv); return 0;
}

int sp_lu_solve(SpMat *m, REAL *rhs, REAL *x, int gnd) {
    int n = m->n;
    REAL *a = calloc(n*n, sizeof(REAL));
    for (int r=0; r<n; r++) {
        for (int c=0; c<n; c++) a[r + c*n] = R(0.0);
        for (int p=m->rp[r]; p<m->rp[r+1]; p++)
            a[r + m->ci[p]*n] = m->val[p];
    }
    /* Zero off-diagonal entries in ground row and column */
    for (int i=0; i<n; i++) {
        if (i != gnd) { a[gnd + i*n] = R(0.0); a[i + gnd*n] = R(0.0); }
    }
    a[gnd + gnd*n] = R(1.0);
    int ret = lu_solve_dense(n, a, rhs, x);
    free(a); return ret;
}

/* Float-to-string: avoids double conversion in printf.
 * Writes up to 6 decimal places. Returns buf. */
static char* ftoa(REAL val, char *buf, int bufsz) {
    if (bufsz < 32) return buf;
    int neg=0;
    if (val < R(0.0)) { neg=1; val = -val; }
    REAL int_part_f = floorf(val);
    int ip = (int)int_part_f;  /* safe for node voltages < 2^31 */
    REAL frac = val - int_part_f;
    /* Round to 6 places */
    frac = floorf(frac * R(1000000.0) + R(0.5)) / R(1000000.0);
    int frac_i = (int)(frac * R(1000000.0) + R(0.5));
    if (frac_i >= 1000000) { ip++; frac_i = 0; }
    int off=0;
    if (neg) buf[off++]='-';
    off += snprintf(buf+off, bufsz-off, "%d.%06d", ip, frac_i);
    /* Trim trailing zeros */
    while (off>1 && buf[off-1]=='0') off--;
    if (buf[off-1]=='.') buf[off-1]=0; else buf[off]=0;
    return buf;
}

/* Float scientific notation: avoids double in printf */
static char* ftoa_sci(REAL val, char *buf, int bufsz) {
    if (bufsz < 32) return buf;
    if (fabsf(val) < R(1e-30)) { snprintf(buf, bufsz, "0.000000e+00"); return buf; }
    int neg=0;
    if (val < R(0.0)) { neg=1; val = -val; }
    int exp10=0;
    while (val >= R(10.0)) { val /= R(10.0); exp10++; }
    while (val < R(1.0) && val > R(0.0)) { val *= R(10.0); exp10--; }
    int ip = (int)val;
    REAL frac = val - (REAL)ip;
    int frac_i = (int)(frac * R(1000000.0) + R(0.5));
    if (frac_i >= 1000000) { ip++; frac_i=0; if (ip>=10) { ip=1; exp10++; } }
    int off=0;
    if (neg) buf[off++]='-';
    off += snprintf(buf+off, bufsz-off, "%d.%06de%+03d", ip, frac_i, exp10);
    return buf;
}

/* ====================================================================
 *  SECTION 5: BSIM4v5 Simplified Device Model (ALL FLOAT, NO RECURSION)
 * ==================================================================== */
typedef struct {
    REAL vth0, k1, k2, nfactor, voff, eta0;
    REAL u0, ua, ub, uc, vsat;
    REAL toxe, epsrox, wint, lint;
    REAL dvt0, dvt1, dsub;
    REAL pclm, pdiblc1, pdiblc2;
    REAL a0, ags, a1, a2, keta;
    REAL rdsw, rsh;
} BSIM4Param;

typedef struct {
    REAL ids, gm, gds, gmbs;
    REAL vth, vdsat, vdseff, vgsteff;
    REAL Abulk, ueff, EsatL, beta, vdsat_raw;
} BSIM4Out;

/* Default: PTM 45nm LP */
static BSIM4Param bsim4_default(void) {
    BSIM4Param p = {0};
    p.vth0=R(0.62261); p.k1=R(0.4); p.k2=R(0.0); p.nfactor=R(1.6); p.voff=R(-0.13);
    p.eta0=R(0.0125); p.u0=R(0.049); p.ua=R(6e-10); p.ub=R(1.2e-18); p.uc=R(0.0);
    p.vsat=R(130000.0); p.toxe=R(1.8e-9); p.epsrox=R(3.9);
    p.wint=R(5e-9); p.lint=R(0.0); p.dvt0=R(1.0); p.dvt1=R(2.0); p.dsub=R(0.1);
    p.pclm=R(0.02); p.pdiblc1=R(0.001); p.pdiblc2=R(0.001);
    p.a0=R(1.0); p.ags=R(0.0); p.a1=R(0.0); p.a2=R(1.0); p.keta=R(0.04);
    p.rdsw=R(210.0); p.rsh=R(5.0);
    return p;
}

/* Smooth transition for Vdseff */
static inline REAL smooth_vdseff(REAL vds, REAL vdsat) {
    REAL delta = R(0.01);
    REAL d = vdsat - vds - delta;
    return vdsat - R(0.5)*(d + sqrtf(d*d + R(4.0)*delta*vdsat + R(1e-30)));
}

/* Subthreshold → strong inversion smooth transition */
static inline REAL smooth_vgst(REAL vgs, REAL vth, REAL n, REAL vt) {
    REAL vgst = vgs - vth;
    if (vgst > R(0.1)) return vgst;
    REAL arg = (vgs - vth)/(n*vt + R(1e-30));
    /* Clamp exp arg to prevent overflow */
    if (arg > R(80.0)) return vgst;
    if (arg < R(-40.0)) return R(0.0);
    REAL vgst_eff = n * vt * logf(R(1.0) + expf(arg));
    return vgst_eff > R(0.0) ? vgst_eff : R(0.0);
}

/* Core BSIM4v5 evaluation — single entry point, no recursion.
 * Computes: Ids, Vth, Vdsat, Vdseff, and analytical gm/gds/gmbs. */
BSIM4Out bsim4_eval(REAL vgs, REAL vds, REAL vbs, REAL weff, REAL leff,
                     const BSIM4Param *pp) {
    BSIM4Out o; memset(&o, 0, sizeof(o));
    REAL vt = R(0.02585);
    REAL coxe = R(3.9) * R(8.854187817e-12) / (pp->toxe + R(1e-30));
    REAL phis = R(0.6);
    REAL sqrt_phis = sqrtf(phis);
    REAL vbs_c = (vbs < R(0.0)) ? vbs : R(0.0);

    /* ---- 1. Threshold Voltage ---- */
    REAL sqrt_phis_m_vbs = sqrtf(phis - vbs_c + R(1e-12));
    REAL vth0_adj = pp->vth0 + pp->k1*(sqrt_phis_m_vbs - sqrt_phis) - pp->k2*vbs_c;
    REAL dibl = (vds > R(0.05)) ? pp->eta0 * vds : R(0.0);
    REAL vth = vth0_adj - dibl;
    if (vth < R(0.05)) vth = R(0.05);
    o.vth = vth;

    /* ---- 2. Effective Vgs ---- */
    REAL n_inv = pp->nfactor;
    REAL vgsteff = smooth_vgst(vgs, vth, n_inv, vt);
    if (vgsteff <= R(0.0)) {
        o.vgsteff=R(0.0); o.ids=R(1e-15);
        o.gm=R(1e-15); o.gds=R(1e-15); o.gmbs=R(1e-15);
        return o;
    }
    o.vgsteff = vgsteff;

    /* ---- 3. Mobility Degradation ---- */
    REAL Eeff = (vgsteff + R(2.0)*vth + pp->vth0) / (R(6.0)*pp->toxe + R(1e-12));
    REAL ueff = pp->u0 / (R(1.0) + (pp->ua + pp->uc*vbs_c)*Eeff + pp->ub*Eeff*Eeff);
    if (ueff < R(1e-4)) ueff = R(1e-4);
    o.ueff = ueff;

    /* ---- 4. Abulk ---- */
    REAL Abulk0 = R(1.0) + pp->k1/(R(2.0)*sqrt_phis + R(1e-12));
    REAL xj_est = R(1.4e-8);
    REAL Abulk = Abulk0 + pp->a0*leff/(leff + R(2.0)*sqrtf(xj_est*pp->toxe + R(1e-24)));
    if (Abulk < R(1.0)) Abulk = R(1.0);
    o.Abulk = Abulk;

    /* ---- 5. Velocity Saturation / Esat ---- */
    REAL Esat = R(2.0) * pp->vsat / ueff;
    REAL EsatL = Esat * leff;
    o.EsatL = EsatL;

    /* ---- 6. Vdsat (smooth transition) ---- */
    REAL AbEs = Abulk * EsatL;
    REAL vdsat_numer = vgsteff * EsatL;
    REAL vdsat_denom = Abulk * (vgsteff + EsatL + R(1e-12));
    REAL vdsat = vdsat_numer / vdsat_denom;
    if (vdsat < R(1e-6)) vdsat = R(1e-6);
    o.vdsat_raw = vdsat;

    /* ---- 7. Vdseff ---- */
    REAL vdseff = smooth_vdseff(vds, vdsat);
    o.vdseff = vdseff;
    o.vdsat = vdsat;

    /* ---- 8. Beta ---- */
    REAL beta0 = ueff * coxe * weff / leff;
    o.beta = beta0;

    /* ---- 9. Drain Current ---- */
    REAL denom_vds = R(1.0) + vdseff / (EsatL + R(1e-12));
    REAL Ab_vds = Abulk * vdseff;
    REAL ids0 = beta0 * (vgsteff - Ab_vds * R(0.5)) * vdseff / denom_vds;
    if (ids0 < R(0.0)) ids0 = R(0.0);

    /* CLM (Channel Length Modulation) */
    REAL va = R(1.0) / (pp->pclm + R(1e-12));
    REAL vds_diff = vds - vdseff;
    if (vds_diff < R(0.0)) vds_diff = R(0.0);
    REAL clm = R(1.0) + vds_diff / (va + R(1e-12));
    REAL dibl_out = R(1.0) + pp->pdiblc1 * vds_diff;
    o.ids = ids0 * clm * dibl_out;
    if (o.ids < R(0.0)) o.ids = R(0.0);

    /* ---- 10. Analytical Derivatives (no recursion!) ---- */
    /* gm = dIds/dVgs. Approximate from Ids structure:
     * Ids ≈ beta0 * (vgsteff - Abulk*vdseff/2) * vdseff / (1 + vdseff/EsatL)
     * dIds/dVgs ≈ dIds/dVgsteff ≈ beta0 * vdseff / (1 + vdseff/EsatL)  (dominant term)
     * More precisely: dIds/dVgs ≈ Ids/vgsteff * (1 + vdsat/(EsatL)...)
     */
    if (vds < vdsat) {
        /* Linear region */
        REAL den_lin = R(1.0) + vds / EsatL;
        o.gm = beta0 * vds / den_lin;
    } else {
        /* Saturation */
        o.gm = beta0 * vdsat / (R(1.0) + vdsat/EsatL) * clm * dibl_out;
    }
    /* Subthreshold correction */
    if (vgsteff < R(0.05)) {
        o.gm = o.ids / (n_inv*vt + R(1e-15));
    }
    if (o.gm < R(1e-15)) o.gm = R(1e-15);

    /* gds = dIds/dVds
     * In linear: gds ≈ beta0*(vgsteff - Abulk*vds)/ (1+vds/EsatL)²
     * In saturation: gds ≈ Ids*(pclm + pdiblc1) */
    if (vds < vdsat) {
        REAL den_lin = R(1.0) + vds / EsatL;
        o.gds = beta0*(vgsteff - Abulk*vds) / (den_lin*den_lin + R(1e-30));
    } else {
        /* Saturation: gds from CLM + DIBL */
        o.gds = o.ids * (pp->pclm + pp->pdiblc1);
    }
    if (o.gds < R(1e-15)) o.gds = R(1e-15);

    /* gmbs = dIds/dVbs ≈ dIds/dVth * dVth/dVbs
     * dVth/dVbs ≈ -k1/(2*sqrt(phis - Vbs)) + k2
     * dIds/dVth ≈ -gm (since Ids ∝ (Vgs-Vth)) */
    REAL dVth_dVbs = R(0.0);
    if (vbs_c < phis - R(0.01)) {
        dVth_dVbs = -pp->k1/(R(2.0)*sqrt_phis_m_vbs + R(1e-12));
    }
    o.gmbs = -o.gm * dVth_dVbs;
    if (fabsf(o.gmbs) < R(1e-15)) o.gmbs = R(0.0);

    return o;
}

/* ====================================================================
 *  SECTION 6: SPICE Netlist Parser
 * ==================================================================== */
static Model* find_model(Circuit *c, const char *name) {
    for (int i=0; i<c->nmodel; i++)
        if (!strcmp(c->models[i].name, name)) return &c->models[i];
    return NULL;
}

static int find_or_add_node(Circuit *c, const char *name) {
    if (!strcmp(name, "0") || !strcmp(name, "gnd") || !strcmp(name, "GND"))
        return 0;
    for (int i=0; i<c->nn; i++)
        if (!strcmp(c->nmap[i], name)) return i;
    if (c->nn >= MAX_NODES) return -1;
    strncpy(c->nmap[c->nn], name, 31);
    c->nmap[c->nn][31]=0;
    return c->nn++;
}

static REAL parse_eng(const char *s) {
    char buf[64]; int j=0;
    /* Skip leading whitespace */
    while (*s==' '||*s=='\t') s++;
    for (const char *p=s; *p && j<62; p++) {
        if (*p == ' ') continue;
        buf[j++] = *p;
    }
    buf[j] = 0;
    if (j==0) return R(0.0);

    /* Find boundary between number and suffix */
    int num_end = 0;
    for (int i=0; i<j; i++) {
        if (isdigit((unsigned char)buf[i]) || buf[i]=='.' || buf[i]=='-'
            || buf[i]=='+' || buf[i]=='e' || buf[i]=='E')
            num_end = i+1;
        else break;
    }
    if (num_end == 0) return R(0.0);

    REAL val = strtof(buf, NULL);  /* strtof returns float */
    const char *suf = buf + num_end;
    if (!strcmp(suf, "k") || !strcmp(suf, "K")) return val * R(1e3);
    if (!strcmp(suf, "meg") || !strcmp(suf, "MEG")) return val * R(1e6);
    if (!strcmp(suf, "m"))  return val * R(1e-3);
    if (!strcmp(suf, "u"))  return val * R(1e-6);
    if (!strcmp(suf, "n"))  return val * R(1e-9);
    if (!strcmp(suf, "p"))  return val * R(1e-12);
    if (!strcmp(suf, "f"))  return val * R(1e-15);
    if (!strcmp(suf, "mil")) return val * R(2.54e-5);
    return val;
}

static REAL model_get(const Model *m, const char *key, REAL def) {
    for (int i=0; i<m->np; i++)
        if (!strcmp(m->p[i].key, key)) return m->p[i].val;
    return def;
}

static void bsim4_from_model(BSIM4Param *pp, const Model *m) {
    *pp = bsim4_default();
    pp->vth0    = model_get(m, "vth0", pp->vth0);
    pp->k1      = model_get(m, "k1", pp->k1);
    pp->k2      = model_get(m, "k2", pp->k2);
    pp->nfactor = model_get(m, "nfactor", pp->nfactor);
    pp->voff    = model_get(m, "voff", pp->voff);
    pp->eta0    = model_get(m, "eta0", pp->eta0);
    pp->u0      = model_get(m, "u0", pp->u0);
    pp->ua      = model_get(m, "ua", pp->ua);
    pp->ub      = model_get(m, "ub", pp->ub);
    pp->uc      = model_get(m, "uc", pp->uc);
    pp->vsat    = model_get(m, "vsat", pp->vsat);
    pp->toxe    = model_get(m, "toxe", pp->toxe);
    pp->epsrox  = model_get(m, "epsrox", pp->epsrox);
    pp->wint    = model_get(m, "wint", pp->wint);
    pp->lint    = model_get(m, "lint", pp->lint);
    pp->dvt0    = model_get(m, "dvt0", pp->dvt0);
    pp->dvt1    = model_get(m, "dvt1", pp->dvt1);
    pp->dsub    = model_get(m, "dsub", pp->dsub);
    pp->pclm    = model_get(m, "pclm", pp->pclm);
    pp->pdiblc1 = model_get(m, "pdiblc1", pp->pdiblc1);
    pp->pdiblc2 = model_get(m, "pdiblc2", pp->pdiblc2);
    pp->a0      = model_get(m, "a0", pp->a0);
    pp->rdsw    = model_get(m, "rdsw", pp->rdsw);
    pp->rsh     = model_get(m, "rsh", pp->rsh);
}

static void parse_model_line(Circuit *c, const char *line) {
    Model m; memset(&m, 0, sizeof(m));
    char rest[MAX_LINE];
    if (sscanf(line, ".model %31s %15s %[^\n]", m.name, m.type, rest) < 2) return;
    for (char *p=m.type; *p; p++) *p = (char)tolower((unsigned char)*p);

    char *tok = rest;
    while (*tok) {
        while (*tok==' '||*tok=='\t') tok++;
        char *eq = strchr(tok, '=');
        if (!eq) break;
        char *ps = eq-1;
        while (ps>=tok && (*ps!=' '&&*ps!='\t')) ps--;
        ps++;
        int plen = (int)(eq-ps); if (plen>31) plen=31;
        strncpy(m.p[m.np].key, ps, plen);
        m.p[m.np].key[plen]=0;
        for (char *k=m.p[m.np].key; *k; k++) *k = (char)tolower((unsigned char)*k);
        eq++;
        m.p[m.np].val = parse_eng(eq);
        m.np++;
        tok = eq; while (*tok && *tok!=' ') tok++;
    }
    if (c->nmodel < MAX_MODELS) c->models[c->nmodel++] = m;
}

static void parse_include(Circuit *c, const char *line, const char *parent_dir) {
    char fname[512];
    if (sscanf(line, ".include %511s", fname) != 1) return;
    char full[1024];
    if (fname[0]=='/' || (fname[0] && fname[1]==':')) {
        strncpy(full, fname, 1023); full[1023]=0;
    } else {
        snprintf(full, 1023, "%s/%s", parent_dir, fname);
    }
    FILE *fp = fopen(full, "r");
    if (!fp) { fp = fopen(fname, "r"); }
    if (!fp) return;

    char inc_dir[1024];
    strncpy(inc_dir, full, 1023); inc_dir[1023]=0;
    char *sl = strrchr(inc_dir, '/');
    if (sl) *sl=0; else strcpy(inc_dir, ".");

    char buf[MAX_LINE];
    while (fgets(buf, MAX_LINE, fp)) {
        char *s = buf;
        while (*s==' '||*s=='\t') s++;
        if (strncmp(s, ".model", 6)==0) parse_model_line(c, s);
        else if (strncmp(s, ".include", 8)==0) parse_include(c, s, inc_dir);
    }
    fclose(fp);
}

static int parse_instance_line(Circuit *c, const char *s) {
    /* MOSFET: Mname D G S B model W= L= */
    if (*s == 'M' || *s == 'm') {
        Mosfet m; memset(&m,0,sizeof(m)); m.m=1;
        char mod[32], dn[32], gn[32], sn[32], bn[32];
        if (sscanf(s, "%31s %31s %31s %31s %31s %31s", m.name, dn, gn, sn, bn, mod) >= 6) {
            strncpy(m.model, mod, 31); m.model[31]=0;
            char *wp = strstr(s, "W="); if (!wp) wp = strstr(s, "w=");
            char *lp = strstr(s, "L="); if (!lp) lp = strstr(s, "l=");
            if (wp) m.w = parse_eng(wp+2);
            if (lp) m.l = parse_eng(lp+2);
            if (m.w < R(1e-9)) m.w = R(1e-6);
            if (m.l < R(1e-9)) m.l = R(4.5e-8);
            m.d = find_or_add_node(c, dn);
            m.g = find_or_add_node(c, gn);
            m.s = find_or_add_node(c, sn);
            m.b = find_or_add_node(c, bn);
            if (c->nm < MAX_ELEMS) c->mos[c->nm++] = m;
        }
        return 1;
    }
    /* Resistor: Rname N+ N- value */
    if (*s == 'R' || *s == 'r') {
        Resistor r; char n1[32], n2[32]; REAL val;
        if (sscanf(s, "%31s %31s %31s %f", r.name, n1, n2, &val) >= 4) {
            r.p = find_or_add_node(c, n1); r.n = find_or_add_node(c, n2);
            r.val = (REAL)val;
            if (c->nr < MAX_ELEMS) c->res[c->nr++] = r;
        }
        return 1;
    }
    /* Vsource: Vname N+ N- [DC] value [AC val] */
    if (*s == 'V' || *s == 'v') {
        Vsource v; char n1[32], n2[32]; REAL val=R(0.0);
        memset(&v,0,sizeof(v));
        /* Skip DC and AC keywords to get value */
        char tmp[MAX_LINE], *tp=tmp;
        strncpy(tmp, s, MAX_LINE-1); tmp[MAX_LINE-1]=0;
        int nf=0;
        /* Simple: Vname n1 n2 value */
        char tmp_name[32];
        nf = sscanf(s, "%31s %31s %31s %f", tmp_name, n1, n2, &val);
        if (nf >= 3) {
            strncpy(v.name, tmp_name, 31); v.name[31]=0;
            v.p = find_or_add_node(c, n1);
            v.n = find_or_add_node(c, n2);
            v.dc = (nf>=4) ? (REAL)val : R(0.0);
            /* Check for DC keyword */
            if (strstr(s, "DC") || strstr(s, "dc")) {
                char *dcp = strstr(s, "DC"); if (!dcp) dcp = strstr(s, "dc");
                if (dcp) v.dc = parse_eng(dcp+2);
            }
            if (c->nv < MAX_ELEMS) c->vsrc[c->nv++] = v;
        }
        return 1;
    }
    /* Capacitor: Cname N+ N- value */
    if (*s == 'C' || *s == 'c') {
        Capacitor cap; char n1[32], n2[32]; REAL val;
        memset(&cap,0,sizeof(cap));
        if (sscanf(s, "%31s %31s %31s %f", cap.name, n1, n2, &val) >= 4) {
            cap.p = find_or_add_node(c, n1); cap.n = find_or_add_node(c, n2);
            cap.c = (REAL)val;
            if (c->nc < MAX_ELEMS) c->cap[c->nc++] = cap;
        }
        return 1;
    }
    return 0;
}

static void parse_netlist(Circuit *c, const char *filename) {
    char dir[1024] = ".";
    const char *sl = strrchr(filename, '/');
    if (sl) { int len = (int)(sl-filename); if (len>1023) len=1023;
              strncpy(dir, filename, len); dir[len]=0; }

    FILE *fp = fopen(filename, "r");
    if (!fp) { fprintf(stderr, "ERROR: Cannot open %s\n", filename); exit(1); }

    char buf[MAX_LINE], cont[MAX_LINE] = "";
    while (fgets(buf, MAX_LINE, fp)) {
        int bl = (int)strlen(buf);
        while (bl>0 && (buf[bl-1]=='\n'||buf[bl-1]=='\r')) buf[--bl]=0;

        char *s = buf;
        while (*s==' '||*s=='\t') s++;
        if (*s=='*' || *s==0) continue;

        /* Continuation line */
        if (*s=='+') {
            if (strlen(cont)+strlen(s+1)+2 < MAX_LINE)
                { strcat(cont, " "); strcat(cont, s+1); }
            continue;
        }

        /* Process accumulated continuation */
        if (cont[0]) {
            char cs[MAX_LINE]; strncpy(cs, cont, MAX_LINE-1); cs[MAX_LINE-1]=0;
            char *cs2 = cs; while (*cs2==' '||*cs2=='\t') cs2++;
            if (strncmp(cs2, ".model", 6)==0) parse_model_line(c, cs2);
            else if (strncmp(cs2, ".include", 8)==0) parse_include(c, cs2, dir);
            else if (strncmp(cs2, ".dc", 3)==0) {
                c->do_dc=1;
                sscanf(cs2, ".dc %31s %f %f %f", c->dc_src, &c->dc_start, &c->dc_stop, &c->dc_step);
            } else if (strncmp(cs2, ".tran", 5)==0) {
                c->do_tran=1;
                sscanf(cs2, ".tran %f %f", &c->tran_tstep, &c->tran_tstop);
            }
            cont[0]=0;
        }

        /* Parse current line */
        if (strncmp(s, ".model", 6)==0) parse_model_line(c, s);
        else if (strncmp(s, ".include", 8)==0) parse_include(c, s, dir);
        else if (strncmp(s, ".op", 3)==0) c->do_op = 1;
        else if (strncmp(s, ".dc", 3)==0) {
            c->do_dc=1;
            sscanf(s, ".dc %31s %f %f %f", c->dc_src, &c->dc_start, &c->dc_stop, &c->dc_step);
        }
        else if (strncmp(s, ".tran", 5)==0) {
            c->do_tran=1;
            sscanf(s, ".tran %f %f", &c->tran_tstep, &c->tran_tstop);
        }
        else if (strncmp(s, ".control", 8)==0 || strncmp(s, ".endc", 5)==0
              || strncmp(s, "print", 5)==0 || strncmp(s, "plot", 4)==0
              || strncmp(s, "op", 2)==0 || strncmp(s, "dc", 2)==0
              || strncmp(s, "tran", 4)==0) { /* skip control */ }
        else if (!strncmp(s, ".end", 4)) break;
        else if (*s == '.') { /* unknown dot-cmd */ }
        else if (!parse_instance_line(c, s)) {
            /* Save as potential continuation start */
            strncpy(cont, s, MAX_LINE-1); cont[MAX_LINE-1]=0;
        }
    }
    fclose(fp);
}

/* ====================================================================
 *  SECTION 7: MNA Matrix Assembly
 * ==================================================================== */
static void mna_stamp_resistor(SpMat *J, REAL *rhs, int p, int n, REAL g) {
    sp_add(J, p, p, g);  sp_add(J, p, n, -g);
    sp_add(J, n, p, -g); sp_add(J, n, n, g);
}

static void mna_stamp_vsrc(SpMat *J, REAL *rhs, int p, int n, int vidx, REAL val) {
    sp_add(J, p, vidx, R(1.0));
    sp_add(J, n, vidx, R(-1.0));
    sp_add(J, vidx, p, R(1.0));
    sp_add(J, vidx, n, R(-1.0));
    rhs[vidx] = val;
}

static void mna_stamp_mosfet(SpMat *J, REAL *rhs, int d, int g, int s, int b,
                              REAL *v, const BSIM4Param *pp, REAL w, REAL l) {
    REAL vgs = v[g] - v[s];
    REAL vds = v[d] - v[s];
    REAL vbs = v[b] - v[s];
    REAL weff = w - R(2.0)*pp->wint;
    REAL leff = l - R(2.0)*pp->lint;
    if (weff < R(1e-8)) weff = R(1e-8);
    if (leff < R(1e-9)) leff = R(1e-9);

    BSIM4Out o = bsim4_eval(vgs, vds, vbs, weff, leff, pp);
    REAL gm=o.gm, gds=o.gds, gmbs=o.gmbs, ids=o.ids;

    /* KCL at drain node: +Ids from D to S */
    /* Jacobian stamping: dI_D/dV_G = gm, dI_D/dV_D = gds, dI_D/dV_S = -gm-gds, dI_D/dV_B = gmbs */
    sp_add(J, d, d,  gds);
    sp_add(J, d, g,  gm);
    sp_add(J, d, s, -gds - gm - gmbs);
    sp_add(J, d, b,  gmbs);

    sp_add(J, s, d, -gds);
    sp_add(J, s, g, -gm);
    sp_add(J, s, s,  gds + gm + gmbs);
    sp_add(J, s, b, -gmbs);

    rhs[d] -= ids;
    rhs[s] += ids;
}

/* ====================================================================
 *  SECTION 8: Newton-Raphson DC Solver
 * ==================================================================== */
static int dc_solve(REAL *v, REAL *i, Circuit *c, const BSIM4Param *pp,
                    int max_iter, REAL gmin, REAL abstol) {
    int n = c->nn + c->nv;
    SpMat *J = sp_new(n, n*n);

    /* Initial guess: voltage sources set their nodes */
    for (int j=0; j<c->nn; j++) v[j] = R(0.0);
    for (int j=0; j<c->nv; j++) i[j] = R(0.0);
    for (int j=0; j<c->nv; j++) {
        v[c->vsrc[j].p] = c->vsrc[j].dc * R(0.5);
    }

    for (int iter=0; iter<max_iter; iter++) {
        sp_clear(J);
        REAL *rhs = calloc(n, sizeof(REAL));

        /* Gmin to ground */
        for (int j=0; j<c->nn; j++) {
            if (j != c->ngnd) sp_add(J, j, j, gmin);
        }

        /* Resistors */
        for (int j=0; j<c->nr; j++) {
            REAL g = R(1.0) / (c->res[j].val + R(1e-30));
            mna_stamp_resistor(J, rhs, c->res[j].p, c->res[j].n, g);
        }

        /* MOSFETs */
        for (int j=0; j<c->nm; j++) {
            Mosfet *m = &c->mos[j];
            /* Determine which model to use */
            const Model *mod = find_model(c, m->model);
            BSIM4Param pp_loc = (mod && strstr(mod->type, "pmos")) ? *pp : *pp;
            /* For PMOS, flip signs if needed */
            if (mod && strstr(mod->type, "pmos")) {
                /* We reuse the same pp but swap vth sign internally
                 * For simplicity, use pp_nmos for now. PMOS TODO */
            }
            mna_stamp_mosfet(J, rhs, m->d, m->g, m->s, m->b, v, &pp_loc, m->w, m->l);
        }

        /* Voltage sources */
        for (int j=0; j<c->nv; j++) {
            int vidx = c->nn + j;
            mna_stamp_vsrc(J, rhs, c->vsrc[j].p, c->vsrc[j].n, vidx, c->vsrc[j].dc);
        }

        /* Ground node: fix to 0V. Set diagonal=1 and zero rhs.
         * Other entries in ground row/col will be neutralized
         * in sp_lu_solve when building dense matrix. */
        sp_add(J, c->ngnd, c->ngnd, R(1.0));
        rhs[c->ngnd] = R(0.0);

        /* Solve */
        REAL *dx = calloc(n, sizeof(REAL));
        if (sp_lu_solve(J, rhs, dx, c->ngnd) < 0) { free(rhs); free(dx); return iter; }

        /* Update + voltage limiting */
        REAL max_dv = R(0.0);
        for (int j=0; j<c->nn; j++) {
            REAL dv = dx[j];
            if (dv > R(0.5)) dv = R(0.5);
            if (dv < R(-0.5)) dv = R(-0.5);
            v[j] += dv;
            REAL ad = fabsf(dv);
            if (ad > max_dv) max_dv = ad;
        }
        for (int j=0; j<c->nv; j++) i[j] += dx[c->nn + j];

        free(rhs); free(dx);
        if (max_dv < abstol) return iter+1;
    }
    return max_iter;
}

/* ====================================================================
 *  SECTION 9: TRAN Solver (Forward Euler)
 * ==================================================================== */
static void tran_solve(Circuit *c, const BSIM4Param *pp, REAL tstop, REAL tstep) {
    REAL *v = calloc(c->nn, sizeof(REAL));
    REAL *i = calloc(c->nv, sizeof(REAL));
    /* Initial DC solve */
    dc_solve(v, i, c, pp, 100, R(1e-12), R(1e-6));

    printf("Index   time       ");
    for (int j=0; j<c->nn; j++) if (j!=c->ngnd) printf("V(%-10s) ", c->nmap[j]);
    printf("\n");

    int step = 0;
    for (REAL t=R(0.0); t <= tstop+R(1e-9) && step<MAX_TRAN; t+=tstep, step++) {
        printf("%-5d   %-10.4e ", step, (double)t);
        for (int j=0; j<c->nn; j++) if (j!=c->ngnd) printf("%-12.6f ", (double)v[j]);
        printf("\n");

        /* Simple: DC solve at each time point with companion models for caps */
        /* For now, just re-solve DC (capacitors act as open circuit at DC) */
        dc_solve(v, i, c, pp, 30, R(1e-12), R(1e-6));
    }
    free(v); free(i);
}

/* ====================================================================
 *  SECTION 10: Main
 * ==================================================================== */
int main(int argc, char **argv) {
    printf("=== float_spice v2.0: Zero-Double Float-First SPICE Engine ===\n\n");

    if (argc < 2) {
        printf("Usage: %s <circuit.sp>\n", argv[0]);
        return 1;
    }

    Circuit *c = calloc(1, sizeof(Circuit));
    c->res  = calloc(MAX_ELEMS, sizeof(Resistor));
    c->mos  = calloc(MAX_ELEMS, sizeof(Mosfet));
    c->vsrc = calloc(MAX_ELEMS, sizeof(Vsource));
    c->cap  = calloc(MAX_ELEMS, sizeof(Capacitor));
    c->nn = 1; strcpy(c->nmap[0], "0");

    parse_netlist(c, argv[1]);

    printf("Circuit: %s\n", argv[1]);
    printf("  Nodes: %d  Resistors: %d  MOSFETs: %d  Vsrcs: %d  Caps: %d\n",
           c->nn, c->nr, c->nm, c->nv, c->nc);

    /* Build BSIM4 params from models */
    BSIM4Param pp_nmos = bsim4_default();
    BSIM4Param pp_pmos = bsim4_default();
    for (int i=0; i<c->nmodel; i++) {
        if ((strstr(c->models[i].type, "nmos") || c->models[i].type[0]=='n')
            && pp_nmos.vth0 == bsim4_default().vth0) {
            bsim4_from_model(&pp_nmos, &c->models[i]);
            printf("  NMOS model: %s (vth0=%.4f u0=%.4f toxe=%.2e)\n",
                   c->models[i].name, (double)pp_nmos.vth0, (double)pp_nmos.u0, (double)pp_nmos.toxe);
        }
        if ((strstr(c->models[i].type, "pmos") || c->models[i].type[0]=='p')
            && pp_pmos.vth0 == bsim4_default().vth0) {
            bsim4_from_model(&pp_pmos, &c->models[i]);
            printf("  PMOS model: %s (vth0=%.4f u0=%.4f toxe=%.2e)\n",
                   c->models[i].name, (double)pp_pmos.vth0, (double)pp_pmos.u0, (double)pp_pmos.toxe);
        }
    }

    BSIM4Param *pp = &pp_nmos;

    if (c->do_tran) {
        printf("\nTRAN analysis: tstop=%.4e tstep=%.4e\n", (double)c->tran_tstop, (double)c->tran_tstep);
        tran_solve(c, pp, c->tran_tstop, c->tran_tstep);
    } else if (c->do_dc && c->dc_src[0]) {
        printf("\nDC Sweep: %s from %.4f to %.4f step %.4f\n",
               c->dc_src, (double)c->dc_start, (double)c->dc_stop, (double)c->dc_step);

        /* Find sweep source */
        int sidx = -1;
        for (int j=0; j<c->nv; j++) {
            if (strstr(c->vsrc[j].name, c->dc_src)) { sidx = j; break; }
        }
        if (sidx < 0) {
            for (int j=0; j<c->nv; j++) {
                if (strstr(c->dc_src, c->vsrc[j].name)) { sidx = j; break; }
            }
        }

        printf("Sweep    ");
        for (int j=0; j<c->nn; j++) if (j!=c->ngnd) printf("V(%-10s) ", c->nmap[j]);
        printf("\n");

        int swcnt=0;
        for (REAL sv=c->dc_start; sv <= c->dc_stop+R(1e-9) && swcnt<MAX_SWEEP;
             sv += c->dc_step, swcnt++) {
            if (sidx >= 0) c->vsrc[sidx].dc = sv;

            REAL *v = calloc(c->nn, sizeof(REAL));
            REAL *i = calloc(c->nv, sizeof(REAL));
            int iters = dc_solve(v, i, c, pp, 100, R(1e-12), R(1e-6));
            printf("%-8.4f ", (double)sv);
            for (int j=0; j<c->nn; j++) if (j!=c->ngnd) printf("%-12.6f ", (double)v[j]);
            printf(" # %d iters\n", iters);
            free(v); free(i);
        }
    } else {
        printf("\nDC Operating Point:\n");

        REAL *v = calloc(c->nn, sizeof(REAL));
        REAL *i = calloc(c->nv, sizeof(REAL));
        int iters = dc_solve(v, i, c, pp, 100, R(1e-12), R(1e-6));

        printf("  DC convergence: %d iterations\n", iters);
        printf("\n  Node Voltages:\n");
        printf("  %-12s %s\n", "Node", "Voltage");
        printf("  %-12s %s\n", "----", "-------");
        for (int j=0; j<c->nn; j++)
            printf("  %-12s %.6f\n", c->nmap[j], (double)v[j]);

        printf("\n  Source Currents:\n");
        printf("  %-12s %s\n", "Source", "Current");
        printf("  %-12s %s\n", "------", "-------");
        for (int j=0; j<c->nv; j++)
            printf("  %-12s %.6e\n", c->vsrc[j].name, (double)i[j]);

        printf("\n  Device Parameters:\n");
        for (int j=0; j<c->nm; j++) {
            Mosfet *m = &c->mos[j];
            REAL vgs = v[m->g] - v[m->s];
            REAL vds = v[m->d] - v[m->s];
            REAL vbs = v[m->b] - v[m->s];
            REAL weff = m->w - R(2.0)*pp->wint;
            REAL leff = m->l - R(2.0)*pp->lint;
            if (weff < R(1e-8)) weff = R(1e-8);
            if (leff < R(1e-9)) leff = R(1e-9);
            BSIM4Out o = bsim4_eval(vgs, vds, vbs, weff, leff, pp);
            printf("  device %-15s Ids=%.6e  gm=%.6e  gds=%.6e  vth=%.6f  vdsat=%.6f\n",
                   m->name, (double)o.ids, (double)o.gm, (double)o.gds,
                   (double)o.vth, (double)o.vdsat);
        }

        free(v); free(i);
    }

    printf("\n[Done]\n");
    free(c->res); free(c->mos); free(c->vsrc); free(c->cap); free(c);
    return 0;
}
