/* ngspice_stubs/cktdefs.h — Minimal CKTcircuit for standalone BSIM4v5 DC extraction.
 * Only includes fields that b4v5ld.c actually dereferences in DC mode.
 * Transient fields (CKTstate2, CKTdelta, CKTdeltaOld) are included for
 * struct compatibility but are zero/NULL in DC.
 */
#ifndef NGSPICE_STUBS_CKTDEFS_H
#define NGSPICE_STUBS_CKTDEFS_H

/* gendefs.h included separately by bsim4v5def.h — not needed here */

/* Mode flags used by BSIM4v5 code */
#define MODEDCOP       0x0001   /* DC operating point */
#define MODEDCTRANCURVE 0x0002  /* DC transfer curve */
#define MODEAC         0x0004   /* AC analysis */
#define MODETRAN       0x0008   /* Transient analysis */
#define MODETRANOP     0x0010   /* Transient operating point */
#define MODEINITFLOAT  0x2000   /* Initial float solution */
#define MODEINITJCT    0x1000   /* Initialize junction capacitances */
#define MODEINITTRAN   0x4000   /* Initialize transient */
#define MODEINITSMSIG  0x8000   /* Initialize small-signal */

/* Convergence state flags */
#define CKTDCconv      0x01
#define CKTtranconv    0x02

struct CKTcircuit {
    /* Temperature */
    SPICE_REAL CKTtemp;           /* circuit temperature (K) */

    /* Mode */
    int  CKTmode;                 /* analysis mode flags */
    int  CKTcurTask;             /* current task index */
    int  CKTnoncon;              /* non-convergence flag */
    int  CKTstat;                /* circuit state flags */

    /* State vectors — we provide float_spice voltage arrays */
    SPICE_REAL *CKTstate0;       /* current state (node voltages) */
    SPICE_REAL *CKTstate1;       /* previous state (TRAN only) */
    SPICE_REAL *CKTstate2;       /* 2-timesteps-ago state (TRAN only) */

    /* RHS vector — device current contributions */
    SPICE_REAL *CKTrhs;          /* right-hand side */
    SPICE_REAL *CKTrhsOld;       /* previous RHS (gmin stepping) */

    /* Time step info (TRAN only, unused in DC) */
    SPICE_REAL CKTdelta;         /* current time step */
    SPICE_REAL CKTdeltaOld[8];   /* previous time steps */

    /* Convergence test (simplified) */
    SPICE_REAL CKTgmin;          /* gmin conductance */
    SPICE_REAL CKTabstol;        /* absolute tolerance */
    SPICE_REAL CKTreltol;        /* relative tolerance */
    SPICE_REAL CKTvoltTol;       /* voltage tolerance */
    SPICE_REAL CKTtemptol;       /* temperature tolerance */

    /* Ground node index */
    int CKTground;               /* reference node (0) */
};

#endif
