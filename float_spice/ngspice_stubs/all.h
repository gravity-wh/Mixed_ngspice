/* ngspice_stubs/all.h — Umbrella header: include BEFORE any BSIM4v5 files.
 * This ensures all stub types are defined before the BSIM4v5 code sees them.
 */
#ifndef NGSPICE_STUBS_ALL_H
#define NGSPICE_STUBS_ALL_H

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SPICE_REAL is set via -DSPICE_REAL=float */

/* ===== Base types (must come first) ===== */
typedef char *IFuid;

struct GENmodel {
    int     GENmodType;
    struct GENmodel *GENnextModel;
    struct GENinstance *GENinstances;
    IFuid   GENmodName;
};
typedef struct GENmodel GENmodel;

struct GENinstance {
    struct GENmodel *GENmodPtr;
    struct GENinstance *GENnextInstance;
    IFuid   GENname;
    int     GENstate;
};
typedef struct GENinstance GENinstance;

/* ===== Complex number ===== */
typedef struct { SPICE_REAL real; SPICE_REAL imag; } SPcomplex;

/* ===== IF types ===== */
typedef struct { int iValue; SPICE_REAL rValue; char *sValue; } IFvalue;
typedef struct { char *keyword; int dataType; IFvalue *defaultValue; int description; } IFparm;
#define IF_REAL    1
#define IF_INTEGER 2
#define IF_STRING  3
#define IF_FLAG    4
#define IF_NODE    5
#define IF_INSTANCE 6
#define IF_UID     7

/* Forward declarations for IF types */
typedef struct sDEVdevice IFdevice;
typedef struct sDEVmodel IFmodel;
typedef struct sANALYSIS IFanalysis;

/* ===== CKTcircuit ===== */
#define MODEDCOP       0x0001
#define MODEDCTRANCURVE 0x0002
#define MODEAC         0x0004
#define MODETRAN       0x0008
#define MODETRANOP     0x0010
#define MODEINITFLOAT  0x2000
#define MODEINITJCT    0x1000
#define MODEINITTRAN   0x4000
#define MODEINITSMSIG  0x8000
#define MODEUIC        0x20000
#define MODEINITFIX    0x40000
#define MODEINITPRED   0x80000
#define CHARGE         0x100000

struct CKTcircuit {
    SPICE_REAL CKTtemp;
    int  CKTmode;
    int  CKTcurTask;
    int  CKTnoncon;
    int  CKTstat;
    SPICE_REAL *CKTstate0;
    SPICE_REAL *CKTstate1;
    SPICE_REAL *CKTstate2;
    SPICE_REAL *CKTrhs;
    SPICE_REAL *CKTrhsOld;
    SPICE_REAL CKTdelta;
    SPICE_REAL CKTdeltaOld[8];
    SPICE_REAL CKTgmin;
    SPICE_REAL CKTabstol;
    SPICE_REAL CKTreltol;
    SPICE_REAL CKTvoltTol;
    SPICE_REAL CKTtemptol;
    int CKTground;
    int CKTbypass;        /* bypass flag */
    int CKTag[1];         /* transient analysis tag (array) */
    struct _JOB { int JOBtype; } *CKTcurJob;  /* current job pointer */
};
typedef struct CKTcircuit CKTcircuit;

/* ===== Sparse matrix types (stubs) ===== */
typedef struct { int dummy; } SMPmatrix;
typedef void BindElement;

/* ===== Noise stubs ===== */
typedef struct { int dummy; } Ndata;
#define NSTATVARS 0

/* ===== Physical constants ===== */
#define CONSTvt0       (8.617333262145e-5)
#define CONSTroot2     (1.4142135623730951)
#define CONSTKoverQ    (8.617333262145e-5)
#define CONSTCtoK      (273.15)
#define REFTEMPC       (27.0)
#define REFTEMP        (300.15)
#define CONSTboltz     (1.3806226e-23)

/* ===== Error codes ===== */
#define E_PANIC      (-1)
#define E_BADPARM    (-2)
#define E_NOMODEL    (-3)
#define E_NODEV      (-4)
#define E_INTERN     (-5)
#define ERR_FATAL     (-6)
#define OK            0

/* ===== Math macros ===== */
#define SPICE_EXP(x)   expf(x)
#define SPICE_LOG(x)   logf(x)
#define SPICE_SQRT(x)  sqrtf(x)
#define SPICE_POW(x,y) powf((x),(y))
#define SPICE_FABS(x)  fabsf(x)
#define SPICE_ATAN(x)  atanf(x)
#define MAX(a,b)       ((a)>(b)?(a):(b))
#define MIN(a,b)       ((a)<(b)?(a):(b))
#define FREE(p)        free(p)
#define TMALLOC(t,n)   ((t*)calloc((n),sizeof(t)))

/* ===== Function stubs (not used in DC mode, but needed for linking) ===== */
static inline int NIintegrate(CKTcircuit *ckt, SPICE_REAL *geq, SPICE_REAL *ceq,
                              SPICE_REAL cap, SPICE_REAL q) {
    (void)ckt; *geq = 0.0; *ceq = q; (void)cap;
    return 0;
}
static inline SPICE_REAL DEVfetlim(SPICE_REAL v_new, SPICE_REAL v_old, SPICE_REAL vth) {
    (void)v_old; (void)vth; return v_new;
}
static inline SPICE_REAL DEVlimvds(SPICE_REAL v_new, SPICE_REAL v_old) {
    (void)v_old; return v_new;
}
static inline SPICE_REAL DEVpnjlim(SPICE_REAL v_new, SPICE_REAL v_old, SPICE_REAL vt,
                                    SPICE_REAL vcrit, int *check) {
    *check = 0; (void)v_old; (void)vt; (void)vcrit; return v_new;
}

/* SPfrontEnd stub — global error handler */
#include <stdarg.h>
struct spfrontend_stub {
    void (*IFerrorf)(int code, const char *fmt, ...);
};
static void _stub_IFerrorf(int code, const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "BSIM4v5 ERROR [%d]: ", code);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
}
__attribute__((unused))
static struct spfrontend_stub _SPfrontEnd_g = { _stub_IFerrorf };
#define SPfrontEnd (&_SPfrontEnd_g)

/* Geometry function stubs (these use double in ngspice, but are not in DC hot path) */
static inline int BSIM4v5PAeffGeo(SPICE_REAL w, int isOut, int isPS, SPICE_REAL geo,
    SPICE_REAL xl, SPICE_REAL nd, SPICE_REAL xw, SPICE_REAL *pa, SPICE_REAL *wpe,
    SPICE_REAL *wpeq, SPICE_REAL *sa_eff) {
    (void)w; (void)isOut; (void)isPS; (void)geo; (void)xl; (void)nd; (void)xw;
    *pa = 0; *wpe = 0; *wpeq = 0; *sa_eff = 0; return 0;
}
static inline int BSIM4v5RdseffGeo(SPICE_REAL w, int isOut, int isPS, int isS,
    SPICE_REAL geo, SPICE_REAL xl, SPICE_REAL nd, SPICE_REAL xw, SPICE_REAL sa,
    int binUnit, SPICE_REAL *rdseff) {
    (void)w; (void)isOut; (void)isPS; (void)isS; (void)geo; (void)xl;
    (void)nd; (void)xw; (void)sa; (void)binUnit; *rdseff = 0; return 0;
}

#endif /* NGSPICE_STUBS_ALL_H */
