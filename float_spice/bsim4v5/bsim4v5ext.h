/* bsim4v5ext.h — Cleaned-up extern declarations for standalone extraction.
 * All double parameters replaced with SPICE_REAL.
 * Functions not needed for DC-only extraction are removed.
 */
#ifndef BSIM4V5EXT_STANDALONE_H
#define BSIM4V5EXT_STANDALONE_H

/* Core functions we actually call */
extern int BSIM4v5load(GENmodel*,CKTcircuit*);
extern int BSIM4v5temp(GENmodel*,CKTcircuit*);

/* Functions referenced in BSIM4v5instance struct — never called but must link */
extern int BSIM4v5acLoad(GENmodel *,CKTcircuit*);
extern int BSIM4v5ask(CKTcircuit *,GENinstance*,int,IFvalue*,IFvalue*);
extern int BSIM4v5convTest(GENmodel *,CKTcircuit*);
extern int BSIM4v5getic(GENmodel*,CKTcircuit*);
extern int BSIM4v5mAsk(CKTcircuit*,GENmodel *,int, IFvalue*);
extern int BSIM4v5mDelete(GENmodel*);
extern int BSIM4v5mParam(int,IFvalue*,GENmodel*);
extern int BSIM4v5param(int,IFvalue*,GENinstance*,IFvalue*);
extern int BSIM4v5pzLoad(GENmodel*,CKTcircuit*,SPcomplex*);
extern int BSIM4v5setup(SMPmatrix*,GENmodel*,CKTcircuit*,int*);
extern int BSIM4v5unsetup(GENmodel*,CKTcircuit*);
extern int BSIM4v5soaCheck(CKTcircuit *, GENmodel *);

/* These use double in original ngspice — stub them out */
/* BSIM4v5mosCap, BSIM4v5SPICE_TRUNC, BSIM4v5noise removed (not needed) */

/* Geometry functions — stubbed inline in ngspice_stubs/all.h */
/* BSIM4v5PAeffGeo, BSIM4v5RdseffGeo declared in all.h */

#endif
