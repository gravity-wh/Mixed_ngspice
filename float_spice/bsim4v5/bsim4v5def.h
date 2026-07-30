/**********
Copyright 2005 Regents of the University of California.  All rights reserved.
Author: 2000 Weidong Liu.
Modified by Xuemei Xi, 11/15/2002.
Modified by Xuemei Xi, 05/09/2003.
Modified by Xuemei Xi, 03/04/2004.
Modified by Xuemei Xi, Mohan Dunga, 09/24/2004.
Modified by Xuemei Xi, 07/29/2005.
File: bsim4v5def.h
**********/

#ifndef BSIM4V5
#define BSIM4V5

#include "../ngspice_stubs/all.h"

typedef struct sBSIM4v5instance
{

    struct GENinstance gen;

#define BSIM4v5modPtr(inst) ((struct sBSIM4v5model *)((inst)->gen.GENmodPtr))
#define BSIM4v5nextInstance(inst) ((struct sBSIM4v5instance *)((inst)->gen.GENnextInstance))
#define BSIM4v5name gen.GENname
#define BSIM4v5states gen.GENstate

    const int BSIM4v5dNode;
    const int BSIM4v5gNodeExt;
    const int BSIM4v5sNode;
    const int BSIM4v5bNode;
    int BSIM4v5dNodePrime;
    int BSIM4v5gNodePrime;
    int BSIM4v5gNodeMid;
    int BSIM4v5sNodePrime;
    int BSIM4v5bNodePrime;
    int BSIM4v5dbNode;
    int BSIM4v5sbNode;
    int BSIM4v5qNode;

    SPICE_REAL BSIM4v5ueff;
    SPICE_REAL BSIM4v5thetavth; 
    SPICE_REAL BSIM4v5von;
    SPICE_REAL BSIM4v5vdsat;
    SPICE_REAL BSIM4v5cgdo;
    SPICE_REAL BSIM4v5qgdo;
    SPICE_REAL BSIM4v5cgso;
    SPICE_REAL BSIM4v5qgso;
    SPICE_REAL BSIM4v5grbsb;
    SPICE_REAL BSIM4v5grbdb;
    SPICE_REAL BSIM4v5grbpb;
    SPICE_REAL BSIM4v5grbps;
    SPICE_REAL BSIM4v5grbpd;

    SPICE_REAL BSIM4v5vjsmFwd;
    SPICE_REAL BSIM4v5vjsmRev;
    SPICE_REAL BSIM4v5vjdmFwd;
    SPICE_REAL BSIM4v5vjdmRev;
    SPICE_REAL BSIM4v5XExpBVS;
    SPICE_REAL BSIM4v5XExpBVD;
    SPICE_REAL BSIM4v5SslpFwd;
    SPICE_REAL BSIM4v5SslpRev;
    SPICE_REAL BSIM4v5DslpFwd;
    SPICE_REAL BSIM4v5DslpRev;
    SPICE_REAL BSIM4v5IVjsmFwd;
    SPICE_REAL BSIM4v5IVjsmRev;
    SPICE_REAL BSIM4v5IVjdmFwd;
    SPICE_REAL BSIM4v5IVjdmRev;

    SPICE_REAL BSIM4v5grgeltd;
    SPICE_REAL BSIM4v5Pseff;
    SPICE_REAL BSIM4v5Pdeff;
    SPICE_REAL BSIM4v5Aseff;
    SPICE_REAL BSIM4v5Adeff;

    SPICE_REAL BSIM4v5l;
    SPICE_REAL BSIM4v5w;
    SPICE_REAL BSIM4v5drainArea;
    SPICE_REAL BSIM4v5sourceArea;
    SPICE_REAL BSIM4v5drainSquares;
    SPICE_REAL BSIM4v5sourceSquares;
    SPICE_REAL BSIM4v5drainPerimeter;
    SPICE_REAL BSIM4v5sourcePerimeter;
    SPICE_REAL BSIM4v5sourceConductance;
    SPICE_REAL BSIM4v5drainConductance;
     /* stress effect instance param */
    SPICE_REAL BSIM4v5sa;
    SPICE_REAL BSIM4v5sb;
    SPICE_REAL BSIM4v5sd;
    SPICE_REAL BSIM4v5sca;
    SPICE_REAL BSIM4v5scb;
    SPICE_REAL BSIM4v5scc;
    SPICE_REAL BSIM4v5sc;

    SPICE_REAL BSIM4v5rbdb;
    SPICE_REAL BSIM4v5rbsb;
    SPICE_REAL BSIM4v5rbpb;
    SPICE_REAL BSIM4v5rbps;
    SPICE_REAL BSIM4v5rbpd;
    
    SPICE_REAL BSIM4v5delvto;
    SPICE_REAL BSIM4v5mulu0;
    SPICE_REAL BSIM4v5xgw;
    SPICE_REAL BSIM4v5ngcon;
    SPICE_REAL BSIM4v5dtemp;

     /* added here to account stress effect instance dependence */
    SPICE_REAL BSIM4v5u0temp;
    SPICE_REAL BSIM4v5vsattemp;
    SPICE_REAL BSIM4v5vth0;
    SPICE_REAL BSIM4v5vfb;
    SPICE_REAL BSIM4v5vfbzb;
    SPICE_REAL BSIM4v5vtfbphi1;
    SPICE_REAL BSIM4v5vtfbphi2;
    SPICE_REAL BSIM4v5k2;
    SPICE_REAL BSIM4v5vbsc;
    SPICE_REAL BSIM4v5k2ox;
    SPICE_REAL BSIM4v5eta0;

    SPICE_REAL BSIM4v5icVDS;
    SPICE_REAL BSIM4v5icVGS;
    SPICE_REAL BSIM4v5icVBS;
    SPICE_REAL BSIM4v5nf;
    SPICE_REAL BSIM4v5m;
    int BSIM4v5off;
    int BSIM4v5mode;
    int BSIM4v5trnqsMod;
    int BSIM4v5acnqsMod;
    int BSIM4v5rbodyMod;
    int BSIM4v5rgateMod;
    int BSIM4v5geoMod;
    int BSIM4v5rgeoMod;
    int BSIM4v5min;


    /* OP point */
    SPICE_REAL BSIM4v5Vgsteff;
    SPICE_REAL BSIM4v5vgs_eff;
    SPICE_REAL BSIM4v5vgd_eff;
    SPICE_REAL BSIM4v5dvgs_eff_dvg;
    SPICE_REAL BSIM4v5dvgd_eff_dvg;
    SPICE_REAL BSIM4v5Vdseff;
    SPICE_REAL BSIM4v5nstar;
    SPICE_REAL BSIM4v5Abulk;
    SPICE_REAL BSIM4v5EsatL;
    SPICE_REAL BSIM4v5AbovVgst2Vtm;
    SPICE_REAL BSIM4v5qinv;
    SPICE_REAL BSIM4v5cd;
    SPICE_REAL BSIM4v5cbs;
    SPICE_REAL BSIM4v5cbd;
    SPICE_REAL BSIM4v5csub;
    SPICE_REAL BSIM4v5Igidl;
    SPICE_REAL BSIM4v5Igisl;
    SPICE_REAL BSIM4v5gm;
    SPICE_REAL BSIM4v5gds;
    SPICE_REAL BSIM4v5gmbs;
    SPICE_REAL BSIM4v5gbd;
    SPICE_REAL BSIM4v5gbs;

    SPICE_REAL BSIM4v5gbbs;
    SPICE_REAL BSIM4v5gbgs;
    SPICE_REAL BSIM4v5gbds;
    SPICE_REAL BSIM4v5ggidld;
    SPICE_REAL BSIM4v5ggidlg;
    SPICE_REAL BSIM4v5ggidls;
    SPICE_REAL BSIM4v5ggidlb;
    SPICE_REAL BSIM4v5ggisld;
    SPICE_REAL BSIM4v5ggislg;
    SPICE_REAL BSIM4v5ggisls;
    SPICE_REAL BSIM4v5ggislb;

    SPICE_REAL BSIM4v5Igcs;
    SPICE_REAL BSIM4v5gIgcsg;
    SPICE_REAL BSIM4v5gIgcsd;
    SPICE_REAL BSIM4v5gIgcss;
    SPICE_REAL BSIM4v5gIgcsb;
    SPICE_REAL BSIM4v5Igcd;
    SPICE_REAL BSIM4v5gIgcdg;
    SPICE_REAL BSIM4v5gIgcdd;
    SPICE_REAL BSIM4v5gIgcds;
    SPICE_REAL BSIM4v5gIgcdb;

    SPICE_REAL BSIM4v5Igs;
    SPICE_REAL BSIM4v5gIgsg;
    SPICE_REAL BSIM4v5gIgss;
    SPICE_REAL BSIM4v5Igd;
    SPICE_REAL BSIM4v5gIgdg;
    SPICE_REAL BSIM4v5gIgdd;

    SPICE_REAL BSIM4v5Igb;
    SPICE_REAL BSIM4v5gIgbg;
    SPICE_REAL BSIM4v5gIgbd;
    SPICE_REAL BSIM4v5gIgbs;
    SPICE_REAL BSIM4v5gIgbb;

    SPICE_REAL BSIM4v5grdsw;
    SPICE_REAL BSIM4v5IdovVds;
    SPICE_REAL BSIM4v5gcrg;
    SPICE_REAL BSIM4v5gcrgd;
    SPICE_REAL BSIM4v5gcrgg;
    SPICE_REAL BSIM4v5gcrgs;
    SPICE_REAL BSIM4v5gcrgb;

    SPICE_REAL BSIM4v5gstot;
    SPICE_REAL BSIM4v5gstotd;
    SPICE_REAL BSIM4v5gstotg;
    SPICE_REAL BSIM4v5gstots;
    SPICE_REAL BSIM4v5gstotb;

    SPICE_REAL BSIM4v5gdtot;
    SPICE_REAL BSIM4v5gdtotd;
    SPICE_REAL BSIM4v5gdtotg;
    SPICE_REAL BSIM4v5gdtots;
    SPICE_REAL BSIM4v5gdtotb;

    SPICE_REAL BSIM4v5cggb;
    SPICE_REAL BSIM4v5cgdb;
    SPICE_REAL BSIM4v5cgsb;
    SPICE_REAL BSIM4v5cbgb;
    SPICE_REAL BSIM4v5cbdb;
    SPICE_REAL BSIM4v5cbsb;
    SPICE_REAL BSIM4v5cdgb;
    SPICE_REAL BSIM4v5cddb;
    SPICE_REAL BSIM4v5cdsb;
    SPICE_REAL BSIM4v5csgb;
    SPICE_REAL BSIM4v5csdb;
    SPICE_REAL BSIM4v5cssb;
    SPICE_REAL BSIM4v5cgbb;
    SPICE_REAL BSIM4v5cdbb;
    SPICE_REAL BSIM4v5csbb;
    SPICE_REAL BSIM4v5cbbb;
    SPICE_REAL BSIM4v5capbd;
    SPICE_REAL BSIM4v5capbs;

    SPICE_REAL BSIM4v5cqgb;
    SPICE_REAL BSIM4v5cqdb;
    SPICE_REAL BSIM4v5cqsb;
    SPICE_REAL BSIM4v5cqbb;

    SPICE_REAL BSIM4v5qgate;
    SPICE_REAL BSIM4v5qbulk;
    SPICE_REAL BSIM4v5qdrn;
    SPICE_REAL BSIM4v5qsrc;
    SPICE_REAL BSIM4v5qdef;

    SPICE_REAL BSIM4v5qchqs;
    SPICE_REAL BSIM4v5taunet;
    SPICE_REAL BSIM4v5gtau;
    SPICE_REAL BSIM4v5gtg;
    SPICE_REAL BSIM4v5gtd;
    SPICE_REAL BSIM4v5gts;
    SPICE_REAL BSIM4v5gtb;
    SPICE_REAL BSIM4v5SjctTempRevSatCur;
    SPICE_REAL BSIM4v5DjctTempRevSatCur;
    SPICE_REAL BSIM4v5SswTempRevSatCur;
    SPICE_REAL BSIM4v5DswTempRevSatCur;
    SPICE_REAL BSIM4v5SswgTempRevSatCur;
    SPICE_REAL BSIM4v5DswgTempRevSatCur;

    struct bsim4v5SizeDependParam  *pParam;

    unsigned BSIM4v5lGiven :1;
    unsigned BSIM4v5wGiven :1;
    unsigned BSIM4v5mGiven :1;
    unsigned BSIM4v5nfGiven :1;
    unsigned BSIM4v5minGiven :1;
    unsigned BSIM4v5drainAreaGiven :1;
    unsigned BSIM4v5sourceAreaGiven    :1;
    unsigned BSIM4v5drainSquaresGiven  :1;
    unsigned BSIM4v5sourceSquaresGiven :1;
    unsigned BSIM4v5drainPerimeterGiven    :1;
    unsigned BSIM4v5sourcePerimeterGiven   :1;
    unsigned BSIM4v5saGiven :1;
    unsigned BSIM4v5sbGiven :1;
    unsigned BSIM4v5sdGiven :1;
    unsigned BSIM4v5scaGiven :1;
    unsigned BSIM4v5scbGiven :1;
    unsigned BSIM4v5sccGiven :1;
    unsigned BSIM4v5scGiven :1;
    unsigned BSIM4v5rbdbGiven   :1;
    unsigned BSIM4v5rbsbGiven   :1;
    unsigned BSIM4v5rbpbGiven   :1;
    unsigned BSIM4v5rbpdGiven   :1;
    unsigned BSIM4v5rbpsGiven   :1;
    unsigned BSIM4v5delvtoGiven   :1;
    unsigned BSIM4v5mulu0Given   :1;
    unsigned BSIM4v5xgwGiven   :1;
    unsigned BSIM4v5ngconGiven   :1;
    unsigned BSIM4v5dtempGiven : 1;
    unsigned BSIM4v5icVDSGiven :1;
    unsigned BSIM4v5icVGSGiven :1;
    unsigned BSIM4v5icVBSGiven :1;
    unsigned BSIM4v5trnqsModGiven :1;
    unsigned BSIM4v5acnqsModGiven :1;
    unsigned BSIM4v5rbodyModGiven :1;
    unsigned BSIM4v5rgateModGiven :1;
    unsigned BSIM4v5geoModGiven :1;
    unsigned BSIM4v5rgeoModGiven :1;


    SPICE_REAL *BSIM4v5DPdPtr;
    SPICE_REAL *BSIM4v5DPdpPtr;
    SPICE_REAL *BSIM4v5DPgpPtr;
    SPICE_REAL *BSIM4v5DPgmPtr;
    SPICE_REAL *BSIM4v5DPspPtr;
    SPICE_REAL *BSIM4v5DPbpPtr;
    SPICE_REAL *BSIM4v5DPdbPtr;

    SPICE_REAL *BSIM4v5DdPtr;
    SPICE_REAL *BSIM4v5DdpPtr;

    SPICE_REAL *BSIM4v5GPdpPtr;
    SPICE_REAL *BSIM4v5GPgpPtr;
    SPICE_REAL *BSIM4v5GPgmPtr;
    SPICE_REAL *BSIM4v5GPgePtr;
    SPICE_REAL *BSIM4v5GPspPtr;
    SPICE_REAL *BSIM4v5GPbpPtr;

    SPICE_REAL *BSIM4v5GMdpPtr;
    SPICE_REAL *BSIM4v5GMgpPtr;
    SPICE_REAL *BSIM4v5GMgmPtr;
    SPICE_REAL *BSIM4v5GMgePtr;
    SPICE_REAL *BSIM4v5GMspPtr;
    SPICE_REAL *BSIM4v5GMbpPtr;

    SPICE_REAL *BSIM4v5GEdpPtr;
    SPICE_REAL *BSIM4v5GEgpPtr;
    SPICE_REAL *BSIM4v5GEgmPtr;
    SPICE_REAL *BSIM4v5GEgePtr;
    SPICE_REAL *BSIM4v5GEspPtr;
    SPICE_REAL *BSIM4v5GEbpPtr;

    SPICE_REAL *BSIM4v5SPdpPtr;
    SPICE_REAL *BSIM4v5SPgpPtr;
    SPICE_REAL *BSIM4v5SPgmPtr;
    SPICE_REAL *BSIM4v5SPsPtr;
    SPICE_REAL *BSIM4v5SPspPtr;
    SPICE_REAL *BSIM4v5SPbpPtr;
    SPICE_REAL *BSIM4v5SPsbPtr;

    SPICE_REAL *BSIM4v5SspPtr;
    SPICE_REAL *BSIM4v5SsPtr;

    SPICE_REAL *BSIM4v5BPdpPtr;
    SPICE_REAL *BSIM4v5BPgpPtr;
    SPICE_REAL *BSIM4v5BPgmPtr;
    SPICE_REAL *BSIM4v5BPspPtr;
    SPICE_REAL *BSIM4v5BPdbPtr;
    SPICE_REAL *BSIM4v5BPbPtr;
    SPICE_REAL *BSIM4v5BPsbPtr;
    SPICE_REAL *BSIM4v5BPbpPtr;

    SPICE_REAL *BSIM4v5DBdpPtr;
    SPICE_REAL *BSIM4v5DBdbPtr;
    SPICE_REAL *BSIM4v5DBbpPtr;
    SPICE_REAL *BSIM4v5DBbPtr;

    SPICE_REAL *BSIM4v5SBspPtr;
    SPICE_REAL *BSIM4v5SBbpPtr;
    SPICE_REAL *BSIM4v5SBbPtr;
    SPICE_REAL *BSIM4v5SBsbPtr;

    SPICE_REAL *BSIM4v5BdbPtr;
    SPICE_REAL *BSIM4v5BbpPtr;
    SPICE_REAL *BSIM4v5BsbPtr;
    SPICE_REAL *BSIM4v5BbPtr;

    SPICE_REAL *BSIM4v5DgpPtr;
    SPICE_REAL *BSIM4v5DspPtr;
    SPICE_REAL *BSIM4v5DbpPtr;
    SPICE_REAL *BSIM4v5SdpPtr;
    SPICE_REAL *BSIM4v5SgpPtr;
    SPICE_REAL *BSIM4v5SbpPtr;

    SPICE_REAL *BSIM4v5QdpPtr;
    SPICE_REAL *BSIM4v5QgpPtr;
    SPICE_REAL *BSIM4v5QspPtr;
    SPICE_REAL *BSIM4v5QbpPtr;
    SPICE_REAL *BSIM4v5QqPtr;
    SPICE_REAL *BSIM4v5DPqPtr;
    SPICE_REAL *BSIM4v5GPqPtr;
    SPICE_REAL *BSIM4v5SPqPtr;

#ifdef USE_OMP
    /* per instance storage of results, to update matrix at a later stge */
    SPICE_REAL BSIM4v5rhsdPrime;
    SPICE_REAL BSIM4v5rhsgPrime;
    SPICE_REAL BSIM4v5rhsgExt;
    SPICE_REAL BSIM4v5grhsMid;
    SPICE_REAL BSIM4v5rhsbPrime;
    SPICE_REAL BSIM4v5rhssPrime;
    SPICE_REAL BSIM4v5rhsdb;
    SPICE_REAL BSIM4v5rhssb;
    SPICE_REAL BSIM4v5rhsd;
    SPICE_REAL BSIM4v5rhss;
    SPICE_REAL BSIM4v5rhsq;

    SPICE_REAL BSIM4v5_1;
    SPICE_REAL BSIM4v5_2;
    SPICE_REAL BSIM4v5_3;
    SPICE_REAL BSIM4v5_4;
    SPICE_REAL BSIM4v5_5;
    SPICE_REAL BSIM4v5_6;
    SPICE_REAL BSIM4v5_7;
    SPICE_REAL BSIM4v5_8;
    SPICE_REAL BSIM4v5_9;
    SPICE_REAL BSIM4v5_10;
    SPICE_REAL BSIM4v5_11;
    SPICE_REAL BSIM4v5_12;
    SPICE_REAL BSIM4v5_13;
    SPICE_REAL BSIM4v5_14;
    SPICE_REAL BSIM4v5_15;
    SPICE_REAL BSIM4v5_16;
    SPICE_REAL BSIM4v5_17;
    SPICE_REAL BSIM4v5_18;
    SPICE_REAL BSIM4v5_19;
    SPICE_REAL BSIM4v5_20;
    SPICE_REAL BSIM4v5_21;
    SPICE_REAL BSIM4v5_22;
    SPICE_REAL BSIM4v5_23;
    SPICE_REAL BSIM4v5_24;
    SPICE_REAL BSIM4v5_25;
    SPICE_REAL BSIM4v5_26;
    SPICE_REAL BSIM4v5_27;
    SPICE_REAL BSIM4v5_28;
    SPICE_REAL BSIM4v5_29;
    SPICE_REAL BSIM4v5_30;
    SPICE_REAL BSIM4v5_31;
    SPICE_REAL BSIM4v5_32;
    SPICE_REAL BSIM4v5_33;
    SPICE_REAL BSIM4v5_34;
    SPICE_REAL BSIM4v5_35;
    SPICE_REAL BSIM4v5_36;
    SPICE_REAL BSIM4v5_37;
    SPICE_REAL BSIM4v5_38;
    SPICE_REAL BSIM4v5_39;
    SPICE_REAL BSIM4v5_40;
    SPICE_REAL BSIM4v5_41;
    SPICE_REAL BSIM4v5_42;
    SPICE_REAL BSIM4v5_43;
    SPICE_REAL BSIM4v5_44;
    SPICE_REAL BSIM4v5_45;
    SPICE_REAL BSIM4v5_46;
    SPICE_REAL BSIM4v5_47;
    SPICE_REAL BSIM4v5_48;
    SPICE_REAL BSIM4v5_49;
    SPICE_REAL BSIM4v5_50;
    SPICE_REAL BSIM4v5_51;
    SPICE_REAL BSIM4v5_52;
    SPICE_REAL BSIM4v5_53;
    SPICE_REAL BSIM4v5_54;
    SPICE_REAL BSIM4v5_55;
    SPICE_REAL BSIM4v5_56;
    SPICE_REAL BSIM4v5_57;
    SPICE_REAL BSIM4v5_58;
    SPICE_REAL BSIM4v5_59;
    SPICE_REAL BSIM4v5_60;
    SPICE_REAL BSIM4v5_61;
    SPICE_REAL BSIM4v5_62;
    SPICE_REAL BSIM4v5_63;
    SPICE_REAL BSIM4v5_64;
    SPICE_REAL BSIM4v5_65;
    SPICE_REAL BSIM4v5_66;
    SPICE_REAL BSIM4v5_67;
    SPICE_REAL BSIM4v5_68;
    SPICE_REAL BSIM4v5_69;
    SPICE_REAL BSIM4v5_70;
    SPICE_REAL BSIM4v5_71;
    SPICE_REAL BSIM4v5_72;
    SPICE_REAL BSIM4v5_73;
    SPICE_REAL BSIM4v5_74;
    SPICE_REAL BSIM4v5_75;
    SPICE_REAL BSIM4v5_76;
    SPICE_REAL BSIM4v5_77;
    SPICE_REAL BSIM4v5_78;
    SPICE_REAL BSIM4v5_79;
    SPICE_REAL BSIM4v5_80;
    SPICE_REAL BSIM4v5_81;
    SPICE_REAL BSIM4v5_82;
    SPICE_REAL BSIM4v5_83;
    SPICE_REAL BSIM4v5_84;
    SPICE_REAL BSIM4v5_85;
    SPICE_REAL BSIM4v5_86;
    SPICE_REAL BSIM4v5_87;
    SPICE_REAL BSIM4v5_88;
    SPICE_REAL BSIM4v5_89;
    SPICE_REAL BSIM4v5_90;
    SPICE_REAL BSIM4v5_91;
    SPICE_REAL BSIM4v5_92;
    SPICE_REAL BSIM4v5_93;
    SPICE_REAL BSIM4v5_94;
    SPICE_REAL BSIM4v5_95;
    SPICE_REAL BSIM4v5_96;
    SPICE_REAL BSIM4v5_97;
    SPICE_REAL BSIM4v5_98;
    SPICE_REAL BSIM4v5_99;
    SPICE_REAL BSIM4v5_100;
    SPICE_REAL BSIM4v5_101;
    SPICE_REAL BSIM4v5_102;
    SPICE_REAL BSIM4v5_103;

#endif

#define BSIM4v5vbd BSIM4v5states+ 0
#define BSIM4v5vbs BSIM4v5states+ 1
#define BSIM4v5vgs BSIM4v5states+ 2
#define BSIM4v5vds BSIM4v5states+ 3
#define BSIM4v5vdbs BSIM4v5states+ 4
#define BSIM4v5vdbd BSIM4v5states+ 5
#define BSIM4v5vsbs BSIM4v5states+ 6
#define BSIM4v5vges BSIM4v5states+ 7
#define BSIM4v5vgms BSIM4v5states+ 8
#define BSIM4v5vses BSIM4v5states+ 9
#define BSIM4v5vdes BSIM4v5states+ 10

#define BSIM4v5qb BSIM4v5states+ 11
#define BSIM4v5cqb BSIM4v5states+ 12
#define BSIM4v5qg BSIM4v5states+ 13
#define BSIM4v5cqg BSIM4v5states+ 14
#define BSIM4v5qd BSIM4v5states+ 15
#define BSIM4v5cqd BSIM4v5states+ 16
#define BSIM4v5qgmid BSIM4v5states+ 17
#define BSIM4v5cqgmid BSIM4v5states+ 18

#define BSIM4v5qbs  BSIM4v5states+ 19
#define BSIM4v5cqbs  BSIM4v5states+ 20
#define BSIM4v5qbd  BSIM4v5states+ 21
#define BSIM4v5cqbd  BSIM4v5states+ 22

#define BSIM4v5qcheq BSIM4v5states+ 23
#define BSIM4v5cqcheq BSIM4v5states+ 24
#define BSIM4v5qcdump BSIM4v5states+ 25
#define BSIM4v5cqcdump BSIM4v5states+ 26
#define BSIM4v5qdef BSIM4v5states+ 27
#define BSIM4v5qs BSIM4v5states+ 28

#define BSIM4v5numStates 29


/* indices to the array of BSIM4v5 NOISE SOURCES */

#define BSIM4v5RDNOIZ       0
#define BSIM4v5RSNOIZ       1
#define BSIM4v5RGNOIZ       2
#define BSIM4v5RBPSNOIZ     3
#define BSIM4v5RBPDNOIZ     4
#define BSIM4v5RBPBNOIZ     5
#define BSIM4v5RBSBNOIZ     6
#define BSIM4v5RBDBNOIZ     7
#define BSIM4v5IDNOIZ       8
#define BSIM4v5FLNOIZ       9
#define BSIM4v5IGSNOIZ      10
#define BSIM4v5IGDNOIZ      11
#define BSIM4v5IGBNOIZ      12
#define BSIM4v5TOTNOIZ      13

#define BSIM4v5NSRCS        14  /* Number of BSIM4v5 noise sources */

#ifndef NONOISE
    SPICE_REAL BSIM4v5nVar[NSTATVARS][BSIM4v5NSRCS];
#else /* NONOISE */
        SPICE_REAL **BSIM4v5nVar;
#endif /* NONOISE */

#ifdef KLU
    BindElement *BSIM4v5DPbpBinding ;
    BindElement *BSIM4v5GPbpBinding ;
    BindElement *BSIM4v5SPbpBinding ;
    BindElement *BSIM4v5BPdpBinding ;
    BindElement *BSIM4v5BPgpBinding ;
    BindElement *BSIM4v5BPspBinding ;
    BindElement *BSIM4v5BPbpBinding ;
    BindElement *BSIM4v5DdBinding ;
    BindElement *BSIM4v5GPgpBinding ;
    BindElement *BSIM4v5SsBinding ;
    BindElement *BSIM4v5DPdpBinding ;
    BindElement *BSIM4v5SPspBinding ;
    BindElement *BSIM4v5DdpBinding ;
    BindElement *BSIM4v5GPdpBinding ;
    BindElement *BSIM4v5GPspBinding ;
    BindElement *BSIM4v5SspBinding ;
    BindElement *BSIM4v5DPspBinding ;
    BindElement *BSIM4v5DPdBinding ;
    BindElement *BSIM4v5DPgpBinding ;
    BindElement *BSIM4v5SPgpBinding ;
    BindElement *BSIM4v5SPsBinding ;
    BindElement *BSIM4v5SPdpBinding ;
    BindElement *BSIM4v5QqBinding ;
    BindElement *BSIM4v5QbpBinding ;
    BindElement *BSIM4v5QdpBinding ;
    BindElement *BSIM4v5QspBinding ;
    BindElement *BSIM4v5QgpBinding ;
    BindElement *BSIM4v5DPqBinding ;
    BindElement *BSIM4v5SPqBinding ;
    BindElement *BSIM4v5GPqBinding ;
    BindElement *BSIM4v5GEgeBinding ;
    BindElement *BSIM4v5GEgpBinding ;
    BindElement *BSIM4v5GPgeBinding ;
    BindElement *BSIM4v5GEdpBinding ;
    BindElement *BSIM4v5GEspBinding ;
    BindElement *BSIM4v5GEbpBinding ;
    BindElement *BSIM4v5GMdpBinding ;
    BindElement *BSIM4v5GMgpBinding ;
    BindElement *BSIM4v5GMgmBinding ;
    BindElement *BSIM4v5GMgeBinding ;
    BindElement *BSIM4v5GMspBinding ;
    BindElement *BSIM4v5GMbpBinding ;
    BindElement *BSIM4v5DPgmBinding ;
    BindElement *BSIM4v5GPgmBinding ;
    BindElement *BSIM4v5GEgmBinding ;
    BindElement *BSIM4v5SPgmBinding ;
    BindElement *BSIM4v5BPgmBinding ;
    BindElement *BSIM4v5DPdbBinding ;
    BindElement *BSIM4v5SPsbBinding ;
    BindElement *BSIM4v5DBdpBinding ;
    BindElement *BSIM4v5DBdbBinding ;
    BindElement *BSIM4v5DBbpBinding ;
    BindElement *BSIM4v5DBbBinding ;
    BindElement *BSIM4v5BPdbBinding ;
    BindElement *BSIM4v5BPbBinding ;
    BindElement *BSIM4v5BPsbBinding ;
    BindElement *BSIM4v5SBspBinding ;
    BindElement *BSIM4v5SBbpBinding ;
    BindElement *BSIM4v5SBbBinding ;
    BindElement *BSIM4v5SBsbBinding ;
    BindElement *BSIM4v5BdbBinding ;
    BindElement *BSIM4v5BbpBinding ;
    BindElement *BSIM4v5BsbBinding ;
    BindElement *BSIM4v5BbBinding ;
    BindElement *BSIM4v5DgpBinding ;
    BindElement *BSIM4v5DspBinding ;
    BindElement *BSIM4v5DbpBinding ;
    BindElement *BSIM4v5SdpBinding ;
    BindElement *BSIM4v5SgpBinding ;
    BindElement *BSIM4v5SbpBinding ;
#endif

} BSIM4v5instance ;

struct bsim4v5SizeDependParam
{
    SPICE_REAL Width;
    SPICE_REAL Length;
    SPICE_REAL NFinger;

    SPICE_REAL BSIM4v5cdsc;           
    SPICE_REAL BSIM4v5cdscb;    
    SPICE_REAL BSIM4v5cdscd;       
    SPICE_REAL BSIM4v5cit;           
    SPICE_REAL BSIM4v5nfactor;      
    SPICE_REAL BSIM4v5xj;
    SPICE_REAL BSIM4v5vsat;         
    SPICE_REAL BSIM4v5at;         
    SPICE_REAL BSIM4v5a0;   
    SPICE_REAL BSIM4v5ags;      
    SPICE_REAL BSIM4v5a1;         
    SPICE_REAL BSIM4v5a2;         
    SPICE_REAL BSIM4v5keta;     
    SPICE_REAL BSIM4v5nsub;
    SPICE_REAL BSIM4v5ndep;        
    SPICE_REAL BSIM4v5nsd;
    SPICE_REAL BSIM4v5phin;
    SPICE_REAL BSIM4v5ngate;        
    SPICE_REAL BSIM4v5gamma1;      
    SPICE_REAL BSIM4v5gamma2;     
    SPICE_REAL BSIM4v5vbx;      
    SPICE_REAL BSIM4v5vbi;       
    SPICE_REAL BSIM4v5vbm;       
    SPICE_REAL BSIM4v5xt;       
    SPICE_REAL BSIM4v5phi;
    SPICE_REAL BSIM4v5litl;
    SPICE_REAL BSIM4v5k1;
    SPICE_REAL BSIM4v5kt1;
    SPICE_REAL BSIM4v5kt1l;
    SPICE_REAL BSIM4v5kt2;
    SPICE_REAL BSIM4v5k2;
    SPICE_REAL BSIM4v5k3;
    SPICE_REAL BSIM4v5k3b;
    SPICE_REAL BSIM4v5w0;
    SPICE_REAL BSIM4v5dvtp0;
    SPICE_REAL BSIM4v5dvtp1;
    SPICE_REAL BSIM4v5lpe0;
    SPICE_REAL BSIM4v5lpeb;
    SPICE_REAL BSIM4v5dvt0;      
    SPICE_REAL BSIM4v5dvt1;      
    SPICE_REAL BSIM4v5dvt2;      
    SPICE_REAL BSIM4v5dvt0w;      
    SPICE_REAL BSIM4v5dvt1w;      
    SPICE_REAL BSIM4v5dvt2w;      
    SPICE_REAL BSIM4v5drout;      
    SPICE_REAL BSIM4v5dsub;      
    SPICE_REAL BSIM4v5vth0;
    SPICE_REAL BSIM4v5ua;
    SPICE_REAL BSIM4v5ua1;
    SPICE_REAL BSIM4v5ub;
    SPICE_REAL BSIM4v5ub1;
    SPICE_REAL BSIM4v5uc;
    SPICE_REAL BSIM4v5uc1;
    SPICE_REAL BSIM4v5ud;
    SPICE_REAL BSIM4v5ud1;
    SPICE_REAL BSIM4v5up;
    SPICE_REAL BSIM4v5lp;
    SPICE_REAL BSIM4v5u0;
    SPICE_REAL BSIM4v5eu;
    SPICE_REAL BSIM4v5ute;
    SPICE_REAL BSIM4v5voff;
    SPICE_REAL BSIM4v5tvoff;
    SPICE_REAL BSIM4v5minv;
    SPICE_REAL BSIM4v5vfb;
    SPICE_REAL BSIM4v5delta;
    SPICE_REAL BSIM4v5rdsw;       
    SPICE_REAL BSIM4v5rds0;       
    SPICE_REAL BSIM4v5rs0;
    SPICE_REAL BSIM4v5rd0;
    SPICE_REAL BSIM4v5rsw;
    SPICE_REAL BSIM4v5rdw;
    SPICE_REAL BSIM4v5prwg;       
    SPICE_REAL BSIM4v5prwb;       
    SPICE_REAL BSIM4v5prt;       
    SPICE_REAL BSIM4v5eta0;         
    SPICE_REAL BSIM4v5etab;         
    SPICE_REAL BSIM4v5pclm;      
    SPICE_REAL BSIM4v5pdibl1;      
    SPICE_REAL BSIM4v5pdibl2;      
    SPICE_REAL BSIM4v5pdiblb;      
    SPICE_REAL BSIM4v5fprout;
    SPICE_REAL BSIM4v5pdits;
    SPICE_REAL BSIM4v5pditsd;
    SPICE_REAL BSIM4v5pscbe1;       
    SPICE_REAL BSIM4v5pscbe2;       
    SPICE_REAL BSIM4v5pvag;       
    SPICE_REAL BSIM4v5wr;
    SPICE_REAL BSIM4v5dwg;
    SPICE_REAL BSIM4v5dwb;
    SPICE_REAL BSIM4v5b0;
    SPICE_REAL BSIM4v5b1;
    SPICE_REAL BSIM4v5alpha0;
    SPICE_REAL BSIM4v5alpha1;
    SPICE_REAL BSIM4v5beta0;
    SPICE_REAL BSIM4v5agidl;
    SPICE_REAL BSIM4v5bgidl;
    SPICE_REAL BSIM4v5cgidl;
    SPICE_REAL BSIM4v5egidl;
    SPICE_REAL BSIM4v5aigc;
    SPICE_REAL BSIM4v5bigc;
    SPICE_REAL BSIM4v5cigc;
    SPICE_REAL BSIM4v5aigsd;
    SPICE_REAL BSIM4v5bigsd;
    SPICE_REAL BSIM4v5cigsd;
    SPICE_REAL BSIM4v5aigbacc;
    SPICE_REAL BSIM4v5bigbacc;
    SPICE_REAL BSIM4v5cigbacc;
    SPICE_REAL BSIM4v5aigbinv;
    SPICE_REAL BSIM4v5bigbinv;
    SPICE_REAL BSIM4v5cigbinv;
    SPICE_REAL BSIM4v5nigc;
    SPICE_REAL BSIM4v5nigbacc;
    SPICE_REAL BSIM4v5nigbinv;
    SPICE_REAL BSIM4v5ntox;
    SPICE_REAL BSIM4v5eigbinv;
    SPICE_REAL BSIM4v5pigcd;
    SPICE_REAL BSIM4v5poxedge;
    SPICE_REAL BSIM4v5xrcrg1;
    SPICE_REAL BSIM4v5xrcrg2;
    SPICE_REAL BSIM4v5lambda; /* overshoot */
    SPICE_REAL BSIM4v5vtl; /* thermal velocity limit */
    SPICE_REAL BSIM4v5xn; /* back scattering parameter */
    SPICE_REAL BSIM4v5lc; /* back scattering parameter */
    SPICE_REAL BSIM4v5tfactor;  /* ballistic transportation factor  */
    SPICE_REAL BSIM4v5vfbsdoff;  /* S/D flatband offset voltage  */
    SPICE_REAL BSIM4v5tvfbsdoff;  

/* added for stress effect */
    SPICE_REAL BSIM4v5ku0;
    SPICE_REAL BSIM4v5kvth0;
    SPICE_REAL BSIM4v5ku0temp;
    SPICE_REAL BSIM4v5rho_ref;
    SPICE_REAL BSIM4v5inv_od_ref;
/* added for well proximity effect */
    SPICE_REAL BSIM4v5kvth0we;
    SPICE_REAL BSIM4v5k2we;
    SPICE_REAL BSIM4v5ku0we;

    /* CV model */
    SPICE_REAL BSIM4v5cgsl;
    SPICE_REAL BSIM4v5cgdl;
    SPICE_REAL BSIM4v5ckappas;
    SPICE_REAL BSIM4v5ckappad;
    SPICE_REAL BSIM4v5cf;
    SPICE_REAL BSIM4v5clc;
    SPICE_REAL BSIM4v5cle;
    SPICE_REAL BSIM4v5vfbcv;
    SPICE_REAL BSIM4v5noff;
    SPICE_REAL BSIM4v5voffcv;
    SPICE_REAL BSIM4v5acde;
    SPICE_REAL BSIM4v5moin;

/* Pre-calculated constants */

    SPICE_REAL BSIM4v5dw;
    SPICE_REAL BSIM4v5dl;
    SPICE_REAL BSIM4v5leff;
    SPICE_REAL BSIM4v5weff;

    SPICE_REAL BSIM4v5dwc;
    SPICE_REAL BSIM4v5dlc;
    SPICE_REAL BSIM4v5dlcig;
    SPICE_REAL BSIM4v5dwj;
    SPICE_REAL BSIM4v5leffCV;
    SPICE_REAL BSIM4v5weffCV;
    SPICE_REAL BSIM4v5weffCJ;
    SPICE_REAL BSIM4v5abulkCVfactor;
    SPICE_REAL BSIM4v5cgso;
    SPICE_REAL BSIM4v5cgdo;
    SPICE_REAL BSIM4v5cgbo;

    SPICE_REAL BSIM4v5u0temp;       
    SPICE_REAL BSIM4v5vsattemp;   
    SPICE_REAL BSIM4v5sqrtPhi;   
    SPICE_REAL BSIM4v5phis3;   
    SPICE_REAL BSIM4v5Xdep0;          
    SPICE_REAL BSIM4v5sqrtXdep0;          
    SPICE_REAL BSIM4v5theta0vb0;
    SPICE_REAL BSIM4v5thetaRout; 
    SPICE_REAL BSIM4v5mstar;
    SPICE_REAL BSIM4v5voffcbn;
    SPICE_REAL BSIM4v5rdswmin;
    SPICE_REAL BSIM4v5rdwmin;
    SPICE_REAL BSIM4v5rswmin;
    SPICE_REAL BSIM4v5vfbsd;

    SPICE_REAL BSIM4v5cof1;
    SPICE_REAL BSIM4v5cof2;
    SPICE_REAL BSIM4v5cof3;
    SPICE_REAL BSIM4v5cof4;
    SPICE_REAL BSIM4v5cdep0;
    SPICE_REAL BSIM4v5ToxRatio;
    SPICE_REAL BSIM4v5Aechvb;
    SPICE_REAL BSIM4v5Bechvb;
    SPICE_REAL BSIM4v5ToxRatioEdge;
    SPICE_REAL BSIM4v5AechvbEdge;
    SPICE_REAL BSIM4v5BechvbEdge;
    SPICE_REAL BSIM4v5ldeb;
    SPICE_REAL BSIM4v5k1ox;
    SPICE_REAL BSIM4v5k2ox;
    SPICE_REAL BSIM4v5vfbzbfactor;


    struct bsim4v5SizeDependParam  *pNext;
};


typedef struct sBSIM4v5model 
{

    struct GENmodel gen;

#define BSIM4v5modType gen.GENmodType
#define BSIM4v5nextModel(inst) ((struct sBSIM4v5model *)((inst)->gen.GENnextModel))
#define BSIM4v5instances(inst) ((BSIM4v5instance *)((inst)->gen.GENinstances))
#define BSIM4v5modName gen.GENmodName

    int BSIM4v5type;

    int    BSIM4v5mobMod;
    int    BSIM4v5capMod;
    int    BSIM4v5dioMod;
    int    BSIM4v5trnqsMod;
    int    BSIM4v5acnqsMod;
    int    BSIM4v5fnoiMod;
    int    BSIM4v5tnoiMod;
    int    BSIM4v5rdsMod;
    int    BSIM4v5rbodyMod;
    int    BSIM4v5rgateMod;
    int    BSIM4v5perMod;
    int    BSIM4v5geoMod;
    int    BSIM4v5rgeoMod;
    int    BSIM4v5igcMod;
    int    BSIM4v5igbMod;
    int    BSIM4v5tempMod;
    int    BSIM4v5binUnit;
    int    BSIM4v5paramChk;
    char   *BSIM4v5version;             
    SPICE_REAL BSIM4v5toxe;             
    SPICE_REAL BSIM4v5toxp;
    SPICE_REAL BSIM4v5toxm;
    SPICE_REAL BSIM4v5dtox;
    SPICE_REAL BSIM4v5epsrox;
    SPICE_REAL BSIM4v5cdsc;           
    SPICE_REAL BSIM4v5cdscb; 
    SPICE_REAL BSIM4v5cdscd;          
    SPICE_REAL BSIM4v5cit;           
    SPICE_REAL BSIM4v5nfactor;      
    SPICE_REAL BSIM4v5xj;
    SPICE_REAL BSIM4v5vsat;         
    SPICE_REAL BSIM4v5at;         
    SPICE_REAL BSIM4v5a0;   
    SPICE_REAL BSIM4v5ags;      
    SPICE_REAL BSIM4v5a1;         
    SPICE_REAL BSIM4v5a2;         
    SPICE_REAL BSIM4v5keta;     
    SPICE_REAL BSIM4v5nsub;
    SPICE_REAL BSIM4v5ndep;        
    SPICE_REAL BSIM4v5nsd;
    SPICE_REAL BSIM4v5phin;
    SPICE_REAL BSIM4v5ngate;        
    SPICE_REAL BSIM4v5gamma1;      
    SPICE_REAL BSIM4v5gamma2;     
    SPICE_REAL BSIM4v5vbx;      
    SPICE_REAL BSIM4v5vbm;       
    SPICE_REAL BSIM4v5xt;       
    SPICE_REAL BSIM4v5k1;
    SPICE_REAL BSIM4v5kt1;
    SPICE_REAL BSIM4v5kt1l;
    SPICE_REAL BSIM4v5kt2;
    SPICE_REAL BSIM4v5k2;
    SPICE_REAL BSIM4v5k3;
    SPICE_REAL BSIM4v5k3b;
    SPICE_REAL BSIM4v5w0;
    SPICE_REAL BSIM4v5dvtp0;
    SPICE_REAL BSIM4v5dvtp1;
    SPICE_REAL BSIM4v5lpe0;
    SPICE_REAL BSIM4v5lpeb;
    SPICE_REAL BSIM4v5dvt0;      
    SPICE_REAL BSIM4v5dvt1;      
    SPICE_REAL BSIM4v5dvt2;      
    SPICE_REAL BSIM4v5dvt0w;      
    SPICE_REAL BSIM4v5dvt1w;      
    SPICE_REAL BSIM4v5dvt2w;      
    SPICE_REAL BSIM4v5drout;      
    SPICE_REAL BSIM4v5dsub;      
    SPICE_REAL BSIM4v5vth0;
    SPICE_REAL BSIM4v5eu;
    SPICE_REAL BSIM4v5ua;
    SPICE_REAL BSIM4v5ua1;
    SPICE_REAL BSIM4v5ub;
    SPICE_REAL BSIM4v5ub1;
    SPICE_REAL BSIM4v5uc;
    SPICE_REAL BSIM4v5uc1;
    SPICE_REAL BSIM4v5ud;
    SPICE_REAL BSIM4v5ud1;
    SPICE_REAL BSIM4v5up;
    SPICE_REAL BSIM4v5lp;
    SPICE_REAL BSIM4v5u0;
    SPICE_REAL BSIM4v5ute;
    SPICE_REAL BSIM4v5voff;
    SPICE_REAL BSIM4v5tvoff;
    SPICE_REAL BSIM4v5minv;
    SPICE_REAL BSIM4v5voffl;
    SPICE_REAL BSIM4v5delta;
    SPICE_REAL BSIM4v5rdsw;       
    SPICE_REAL BSIM4v5rdswmin;
    SPICE_REAL BSIM4v5rdwmin;
    SPICE_REAL BSIM4v5rswmin;
    SPICE_REAL BSIM4v5rsw;
    SPICE_REAL BSIM4v5rdw;
    SPICE_REAL BSIM4v5prwg;
    SPICE_REAL BSIM4v5prwb;
    SPICE_REAL BSIM4v5prt;       
    SPICE_REAL BSIM4v5eta0;         
    SPICE_REAL BSIM4v5etab;         
    SPICE_REAL BSIM4v5pclm;      
    SPICE_REAL BSIM4v5pdibl1;      
    SPICE_REAL BSIM4v5pdibl2;      
    SPICE_REAL BSIM4v5pdiblb;
    SPICE_REAL BSIM4v5fprout;
    SPICE_REAL BSIM4v5pdits;
    SPICE_REAL BSIM4v5pditsd;
    SPICE_REAL BSIM4v5pditsl;
    SPICE_REAL BSIM4v5pscbe1;       
    SPICE_REAL BSIM4v5pscbe2;       
    SPICE_REAL BSIM4v5pvag;       
    SPICE_REAL BSIM4v5wr;
    SPICE_REAL BSIM4v5dwg;
    SPICE_REAL BSIM4v5dwb;
    SPICE_REAL BSIM4v5b0;
    SPICE_REAL BSIM4v5b1;
    SPICE_REAL BSIM4v5alpha0;
    SPICE_REAL BSIM4v5alpha1;
    SPICE_REAL BSIM4v5beta0;
    SPICE_REAL BSIM4v5agidl;
    SPICE_REAL BSIM4v5bgidl;
    SPICE_REAL BSIM4v5cgidl;
    SPICE_REAL BSIM4v5egidl;
    SPICE_REAL BSIM4v5aigc;
    SPICE_REAL BSIM4v5bigc;
    SPICE_REAL BSIM4v5cigc;
    SPICE_REAL BSIM4v5aigsd;
    SPICE_REAL BSIM4v5bigsd;
    SPICE_REAL BSIM4v5cigsd;
    SPICE_REAL BSIM4v5aigbacc;
    SPICE_REAL BSIM4v5bigbacc;
    SPICE_REAL BSIM4v5cigbacc;
    SPICE_REAL BSIM4v5aigbinv;
    SPICE_REAL BSIM4v5bigbinv;
    SPICE_REAL BSIM4v5cigbinv;
    SPICE_REAL BSIM4v5nigc;
    SPICE_REAL BSIM4v5nigbacc;
    SPICE_REAL BSIM4v5nigbinv;
    SPICE_REAL BSIM4v5ntox;
    SPICE_REAL BSIM4v5eigbinv;
    SPICE_REAL BSIM4v5pigcd;
    SPICE_REAL BSIM4v5poxedge;
    SPICE_REAL BSIM4v5toxref;
    SPICE_REAL BSIM4v5ijthdfwd;
    SPICE_REAL BSIM4v5ijthsfwd;
    SPICE_REAL BSIM4v5ijthdrev;
    SPICE_REAL BSIM4v5ijthsrev;
    SPICE_REAL BSIM4v5xjbvd;
    SPICE_REAL BSIM4v5xjbvs;
    SPICE_REAL BSIM4v5bvd;
    SPICE_REAL BSIM4v5bvs;

    SPICE_REAL BSIM4v5jtss;
    SPICE_REAL BSIM4v5jtsd;
    SPICE_REAL BSIM4v5jtssws;
    SPICE_REAL BSIM4v5jtsswd;
    SPICE_REAL BSIM4v5jtsswgs;
    SPICE_REAL BSIM4v5jtsswgd;
    SPICE_REAL BSIM4v5njts;
    SPICE_REAL BSIM4v5njtssw;
    SPICE_REAL BSIM4v5njtsswg;
    SPICE_REAL BSIM4v5xtss;
    SPICE_REAL BSIM4v5xtsd;
    SPICE_REAL BSIM4v5xtssws;
    SPICE_REAL BSIM4v5xtsswd;
    SPICE_REAL BSIM4v5xtsswgs;
    SPICE_REAL BSIM4v5xtsswgd;
    SPICE_REAL BSIM4v5tnjts;
    SPICE_REAL BSIM4v5tnjtssw;
    SPICE_REAL BSIM4v5tnjtsswg;
    SPICE_REAL BSIM4v5vtss;
    SPICE_REAL BSIM4v5vtsd;
    SPICE_REAL BSIM4v5vtssws;
    SPICE_REAL BSIM4v5vtsswd;
    SPICE_REAL BSIM4v5vtsswgs;
    SPICE_REAL BSIM4v5vtsswgd;

    SPICE_REAL BSIM4v5xrcrg1;
    SPICE_REAL BSIM4v5xrcrg2;
    SPICE_REAL BSIM4v5lambda;
    SPICE_REAL BSIM4v5vtl; 
    SPICE_REAL BSIM4v5lc; 
    SPICE_REAL BSIM4v5xn; 
    SPICE_REAL BSIM4v5vfbsdoff;  /* S/D flatband offset voltage  */
    SPICE_REAL BSIM4v5lintnoi;  /* lint offset for noise calculation  */
    SPICE_REAL BSIM4v5tvfbsdoff;  

    SPICE_REAL BSIM4v5vfb;
    SPICE_REAL BSIM4v5gbmin;
    SPICE_REAL BSIM4v5rbdb;
    SPICE_REAL BSIM4v5rbsb;
    SPICE_REAL BSIM4v5rbpb;
    SPICE_REAL BSIM4v5rbps;
    SPICE_REAL BSIM4v5rbpd;

    SPICE_REAL BSIM4v5rbps0;
    SPICE_REAL BSIM4v5rbpsl;
    SPICE_REAL BSIM4v5rbpsw;
    SPICE_REAL BSIM4v5rbpsnf;

    SPICE_REAL BSIM4v5rbpd0;
    SPICE_REAL BSIM4v5rbpdl;
    SPICE_REAL BSIM4v5rbpdw;
    SPICE_REAL BSIM4v5rbpdnf;

    SPICE_REAL BSIM4v5rbpbx0;
    SPICE_REAL BSIM4v5rbpbxl;
    SPICE_REAL BSIM4v5rbpbxw;
    SPICE_REAL BSIM4v5rbpbxnf;
    SPICE_REAL BSIM4v5rbpby0;
    SPICE_REAL BSIM4v5rbpbyl;
    SPICE_REAL BSIM4v5rbpbyw;
    SPICE_REAL BSIM4v5rbpbynf;

    SPICE_REAL BSIM4v5rbsbx0;
    SPICE_REAL BSIM4v5rbsby0;
    SPICE_REAL BSIM4v5rbdbx0;
    SPICE_REAL BSIM4v5rbdby0;

    SPICE_REAL BSIM4v5rbsdbxl;
    SPICE_REAL BSIM4v5rbsdbxw;
    SPICE_REAL BSIM4v5rbsdbxnf;
    SPICE_REAL BSIM4v5rbsdbyl;
    SPICE_REAL BSIM4v5rbsdbyw;
    SPICE_REAL BSIM4v5rbsdbynf;

    SPICE_REAL BSIM4v5tnoia;
    SPICE_REAL BSIM4v5tnoib;
    SPICE_REAL BSIM4v5rnoia;
    SPICE_REAL BSIM4v5rnoib;
    SPICE_REAL BSIM4v5ntnoi;

    /* CV model and Parasitics */
    SPICE_REAL BSIM4v5cgsl;
    SPICE_REAL BSIM4v5cgdl;
    SPICE_REAL BSIM4v5ckappas;
    SPICE_REAL BSIM4v5ckappad;
    SPICE_REAL BSIM4v5cf;
    SPICE_REAL BSIM4v5vfbcv;
    SPICE_REAL BSIM4v5clc;
    SPICE_REAL BSIM4v5cle;
    SPICE_REAL BSIM4v5dwc;
    SPICE_REAL BSIM4v5dlc;
    SPICE_REAL BSIM4v5xw;
    SPICE_REAL BSIM4v5xl;
    SPICE_REAL BSIM4v5dlcig;
    SPICE_REAL BSIM4v5dwj;
    SPICE_REAL BSIM4v5noff;
    SPICE_REAL BSIM4v5voffcv;
    SPICE_REAL BSIM4v5acde;
    SPICE_REAL BSIM4v5moin;
    SPICE_REAL BSIM4v5tcj;
    SPICE_REAL BSIM4v5tcjsw;
    SPICE_REAL BSIM4v5tcjswg;
    SPICE_REAL BSIM4v5tpb;
    SPICE_REAL BSIM4v5tpbsw;
    SPICE_REAL BSIM4v5tpbswg;
    SPICE_REAL BSIM4v5dmcg;
    SPICE_REAL BSIM4v5dmci;
    SPICE_REAL BSIM4v5dmdg;
    SPICE_REAL BSIM4v5dmcgt;
    SPICE_REAL BSIM4v5xgw;
    SPICE_REAL BSIM4v5xgl;
    SPICE_REAL BSIM4v5rshg;
    SPICE_REAL BSIM4v5ngcon;

    /* Length Dependence */
    SPICE_REAL BSIM4v5lcdsc;           
    SPICE_REAL BSIM4v5lcdscb; 
    SPICE_REAL BSIM4v5lcdscd;          
    SPICE_REAL BSIM4v5lcit;           
    SPICE_REAL BSIM4v5lnfactor;      
    SPICE_REAL BSIM4v5lxj;
    SPICE_REAL BSIM4v5lvsat;         
    SPICE_REAL BSIM4v5lat;         
    SPICE_REAL BSIM4v5la0;   
    SPICE_REAL BSIM4v5lags;      
    SPICE_REAL BSIM4v5la1;         
    SPICE_REAL BSIM4v5la2;         
    SPICE_REAL BSIM4v5lketa;     
    SPICE_REAL BSIM4v5lnsub;
    SPICE_REAL BSIM4v5lndep;        
    SPICE_REAL BSIM4v5lnsd;
    SPICE_REAL BSIM4v5lphin;
    SPICE_REAL BSIM4v5lngate;        
    SPICE_REAL BSIM4v5lgamma1;      
    SPICE_REAL BSIM4v5lgamma2;     
    SPICE_REAL BSIM4v5lvbx;      
    SPICE_REAL BSIM4v5lvbm;       
    SPICE_REAL BSIM4v5lxt;       
    SPICE_REAL BSIM4v5lk1;
    SPICE_REAL BSIM4v5lkt1;
    SPICE_REAL BSIM4v5lkt1l;
    SPICE_REAL BSIM4v5lkt2;
    SPICE_REAL BSIM4v5lk2;
    SPICE_REAL BSIM4v5lk3;
    SPICE_REAL BSIM4v5lk3b;
    SPICE_REAL BSIM4v5lw0;
    SPICE_REAL BSIM4v5ldvtp0;
    SPICE_REAL BSIM4v5ldvtp1;
    SPICE_REAL BSIM4v5llpe0;
    SPICE_REAL BSIM4v5llpeb;
    SPICE_REAL BSIM4v5ldvt0;      
    SPICE_REAL BSIM4v5ldvt1;      
    SPICE_REAL BSIM4v5ldvt2;      
    SPICE_REAL BSIM4v5ldvt0w;      
    SPICE_REAL BSIM4v5ldvt1w;      
    SPICE_REAL BSIM4v5ldvt2w;      
    SPICE_REAL BSIM4v5ldrout;      
    SPICE_REAL BSIM4v5ldsub;      
    SPICE_REAL BSIM4v5lvth0;
    SPICE_REAL BSIM4v5lua;
    SPICE_REAL BSIM4v5lua1;
    SPICE_REAL BSIM4v5lub;
    SPICE_REAL BSIM4v5lub1;
    SPICE_REAL BSIM4v5luc;
    SPICE_REAL BSIM4v5luc1;
    SPICE_REAL BSIM4v5lud;
    SPICE_REAL BSIM4v5lud1;
    SPICE_REAL BSIM4v5lup;
    SPICE_REAL BSIM4v5llp;
    SPICE_REAL BSIM4v5lu0;
    SPICE_REAL BSIM4v5leu;
    SPICE_REAL BSIM4v5lute;
    SPICE_REAL BSIM4v5lvoff;
    SPICE_REAL BSIM4v5ltvoff;
    SPICE_REAL BSIM4v5lminv;
    SPICE_REAL BSIM4v5ldelta;
    SPICE_REAL BSIM4v5lrdsw;       
    SPICE_REAL BSIM4v5lrsw;
    SPICE_REAL BSIM4v5lrdw;
    SPICE_REAL BSIM4v5lprwg;
    SPICE_REAL BSIM4v5lprwb;
    SPICE_REAL BSIM4v5lprt;       
    SPICE_REAL BSIM4v5leta0;         
    SPICE_REAL BSIM4v5letab;         
    SPICE_REAL BSIM4v5lpclm;      
    SPICE_REAL BSIM4v5lpdibl1;      
    SPICE_REAL BSIM4v5lpdibl2;      
    SPICE_REAL BSIM4v5lpdiblb;
    SPICE_REAL BSIM4v5lfprout;
    SPICE_REAL BSIM4v5lpdits;
    SPICE_REAL BSIM4v5lpditsd;
    SPICE_REAL BSIM4v5lpscbe1;       
    SPICE_REAL BSIM4v5lpscbe2;       
    SPICE_REAL BSIM4v5lpvag;       
    SPICE_REAL BSIM4v5lwr;
    SPICE_REAL BSIM4v5ldwg;
    SPICE_REAL BSIM4v5ldwb;
    SPICE_REAL BSIM4v5lb0;
    SPICE_REAL BSIM4v5lb1;
    SPICE_REAL BSIM4v5lalpha0;
    SPICE_REAL BSIM4v5lalpha1;
    SPICE_REAL BSIM4v5lbeta0;
    SPICE_REAL BSIM4v5lvfb;
    SPICE_REAL BSIM4v5lagidl;
    SPICE_REAL BSIM4v5lbgidl;
    SPICE_REAL BSIM4v5lcgidl;
    SPICE_REAL BSIM4v5legidl;
    SPICE_REAL BSIM4v5laigc;
    SPICE_REAL BSIM4v5lbigc;
    SPICE_REAL BSIM4v5lcigc;
    SPICE_REAL BSIM4v5laigsd;
    SPICE_REAL BSIM4v5lbigsd;
    SPICE_REAL BSIM4v5lcigsd;
    SPICE_REAL BSIM4v5laigbacc;
    SPICE_REAL BSIM4v5lbigbacc;
    SPICE_REAL BSIM4v5lcigbacc;
    SPICE_REAL BSIM4v5laigbinv;
    SPICE_REAL BSIM4v5lbigbinv;
    SPICE_REAL BSIM4v5lcigbinv;
    SPICE_REAL BSIM4v5lnigc;
    SPICE_REAL BSIM4v5lnigbacc;
    SPICE_REAL BSIM4v5lnigbinv;
    SPICE_REAL BSIM4v5lntox;
    SPICE_REAL BSIM4v5leigbinv;
    SPICE_REAL BSIM4v5lpigcd;
    SPICE_REAL BSIM4v5lpoxedge;
    SPICE_REAL BSIM4v5lxrcrg1;
    SPICE_REAL BSIM4v5lxrcrg2;
    SPICE_REAL BSIM4v5llambda;
    SPICE_REAL BSIM4v5lvtl; 
    SPICE_REAL BSIM4v5lxn; 
    SPICE_REAL BSIM4v5lvfbsdoff; 
    SPICE_REAL BSIM4v5ltvfbsdoff; 

    /* CV model */
    SPICE_REAL BSIM4v5lcgsl;
    SPICE_REAL BSIM4v5lcgdl;
    SPICE_REAL BSIM4v5lckappas;
    SPICE_REAL BSIM4v5lckappad;
    SPICE_REAL BSIM4v5lcf;
    SPICE_REAL BSIM4v5lclc;
    SPICE_REAL BSIM4v5lcle;
    SPICE_REAL BSIM4v5lvfbcv;
    SPICE_REAL BSIM4v5lnoff;
    SPICE_REAL BSIM4v5lvoffcv;
    SPICE_REAL BSIM4v5lacde;
    SPICE_REAL BSIM4v5lmoin;

    /* Width Dependence */
    SPICE_REAL BSIM4v5wcdsc;           
    SPICE_REAL BSIM4v5wcdscb; 
    SPICE_REAL BSIM4v5wcdscd;          
    SPICE_REAL BSIM4v5wcit;           
    SPICE_REAL BSIM4v5wnfactor;      
    SPICE_REAL BSIM4v5wxj;
    SPICE_REAL BSIM4v5wvsat;         
    SPICE_REAL BSIM4v5wat;         
    SPICE_REAL BSIM4v5wa0;   
    SPICE_REAL BSIM4v5wags;      
    SPICE_REAL BSIM4v5wa1;         
    SPICE_REAL BSIM4v5wa2;         
    SPICE_REAL BSIM4v5wketa;     
    SPICE_REAL BSIM4v5wnsub;
    SPICE_REAL BSIM4v5wndep;        
    SPICE_REAL BSIM4v5wnsd;
    SPICE_REAL BSIM4v5wphin;
    SPICE_REAL BSIM4v5wngate;        
    SPICE_REAL BSIM4v5wgamma1;      
    SPICE_REAL BSIM4v5wgamma2;     
    SPICE_REAL BSIM4v5wvbx;      
    SPICE_REAL BSIM4v5wvbm;       
    SPICE_REAL BSIM4v5wxt;       
    SPICE_REAL BSIM4v5wk1;
    SPICE_REAL BSIM4v5wkt1;
    SPICE_REAL BSIM4v5wkt1l;
    SPICE_REAL BSIM4v5wkt2;
    SPICE_REAL BSIM4v5wk2;
    SPICE_REAL BSIM4v5wk3;
    SPICE_REAL BSIM4v5wk3b;
    SPICE_REAL BSIM4v5ww0;
    SPICE_REAL BSIM4v5wdvtp0;
    SPICE_REAL BSIM4v5wdvtp1;
    SPICE_REAL BSIM4v5wlpe0;
    SPICE_REAL BSIM4v5wlpeb;
    SPICE_REAL BSIM4v5wdvt0;      
    SPICE_REAL BSIM4v5wdvt1;      
    SPICE_REAL BSIM4v5wdvt2;      
    SPICE_REAL BSIM4v5wdvt0w;      
    SPICE_REAL BSIM4v5wdvt1w;      
    SPICE_REAL BSIM4v5wdvt2w;      
    SPICE_REAL BSIM4v5wdrout;      
    SPICE_REAL BSIM4v5wdsub;      
    SPICE_REAL BSIM4v5wvth0;
    SPICE_REAL BSIM4v5wua;
    SPICE_REAL BSIM4v5wua1;
    SPICE_REAL BSIM4v5wub;
    SPICE_REAL BSIM4v5wub1;
    SPICE_REAL BSIM4v5wuc;
    SPICE_REAL BSIM4v5wuc1;
    SPICE_REAL BSIM4v5wud;
    SPICE_REAL BSIM4v5wud1;
    SPICE_REAL BSIM4v5wup;
    SPICE_REAL BSIM4v5wlp;
    SPICE_REAL BSIM4v5wu0;
    SPICE_REAL BSIM4v5weu;
    SPICE_REAL BSIM4v5wute;
    SPICE_REAL BSIM4v5wvoff;
    SPICE_REAL BSIM4v5wtvoff;
    SPICE_REAL BSIM4v5wminv;
    SPICE_REAL BSIM4v5wdelta;
    SPICE_REAL BSIM4v5wrdsw;       
    SPICE_REAL BSIM4v5wrsw;
    SPICE_REAL BSIM4v5wrdw;
    SPICE_REAL BSIM4v5wprwg;
    SPICE_REAL BSIM4v5wprwb;
    SPICE_REAL BSIM4v5wprt;       
    SPICE_REAL BSIM4v5weta0;         
    SPICE_REAL BSIM4v5wetab;         
    SPICE_REAL BSIM4v5wpclm;      
    SPICE_REAL BSIM4v5wpdibl1;      
    SPICE_REAL BSIM4v5wpdibl2;      
    SPICE_REAL BSIM4v5wpdiblb;
    SPICE_REAL BSIM4v5wfprout;
    SPICE_REAL BSIM4v5wpdits;
    SPICE_REAL BSIM4v5wpditsd;
    SPICE_REAL BSIM4v5wpscbe1;       
    SPICE_REAL BSIM4v5wpscbe2;       
    SPICE_REAL BSIM4v5wpvag;       
    SPICE_REAL BSIM4v5wwr;
    SPICE_REAL BSIM4v5wdwg;
    SPICE_REAL BSIM4v5wdwb;
    SPICE_REAL BSIM4v5wb0;
    SPICE_REAL BSIM4v5wb1;
    SPICE_REAL BSIM4v5walpha0;
    SPICE_REAL BSIM4v5walpha1;
    SPICE_REAL BSIM4v5wbeta0;
    SPICE_REAL BSIM4v5wvfb;
    SPICE_REAL BSIM4v5wagidl;
    SPICE_REAL BSIM4v5wbgidl;
    SPICE_REAL BSIM4v5wcgidl;
    SPICE_REAL BSIM4v5wegidl;
    SPICE_REAL BSIM4v5waigc;
    SPICE_REAL BSIM4v5wbigc;
    SPICE_REAL BSIM4v5wcigc;
    SPICE_REAL BSIM4v5waigsd;
    SPICE_REAL BSIM4v5wbigsd;
    SPICE_REAL BSIM4v5wcigsd;
    SPICE_REAL BSIM4v5waigbacc;
    SPICE_REAL BSIM4v5wbigbacc;
    SPICE_REAL BSIM4v5wcigbacc;
    SPICE_REAL BSIM4v5waigbinv;
    SPICE_REAL BSIM4v5wbigbinv;
    SPICE_REAL BSIM4v5wcigbinv;
    SPICE_REAL BSIM4v5wnigc;
    SPICE_REAL BSIM4v5wnigbacc;
    SPICE_REAL BSIM4v5wnigbinv;
    SPICE_REAL BSIM4v5wntox;
    SPICE_REAL BSIM4v5weigbinv;
    SPICE_REAL BSIM4v5wpigcd;
    SPICE_REAL BSIM4v5wpoxedge;
    SPICE_REAL BSIM4v5wxrcrg1;
    SPICE_REAL BSIM4v5wxrcrg2;
    SPICE_REAL BSIM4v5wlambda;
    SPICE_REAL BSIM4v5wvtl; 
    SPICE_REAL BSIM4v5wxn; 
    SPICE_REAL BSIM4v5wvfbsdoff;  
    SPICE_REAL BSIM4v5wtvfbsdoff;  

    /* CV model */
    SPICE_REAL BSIM4v5wcgsl;
    SPICE_REAL BSIM4v5wcgdl;
    SPICE_REAL BSIM4v5wckappas;
    SPICE_REAL BSIM4v5wckappad;
    SPICE_REAL BSIM4v5wcf;
    SPICE_REAL BSIM4v5wclc;
    SPICE_REAL BSIM4v5wcle;
    SPICE_REAL BSIM4v5wvfbcv;
    SPICE_REAL BSIM4v5wnoff;
    SPICE_REAL BSIM4v5wvoffcv;
    SPICE_REAL BSIM4v5wacde;
    SPICE_REAL BSIM4v5wmoin;

    /* Cross-term Dependence */
    SPICE_REAL BSIM4v5pcdsc;           
    SPICE_REAL BSIM4v5pcdscb; 
    SPICE_REAL BSIM4v5pcdscd;          
    SPICE_REAL BSIM4v5pcit;           
    SPICE_REAL BSIM4v5pnfactor;      
    SPICE_REAL BSIM4v5pxj;
    SPICE_REAL BSIM4v5pvsat;         
    SPICE_REAL BSIM4v5pat;         
    SPICE_REAL BSIM4v5pa0;   
    SPICE_REAL BSIM4v5pags;      
    SPICE_REAL BSIM4v5pa1;         
    SPICE_REAL BSIM4v5pa2;         
    SPICE_REAL BSIM4v5pketa;     
    SPICE_REAL BSIM4v5pnsub;
    SPICE_REAL BSIM4v5pndep;        
    SPICE_REAL BSIM4v5pnsd;
    SPICE_REAL BSIM4v5pphin;
    SPICE_REAL BSIM4v5pngate;        
    SPICE_REAL BSIM4v5pgamma1;      
    SPICE_REAL BSIM4v5pgamma2;     
    SPICE_REAL BSIM4v5pvbx;      
    SPICE_REAL BSIM4v5pvbm;       
    SPICE_REAL BSIM4v5pxt;       
    SPICE_REAL BSIM4v5pk1;
    SPICE_REAL BSIM4v5pkt1;
    SPICE_REAL BSIM4v5pkt1l;
    SPICE_REAL BSIM4v5pkt2;
    SPICE_REAL BSIM4v5pk2;
    SPICE_REAL BSIM4v5pk3;
    SPICE_REAL BSIM4v5pk3b;
    SPICE_REAL BSIM4v5pw0;
    SPICE_REAL BSIM4v5pdvtp0;
    SPICE_REAL BSIM4v5pdvtp1;
    SPICE_REAL BSIM4v5plpe0;
    SPICE_REAL BSIM4v5plpeb;
    SPICE_REAL BSIM4v5pdvt0;      
    SPICE_REAL BSIM4v5pdvt1;      
    SPICE_REAL BSIM4v5pdvt2;      
    SPICE_REAL BSIM4v5pdvt0w;      
    SPICE_REAL BSIM4v5pdvt1w;      
    SPICE_REAL BSIM4v5pdvt2w;      
    SPICE_REAL BSIM4v5pdrout;      
    SPICE_REAL BSIM4v5pdsub;      
    SPICE_REAL BSIM4v5pvth0;
    SPICE_REAL BSIM4v5pua;
    SPICE_REAL BSIM4v5pua1;
    SPICE_REAL BSIM4v5pub;
    SPICE_REAL BSIM4v5pub1;
    SPICE_REAL BSIM4v5puc;
    SPICE_REAL BSIM4v5puc1;
    SPICE_REAL BSIM4v5pud;
    SPICE_REAL BSIM4v5pud1;
    SPICE_REAL BSIM4v5pup;
    SPICE_REAL BSIM4v5plp;
    SPICE_REAL BSIM4v5pu0;
    SPICE_REAL BSIM4v5peu;
    SPICE_REAL BSIM4v5pute;
    SPICE_REAL BSIM4v5pvoff;
    SPICE_REAL BSIM4v5ptvoff;
    SPICE_REAL BSIM4v5pminv;
    SPICE_REAL BSIM4v5pdelta;
    SPICE_REAL BSIM4v5prdsw;
    SPICE_REAL BSIM4v5prsw;
    SPICE_REAL BSIM4v5prdw;
    SPICE_REAL BSIM4v5pprwg;
    SPICE_REAL BSIM4v5pprwb;
    SPICE_REAL BSIM4v5pprt;       
    SPICE_REAL BSIM4v5peta0;         
    SPICE_REAL BSIM4v5petab;         
    SPICE_REAL BSIM4v5ppclm;      
    SPICE_REAL BSIM4v5ppdibl1;      
    SPICE_REAL BSIM4v5ppdibl2;      
    SPICE_REAL BSIM4v5ppdiblb;
    SPICE_REAL BSIM4v5pfprout;
    SPICE_REAL BSIM4v5ppdits;
    SPICE_REAL BSIM4v5ppditsd;
    SPICE_REAL BSIM4v5ppscbe1;       
    SPICE_REAL BSIM4v5ppscbe2;       
    SPICE_REAL BSIM4v5ppvag;       
    SPICE_REAL BSIM4v5pwr;
    SPICE_REAL BSIM4v5pdwg;
    SPICE_REAL BSIM4v5pdwb;
    SPICE_REAL BSIM4v5pb0;
    SPICE_REAL BSIM4v5pb1;
    SPICE_REAL BSIM4v5palpha0;
    SPICE_REAL BSIM4v5palpha1;
    SPICE_REAL BSIM4v5pbeta0;
    SPICE_REAL BSIM4v5pvfb;
    SPICE_REAL BSIM4v5pagidl;
    SPICE_REAL BSIM4v5pbgidl;
    SPICE_REAL BSIM4v5pcgidl;
    SPICE_REAL BSIM4v5pegidl;
    SPICE_REAL BSIM4v5paigc;
    SPICE_REAL BSIM4v5pbigc;
    SPICE_REAL BSIM4v5pcigc;
    SPICE_REAL BSIM4v5paigsd;
    SPICE_REAL BSIM4v5pbigsd;
    SPICE_REAL BSIM4v5pcigsd;
    SPICE_REAL BSIM4v5paigbacc;
    SPICE_REAL BSIM4v5pbigbacc;
    SPICE_REAL BSIM4v5pcigbacc;
    SPICE_REAL BSIM4v5paigbinv;
    SPICE_REAL BSIM4v5pbigbinv;
    SPICE_REAL BSIM4v5pcigbinv;
    SPICE_REAL BSIM4v5pnigc;
    SPICE_REAL BSIM4v5pnigbacc;
    SPICE_REAL BSIM4v5pnigbinv;
    SPICE_REAL BSIM4v5pntox;
    SPICE_REAL BSIM4v5peigbinv;
    SPICE_REAL BSIM4v5ppigcd;
    SPICE_REAL BSIM4v5ppoxedge;
    SPICE_REAL BSIM4v5pxrcrg1;
    SPICE_REAL BSIM4v5pxrcrg2;
    SPICE_REAL BSIM4v5plambda;
    SPICE_REAL BSIM4v5pvtl;
    SPICE_REAL BSIM4v5pxn; 
    SPICE_REAL BSIM4v5pvfbsdoff;  
    SPICE_REAL BSIM4v5ptvfbsdoff;  

    /* CV model */
    SPICE_REAL BSIM4v5pcgsl;
    SPICE_REAL BSIM4v5pcgdl;
    SPICE_REAL BSIM4v5pckappas;
    SPICE_REAL BSIM4v5pckappad;
    SPICE_REAL BSIM4v5pcf;
    SPICE_REAL BSIM4v5pclc;
    SPICE_REAL BSIM4v5pcle;
    SPICE_REAL BSIM4v5pvfbcv;
    SPICE_REAL BSIM4v5pnoff;
    SPICE_REAL BSIM4v5pvoffcv;
    SPICE_REAL BSIM4v5pacde;
    SPICE_REAL BSIM4v5pmoin;

    SPICE_REAL BSIM4v5tnom;
    SPICE_REAL BSIM4v5cgso;
    SPICE_REAL BSIM4v5cgdo;
    SPICE_REAL BSIM4v5cgbo;
    SPICE_REAL BSIM4v5xpart;
    SPICE_REAL BSIM4v5cFringOut;
    SPICE_REAL BSIM4v5cFringMax;

    SPICE_REAL BSIM4v5sheetResistance;
    SPICE_REAL BSIM4v5SjctSatCurDensity;
    SPICE_REAL BSIM4v5DjctSatCurDensity;
    SPICE_REAL BSIM4v5SjctSidewallSatCurDensity;
    SPICE_REAL BSIM4v5DjctSidewallSatCurDensity;
    SPICE_REAL BSIM4v5SjctGateSidewallSatCurDensity;
    SPICE_REAL BSIM4v5DjctGateSidewallSatCurDensity;
    SPICE_REAL BSIM4v5SbulkJctPotential;
    SPICE_REAL BSIM4v5DbulkJctPotential;
    SPICE_REAL BSIM4v5SbulkJctBotGradingCoeff;
    SPICE_REAL BSIM4v5DbulkJctBotGradingCoeff;
    SPICE_REAL BSIM4v5SbulkJctSideGradingCoeff;
    SPICE_REAL BSIM4v5DbulkJctSideGradingCoeff;
    SPICE_REAL BSIM4v5SbulkJctGateSideGradingCoeff;
    SPICE_REAL BSIM4v5DbulkJctGateSideGradingCoeff;
    SPICE_REAL BSIM4v5SsidewallJctPotential;
    SPICE_REAL BSIM4v5DsidewallJctPotential;
    SPICE_REAL BSIM4v5SGatesidewallJctPotential;
    SPICE_REAL BSIM4v5DGatesidewallJctPotential;
    SPICE_REAL BSIM4v5SunitAreaJctCap;
    SPICE_REAL BSIM4v5DunitAreaJctCap;
    SPICE_REAL BSIM4v5SunitLengthSidewallJctCap;
    SPICE_REAL BSIM4v5DunitLengthSidewallJctCap;
    SPICE_REAL BSIM4v5SunitLengthGateSidewallJctCap;
    SPICE_REAL BSIM4v5DunitLengthGateSidewallJctCap;
    SPICE_REAL BSIM4v5SjctEmissionCoeff;
    SPICE_REAL BSIM4v5DjctEmissionCoeff;
    SPICE_REAL BSIM4v5SjctTempExponent;
    SPICE_REAL BSIM4v5DjctTempExponent;
    SPICE_REAL BSIM4v5njtstemp;
    SPICE_REAL BSIM4v5njtsswtemp;
    SPICE_REAL BSIM4v5njtsswgtemp;

    SPICE_REAL BSIM4v5Lint;
    SPICE_REAL BSIM4v5Ll;
    SPICE_REAL BSIM4v5Llc;
    SPICE_REAL BSIM4v5Lln;
    SPICE_REAL BSIM4v5Lw;
    SPICE_REAL BSIM4v5Lwc;
    SPICE_REAL BSIM4v5Lwn;
    SPICE_REAL BSIM4v5Lwl;
    SPICE_REAL BSIM4v5Lwlc;
    SPICE_REAL BSIM4v5Lmin;
    SPICE_REAL BSIM4v5Lmax;

    SPICE_REAL BSIM4v5Wint;
    SPICE_REAL BSIM4v5Wl;
    SPICE_REAL BSIM4v5Wlc;
    SPICE_REAL BSIM4v5Wln;
    SPICE_REAL BSIM4v5Ww;
    SPICE_REAL BSIM4v5Wwc;
    SPICE_REAL BSIM4v5Wwn;
    SPICE_REAL BSIM4v5Wwl;
    SPICE_REAL BSIM4v5Wwlc;
    SPICE_REAL BSIM4v5Wmin;
    SPICE_REAL BSIM4v5Wmax;

    /* added for stress effect */
    SPICE_REAL BSIM4v5saref;
    SPICE_REAL BSIM4v5sbref;
    SPICE_REAL BSIM4v5wlod;
    SPICE_REAL BSIM4v5ku0;
    SPICE_REAL BSIM4v5kvsat;
    SPICE_REAL BSIM4v5kvth0;
    SPICE_REAL BSIM4v5tku0;
    SPICE_REAL BSIM4v5llodku0;
    SPICE_REAL BSIM4v5wlodku0;
    SPICE_REAL BSIM4v5llodvth;
    SPICE_REAL BSIM4v5wlodvth;
    SPICE_REAL BSIM4v5lku0;
    SPICE_REAL BSIM4v5wku0;
    SPICE_REAL BSIM4v5pku0;
    SPICE_REAL BSIM4v5lkvth0;
    SPICE_REAL BSIM4v5wkvth0;
    SPICE_REAL BSIM4v5pkvth0;
    SPICE_REAL BSIM4v5stk2;
    SPICE_REAL BSIM4v5lodk2;
    SPICE_REAL BSIM4v5steta0;
    SPICE_REAL BSIM4v5lodeta0;

    SPICE_REAL BSIM4v5web; 
    SPICE_REAL BSIM4v5wec;
    SPICE_REAL BSIM4v5kvth0we; 
    SPICE_REAL BSIM4v5k2we; 
    SPICE_REAL BSIM4v5ku0we; 
    SPICE_REAL BSIM4v5scref; 
    SPICE_REAL BSIM4v5wpemod; 
    SPICE_REAL BSIM4v5lkvth0we;
    SPICE_REAL BSIM4v5lk2we;
    SPICE_REAL BSIM4v5lku0we;
    SPICE_REAL BSIM4v5wkvth0we;
    SPICE_REAL BSIM4v5wk2we;
    SPICE_REAL BSIM4v5wku0we;
    SPICE_REAL BSIM4v5pkvth0we;
    SPICE_REAL BSIM4v5pk2we;
    SPICE_REAL BSIM4v5pku0we;

/* Pre-calculated constants
 * move to size-dependent param */
    SPICE_REAL BSIM4v5vtm;   
    SPICE_REAL BSIM4v5vtm0;   
    SPICE_REAL BSIM4v5coxe;
    SPICE_REAL BSIM4v5coxp;
    SPICE_REAL BSIM4v5cof1;
    SPICE_REAL BSIM4v5cof2;
    SPICE_REAL BSIM4v5cof3;
    SPICE_REAL BSIM4v5cof4;
    SPICE_REAL BSIM4v5vcrit;
    SPICE_REAL BSIM4v5factor1;
    SPICE_REAL BSIM4v5PhiBS;
    SPICE_REAL BSIM4v5PhiBSWS;
    SPICE_REAL BSIM4v5PhiBSWGS;
    SPICE_REAL BSIM4v5SjctTempSatCurDensity;
    SPICE_REAL BSIM4v5SjctSidewallTempSatCurDensity;
    SPICE_REAL BSIM4v5SjctGateSidewallTempSatCurDensity;
    SPICE_REAL BSIM4v5PhiBD;
    SPICE_REAL BSIM4v5PhiBSWD;
    SPICE_REAL BSIM4v5PhiBSWGD;
    SPICE_REAL BSIM4v5DjctTempSatCurDensity;
    SPICE_REAL BSIM4v5DjctSidewallTempSatCurDensity;
    SPICE_REAL BSIM4v5DjctGateSidewallTempSatCurDensity;
    SPICE_REAL BSIM4v5SunitAreaTempJctCap;
    SPICE_REAL BSIM4v5DunitAreaTempJctCap;
    SPICE_REAL BSIM4v5SunitLengthSidewallTempJctCap;
    SPICE_REAL BSIM4v5DunitLengthSidewallTempJctCap;
    SPICE_REAL BSIM4v5SunitLengthGateSidewallTempJctCap;
    SPICE_REAL BSIM4v5DunitLengthGateSidewallTempJctCap;

    SPICE_REAL BSIM4v5oxideTrapDensityA;      
    SPICE_REAL BSIM4v5oxideTrapDensityB;     
    SPICE_REAL BSIM4v5oxideTrapDensityC;  
    SPICE_REAL BSIM4v5em;  
    SPICE_REAL BSIM4v5ef;  
    SPICE_REAL BSIM4v5af;  
    SPICE_REAL BSIM4v5kf;  

    SPICE_REAL BSIM4v5vgsMax;
    SPICE_REAL BSIM4v5vgdMax;
    SPICE_REAL BSIM4v5vgbMax;
    SPICE_REAL BSIM4v5vdsMax;
    SPICE_REAL BSIM4v5vbsMax;
    SPICE_REAL BSIM4v5vbdMax;
    SPICE_REAL BSIM4v5vgsrMax;
    SPICE_REAL BSIM4v5vgdrMax;
    SPICE_REAL BSIM4v5vgbrMax;
    SPICE_REAL BSIM4v5vbsrMax;
    SPICE_REAL BSIM4v5vbdrMax;

    struct bsim4v5SizeDependParam *pSizeDependParamKnot;

#ifdef USE_OMP
    int BSIM4v5InstCount;
    struct sBSIM4v5instance **BSIM4v5InstanceArray;
#endif

    /* Flags */
    unsigned BSIM4v5rgeomodGiven :1;
    unsigned BSIM4v5stimodGiven :1;
    unsigned BSIM4v5sa0Given :1;
    unsigned BSIM4v5sb0Given :1;

    unsigned  BSIM4v5mobModGiven :1;
    unsigned  BSIM4v5binUnitGiven :1;
    unsigned  BSIM4v5capModGiven :1;
    unsigned  BSIM4v5dioModGiven :1;
    unsigned  BSIM4v5rdsModGiven :1;
    unsigned  BSIM4v5rbodyModGiven :1;
    unsigned  BSIM4v5rgateModGiven :1;
    unsigned  BSIM4v5perModGiven :1;
    unsigned  BSIM4v5geoModGiven :1;
    unsigned  BSIM4v5rgeoModGiven :1;
    unsigned  BSIM4v5paramChkGiven :1;
    unsigned  BSIM4v5trnqsModGiven :1;
    unsigned  BSIM4v5acnqsModGiven :1;
    unsigned  BSIM4v5fnoiModGiven :1;
    unsigned  BSIM4v5tnoiModGiven :1;
    unsigned  BSIM4v5igcModGiven :1;
    unsigned  BSIM4v5igbModGiven :1;
    unsigned  BSIM4v5tempModGiven :1;
    unsigned  BSIM4v5typeGiven   :1;
    unsigned  BSIM4v5toxrefGiven   :1;
    unsigned  BSIM4v5toxeGiven   :1;
    unsigned  BSIM4v5toxpGiven   :1;
    unsigned  BSIM4v5toxmGiven   :1;
    unsigned  BSIM4v5dtoxGiven   :1;
    unsigned  BSIM4v5epsroxGiven   :1;
    unsigned  BSIM4v5versionGiven   :1;
    unsigned  BSIM4v5cdscGiven   :1;
    unsigned  BSIM4v5cdscbGiven   :1;
    unsigned  BSIM4v5cdscdGiven   :1;
    unsigned  BSIM4v5citGiven   :1;
    unsigned  BSIM4v5nfactorGiven   :1;
    unsigned  BSIM4v5xjGiven   :1;
    unsigned  BSIM4v5vsatGiven   :1;
    unsigned  BSIM4v5atGiven   :1;
    unsigned  BSIM4v5a0Given   :1;
    unsigned  BSIM4v5agsGiven   :1;
    unsigned  BSIM4v5a1Given   :1;
    unsigned  BSIM4v5a2Given   :1;
    unsigned  BSIM4v5ketaGiven   :1;    
    unsigned  BSIM4v5nsubGiven   :1;
    unsigned  BSIM4v5ndepGiven   :1;
    unsigned  BSIM4v5nsdGiven    :1;
    unsigned  BSIM4v5phinGiven   :1;
    unsigned  BSIM4v5ngateGiven   :1;
    unsigned  BSIM4v5gamma1Given   :1;
    unsigned  BSIM4v5gamma2Given   :1;
    unsigned  BSIM4v5vbxGiven   :1;
    unsigned  BSIM4v5vbmGiven   :1;
    unsigned  BSIM4v5xtGiven   :1;
    unsigned  BSIM4v5k1Given   :1;
    unsigned  BSIM4v5kt1Given   :1;
    unsigned  BSIM4v5kt1lGiven   :1;
    unsigned  BSIM4v5kt2Given   :1;
    unsigned  BSIM4v5k2Given   :1;
    unsigned  BSIM4v5k3Given   :1;
    unsigned  BSIM4v5k3bGiven   :1;
    unsigned  BSIM4v5w0Given   :1;
    unsigned  BSIM4v5dvtp0Given :1;
    unsigned  BSIM4v5dvtp1Given :1;
    unsigned  BSIM4v5lpe0Given   :1;
    unsigned  BSIM4v5lpebGiven   :1;
    unsigned  BSIM4v5dvt0Given   :1;   
    unsigned  BSIM4v5dvt1Given   :1;     
    unsigned  BSIM4v5dvt2Given   :1;     
    unsigned  BSIM4v5dvt0wGiven   :1;   
    unsigned  BSIM4v5dvt1wGiven   :1;     
    unsigned  BSIM4v5dvt2wGiven   :1;     
    unsigned  BSIM4v5droutGiven   :1;     
    unsigned  BSIM4v5dsubGiven   :1;     
    unsigned  BSIM4v5vth0Given   :1;
    unsigned  BSIM4v5euGiven   :1;
    unsigned  BSIM4v5uaGiven   :1;
    unsigned  BSIM4v5ua1Given   :1;
    unsigned  BSIM4v5ubGiven   :1;
    unsigned  BSIM4v5ub1Given   :1;
    unsigned  BSIM4v5ucGiven   :1;
    unsigned  BSIM4v5uc1Given   :1;
    unsigned  BSIM4v5udGiven     :1;
    unsigned  BSIM4v5ud1Given     :1;
    unsigned  BSIM4v5upGiven     :1;
    unsigned  BSIM4v5lpGiven     :1;
    unsigned  BSIM4v5u0Given   :1;
    unsigned  BSIM4v5uteGiven   :1;
    unsigned  BSIM4v5voffGiven   :1;
    unsigned  BSIM4v5tvoffGiven   :1;
    unsigned  BSIM4v5vofflGiven  :1;
    unsigned  BSIM4v5minvGiven   :1;
    unsigned  BSIM4v5rdswGiven   :1;      
    unsigned  BSIM4v5rdswminGiven :1;
    unsigned  BSIM4v5rdwminGiven :1;
    unsigned  BSIM4v5rswminGiven :1;
    unsigned  BSIM4v5rswGiven   :1;
    unsigned  BSIM4v5rdwGiven   :1;
    unsigned  BSIM4v5prwgGiven   :1;      
    unsigned  BSIM4v5prwbGiven   :1;      
    unsigned  BSIM4v5prtGiven   :1;      
    unsigned  BSIM4v5eta0Given   :1;    
    unsigned  BSIM4v5etabGiven   :1;    
    unsigned  BSIM4v5pclmGiven   :1;   
    unsigned  BSIM4v5pdibl1Given   :1;   
    unsigned  BSIM4v5pdibl2Given   :1;  
    unsigned  BSIM4v5pdiblbGiven   :1;  
    unsigned  BSIM4v5fproutGiven   :1;
    unsigned  BSIM4v5pditsGiven    :1;
    unsigned  BSIM4v5pditsdGiven    :1;
    unsigned  BSIM4v5pditslGiven    :1;
    unsigned  BSIM4v5pscbe1Given   :1;    
    unsigned  BSIM4v5pscbe2Given   :1;    
    unsigned  BSIM4v5pvagGiven   :1;    
    unsigned  BSIM4v5deltaGiven  :1;     
    unsigned  BSIM4v5wrGiven   :1;
    unsigned  BSIM4v5dwgGiven   :1;
    unsigned  BSIM4v5dwbGiven   :1;
    unsigned  BSIM4v5b0Given   :1;
    unsigned  BSIM4v5b1Given   :1;
    unsigned  BSIM4v5alpha0Given   :1;
    unsigned  BSIM4v5alpha1Given   :1;
    unsigned  BSIM4v5beta0Given   :1;
    unsigned  BSIM4v5agidlGiven   :1;
    unsigned  BSIM4v5bgidlGiven   :1;
    unsigned  BSIM4v5cgidlGiven   :1;
    unsigned  BSIM4v5egidlGiven   :1;
    unsigned  BSIM4v5aigcGiven   :1;
    unsigned  BSIM4v5bigcGiven   :1;
    unsigned  BSIM4v5cigcGiven   :1;
    unsigned  BSIM4v5aigsdGiven   :1;
    unsigned  BSIM4v5bigsdGiven   :1;
    unsigned  BSIM4v5cigsdGiven   :1;
    unsigned  BSIM4v5aigbaccGiven   :1;
    unsigned  BSIM4v5bigbaccGiven   :1;
    unsigned  BSIM4v5cigbaccGiven   :1;
    unsigned  BSIM4v5aigbinvGiven   :1;
    unsigned  BSIM4v5bigbinvGiven   :1;
    unsigned  BSIM4v5cigbinvGiven   :1;
    unsigned  BSIM4v5nigcGiven   :1;
    unsigned  BSIM4v5nigbinvGiven   :1;
    unsigned  BSIM4v5nigbaccGiven   :1;
    unsigned  BSIM4v5ntoxGiven   :1;
    unsigned  BSIM4v5eigbinvGiven   :1;
    unsigned  BSIM4v5pigcdGiven   :1;
    unsigned  BSIM4v5poxedgeGiven   :1;
    unsigned  BSIM4v5ijthdfwdGiven  :1;
    unsigned  BSIM4v5ijthsfwdGiven  :1;
    unsigned  BSIM4v5ijthdrevGiven  :1;
    unsigned  BSIM4v5ijthsrevGiven  :1;
    unsigned  BSIM4v5xjbvdGiven   :1;
    unsigned  BSIM4v5xjbvsGiven   :1;
    unsigned  BSIM4v5bvdGiven   :1;
    unsigned  BSIM4v5bvsGiven   :1;

    unsigned  BSIM4v5jtssGiven   :1;
    unsigned  BSIM4v5jtsdGiven   :1;
    unsigned  BSIM4v5jtsswsGiven   :1;
    unsigned  BSIM4v5jtsswdGiven   :1;
    unsigned  BSIM4v5jtsswgsGiven   :1;
    unsigned  BSIM4v5jtsswgdGiven   :1;
    unsigned  BSIM4v5njtsGiven   :1;
    unsigned  BSIM4v5njtsswGiven   :1;
    unsigned  BSIM4v5njtsswgGiven   :1;
    unsigned  BSIM4v5xtssGiven   :1;
    unsigned  BSIM4v5xtsdGiven   :1;
    unsigned  BSIM4v5xtsswsGiven   :1;
    unsigned  BSIM4v5xtsswdGiven   :1;
    unsigned  BSIM4v5xtsswgsGiven   :1;
    unsigned  BSIM4v5xtsswgdGiven   :1;
    unsigned  BSIM4v5tnjtsGiven   :1;
    unsigned  BSIM4v5tnjtsswGiven   :1;
    unsigned  BSIM4v5tnjtsswgGiven   :1;
    unsigned  BSIM4v5vtssGiven   :1;
    unsigned  BSIM4v5vtsdGiven   :1;
    unsigned  BSIM4v5vtsswsGiven   :1;
    unsigned  BSIM4v5vtsswdGiven   :1;
    unsigned  BSIM4v5vtsswgsGiven   :1;
    unsigned  BSIM4v5vtsswgdGiven   :1;

    unsigned  BSIM4v5vfbGiven   :1;
    unsigned  BSIM4v5gbminGiven :1;
    unsigned  BSIM4v5rbdbGiven :1;
    unsigned  BSIM4v5rbsbGiven :1;
    unsigned  BSIM4v5rbpsGiven :1;
    unsigned  BSIM4v5rbpdGiven :1;
    unsigned  BSIM4v5rbpbGiven :1;

    unsigned BSIM4v5rbps0Given :1;
    unsigned BSIM4v5rbpslGiven :1;
    unsigned BSIM4v5rbpswGiven :1;
    unsigned BSIM4v5rbpsnfGiven :1;

    unsigned BSIM4v5rbpd0Given :1;
    unsigned BSIM4v5rbpdlGiven :1;
    unsigned BSIM4v5rbpdwGiven :1;
    unsigned BSIM4v5rbpdnfGiven :1;

    unsigned BSIM4v5rbpbx0Given :1;
    unsigned BSIM4v5rbpbxlGiven :1;
    unsigned BSIM4v5rbpbxwGiven :1;
    unsigned BSIM4v5rbpbxnfGiven :1;
    unsigned BSIM4v5rbpby0Given :1;
    unsigned BSIM4v5rbpbylGiven :1;
    unsigned BSIM4v5rbpbywGiven :1;
    unsigned BSIM4v5rbpbynfGiven :1;

    unsigned BSIM4v5rbsbx0Given :1;
    unsigned BSIM4v5rbsby0Given :1;
    unsigned BSIM4v5rbdbx0Given :1;
    unsigned BSIM4v5rbdby0Given :1;

    unsigned BSIM4v5rbsdbxlGiven :1;
    unsigned BSIM4v5rbsdbxwGiven :1;
    unsigned BSIM4v5rbsdbxnfGiven :1;
    unsigned BSIM4v5rbsdbylGiven :1;
    unsigned BSIM4v5rbsdbywGiven :1;
    unsigned BSIM4v5rbsdbynfGiven :1;

    unsigned  BSIM4v5xrcrg1Given   :1;
    unsigned  BSIM4v5xrcrg2Given   :1;
    unsigned  BSIM4v5tnoiaGiven    :1;
    unsigned  BSIM4v5tnoibGiven    :1;
    unsigned  BSIM4v5rnoiaGiven    :1;
    unsigned  BSIM4v5rnoibGiven    :1;
    unsigned  BSIM4v5ntnoiGiven    :1;

    unsigned  BSIM4v5lambdaGiven    :1;
    unsigned  BSIM4v5vtlGiven    :1;
    unsigned  BSIM4v5lcGiven    :1;
    unsigned  BSIM4v5xnGiven    :1;
    unsigned  BSIM4v5vfbsdoffGiven    :1;
    unsigned  BSIM4v5lintnoiGiven    :1;
    unsigned  BSIM4v5tvfbsdoffGiven    :1;

    /* CV model and parasitics */
    unsigned  BSIM4v5cgslGiven   :1;
    unsigned  BSIM4v5cgdlGiven   :1;
    unsigned  BSIM4v5ckappasGiven   :1;
    unsigned  BSIM4v5ckappadGiven   :1;
    unsigned  BSIM4v5cfGiven   :1;
    unsigned  BSIM4v5vfbcvGiven   :1;
    unsigned  BSIM4v5clcGiven   :1;
    unsigned  BSIM4v5cleGiven   :1;
    unsigned  BSIM4v5dwcGiven   :1;
    unsigned  BSIM4v5dlcGiven   :1;
    unsigned  BSIM4v5xwGiven    :1;
    unsigned  BSIM4v5xlGiven    :1;
    unsigned  BSIM4v5dlcigGiven   :1;
    unsigned  BSIM4v5dwjGiven   :1;
    unsigned  BSIM4v5noffGiven  :1;
    unsigned  BSIM4v5voffcvGiven :1;
    unsigned  BSIM4v5acdeGiven  :1;
    unsigned  BSIM4v5moinGiven  :1;
    unsigned  BSIM4v5tcjGiven   :1;
    unsigned  BSIM4v5tcjswGiven :1;
    unsigned  BSIM4v5tcjswgGiven :1;
    unsigned  BSIM4v5tpbGiven    :1;
    unsigned  BSIM4v5tpbswGiven  :1;
    unsigned  BSIM4v5tpbswgGiven :1;
    unsigned  BSIM4v5dmcgGiven :1;
    unsigned  BSIM4v5dmciGiven :1;
    unsigned  BSIM4v5dmdgGiven :1;
    unsigned  BSIM4v5dmcgtGiven :1;
    unsigned  BSIM4v5xgwGiven :1;
    unsigned  BSIM4v5xglGiven :1;
    unsigned  BSIM4v5rshgGiven :1;
    unsigned  BSIM4v5ngconGiven :1;


    /* Length dependence */
    unsigned  BSIM4v5lcdscGiven   :1;
    unsigned  BSIM4v5lcdscbGiven   :1;
    unsigned  BSIM4v5lcdscdGiven   :1;
    unsigned  BSIM4v5lcitGiven   :1;
    unsigned  BSIM4v5lnfactorGiven   :1;
    unsigned  BSIM4v5lxjGiven   :1;
    unsigned  BSIM4v5lvsatGiven   :1;
    unsigned  BSIM4v5latGiven   :1;
    unsigned  BSIM4v5la0Given   :1;
    unsigned  BSIM4v5lagsGiven   :1;
    unsigned  BSIM4v5la1Given   :1;
    unsigned  BSIM4v5la2Given   :1;
    unsigned  BSIM4v5lketaGiven   :1;    
    unsigned  BSIM4v5lnsubGiven   :1;
    unsigned  BSIM4v5lndepGiven   :1;
    unsigned  BSIM4v5lnsdGiven    :1;
    unsigned  BSIM4v5lphinGiven   :1;
    unsigned  BSIM4v5lngateGiven   :1;
    unsigned  BSIM4v5lgamma1Given   :1;
    unsigned  BSIM4v5lgamma2Given   :1;
    unsigned  BSIM4v5lvbxGiven   :1;
    unsigned  BSIM4v5lvbmGiven   :1;
    unsigned  BSIM4v5lxtGiven   :1;
    unsigned  BSIM4v5lk1Given   :1;
    unsigned  BSIM4v5lkt1Given   :1;
    unsigned  BSIM4v5lkt1lGiven   :1;
    unsigned  BSIM4v5lkt2Given   :1;
    unsigned  BSIM4v5lk2Given   :1;
    unsigned  BSIM4v5lk3Given   :1;
    unsigned  BSIM4v5lk3bGiven   :1;
    unsigned  BSIM4v5lw0Given   :1;
    unsigned  BSIM4v5ldvtp0Given :1;
    unsigned  BSIM4v5ldvtp1Given :1;
    unsigned  BSIM4v5llpe0Given   :1;
    unsigned  BSIM4v5llpebGiven   :1;
    unsigned  BSIM4v5ldvt0Given   :1;   
    unsigned  BSIM4v5ldvt1Given   :1;     
    unsigned  BSIM4v5ldvt2Given   :1;     
    unsigned  BSIM4v5ldvt0wGiven   :1;   
    unsigned  BSIM4v5ldvt1wGiven   :1;     
    unsigned  BSIM4v5ldvt2wGiven   :1;     
    unsigned  BSIM4v5ldroutGiven   :1;     
    unsigned  BSIM4v5ldsubGiven   :1;     
    unsigned  BSIM4v5lvth0Given   :1;
    unsigned  BSIM4v5luaGiven   :1;
    unsigned  BSIM4v5lua1Given   :1;
    unsigned  BSIM4v5lubGiven   :1;
    unsigned  BSIM4v5lub1Given   :1;
    unsigned  BSIM4v5lucGiven   :1;
    unsigned  BSIM4v5luc1Given   :1;
    unsigned  BSIM4v5ludGiven     :1;
    unsigned  BSIM4v5lud1Given     :1;
    unsigned  BSIM4v5lupGiven     :1;
    unsigned  BSIM4v5llpGiven     :1;
    unsigned  BSIM4v5lu0Given   :1;
    unsigned  BSIM4v5leuGiven   :1;
    unsigned  BSIM4v5luteGiven   :1;
    unsigned  BSIM4v5lvoffGiven   :1;
    unsigned  BSIM4v5ltvoffGiven   :1;
    unsigned  BSIM4v5lminvGiven   :1;
    unsigned  BSIM4v5lrdswGiven   :1;      
    unsigned  BSIM4v5lrswGiven   :1;
    unsigned  BSIM4v5lrdwGiven   :1;
    unsigned  BSIM4v5lprwgGiven   :1;      
    unsigned  BSIM4v5lprwbGiven   :1;      
    unsigned  BSIM4v5lprtGiven   :1;      
    unsigned  BSIM4v5leta0Given   :1;    
    unsigned  BSIM4v5letabGiven   :1;    
    unsigned  BSIM4v5lpclmGiven   :1;   
    unsigned  BSIM4v5lpdibl1Given   :1;   
    unsigned  BSIM4v5lpdibl2Given   :1;  
    unsigned  BSIM4v5lpdiblbGiven   :1;  
    unsigned  BSIM4v5lfproutGiven   :1;
    unsigned  BSIM4v5lpditsGiven    :1;
    unsigned  BSIM4v5lpditsdGiven    :1;
    unsigned  BSIM4v5lpscbe1Given   :1;    
    unsigned  BSIM4v5lpscbe2Given   :1;    
    unsigned  BSIM4v5lpvagGiven   :1;    
    unsigned  BSIM4v5ldeltaGiven  :1;     
    unsigned  BSIM4v5lwrGiven   :1;
    unsigned  BSIM4v5ldwgGiven   :1;
    unsigned  BSIM4v5ldwbGiven   :1;
    unsigned  BSIM4v5lb0Given   :1;
    unsigned  BSIM4v5lb1Given   :1;
    unsigned  BSIM4v5lalpha0Given   :1;
    unsigned  BSIM4v5lalpha1Given   :1;
    unsigned  BSIM4v5lbeta0Given   :1;
    unsigned  BSIM4v5lvfbGiven   :1;
    unsigned  BSIM4v5lagidlGiven   :1;
    unsigned  BSIM4v5lbgidlGiven   :1;
    unsigned  BSIM4v5lcgidlGiven   :1;
    unsigned  BSIM4v5legidlGiven   :1;
    unsigned  BSIM4v5laigcGiven   :1;
    unsigned  BSIM4v5lbigcGiven   :1;
    unsigned  BSIM4v5lcigcGiven   :1;
    unsigned  BSIM4v5laigsdGiven   :1;
    unsigned  BSIM4v5lbigsdGiven   :1;
    unsigned  BSIM4v5lcigsdGiven   :1;
    unsigned  BSIM4v5laigbaccGiven   :1;
    unsigned  BSIM4v5lbigbaccGiven   :1;
    unsigned  BSIM4v5lcigbaccGiven   :1;
    unsigned  BSIM4v5laigbinvGiven   :1;
    unsigned  BSIM4v5lbigbinvGiven   :1;
    unsigned  BSIM4v5lcigbinvGiven   :1;
    unsigned  BSIM4v5lnigcGiven   :1;
    unsigned  BSIM4v5lnigbinvGiven   :1;
    unsigned  BSIM4v5lnigbaccGiven   :1;
    unsigned  BSIM4v5lntoxGiven   :1;
    unsigned  BSIM4v5leigbinvGiven   :1;
    unsigned  BSIM4v5lpigcdGiven   :1;
    unsigned  BSIM4v5lpoxedgeGiven   :1;
    unsigned  BSIM4v5lxrcrg1Given   :1;
    unsigned  BSIM4v5lxrcrg2Given   :1;
    unsigned  BSIM4v5llambdaGiven    :1;
    unsigned  BSIM4v5lvtlGiven    :1;
    unsigned  BSIM4v5lxnGiven    :1;
    unsigned  BSIM4v5lvfbsdoffGiven    :1;
    unsigned  BSIM4v5ltvfbsdoffGiven    :1;

    /* CV model */
    unsigned  BSIM4v5lcgslGiven   :1;
    unsigned  BSIM4v5lcgdlGiven   :1;
    unsigned  BSIM4v5lckappasGiven   :1;
    unsigned  BSIM4v5lckappadGiven   :1;
    unsigned  BSIM4v5lcfGiven   :1;
    unsigned  BSIM4v5lclcGiven   :1;
    unsigned  BSIM4v5lcleGiven   :1;
    unsigned  BSIM4v5lvfbcvGiven   :1;
    unsigned  BSIM4v5lnoffGiven   :1;
    unsigned  BSIM4v5lvoffcvGiven :1;
    unsigned  BSIM4v5lacdeGiven   :1;
    unsigned  BSIM4v5lmoinGiven   :1;

    /* Width dependence */
    unsigned  BSIM4v5wcdscGiven   :1;
    unsigned  BSIM4v5wcdscbGiven   :1;
    unsigned  BSIM4v5wcdscdGiven   :1;
    unsigned  BSIM4v5wcitGiven   :1;
    unsigned  BSIM4v5wnfactorGiven   :1;
    unsigned  BSIM4v5wxjGiven   :1;
    unsigned  BSIM4v5wvsatGiven   :1;
    unsigned  BSIM4v5watGiven   :1;
    unsigned  BSIM4v5wa0Given   :1;
    unsigned  BSIM4v5wagsGiven   :1;
    unsigned  BSIM4v5wa1Given   :1;
    unsigned  BSIM4v5wa2Given   :1;
    unsigned  BSIM4v5wketaGiven   :1;    
    unsigned  BSIM4v5wnsubGiven   :1;
    unsigned  BSIM4v5wndepGiven   :1;
    unsigned  BSIM4v5wnsdGiven    :1;
    unsigned  BSIM4v5wphinGiven   :1;
    unsigned  BSIM4v5wngateGiven   :1;
    unsigned  BSIM4v5wgamma1Given   :1;
    unsigned  BSIM4v5wgamma2Given   :1;
    unsigned  BSIM4v5wvbxGiven   :1;
    unsigned  BSIM4v5wvbmGiven   :1;
    unsigned  BSIM4v5wxtGiven   :1;
    unsigned  BSIM4v5wk1Given   :1;
    unsigned  BSIM4v5wkt1Given   :1;
    unsigned  BSIM4v5wkt1lGiven   :1;
    unsigned  BSIM4v5wkt2Given   :1;
    unsigned  BSIM4v5wk2Given   :1;
    unsigned  BSIM4v5wk3Given   :1;
    unsigned  BSIM4v5wk3bGiven   :1;
    unsigned  BSIM4v5ww0Given   :1;
    unsigned  BSIM4v5wdvtp0Given :1;
    unsigned  BSIM4v5wdvtp1Given :1;
    unsigned  BSIM4v5wlpe0Given   :1;
    unsigned  BSIM4v5wlpebGiven   :1;
    unsigned  BSIM4v5wdvt0Given   :1;   
    unsigned  BSIM4v5wdvt1Given   :1;     
    unsigned  BSIM4v5wdvt2Given   :1;     
    unsigned  BSIM4v5wdvt0wGiven   :1;   
    unsigned  BSIM4v5wdvt1wGiven   :1;     
    unsigned  BSIM4v5wdvt2wGiven   :1;     
    unsigned  BSIM4v5wdroutGiven   :1;     
    unsigned  BSIM4v5wdsubGiven   :1;     
    unsigned  BSIM4v5wvth0Given   :1;
    unsigned  BSIM4v5wuaGiven   :1;
    unsigned  BSIM4v5wua1Given   :1;
    unsigned  BSIM4v5wubGiven   :1;
    unsigned  BSIM4v5wub1Given   :1;
    unsigned  BSIM4v5wucGiven   :1;
    unsigned  BSIM4v5wuc1Given   :1;
    unsigned  BSIM4v5wudGiven     :1;
    unsigned  BSIM4v5wud1Given     :1;
    unsigned  BSIM4v5wupGiven     :1;
    unsigned  BSIM4v5wlpGiven     :1;
    unsigned  BSIM4v5wu0Given   :1;
    unsigned  BSIM4v5weuGiven   :1;
    unsigned  BSIM4v5wuteGiven   :1;
    unsigned  BSIM4v5wvoffGiven   :1;
    unsigned  BSIM4v5wtvoffGiven   :1;
    unsigned  BSIM4v5wminvGiven   :1;
    unsigned  BSIM4v5wrdswGiven   :1;      
    unsigned  BSIM4v5wrswGiven   :1;
    unsigned  BSIM4v5wrdwGiven   :1;
    unsigned  BSIM4v5wprwgGiven   :1;      
    unsigned  BSIM4v5wprwbGiven   :1;      
    unsigned  BSIM4v5wprtGiven   :1;      
    unsigned  BSIM4v5weta0Given   :1;    
    unsigned  BSIM4v5wetabGiven   :1;    
    unsigned  BSIM4v5wpclmGiven   :1;   
    unsigned  BSIM4v5wpdibl1Given   :1;   
    unsigned  BSIM4v5wpdibl2Given   :1;  
    unsigned  BSIM4v5wpdiblbGiven   :1;  
    unsigned  BSIM4v5wfproutGiven   :1;
    unsigned  BSIM4v5wpditsGiven    :1;
    unsigned  BSIM4v5wpditsdGiven    :1;
    unsigned  BSIM4v5wpscbe1Given   :1;    
    unsigned  BSIM4v5wpscbe2Given   :1;    
    unsigned  BSIM4v5wpvagGiven   :1;    
    unsigned  BSIM4v5wdeltaGiven  :1;     
    unsigned  BSIM4v5wwrGiven   :1;
    unsigned  BSIM4v5wdwgGiven   :1;
    unsigned  BSIM4v5wdwbGiven   :1;
    unsigned  BSIM4v5wb0Given   :1;
    unsigned  BSIM4v5wb1Given   :1;
    unsigned  BSIM4v5walpha0Given   :1;
    unsigned  BSIM4v5walpha1Given   :1;
    unsigned  BSIM4v5wbeta0Given   :1;
    unsigned  BSIM4v5wvfbGiven   :1;
    unsigned  BSIM4v5wagidlGiven   :1;
    unsigned  BSIM4v5wbgidlGiven   :1;
    unsigned  BSIM4v5wcgidlGiven   :1;
    unsigned  BSIM4v5wegidlGiven   :1;
    unsigned  BSIM4v5waigcGiven   :1;
    unsigned  BSIM4v5wbigcGiven   :1;
    unsigned  BSIM4v5wcigcGiven   :1;
    unsigned  BSIM4v5waigsdGiven   :1;
    unsigned  BSIM4v5wbigsdGiven   :1;
    unsigned  BSIM4v5wcigsdGiven   :1;
    unsigned  BSIM4v5waigbaccGiven   :1;
    unsigned  BSIM4v5wbigbaccGiven   :1;
    unsigned  BSIM4v5wcigbaccGiven   :1;
    unsigned  BSIM4v5waigbinvGiven   :1;
    unsigned  BSIM4v5wbigbinvGiven   :1;
    unsigned  BSIM4v5wcigbinvGiven   :1;
    unsigned  BSIM4v5wnigcGiven   :1;
    unsigned  BSIM4v5wnigbinvGiven   :1;
    unsigned  BSIM4v5wnigbaccGiven   :1;
    unsigned  BSIM4v5wntoxGiven   :1;
    unsigned  BSIM4v5weigbinvGiven   :1;
    unsigned  BSIM4v5wpigcdGiven   :1;
    unsigned  BSIM4v5wpoxedgeGiven   :1;
    unsigned  BSIM4v5wxrcrg1Given   :1;
    unsigned  BSIM4v5wxrcrg2Given   :1;
    unsigned  BSIM4v5wlambdaGiven    :1;
    unsigned  BSIM4v5wvtlGiven    :1;
    unsigned  BSIM4v5wxnGiven    :1;
    unsigned  BSIM4v5wvfbsdoffGiven    :1;
    unsigned  BSIM4v5wtvfbsdoffGiven    :1;

    /* CV model */
    unsigned  BSIM4v5wcgslGiven   :1;
    unsigned  BSIM4v5wcgdlGiven   :1;
    unsigned  BSIM4v5wckappasGiven   :1;
    unsigned  BSIM4v5wckappadGiven   :1;
    unsigned  BSIM4v5wcfGiven   :1;
    unsigned  BSIM4v5wclcGiven   :1;
    unsigned  BSIM4v5wcleGiven   :1;
    unsigned  BSIM4v5wvfbcvGiven   :1;
    unsigned  BSIM4v5wnoffGiven   :1;
    unsigned  BSIM4v5wvoffcvGiven :1;
    unsigned  BSIM4v5wacdeGiven   :1;
    unsigned  BSIM4v5wmoinGiven   :1;

    /* Cross-term dependence */
    unsigned  BSIM4v5pcdscGiven   :1;
    unsigned  BSIM4v5pcdscbGiven   :1;
    unsigned  BSIM4v5pcdscdGiven   :1;
    unsigned  BSIM4v5pcitGiven   :1;
    unsigned  BSIM4v5pnfactorGiven   :1;
    unsigned  BSIM4v5pxjGiven   :1;
    unsigned  BSIM4v5pvsatGiven   :1;
    unsigned  BSIM4v5patGiven   :1;
    unsigned  BSIM4v5pa0Given   :1;
    unsigned  BSIM4v5pagsGiven   :1;
    unsigned  BSIM4v5pa1Given   :1;
    unsigned  BSIM4v5pa2Given   :1;
    unsigned  BSIM4v5pketaGiven   :1;    
    unsigned  BSIM4v5pnsubGiven   :1;
    unsigned  BSIM4v5pndepGiven   :1;
    unsigned  BSIM4v5pnsdGiven    :1;
    unsigned  BSIM4v5pphinGiven   :1;
    unsigned  BSIM4v5pngateGiven   :1;
    unsigned  BSIM4v5pgamma1Given   :1;
    unsigned  BSIM4v5pgamma2Given   :1;
    unsigned  BSIM4v5pvbxGiven   :1;
    unsigned  BSIM4v5pvbmGiven   :1;
    unsigned  BSIM4v5pxtGiven   :1;
    unsigned  BSIM4v5pk1Given   :1;
    unsigned  BSIM4v5pkt1Given   :1;
    unsigned  BSIM4v5pkt1lGiven   :1;
    unsigned  BSIM4v5pkt2Given   :1;
    unsigned  BSIM4v5pk2Given   :1;
    unsigned  BSIM4v5pk3Given   :1;
    unsigned  BSIM4v5pk3bGiven   :1;
    unsigned  BSIM4v5pw0Given   :1;
    unsigned  BSIM4v5pdvtp0Given :1;
    unsigned  BSIM4v5pdvtp1Given :1;
    unsigned  BSIM4v5plpe0Given   :1;
    unsigned  BSIM4v5plpebGiven   :1;
    unsigned  BSIM4v5pdvt0Given   :1;   
    unsigned  BSIM4v5pdvt1Given   :1;     
    unsigned  BSIM4v5pdvt2Given   :1;     
    unsigned  BSIM4v5pdvt0wGiven   :1;   
    unsigned  BSIM4v5pdvt1wGiven   :1;     
    unsigned  BSIM4v5pdvt2wGiven   :1;     
    unsigned  BSIM4v5pdroutGiven   :1;     
    unsigned  BSIM4v5pdsubGiven   :1;     
    unsigned  BSIM4v5pvth0Given   :1;
    unsigned  BSIM4v5puaGiven   :1;
    unsigned  BSIM4v5pua1Given   :1;
    unsigned  BSIM4v5pubGiven   :1;
    unsigned  BSIM4v5pub1Given   :1;
    unsigned  BSIM4v5pucGiven   :1;
    unsigned  BSIM4v5puc1Given   :1;
    unsigned  BSIM4v5pudGiven     :1;
    unsigned  BSIM4v5pud1Given     :1;
    unsigned  BSIM4v5pupGiven     :1;
    unsigned  BSIM4v5plpGiven     :1;
    unsigned  BSIM4v5pu0Given   :1;
    unsigned  BSIM4v5peuGiven   :1;
    unsigned  BSIM4v5puteGiven   :1;
    unsigned  BSIM4v5pvoffGiven   :1;
    unsigned  BSIM4v5ptvoffGiven   :1;
    unsigned  BSIM4v5pminvGiven   :1;
    unsigned  BSIM4v5prdswGiven   :1;      
    unsigned  BSIM4v5prswGiven   :1;
    unsigned  BSIM4v5prdwGiven   :1;
    unsigned  BSIM4v5pprwgGiven   :1;      
    unsigned  BSIM4v5pprwbGiven   :1;      
    unsigned  BSIM4v5pprtGiven   :1;      
    unsigned  BSIM4v5peta0Given   :1;    
    unsigned  BSIM4v5petabGiven   :1;    
    unsigned  BSIM4v5ppclmGiven   :1;   
    unsigned  BSIM4v5ppdibl1Given   :1;   
    unsigned  BSIM4v5ppdibl2Given   :1;  
    unsigned  BSIM4v5ppdiblbGiven   :1;  
    unsigned  BSIM4v5pfproutGiven   :1;
    unsigned  BSIM4v5ppditsGiven    :1;
    unsigned  BSIM4v5ppditsdGiven    :1;
    unsigned  BSIM4v5ppscbe1Given   :1;    
    unsigned  BSIM4v5ppscbe2Given   :1;    
    unsigned  BSIM4v5ppvagGiven   :1;    
    unsigned  BSIM4v5pdeltaGiven  :1;     
    unsigned  BSIM4v5pwrGiven   :1;
    unsigned  BSIM4v5pdwgGiven   :1;
    unsigned  BSIM4v5pdwbGiven   :1;
    unsigned  BSIM4v5pb0Given   :1;
    unsigned  BSIM4v5pb1Given   :1;
    unsigned  BSIM4v5palpha0Given   :1;
    unsigned  BSIM4v5palpha1Given   :1;
    unsigned  BSIM4v5pbeta0Given   :1;
    unsigned  BSIM4v5pvfbGiven   :1;
    unsigned  BSIM4v5pagidlGiven   :1;
    unsigned  BSIM4v5pbgidlGiven   :1;
    unsigned  BSIM4v5pcgidlGiven   :1;
    unsigned  BSIM4v5pegidlGiven   :1;
    unsigned  BSIM4v5paigcGiven   :1;
    unsigned  BSIM4v5pbigcGiven   :1;
    unsigned  BSIM4v5pcigcGiven   :1;
    unsigned  BSIM4v5paigsdGiven   :1;
    unsigned  BSIM4v5pbigsdGiven   :1;
    unsigned  BSIM4v5pcigsdGiven   :1;
    unsigned  BSIM4v5paigbaccGiven   :1;
    unsigned  BSIM4v5pbigbaccGiven   :1;
    unsigned  BSIM4v5pcigbaccGiven   :1;
    unsigned  BSIM4v5paigbinvGiven   :1;
    unsigned  BSIM4v5pbigbinvGiven   :1;
    unsigned  BSIM4v5pcigbinvGiven   :1;
    unsigned  BSIM4v5pnigcGiven   :1;
    unsigned  BSIM4v5pnigbinvGiven   :1;
    unsigned  BSIM4v5pnigbaccGiven   :1;
    unsigned  BSIM4v5pntoxGiven   :1;
    unsigned  BSIM4v5peigbinvGiven   :1;
    unsigned  BSIM4v5ppigcdGiven   :1;
    unsigned  BSIM4v5ppoxedgeGiven   :1;
    unsigned  BSIM4v5pxrcrg1Given   :1;
    unsigned  BSIM4v5pxrcrg2Given   :1;
    unsigned  BSIM4v5plambdaGiven    :1;
    unsigned  BSIM4v5pvtlGiven    :1;
    unsigned  BSIM4v5pxnGiven    :1;
    unsigned  BSIM4v5pvfbsdoffGiven    :1;
    unsigned  BSIM4v5ptvfbsdoffGiven    :1;

    /* CV model */
    unsigned  BSIM4v5pcgslGiven   :1;
    unsigned  BSIM4v5pcgdlGiven   :1;
    unsigned  BSIM4v5pckappasGiven   :1;
    unsigned  BSIM4v5pckappadGiven   :1;
    unsigned  BSIM4v5pcfGiven   :1;
    unsigned  BSIM4v5pclcGiven   :1;
    unsigned  BSIM4v5pcleGiven   :1;
    unsigned  BSIM4v5pvfbcvGiven   :1;
    unsigned  BSIM4v5pnoffGiven   :1;
    unsigned  BSIM4v5pvoffcvGiven :1;
    unsigned  BSIM4v5pacdeGiven   :1;
    unsigned  BSIM4v5pmoinGiven   :1;

    unsigned  BSIM4v5useFringeGiven   :1;

    unsigned  BSIM4v5tnomGiven   :1;
    unsigned  BSIM4v5cgsoGiven   :1;
    unsigned  BSIM4v5cgdoGiven   :1;
    unsigned  BSIM4v5cgboGiven   :1;
    unsigned  BSIM4v5xpartGiven   :1;
    unsigned  BSIM4v5sheetResistanceGiven   :1;

    unsigned  BSIM4v5SjctSatCurDensityGiven   :1;
    unsigned  BSIM4v5SjctSidewallSatCurDensityGiven   :1;
    unsigned  BSIM4v5SjctGateSidewallSatCurDensityGiven   :1;
    unsigned  BSIM4v5SbulkJctPotentialGiven   :1;
    unsigned  BSIM4v5SbulkJctBotGradingCoeffGiven   :1;
    unsigned  BSIM4v5SsidewallJctPotentialGiven   :1;
    unsigned  BSIM4v5SGatesidewallJctPotentialGiven   :1;
    unsigned  BSIM4v5SbulkJctSideGradingCoeffGiven   :1;
    unsigned  BSIM4v5SunitAreaJctCapGiven   :1;
    unsigned  BSIM4v5SunitLengthSidewallJctCapGiven   :1;
    unsigned  BSIM4v5SbulkJctGateSideGradingCoeffGiven   :1;
    unsigned  BSIM4v5SunitLengthGateSidewallJctCapGiven   :1;
    unsigned  BSIM4v5SjctEmissionCoeffGiven :1;
    unsigned  BSIM4v5SjctTempExponentGiven	:1;

    unsigned  BSIM4v5DjctSatCurDensityGiven   :1;
    unsigned  BSIM4v5DjctSidewallSatCurDensityGiven   :1;
    unsigned  BSIM4v5DjctGateSidewallSatCurDensityGiven   :1;
    unsigned  BSIM4v5DbulkJctPotentialGiven   :1;
    unsigned  BSIM4v5DbulkJctBotGradingCoeffGiven   :1;
    unsigned  BSIM4v5DsidewallJctPotentialGiven   :1;
    unsigned  BSIM4v5DGatesidewallJctPotentialGiven   :1;
    unsigned  BSIM4v5DbulkJctSideGradingCoeffGiven   :1;
    unsigned  BSIM4v5DunitAreaJctCapGiven   :1;
    unsigned  BSIM4v5DunitLengthSidewallJctCapGiven   :1;
    unsigned  BSIM4v5DbulkJctGateSideGradingCoeffGiven   :1;
    unsigned  BSIM4v5DunitLengthGateSidewallJctCapGiven   :1;
    unsigned  BSIM4v5DjctEmissionCoeffGiven :1;
    unsigned  BSIM4v5DjctTempExponentGiven :1;

    unsigned  BSIM4v5oxideTrapDensityAGiven  :1;         
    unsigned  BSIM4v5oxideTrapDensityBGiven  :1;        
    unsigned  BSIM4v5oxideTrapDensityCGiven  :1;     
    unsigned  BSIM4v5emGiven  :1;     
    unsigned  BSIM4v5efGiven  :1;     
    unsigned  BSIM4v5afGiven  :1;     
    unsigned  BSIM4v5kfGiven  :1;     

    unsigned  BSIM4v5vgsMaxGiven  :1;
    unsigned  BSIM4v5vgdMaxGiven  :1;
    unsigned  BSIM4v5vgbMaxGiven  :1;
    unsigned  BSIM4v5vdsMaxGiven  :1;
    unsigned  BSIM4v5vbsMaxGiven  :1;
    unsigned  BSIM4v5vbdMaxGiven  :1;
    unsigned  BSIM4v5vgsrMaxGiven  :1;
    unsigned  BSIM4v5vgdrMaxGiven  :1;
    unsigned  BSIM4v5vgbrMaxGiven  :1;
    unsigned  BSIM4v5vbsrMaxGiven  :1;
    unsigned  BSIM4v5vbdrMaxGiven  :1;

    unsigned  BSIM4v5LintGiven   :1;
    unsigned  BSIM4v5LlGiven   :1;
    unsigned  BSIM4v5LlcGiven   :1;
    unsigned  BSIM4v5LlnGiven   :1;
    unsigned  BSIM4v5LwGiven   :1;
    unsigned  BSIM4v5LwcGiven   :1;
    unsigned  BSIM4v5LwnGiven   :1;
    unsigned  BSIM4v5LwlGiven   :1;
    unsigned  BSIM4v5LwlcGiven   :1;
    unsigned  BSIM4v5LminGiven   :1;
    unsigned  BSIM4v5LmaxGiven   :1;

    unsigned  BSIM4v5WintGiven   :1;
    unsigned  BSIM4v5WlGiven   :1;
    unsigned  BSIM4v5WlcGiven   :1;
    unsigned  BSIM4v5WlnGiven   :1;
    unsigned  BSIM4v5WwGiven   :1;
    unsigned  BSIM4v5WwcGiven   :1;
    unsigned  BSIM4v5WwnGiven   :1;
    unsigned  BSIM4v5WwlGiven   :1;
    unsigned  BSIM4v5WwlcGiven   :1;
    unsigned  BSIM4v5WminGiven   :1;
    unsigned  BSIM4v5WmaxGiven   :1;

    /* added for stress effect */
    unsigned  BSIM4v5sarefGiven   :1;
    unsigned  BSIM4v5sbrefGiven   :1;
    unsigned  BSIM4v5wlodGiven  :1;
    unsigned  BSIM4v5ku0Given   :1;
    unsigned  BSIM4v5kvsatGiven  :1;
    unsigned  BSIM4v5kvth0Given  :1;
    unsigned  BSIM4v5tku0Given   :1;
    unsigned  BSIM4v5llodku0Given   :1;
    unsigned  BSIM4v5wlodku0Given   :1;
    unsigned  BSIM4v5llodvthGiven   :1;
    unsigned  BSIM4v5wlodvthGiven   :1;
    unsigned  BSIM4v5lku0Given   :1;
    unsigned  BSIM4v5wku0Given   :1;
    unsigned  BSIM4v5pku0Given   :1;
    unsigned  BSIM4v5lkvth0Given   :1;
    unsigned  BSIM4v5wkvth0Given   :1;
    unsigned  BSIM4v5pkvth0Given   :1;
    unsigned  BSIM4v5stk2Given   :1;
    unsigned  BSIM4v5lodk2Given  :1;
    unsigned  BSIM4v5steta0Given :1;
    unsigned  BSIM4v5lodeta0Given :1;

    unsigned  BSIM4v5webGiven   :1;
    unsigned  BSIM4v5wecGiven   :1;
    unsigned  BSIM4v5kvth0weGiven   :1;
    unsigned  BSIM4v5k2weGiven   :1;
    unsigned  BSIM4v5ku0weGiven   :1;
    unsigned  BSIM4v5screfGiven   :1;
    unsigned  BSIM4v5wpemodGiven   :1;
    unsigned  BSIM4v5lkvth0weGiven   :1;
    unsigned  BSIM4v5lk2weGiven   :1;
    unsigned  BSIM4v5lku0weGiven   :1;
    unsigned  BSIM4v5wkvth0weGiven   :1;
    unsigned  BSIM4v5wk2weGiven   :1;
    unsigned  BSIM4v5wku0weGiven   :1;
    unsigned  BSIM4v5pkvth0weGiven   :1;
    unsigned  BSIM4v5pk2weGiven   :1;
    unsigned  BSIM4v5pku0weGiven   :1;


} BSIM4v5model;


#ifndef NMOS
#define NMOS 1
#define PMOS -1
#endif /*NMOS*/


/* Instance parameters */
#define BSIM4v5_W                   1
#define BSIM4v5_L                   2
#define BSIM4v5_AS                  3
#define BSIM4v5_AD                  4
#define BSIM4v5_PS                  5
#define BSIM4v5_PD                  6
#define BSIM4v5_NRS                 7
#define BSIM4v5_NRD                 8
#define BSIM4v5_OFF                 9
#define BSIM4v5_IC                  10
#define BSIM4v5_IC_VDS              11
#define BSIM4v5_IC_VGS              12
#define BSIM4v5_IC_VBS              13
#define BSIM4v5_TRNQSMOD            14
#define BSIM4v5_RBODYMOD            15
#define BSIM4v5_RGATEMOD            16
#define BSIM4v5_GEOMOD              17
#define BSIM4v5_RGEOMOD             18
#define BSIM4v5_NF                  19
#define BSIM4v5_MIN                 20 
#define BSIM4v5_ACNQSMOD            22
#define BSIM4v5_RBDB                23
#define BSIM4v5_RBSB                24
#define BSIM4v5_RBPB                25
#define BSIM4v5_RBPS                26
#define BSIM4v5_RBPD                27
#define BSIM4v5_SA                  28
#define BSIM4v5_SB                  29
#define BSIM4v5_SD                  30
#define BSIM4v5_DELVTO              31
#define BSIM4v5_XGW                 32
#define BSIM4v5_NGCON               33
#define BSIM4v5_SCA                 34
#define BSIM4v5_SCB                 35
#define BSIM4v5_SCC                 36 
#define BSIM4v5_SC                  37
#define BSIM4v5_M                   38
#define BSIM4v5_MULU0               39
#define BSIM4v5_DTEMP               40

/* Global parameters */
#define BSIM4v5_MOD_TEMPMOD         89
#define BSIM4v5_MOD_IGCMOD          90
#define BSIM4v5_MOD_IGBMOD          91
#define BSIM4v5_MOD_ACNQSMOD        92
#define BSIM4v5_MOD_FNOIMOD         93
#define BSIM4v5_MOD_RDSMOD          94
#define BSIM4v5_MOD_DIOMOD          95
#define BSIM4v5_MOD_PERMOD          96
#define BSIM4v5_MOD_GEOMOD          97
#define BSIM4v5_MOD_RGEOMOD         98
#define BSIM4v5_MOD_RGATEMOD        99
#define BSIM4v5_MOD_RBODYMOD        100
#define BSIM4v5_MOD_CAPMOD          101
#define BSIM4v5_MOD_TRNQSMOD        102
#define BSIM4v5_MOD_MOBMOD          103    
#define BSIM4v5_MOD_TNOIMOD         104    
#define BSIM4v5_MOD_TOXE            105
#define BSIM4v5_MOD_CDSC            106
#define BSIM4v5_MOD_CDSCB           107
#define BSIM4v5_MOD_CIT             108
#define BSIM4v5_MOD_NFACTOR         109
#define BSIM4v5_MOD_XJ              110
#define BSIM4v5_MOD_VSAT            111
#define BSIM4v5_MOD_AT              112
#define BSIM4v5_MOD_A0              113
#define BSIM4v5_MOD_A1              114
#define BSIM4v5_MOD_A2              115
#define BSIM4v5_MOD_KETA            116   
#define BSIM4v5_MOD_NSUB            117
#define BSIM4v5_MOD_NDEP            118
#define BSIM4v5_MOD_NGATE           120
#define BSIM4v5_MOD_GAMMA1          121
#define BSIM4v5_MOD_GAMMA2          122
#define BSIM4v5_MOD_VBX             123
#define BSIM4v5_MOD_BINUNIT         124    
#define BSIM4v5_MOD_VBM             125
#define BSIM4v5_MOD_XT              126
#define BSIM4v5_MOD_K1              129
#define BSIM4v5_MOD_KT1             130
#define BSIM4v5_MOD_KT1L            131
#define BSIM4v5_MOD_K2              132
#define BSIM4v5_MOD_KT2             133
#define BSIM4v5_MOD_K3              134
#define BSIM4v5_MOD_K3B             135
#define BSIM4v5_MOD_W0              136
#define BSIM4v5_MOD_LPE0            137
#define BSIM4v5_MOD_DVT0            138
#define BSIM4v5_MOD_DVT1            139
#define BSIM4v5_MOD_DVT2            140
#define BSIM4v5_MOD_DVT0W           141
#define BSIM4v5_MOD_DVT1W           142
#define BSIM4v5_MOD_DVT2W           143
#define BSIM4v5_MOD_DROUT           144
#define BSIM4v5_MOD_DSUB            145
#define BSIM4v5_MOD_VTH0            146
#define BSIM4v5_MOD_UA              147
#define BSIM4v5_MOD_UA1             148
#define BSIM4v5_MOD_UB              149
#define BSIM4v5_MOD_UB1             150
#define BSIM4v5_MOD_UC              151
#define BSIM4v5_MOD_UC1             152
#define BSIM4v5_MOD_U0              153
#define BSIM4v5_MOD_UTE             154
#define BSIM4v5_MOD_VOFF            155
#define BSIM4v5_MOD_DELTA           156
#define BSIM4v5_MOD_RDSW            157
#define BSIM4v5_MOD_PRT             158
#define BSIM4v5_MOD_LDD             159
#define BSIM4v5_MOD_ETA             160
#define BSIM4v5_MOD_ETA0            161
#define BSIM4v5_MOD_ETAB            162
#define BSIM4v5_MOD_PCLM            163
#define BSIM4v5_MOD_PDIBL1          164
#define BSIM4v5_MOD_PDIBL2          165
#define BSIM4v5_MOD_PSCBE1          166
#define BSIM4v5_MOD_PSCBE2          167
#define BSIM4v5_MOD_PVAG            168
#define BSIM4v5_MOD_WR              169
#define BSIM4v5_MOD_DWG             170
#define BSIM4v5_MOD_DWB             171
#define BSIM4v5_MOD_B0              172
#define BSIM4v5_MOD_B1              173
#define BSIM4v5_MOD_ALPHA0          174
#define BSIM4v5_MOD_BETA0           175
#define BSIM4v5_MOD_PDIBLB          178
#define BSIM4v5_MOD_PRWG            179
#define BSIM4v5_MOD_PRWB            180
#define BSIM4v5_MOD_CDSCD           181
#define BSIM4v5_MOD_AGS             182
#define BSIM4v5_MOD_FRINGE          184
#define BSIM4v5_MOD_CGSL            186
#define BSIM4v5_MOD_CGDL            187
#define BSIM4v5_MOD_CKAPPAS         188
#define BSIM4v5_MOD_CF              189
#define BSIM4v5_MOD_CLC             190
#define BSIM4v5_MOD_CLE             191
#define BSIM4v5_MOD_PARAMCHK        192
#define BSIM4v5_MOD_VERSION         193
#define BSIM4v5_MOD_VFBCV           194
#define BSIM4v5_MOD_ACDE            195
#define BSIM4v5_MOD_MOIN            196
#define BSIM4v5_MOD_NOFF            197
#define BSIM4v5_MOD_IJTHDFWD        198
#define BSIM4v5_MOD_ALPHA1          199
#define BSIM4v5_MOD_VFB             200
#define BSIM4v5_MOD_TOXM            201
#define BSIM4v5_MOD_TCJ             202
#define BSIM4v5_MOD_TCJSW           203
#define BSIM4v5_MOD_TCJSWG          204
#define BSIM4v5_MOD_TPB             205
#define BSIM4v5_MOD_TPBSW           206
#define BSIM4v5_MOD_TPBSWG          207
#define BSIM4v5_MOD_VOFFCV          208
#define BSIM4v5_MOD_GBMIN           209
#define BSIM4v5_MOD_RBDB            210
#define BSIM4v5_MOD_RBSB            211
#define BSIM4v5_MOD_RBPB            212
#define BSIM4v5_MOD_RBPS            213
#define BSIM4v5_MOD_RBPD            214
#define BSIM4v5_MOD_DMCG            215
#define BSIM4v5_MOD_DMCI            216
#define BSIM4v5_MOD_DMDG            217
#define BSIM4v5_MOD_XGW             218
#define BSIM4v5_MOD_XGL             219
#define BSIM4v5_MOD_RSHG            220
#define BSIM4v5_MOD_NGCON           221
#define BSIM4v5_MOD_AGIDL           222
#define BSIM4v5_MOD_BGIDL           223
#define BSIM4v5_MOD_EGIDL           224
#define BSIM4v5_MOD_IJTHSFWD        225
#define BSIM4v5_MOD_XJBVD           226
#define BSIM4v5_MOD_XJBVS           227
#define BSIM4v5_MOD_BVD             228
#define BSIM4v5_MOD_BVS             229
#define BSIM4v5_MOD_TOXP            230
#define BSIM4v5_MOD_DTOX            231
#define BSIM4v5_MOD_XRCRG1          232
#define BSIM4v5_MOD_XRCRG2          233
#define BSIM4v5_MOD_EU              234
#define BSIM4v5_MOD_IJTHSREV        235
#define BSIM4v5_MOD_IJTHDREV        236
#define BSIM4v5_MOD_MINV            237
#define BSIM4v5_MOD_VOFFL           238
#define BSIM4v5_MOD_PDITS           239
#define BSIM4v5_MOD_PDITSD          240
#define BSIM4v5_MOD_PDITSL          241
#define BSIM4v5_MOD_TNOIA           242
#define BSIM4v5_MOD_TNOIB           243
#define BSIM4v5_MOD_NTNOI           244
#define BSIM4v5_MOD_FPROUT          245
#define BSIM4v5_MOD_LPEB            246
#define BSIM4v5_MOD_DVTP0           247
#define BSIM4v5_MOD_DVTP1           248
#define BSIM4v5_MOD_CGIDL           249
#define BSIM4v5_MOD_PHIN            250
#define BSIM4v5_MOD_RDSWMIN         251
#define BSIM4v5_MOD_RSW             252
#define BSIM4v5_MOD_RDW             253
#define BSIM4v5_MOD_RDWMIN          254
#define BSIM4v5_MOD_RSWMIN          255
#define BSIM4v5_MOD_NSD             256
#define BSIM4v5_MOD_CKAPPAD         257
#define BSIM4v5_MOD_DMCGT           258
#define BSIM4v5_MOD_AIGC            259
#define BSIM4v5_MOD_BIGC            260
#define BSIM4v5_MOD_CIGC            261
#define BSIM4v5_MOD_AIGBACC         262
#define BSIM4v5_MOD_BIGBACC         263
#define BSIM4v5_MOD_CIGBACC         264            
#define BSIM4v5_MOD_AIGBINV         265
#define BSIM4v5_MOD_BIGBINV         266
#define BSIM4v5_MOD_CIGBINV         267
#define BSIM4v5_MOD_NIGC            268
#define BSIM4v5_MOD_NIGBACC         269
#define BSIM4v5_MOD_NIGBINV         270
#define BSIM4v5_MOD_NTOX            271
#define BSIM4v5_MOD_TOXREF          272
#define BSIM4v5_MOD_EIGBINV         273
#define BSIM4v5_MOD_PIGCD           274
#define BSIM4v5_MOD_POXEDGE         275
#define BSIM4v5_MOD_EPSROX          276
#define BSIM4v5_MOD_AIGSD           277
#define BSIM4v5_MOD_BIGSD           278
#define BSIM4v5_MOD_CIGSD           279
#define BSIM4v5_MOD_JSWGS           280
#define BSIM4v5_MOD_JSWGD           281
#define BSIM4v5_MOD_LAMBDA          282
#define BSIM4v5_MOD_VTL             283
#define BSIM4v5_MOD_LC              284
#define BSIM4v5_MOD_XN              285
#define BSIM4v5_MOD_RNOIA           286
#define BSIM4v5_MOD_RNOIB           287
#define BSIM4v5_MOD_VFBSDOFF        288
#define BSIM4v5_MOD_LINTNOI         289
#define BSIM4v5_MOD_UD              290
#define BSIM4v5_MOD_UD1             291
#define BSIM4v5_MOD_UP              292
#define BSIM4v5_MOD_LP              293
#define BSIM4v5_MOD_TVOFF           294
#define BSIM4v5_MOD_TVFBSDOFF       295

/* Length dependence */
#define BSIM4v5_MOD_LCDSC            301
#define BSIM4v5_MOD_LCDSCB           302
#define BSIM4v5_MOD_LCIT             303
#define BSIM4v5_MOD_LNFACTOR         304
#define BSIM4v5_MOD_LXJ              305
#define BSIM4v5_MOD_LVSAT            306
#define BSIM4v5_MOD_LAT              307
#define BSIM4v5_MOD_LA0              308
#define BSIM4v5_MOD_LA1              309
#define BSIM4v5_MOD_LA2              310
#define BSIM4v5_MOD_LKETA            311
#define BSIM4v5_MOD_LNSUB            312
#define BSIM4v5_MOD_LNDEP            313
#define BSIM4v5_MOD_LNGATE           315
#define BSIM4v5_MOD_LGAMMA1          316
#define BSIM4v5_MOD_LGAMMA2          317
#define BSIM4v5_MOD_LVBX             318
#define BSIM4v5_MOD_LVBM             320
#define BSIM4v5_MOD_LXT              322
#define BSIM4v5_MOD_LK1              325
#define BSIM4v5_MOD_LKT1             326
#define BSIM4v5_MOD_LKT1L            327
#define BSIM4v5_MOD_LK2              328
#define BSIM4v5_MOD_LKT2             329
#define BSIM4v5_MOD_LK3              330
#define BSIM4v5_MOD_LK3B             331
#define BSIM4v5_MOD_LW0              332
#define BSIM4v5_MOD_LLPE0            333
#define BSIM4v5_MOD_LDVT0            334
#define BSIM4v5_MOD_LDVT1            335
#define BSIM4v5_MOD_LDVT2            336
#define BSIM4v5_MOD_LDVT0W           337
#define BSIM4v5_MOD_LDVT1W           338
#define BSIM4v5_MOD_LDVT2W           339
#define BSIM4v5_MOD_LDROUT           340
#define BSIM4v5_MOD_LDSUB            341
#define BSIM4v5_MOD_LVTH0            342
#define BSIM4v5_MOD_LUA              343
#define BSIM4v5_MOD_LUA1             344
#define BSIM4v5_MOD_LUB              345
#define BSIM4v5_MOD_LUB1             346
#define BSIM4v5_MOD_LUC              347
#define BSIM4v5_MOD_LUC1             348
#define BSIM4v5_MOD_LU0              349
#define BSIM4v5_MOD_LUTE             350
#define BSIM4v5_MOD_LVOFF            351
#define BSIM4v5_MOD_LDELTA           352
#define BSIM4v5_MOD_LRDSW            353
#define BSIM4v5_MOD_LPRT             354
#define BSIM4v5_MOD_LLDD             355
#define BSIM4v5_MOD_LETA             356
#define BSIM4v5_MOD_LETA0            357
#define BSIM4v5_MOD_LETAB            358
#define BSIM4v5_MOD_LPCLM            359
#define BSIM4v5_MOD_LPDIBL1          360
#define BSIM4v5_MOD_LPDIBL2          361
#define BSIM4v5_MOD_LPSCBE1          362
#define BSIM4v5_MOD_LPSCBE2          363
#define BSIM4v5_MOD_LPVAG            364
#define BSIM4v5_MOD_LWR              365
#define BSIM4v5_MOD_LDWG             366
#define BSIM4v5_MOD_LDWB             367
#define BSIM4v5_MOD_LB0              368
#define BSIM4v5_MOD_LB1              369
#define BSIM4v5_MOD_LALPHA0          370
#define BSIM4v5_MOD_LBETA0           371
#define BSIM4v5_MOD_LPDIBLB          374
#define BSIM4v5_MOD_LPRWG            375
#define BSIM4v5_MOD_LPRWB            376
#define BSIM4v5_MOD_LCDSCD           377
#define BSIM4v5_MOD_LAGS             378

#define BSIM4v5_MOD_LFRINGE          381
#define BSIM4v5_MOD_LCGSL            383
#define BSIM4v5_MOD_LCGDL            384
#define BSIM4v5_MOD_LCKAPPAS         385
#define BSIM4v5_MOD_LCF              386
#define BSIM4v5_MOD_LCLC             387
#define BSIM4v5_MOD_LCLE             388
#define BSIM4v5_MOD_LVFBCV           389
#define BSIM4v5_MOD_LACDE            390
#define BSIM4v5_MOD_LMOIN            391
#define BSIM4v5_MOD_LNOFF            392
#define BSIM4v5_MOD_LALPHA1          394
#define BSIM4v5_MOD_LVFB             395
#define BSIM4v5_MOD_LVOFFCV          396
#define BSIM4v5_MOD_LAGIDL           397
#define BSIM4v5_MOD_LBGIDL           398
#define BSIM4v5_MOD_LEGIDL           399
#define BSIM4v5_MOD_LXRCRG1          400
#define BSIM4v5_MOD_LXRCRG2          401
#define BSIM4v5_MOD_LEU              402
#define BSIM4v5_MOD_LMINV            403
#define BSIM4v5_MOD_LPDITS           404
#define BSIM4v5_MOD_LPDITSD          405
#define BSIM4v5_MOD_LFPROUT          406
#define BSIM4v5_MOD_LLPEB            407
#define BSIM4v5_MOD_LDVTP0           408
#define BSIM4v5_MOD_LDVTP1           409
#define BSIM4v5_MOD_LCGIDL           410
#define BSIM4v5_MOD_LPHIN            411
#define BSIM4v5_MOD_LRSW             412
#define BSIM4v5_MOD_LRDW             413
#define BSIM4v5_MOD_LNSD             414
#define BSIM4v5_MOD_LCKAPPAD         415
#define BSIM4v5_MOD_LAIGC            416
#define BSIM4v5_MOD_LBIGC            417
#define BSIM4v5_MOD_LCIGC            418
#define BSIM4v5_MOD_LAIGBACC         419            
#define BSIM4v5_MOD_LBIGBACC         420
#define BSIM4v5_MOD_LCIGBACC         421
#define BSIM4v5_MOD_LAIGBINV         422
#define BSIM4v5_MOD_LBIGBINV         423
#define BSIM4v5_MOD_LCIGBINV         424
#define BSIM4v5_MOD_LNIGC            425
#define BSIM4v5_MOD_LNIGBACC         426
#define BSIM4v5_MOD_LNIGBINV         427
#define BSIM4v5_MOD_LNTOX            428
#define BSIM4v5_MOD_LEIGBINV         429
#define BSIM4v5_MOD_LPIGCD           430
#define BSIM4v5_MOD_LPOXEDGE         431
#define BSIM4v5_MOD_LAIGSD           432
#define BSIM4v5_MOD_LBIGSD           433
#define BSIM4v5_MOD_LCIGSD           434

#define BSIM4v5_MOD_LLAMBDA          435
#define BSIM4v5_MOD_LVTL             436
#define BSIM4v5_MOD_LXN              437
#define BSIM4v5_MOD_LVFBSDOFF        438
#define BSIM4v5_MOD_LUD              439
#define BSIM4v5_MOD_LUD1             440
#define BSIM4v5_MOD_LUP              441
#define BSIM4v5_MOD_LLP              442

/* Width dependence */
#define BSIM4v5_MOD_WCDSC            481
#define BSIM4v5_MOD_WCDSCB           482
#define BSIM4v5_MOD_WCIT             483
#define BSIM4v5_MOD_WNFACTOR         484
#define BSIM4v5_MOD_WXJ              485
#define BSIM4v5_MOD_WVSAT            486
#define BSIM4v5_MOD_WAT              487
#define BSIM4v5_MOD_WA0              488
#define BSIM4v5_MOD_WA1              489
#define BSIM4v5_MOD_WA2              490
#define BSIM4v5_MOD_WKETA            491
#define BSIM4v5_MOD_WNSUB            492
#define BSIM4v5_MOD_WNDEP            493
#define BSIM4v5_MOD_WNGATE           495
#define BSIM4v5_MOD_WGAMMA1          496
#define BSIM4v5_MOD_WGAMMA2          497
#define BSIM4v5_MOD_WVBX             498
#define BSIM4v5_MOD_WVBM             500
#define BSIM4v5_MOD_WXT              502
#define BSIM4v5_MOD_WK1              505
#define BSIM4v5_MOD_WKT1             506
#define BSIM4v5_MOD_WKT1L            507
#define BSIM4v5_MOD_WK2              508
#define BSIM4v5_MOD_WKT2             509
#define BSIM4v5_MOD_WK3              510
#define BSIM4v5_MOD_WK3B             511
#define BSIM4v5_MOD_WW0              512
#define BSIM4v5_MOD_WLPE0            513
#define BSIM4v5_MOD_WDVT0            514
#define BSIM4v5_MOD_WDVT1            515
#define BSIM4v5_MOD_WDVT2            516
#define BSIM4v5_MOD_WDVT0W           517
#define BSIM4v5_MOD_WDVT1W           518
#define BSIM4v5_MOD_WDVT2W           519
#define BSIM4v5_MOD_WDROUT           520
#define BSIM4v5_MOD_WDSUB            521
#define BSIM4v5_MOD_WVTH0            522
#define BSIM4v5_MOD_WUA              523
#define BSIM4v5_MOD_WUA1             524
#define BSIM4v5_MOD_WUB              525
#define BSIM4v5_MOD_WUB1             526
#define BSIM4v5_MOD_WUC              527
#define BSIM4v5_MOD_WUC1             528
#define BSIM4v5_MOD_WU0              529
#define BSIM4v5_MOD_WUTE             530
#define BSIM4v5_MOD_WVOFF            531
#define BSIM4v5_MOD_WDELTA           532
#define BSIM4v5_MOD_WRDSW            533
#define BSIM4v5_MOD_WPRT             534
#define BSIM4v5_MOD_WLDD             535
#define BSIM4v5_MOD_WETA             536
#define BSIM4v5_MOD_WETA0            537
#define BSIM4v5_MOD_WETAB            538
#define BSIM4v5_MOD_WPCLM            539
#define BSIM4v5_MOD_WPDIBL1          540
#define BSIM4v5_MOD_WPDIBL2          541
#define BSIM4v5_MOD_WPSCBE1          542
#define BSIM4v5_MOD_WPSCBE2          543
#define BSIM4v5_MOD_WPVAG            544
#define BSIM4v5_MOD_WWR              545
#define BSIM4v5_MOD_WDWG             546
#define BSIM4v5_MOD_WDWB             547
#define BSIM4v5_MOD_WB0              548
#define BSIM4v5_MOD_WB1              549
#define BSIM4v5_MOD_WALPHA0          550
#define BSIM4v5_MOD_WBETA0           551
#define BSIM4v5_MOD_WPDIBLB          554
#define BSIM4v5_MOD_WPRWG            555
#define BSIM4v5_MOD_WPRWB            556
#define BSIM4v5_MOD_WCDSCD           557
#define BSIM4v5_MOD_WAGS             558

#define BSIM4v5_MOD_WFRINGE          561
#define BSIM4v5_MOD_WCGSL            563
#define BSIM4v5_MOD_WCGDL            564
#define BSIM4v5_MOD_WCKAPPAS         565
#define BSIM4v5_MOD_WCF              566
#define BSIM4v5_MOD_WCLC             567
#define BSIM4v5_MOD_WCLE             568
#define BSIM4v5_MOD_WVFBCV           569
#define BSIM4v5_MOD_WACDE            570
#define BSIM4v5_MOD_WMOIN            571
#define BSIM4v5_MOD_WNOFF            572
#define BSIM4v5_MOD_WALPHA1          574
#define BSIM4v5_MOD_WVFB             575
#define BSIM4v5_MOD_WVOFFCV          576
#define BSIM4v5_MOD_WAGIDL           577
#define BSIM4v5_MOD_WBGIDL           578
#define BSIM4v5_MOD_WEGIDL           579
#define BSIM4v5_MOD_WXRCRG1          580
#define BSIM4v5_MOD_WXRCRG2          581
#define BSIM4v5_MOD_WEU              582
#define BSIM4v5_MOD_WMINV            583
#define BSIM4v5_MOD_WPDITS           584
#define BSIM4v5_MOD_WPDITSD          585
#define BSIM4v5_MOD_WFPROUT          586
#define BSIM4v5_MOD_WLPEB            587
#define BSIM4v5_MOD_WDVTP0           588
#define BSIM4v5_MOD_WDVTP1           589
#define BSIM4v5_MOD_WCGIDL           590
#define BSIM4v5_MOD_WPHIN            591
#define BSIM4v5_MOD_WRSW             592
#define BSIM4v5_MOD_WRDW             593
#define BSIM4v5_MOD_WNSD             594
#define BSIM4v5_MOD_WCKAPPAD         595
#define BSIM4v5_MOD_WAIGC            596
#define BSIM4v5_MOD_WBIGC            597
#define BSIM4v5_MOD_WCIGC            598
#define BSIM4v5_MOD_WAIGBACC         599            
#define BSIM4v5_MOD_WBIGBACC         600
#define BSIM4v5_MOD_WCIGBACC         601
#define BSIM4v5_MOD_WAIGBINV         602
#define BSIM4v5_MOD_WBIGBINV         603
#define BSIM4v5_MOD_WCIGBINV         604
#define BSIM4v5_MOD_WNIGC            605
#define BSIM4v5_MOD_WNIGBACC         606
#define BSIM4v5_MOD_WNIGBINV         607
#define BSIM4v5_MOD_WNTOX            608
#define BSIM4v5_MOD_WEIGBINV         609
#define BSIM4v5_MOD_WPIGCD           610
#define BSIM4v5_MOD_WPOXEDGE         611
#define BSIM4v5_MOD_WAIGSD           612
#define BSIM4v5_MOD_WBIGSD           613
#define BSIM4v5_MOD_WCIGSD           614
#define BSIM4v5_MOD_WLAMBDA          615
#define BSIM4v5_MOD_WVTL             616
#define BSIM4v5_MOD_WXN              617
#define BSIM4v5_MOD_WVFBSDOFF        618
#define BSIM4v5_MOD_WUD              619
#define BSIM4v5_MOD_WUD1             620
#define BSIM4v5_MOD_WUP              621
#define BSIM4v5_MOD_WLP              622

/* Cross-term dependence */
#define BSIM4v5_MOD_PCDSC            661
#define BSIM4v5_MOD_PCDSCB           662
#define BSIM4v5_MOD_PCIT             663
#define BSIM4v5_MOD_PNFACTOR         664
#define BSIM4v5_MOD_PXJ              665
#define BSIM4v5_MOD_PVSAT            666
#define BSIM4v5_MOD_PAT              667
#define BSIM4v5_MOD_PA0              668
#define BSIM4v5_MOD_PA1              669
#define BSIM4v5_MOD_PA2              670
#define BSIM4v5_MOD_PKETA            671
#define BSIM4v5_MOD_PNSUB            672
#define BSIM4v5_MOD_PNDEP            673
#define BSIM4v5_MOD_PNGATE           675
#define BSIM4v5_MOD_PGAMMA1          676
#define BSIM4v5_MOD_PGAMMA2          677
#define BSIM4v5_MOD_PVBX             678

#define BSIM4v5_MOD_PVBM             680

#define BSIM4v5_MOD_PXT              682
#define BSIM4v5_MOD_PK1              685
#define BSIM4v5_MOD_PKT1             686
#define BSIM4v5_MOD_PKT1L            687
#define BSIM4v5_MOD_PK2              688
#define BSIM4v5_MOD_PKT2             689
#define BSIM4v5_MOD_PK3              690
#define BSIM4v5_MOD_PK3B             691
#define BSIM4v5_MOD_PW0              692
#define BSIM4v5_MOD_PLPE0            693

#define BSIM4v5_MOD_PDVT0            694
#define BSIM4v5_MOD_PDVT1            695
#define BSIM4v5_MOD_PDVT2            696

#define BSIM4v5_MOD_PDVT0W           697
#define BSIM4v5_MOD_PDVT1W           698
#define BSIM4v5_MOD_PDVT2W           699

#define BSIM4v5_MOD_PDROUT           700
#define BSIM4v5_MOD_PDSUB            701
#define BSIM4v5_MOD_PVTH0            702
#define BSIM4v5_MOD_PUA              703
#define BSIM4v5_MOD_PUA1             704
#define BSIM4v5_MOD_PUB              705
#define BSIM4v5_MOD_PUB1             706
#define BSIM4v5_MOD_PUC              707
#define BSIM4v5_MOD_PUC1             708
#define BSIM4v5_MOD_PU0              709
#define BSIM4v5_MOD_PUTE             710
#define BSIM4v5_MOD_PVOFF            711
#define BSIM4v5_MOD_PDELTA           712
#define BSIM4v5_MOD_PRDSW            713
#define BSIM4v5_MOD_PPRT             714
#define BSIM4v5_MOD_PLDD             715
#define BSIM4v5_MOD_PETA             716
#define BSIM4v5_MOD_PETA0            717
#define BSIM4v5_MOD_PETAB            718
#define BSIM4v5_MOD_PPCLM            719
#define BSIM4v5_MOD_PPDIBL1          720
#define BSIM4v5_MOD_PPDIBL2          721
#define BSIM4v5_MOD_PPSCBE1          722
#define BSIM4v5_MOD_PPSCBE2          723
#define BSIM4v5_MOD_PPVAG            724
#define BSIM4v5_MOD_PWR              725
#define BSIM4v5_MOD_PDWG             726
#define BSIM4v5_MOD_PDWB             727
#define BSIM4v5_MOD_PB0              728
#define BSIM4v5_MOD_PB1              729
#define BSIM4v5_MOD_PALPHA0          730
#define BSIM4v5_MOD_PBETA0           731
#define BSIM4v5_MOD_PPDIBLB          734

#define BSIM4v5_MOD_PPRWG            735
#define BSIM4v5_MOD_PPRWB            736

#define BSIM4v5_MOD_PCDSCD           737
#define BSIM4v5_MOD_PAGS             738

#define BSIM4v5_MOD_PFRINGE          741
#define BSIM4v5_MOD_PCGSL            743
#define BSIM4v5_MOD_PCGDL            744
#define BSIM4v5_MOD_PCKAPPAS         745
#define BSIM4v5_MOD_PCF              746
#define BSIM4v5_MOD_PCLC             747
#define BSIM4v5_MOD_PCLE             748
#define BSIM4v5_MOD_PVFBCV           749
#define BSIM4v5_MOD_PACDE            750
#define BSIM4v5_MOD_PMOIN            751
#define BSIM4v5_MOD_PNOFF            752
#define BSIM4v5_MOD_PALPHA1          754
#define BSIM4v5_MOD_PVFB             755
#define BSIM4v5_MOD_PVOFFCV          756
#define BSIM4v5_MOD_PAGIDL           757
#define BSIM4v5_MOD_PBGIDL           758
#define BSIM4v5_MOD_PEGIDL           759
#define BSIM4v5_MOD_PXRCRG1          760
#define BSIM4v5_MOD_PXRCRG2          761
#define BSIM4v5_MOD_PEU              762
#define BSIM4v5_MOD_PMINV            763
#define BSIM4v5_MOD_PPDITS           764
#define BSIM4v5_MOD_PPDITSD          765
#define BSIM4v5_MOD_PFPROUT          766
#define BSIM4v5_MOD_PLPEB            767
#define BSIM4v5_MOD_PDVTP0           768
#define BSIM4v5_MOD_PDVTP1           769
#define BSIM4v5_MOD_PCGIDL           770
#define BSIM4v5_MOD_PPHIN            771
#define BSIM4v5_MOD_PRSW             772
#define BSIM4v5_MOD_PRDW             773
#define BSIM4v5_MOD_PNSD             774
#define BSIM4v5_MOD_PCKAPPAD         775
#define BSIM4v5_MOD_PAIGC            776
#define BSIM4v5_MOD_PBIGC            777
#define BSIM4v5_MOD_PCIGC            778
#define BSIM4v5_MOD_PAIGBACC         779            
#define BSIM4v5_MOD_PBIGBACC         780
#define BSIM4v5_MOD_PCIGBACC         781
#define BSIM4v5_MOD_PAIGBINV         782
#define BSIM4v5_MOD_PBIGBINV         783
#define BSIM4v5_MOD_PCIGBINV         784
#define BSIM4v5_MOD_PNIGC            785
#define BSIM4v5_MOD_PNIGBACC         786
#define BSIM4v5_MOD_PNIGBINV         787
#define BSIM4v5_MOD_PNTOX            788
#define BSIM4v5_MOD_PEIGBINV         789
#define BSIM4v5_MOD_PPIGCD           790
#define BSIM4v5_MOD_PPOXEDGE         791
#define BSIM4v5_MOD_PAIGSD           792
#define BSIM4v5_MOD_PBIGSD           793
#define BSIM4v5_MOD_PCIGSD           794

#define BSIM4v5_MOD_SAREF            795
#define BSIM4v5_MOD_SBREF            796
#define BSIM4v5_MOD_KU0              797
#define BSIM4v5_MOD_KVSAT            798
#define BSIM4v5_MOD_TKU0             799
#define BSIM4v5_MOD_LLODKU0          800
#define BSIM4v5_MOD_WLODKU0          801
#define BSIM4v5_MOD_LLODVTH          802
#define BSIM4v5_MOD_WLODVTH          803
#define BSIM4v5_MOD_LKU0             804
#define BSIM4v5_MOD_WKU0             805
#define BSIM4v5_MOD_PKU0             806
#define BSIM4v5_MOD_KVTH0            807
#define BSIM4v5_MOD_LKVTH0           808
#define BSIM4v5_MOD_WKVTH0           809
#define BSIM4v5_MOD_PKVTH0           810
#define BSIM4v5_MOD_WLOD		   811
#define BSIM4v5_MOD_STK2		   812
#define BSIM4v5_MOD_LODK2		   813
#define BSIM4v5_MOD_STETA0	   814
#define BSIM4v5_MOD_LODETA0	   815

#define BSIM4v5_MOD_WEB          816
#define BSIM4v5_MOD_WEC          817
#define BSIM4v5_MOD_KVTH0WE          818
#define BSIM4v5_MOD_K2WE          819
#define BSIM4v5_MOD_KU0WE          820
#define BSIM4v5_MOD_SCREF          821
#define BSIM4v5_MOD_WPEMOD          822

#define BSIM4v5_MOD_PLAMBDA          825
#define BSIM4v5_MOD_PVTL             826
#define BSIM4v5_MOD_PXN              827
#define BSIM4v5_MOD_PVFBSDOFF        828

#define BSIM4v5_MOD_TNOM             831
#define BSIM4v5_MOD_CGSO             832
#define BSIM4v5_MOD_CGDO             833
#define BSIM4v5_MOD_CGBO             834
#define BSIM4v5_MOD_XPART            835
#define BSIM4v5_MOD_RSH              836
#define BSIM4v5_MOD_JSS              837
#define BSIM4v5_MOD_PBS              838
#define BSIM4v5_MOD_MJS              839
#define BSIM4v5_MOD_PBSWS            840
#define BSIM4v5_MOD_MJSWS            841
#define BSIM4v5_MOD_CJS              842
#define BSIM4v5_MOD_CJSWS            843
#define BSIM4v5_MOD_NMOS             844
#define BSIM4v5_MOD_PMOS             845
#define BSIM4v5_MOD_NOIA             846
#define BSIM4v5_MOD_NOIB             847
#define BSIM4v5_MOD_NOIC             848
#define BSIM4v5_MOD_LINT             849
#define BSIM4v5_MOD_LL               850
#define BSIM4v5_MOD_LLN              851
#define BSIM4v5_MOD_LW               852
#define BSIM4v5_MOD_LWN              853
#define BSIM4v5_MOD_LWL              854
#define BSIM4v5_MOD_LMIN             855
#define BSIM4v5_MOD_LMAX             856
#define BSIM4v5_MOD_WINT             857
#define BSIM4v5_MOD_WL               858
#define BSIM4v5_MOD_WLN              859
#define BSIM4v5_MOD_WW               860
#define BSIM4v5_MOD_WWN              861
#define BSIM4v5_MOD_WWL              862
#define BSIM4v5_MOD_WMIN             863
#define BSIM4v5_MOD_WMAX             864
#define BSIM4v5_MOD_DWC              865
#define BSIM4v5_MOD_DLC              866
#define BSIM4v5_MOD_XL               867
#define BSIM4v5_MOD_XW               868
#define BSIM4v5_MOD_EM               869
#define BSIM4v5_MOD_EF               870
#define BSIM4v5_MOD_AF               871
#define BSIM4v5_MOD_KF               872
#define BSIM4v5_MOD_NJS              873
#define BSIM4v5_MOD_XTIS             874
#define BSIM4v5_MOD_PBSWGS           875
#define BSIM4v5_MOD_MJSWGS           876
#define BSIM4v5_MOD_CJSWGS           877
#define BSIM4v5_MOD_JSWS             878
#define BSIM4v5_MOD_LLC              879
#define BSIM4v5_MOD_LWC              880
#define BSIM4v5_MOD_LWLC             881
#define BSIM4v5_MOD_WLC              882
#define BSIM4v5_MOD_WWC              883
#define BSIM4v5_MOD_WWLC             884
#define BSIM4v5_MOD_DWJ              885
#define BSIM4v5_MOD_JSD              886
#define BSIM4v5_MOD_PBD              887
#define BSIM4v5_MOD_MJD              888
#define BSIM4v5_MOD_PBSWD            889
#define BSIM4v5_MOD_MJSWD            890
#define BSIM4v5_MOD_CJD              891
#define BSIM4v5_MOD_CJSWD            892
#define BSIM4v5_MOD_NJD              893
#define BSIM4v5_MOD_XTID             894
#define BSIM4v5_MOD_PBSWGD           895
#define BSIM4v5_MOD_MJSWGD           896
#define BSIM4v5_MOD_CJSWGD           897
#define BSIM4v5_MOD_JSWD             898
#define BSIM4v5_MOD_DLCIG            899

/* trap-assisted tunneling */

#define BSIM4v5_MOD_JTSS             900
#define BSIM4v5_MOD_JTSD		   901
#define BSIM4v5_MOD_JTSSWS	   902
#define BSIM4v5_MOD_JTSSWD	   903
#define BSIM4v5_MOD_JTSSWGS	   904
#define BSIM4v5_MOD_JTSSWGD	   905
#define BSIM4v5_MOD_NJTS	 	   906
#define BSIM4v5_MOD_NJTSSW	   907
#define BSIM4v5_MOD_NJTSSWG	   908
#define BSIM4v5_MOD_XTSS		   909
#define BSIM4v5_MOD_XTSD		   910
#define BSIM4v5_MOD_XTSSWS	   911
#define BSIM4v5_MOD_XTSSWD	   912
#define BSIM4v5_MOD_XTSSWGS	   913
#define BSIM4v5_MOD_XTSSWGD	   914
#define BSIM4v5_MOD_TNJTS		   915
#define BSIM4v5_MOD_TNJTSSW	   916
#define BSIM4v5_MOD_TNJTSSWG	   917
#define BSIM4v5_MOD_VTSS             918
#define BSIM4v5_MOD_VTSD		   919
#define BSIM4v5_MOD_VTSSWS	   920
#define BSIM4v5_MOD_VTSSWD	   921
#define BSIM4v5_MOD_VTSSWGS	   922
#define BSIM4v5_MOD_VTSSWGD	   923
#define BSIM4v5_MOD_PUD              924
#define BSIM4v5_MOD_PUD1             925
#define BSIM4v5_MOD_PUP              926
#define BSIM4v5_MOD_PLP              927

/* device questions */
#define BSIM4v5_DNODE                945
#define BSIM4v5_GNODEEXT             946
#define BSIM4v5_SNODE                947
#define BSIM4v5_BNODE                948
#define BSIM4v5_DNODEPRIME           949
#define BSIM4v5_GNODEPRIME           950
#define BSIM4v5_GNODEMIDE            951
#define BSIM4v5_GNODEMID             952
#define BSIM4v5_SNODEPRIME           953
#define BSIM4v5_BNODEPRIME           954
#define BSIM4v5_DBNODE               955
#define BSIM4v5_SBNODE               956
#define BSIM4v5_VBD                  957
#define BSIM4v5_VBS                  958
#define BSIM4v5_VGS                  959
#define BSIM4v5_VDS                  960
#define BSIM4v5_CD                   961
#define BSIM4v5_CBS                  962
#define BSIM4v5_CBD                  963
#define BSIM4v5_GM                   964
#define BSIM4v5_GDS                  965
#define BSIM4v5_GMBS                 966
#define BSIM4v5_GBD                  967
#define BSIM4v5_GBS                  968
#define BSIM4v5_QB                   969
#define BSIM4v5_CQB                  970
#define BSIM4v5_QG                   971
#define BSIM4v5_CQG                  972
#define BSIM4v5_QD                   973
#define BSIM4v5_CQD                  974
#define BSIM4v5_CGGB                 975
#define BSIM4v5_CGDB                 976
#define BSIM4v5_CGSB                 977
#define BSIM4v5_CBGB                 978
#define BSIM4v5_CAPBD                979
#define BSIM4v5_CQBD                 980
#define BSIM4v5_CAPBS                981
#define BSIM4v5_CQBS                 982
#define BSIM4v5_CDGB                 983
#define BSIM4v5_CDDB                 984
#define BSIM4v5_CDSB                 985
#define BSIM4v5_VON                  986
#define BSIM4v5_VDSAT                987
#define BSIM4v5_QBS                  988
#define BSIM4v5_QBD                  989
#define BSIM4v5_SOURCECONDUCT        990
#define BSIM4v5_DRAINCONDUCT         991
#define BSIM4v5_CBDB                 992
#define BSIM4v5_CBSB                 993
#define BSIM4v5_CSUB		   994
#define BSIM4v5_QINV		   995
#define BSIM4v5_IGIDL		   996
#define BSIM4v5_CSGB                 997
#define BSIM4v5_CSDB                 998
#define BSIM4v5_CSSB                 999
#define BSIM4v5_CGBB                 1000
#define BSIM4v5_CDBB                 1001
#define BSIM4v5_CSBB                 1002
#define BSIM4v5_CBBB                 1003
#define BSIM4v5_QS                   1004
#define BSIM4v5_IGISL		   1005
#define BSIM4v5_IGS		   1006
#define BSIM4v5_IGD		   1007
#define BSIM4v5_IGB		   1008
#define BSIM4v5_IGCS		   1009
#define BSIM4v5_IGCD		   1010
#define BSIM4v5_QDEF		   1011
#define BSIM4v5_DELVT0		   1012
#define BSIM4v5_GCRG                 1013
#define BSIM4v5_GTAU                 1014

#define BSIM4v5_MOD_LTVOFF           1051
#define BSIM4v5_MOD_LTVFBSDOFF       1052
#define BSIM4v5_MOD_WTVOFF           1053
#define BSIM4v5_MOD_WTVFBSDOFF       1054
#define BSIM4v5_MOD_PTVOFF           1055
#define BSIM4v5_MOD_PTVFBSDOFF       1056

#define BSIM4v5_MOD_LKVTH0WE          1061
#define BSIM4v5_MOD_LK2WE             1062
#define BSIM4v5_MOD_LKU0WE		1063
#define BSIM4v5_MOD_WKVTH0WE          1064
#define BSIM4v5_MOD_WK2WE             1065
#define BSIM4v5_MOD_WKU0WE		1066
#define BSIM4v5_MOD_PKVTH0WE          1067
#define BSIM4v5_MOD_PK2WE             1068
#define BSIM4v5_MOD_PKU0WE		1069

#define BSIM4v5_MOD_RBPS0               1101
#define BSIM4v5_MOD_RBPSL               1102
#define BSIM4v5_MOD_RBPSW               1103
#define BSIM4v5_MOD_RBPSNF              1104
#define BSIM4v5_MOD_RBPD0               1105
#define BSIM4v5_MOD_RBPDL               1106
#define BSIM4v5_MOD_RBPDW               1107
#define BSIM4v5_MOD_RBPDNF              1108

#define BSIM4v5_MOD_RBPBX0              1109
#define BSIM4v5_MOD_RBPBXL              1110
#define BSIM4v5_MOD_RBPBXW              1111
#define BSIM4v5_MOD_RBPBXNF             1112
#define BSIM4v5_MOD_RBPBY0              1113
#define BSIM4v5_MOD_RBPBYL              1114
#define BSIM4v5_MOD_RBPBYW              1115
#define BSIM4v5_MOD_RBPBYNF             1116

#define BSIM4v5_MOD_RBSBX0              1117
#define BSIM4v5_MOD_RBSBY0              1118
#define BSIM4v5_MOD_RBDBX0              1119
#define BSIM4v5_MOD_RBDBY0              1120

#define BSIM4v5_MOD_RBSDBXL             1121
#define BSIM4v5_MOD_RBSDBXW             1122
#define BSIM4v5_MOD_RBSDBXNF            1123
#define BSIM4v5_MOD_RBSDBYL             1124
#define BSIM4v5_MOD_RBSDBYW             1125
#define BSIM4v5_MOD_RBSDBYNF            1126

#define BSIM4v5_MOD_VGS_MAX             1201
#define BSIM4v5_MOD_VGD_MAX             1202
#define BSIM4v5_MOD_VGB_MAX             1203
#define BSIM4v5_MOD_VDS_MAX             1204
#define BSIM4v5_MOD_VBS_MAX             1205
#define BSIM4v5_MOD_VBD_MAX             1206
#define BSIM4v5_MOD_VGSR_MAX            1207
#define BSIM4v5_MOD_VGDR_MAX            1208
#define BSIM4v5_MOD_VGBR_MAX            1209
#define BSIM4v5_MOD_VBSR_MAX            1210
#define BSIM4v5_MOD_VBDR_MAX            1211

#define BSIM4v5_VGSTEFF                 1400
#define BSIM4v5_VDSEFF                  1401
#define BSIM4v5_CGSO                    1402
#define BSIM4v5_CGDO                    1403
#define BSIM4v5_CGBO                    1404
#define BSIM4v5_WEFF                    1405
#define BSIM4v5_LEFF                    1406

#include "bsim4v5ext.h"

extern void BSIM4v5evaluate(SPICE_REAL, SPICE_REAL,SPICE_REAL,BSIM4v5instance*,BSIM4v5model*,
        SPICE_REAL*,SPICE_REAL*,SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*,
        SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*,
        SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, SPICE_REAL*, CKTcircuit*);
extern int BSIM4v5debug(BSIM4v5model*, BSIM4v5instance*, CKTcircuit*, int);
extern int BSIM4v5checkModel(BSIM4v5model*, BSIM4v5instance*, CKTcircuit*);
extern int BSIM4v5PAeffGeo(SPICE_REAL, int, int, SPICE_REAL, SPICE_REAL, SPICE_REAL, SPICE_REAL, SPICE_REAL *, SPICE_REAL *, SPICE_REAL *, SPICE_REAL *);
extern int BSIM4v5RdseffGeo(SPICE_REAL, int, int, int, SPICE_REAL, SPICE_REAL, SPICE_REAL, SPICE_REAL, SPICE_REAL, int, SPICE_REAL *);

#endif /*BSIM4v5*/
