//************************ INIZIO PROC. DB20CMD ***********************
//* PROCEDURA DI ESECUZIONE DINAMICA DEI COMANDI DB2
//*
//*  PARAMETRI:
//*   DB2    = DB2 UTILIZZATO
//*   CEN    = PARAMETRO PER LIBRERIE D'AMBIENTE
//*   CENN   = PARAMETRO PER DATASETS D'AMBIENTE
//*   AMBL   = PARAMETRO PER LIBRERIE D'AMBIENTE PER AMBIENTI SVILUPPO
//*   AMBP   = PARAMETRO PER DATASETS D'AMBIENTE PER AMBIENTI SVILUPPO
//*
//*********************************************************************
//DB20CMD PROC AMBL=P,AMBP=0,CEN=,CENN=
//*
//MYSET SET AMBL=P NEUTRALIZZO PARAMETRO AMBL
//*
//P1      EXEC PGM=SY20014                                              00001400
//SYSPRINT DD SYSOUT=F                                                  00001500
//SYSUT1   DD DUMMY                                                     00001600
//SYSUT2 DD DSN=&&CMD,UNIT=3390,DISP=(,PASS),                           00001700
//     DCB=(LRECL=80,BLKSIZE=800,RECFM=FB),SPACE=(CYL,5)                00001800
//SYSIN     DD DUMMY                                                    00001900
//P2       EXEC PGM=IKJEFT01,DYNAMNBR=20                                00180000
//STEPLIB DD DSN=Y&CENN.&AMBP.0DB2.PE000.&DB2..DSNLOAD,DISP=SHR         00181001
//*       DD DSN=Y&CENN.&AMBP.0DB2.PE000.&DB2..DSNLOAD,DISP=SHR         00181001
//SYSTSPRT DD SYSOUT=*                                                  00210000
//SYSPRINT DD SYSOUT=*                                                  00220021
//SYSUDUMP DD SYSOUT=D                                                  00230021
//SYSTSIN  DD DSN=L&CEN.&AMBL.00.SYSTEM.INPUT.DB2(&DB2.CMD),DISP=SHR    00240000
//         DD DSN=&&CMD,DISP=(OLD,DELETE)                               00002800
// IF (P2.RC > 4) THEN
//P2DUD EXEC DB20DUD,
//        RTC='04',
//        OPE='<',
//        CEN=&CEN
// ENDIF
//********  FINE PROCEDURA DB20CMD ********************************     00171004
