/* ngspice_stubs/ifsim.h — Minimal IF types for bsim4v5def.h compilation.
 * Only enough to satisfy struct field declarations; BSIM4v5 DC evaluation
 * does not use the ngspice frontend interface.
 */
#ifndef NGSPICE_STUBS_IFSIM_H
#define NGSPICE_STUBS_IFSIM_H

/* IFvalue: parameter value union (needed for IFparm default values) */
typedef struct {
    int     iValue;
    SPICE_REAL rValue;
    char   *sValue;
} IFvalue;

/* IFparm: parameter descriptor (referenced in BSIM4v5model) */
typedef struct {
    char    *keyword;
    int      dataType;
    IFvalue *defaultValue;
    int      description;
} IFparm;

/* IFdevice: device-level interface (only type needed, not full definition) */
typedef struct sDEVdevice IFdevice;

/* IFmodel: model-level interface (only type needed) */
typedef struct sDEVmodel IFmodel;

/* IFanalysis: analysis descriptor (referenced in struct) */
typedef struct sANALYSIS IFanalysis;

/* Data types for IFparm.dataType */
#define IF_REAL    1
#define IF_INTEGER 2
#define IF_STRING  3
#define IF_FLAG    4
#define IF_NODE    5
#define IF_INSTANCE 6
#define IF_UID     7

#endif
