/* ngspice_stubs/sperror.h — Minimal error handling stubs.
 * Replaces SPfrontEnd->IFerrorf() with simple stderr logging.
 * DC-only extraction doesn't need full ngspice error framework.
 */
#ifndef NGSPICE_STUBS_SPERROR_H
#define NGSPICE_STUBS_SPERROR_H

#include <stdio.h>

#define E_PANIC      (-1)
#define E_BADPARM    (-2)
#define E_NOMODEL    (-3)
#define E_NODEV      (-4)
#define E_INTERN     (-5)
#define OK            0

/* SPfrontEnd stub — just a global with error logging functions */
struct spfrontend_stub {
    void (*IFerrorf)(int code, const char *fmt, ...);
    int  (*IFerrMessage)(int code, const char *msg);
};
extern struct spfrontend_stub *SPfrontEnd_init(void);
extern struct spfrontend_stub *SPfrontEnd;

#endif
