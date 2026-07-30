/* ngspice_stubs/gendefs.h — Minimal GENmodel/GENinstance base types.
 * BSIM4v5model inherits from GENmodel (via GENmodel prefix field).
 * BSIM4v5instance inherits from GENinstance.
 * These must match the FP32-patched ngspice struct layout exactly.
 */
#ifndef NGSPICE_STUBS_GENDEFS_H
#define NGSPICE_STUBS_GENDEFS_H

typedef char *IFuid;

struct GENinstance {
    struct GENmodel *GENmodPtr;           /* back-pointer to owning model */
    struct GENinstance *GENnextInstance;  /* linked-list next */
    IFuid   GENname;                      /* instance name string */
    int     GENstate;                     /* state index */
};

struct GENmodel {
    int     GENmodType;                   /* device type code */
    struct GENmodel *GENnextModel;        /* linked-list next */
    struct GENinstance *GENinstances;     /* instance list head */
    IFuid   GENmodName;                   /* model name string */
};

#endif
