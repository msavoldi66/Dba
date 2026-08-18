//*****************************************************************     00171004
//* IN CASO DI ANOMALIA AD UNO STEP PRECEDENTE GESTISCE L'INVIO DI      00171104
//* UNA EVENTUALE MAIL E/O PERMETTE DI CAUSARE L'ABEND DEL JOB PER      00171104
//* BLOCCARNE L'ESECUZIONE.                                             00171104
//* VIENE USATA NELLE PROCEDURE DB20* SU TARGET E SU AMVS.              00171104
//*                                                                     00171104
//* SI COMPONE DI UN SOLO STEP CHE ESEGUE IL PGM ASSEMBLER Y200650      00171104
//* CHE RICHIAMA IL PROGRAMMA REXX Y6DUD PASSANDO TUTTI I PARAMETRI     00171104
//*                                                                     00171104
//* IL DOPPIO PASSAGGIO (PROGRAMMA ASSEMBLER + PROGRAMMA REXX) }        00171104
//* L'UNICO MODO PER POTER CAUSARE DIRETTAMENTE L'ABEND DELLO STEP      00171104
//* NEL CASO VENGA RICHIESTO.                                           00171104
//*                                                                     00171104
//* INPUT:                                                              00171104
//*  FILEIN= CONTIENE L'EVENTUALE TESTO DELLA MAIL CHE SI PUO'          00171104
//*          QUINDI PASSARE IN OVERRIDE (DEFAULT DUMMY)                 00171104
//*                                                                     00171104
//* PARAMETRI:                                                          00171321
//*   DESC = DESCRIZIONE DELL'ABEND CHE VERRA' RIPORTATA NELLA MAIL     00171321
//*   DESC2= DESCRIZIONE AGGIUNTIVA                                     00171321
//*   STEP = STEP DA CONTROLLARE (DEFAULT OGNI STEP PRECEDENTE)         00171321
//*   OPE  = OPERATORE UTILIZZATO PER IL TEST (ES. = > < >=)            00171321
//*   RTC  = RETURN CODE DA CONTROLLARE (IF RTC OPE STEP THEN .DUMP)    00171321
//*   MAIL =  NO  -> SOLO ABEND DEL JOB (DEFAULT)                       00171321
//*           YES -> SOLO MAIL SENZA ABEND DEL JOB                      00171321
//*           ALL -> MAIL E ABEND DEL JOB                               00171321
//*   MAILB= MEMBRO DI INPUT CONTENENTE GLI INDIRIZZI                   00171321
//*   DB2  = OPZIONALE, SE SPECIFICATO AGGIORNA IL TIMESTAMP DI FINE    00171321
//*           SULLA TABELLA AYY2.LOG_UTILITY PER IL JOB CORRENTE        00171321
//*           UTILIZZATO PRINCIPALMENTE PER LA PROCEDURA DB20LOAD       00171321
//*   ULTIMO= Y -> CONSIDERA SOLO L'ULTIMO STEP                         00171321
//*           N -> CONSIDERA TUTTI GLI STEP PRECEDENTI (DEFAULT)        00171321
//*                                                                     00171321
//* 21.04.23: DOCUMENTAZIONE SPOSTATA NEL JCL                           00171321
//*                                                                     00171321
//*****************************************************************     00174004
//DB20DUD PROC DESC='JOBS DI MANUTENZIONE DB2',CEN=,
//       DESC2='',
//       AMBL='P',
//       RTC='00',
//       OPE='=',
//       STEP='',
//       DB2='',
//       CHIAVE='',
//       MAIL='NO',
//       ULTIMO='NO',
//       MAILB=MDB1,TESTLIB=
//* EXPORT DEI SIMBOLI DA UTILIZZARE NEGLI INPUT IN STREAM
//P000EXP  EXPORT SYMLIST=(RTC,STEP,MAIL,DB2,
//         CHIAVE,ULTIMO)
//P000SET  SET RTC=&RTC,STEP=&STEP,MAIL=&MAIL,DB2=&DB2,
//         CHIAVE=&CHIAVE,ULTIMO=&ULTIMO
//P0       EXEC PGM=Y200650,
// PARM=('Y6DUD OPER(&OPE) DESC1(&DESC)',
//   'DESC2(&DESC2)')
//STEPLIB  DD DSN=L&CEN.&AMBL.0Y.TBAN0000.LOADBATC,DISP=SHR             00001600
//         DD DSN=Y&CENN.00DB2.PE000.DSNLOAD,DISP=SHR                   00001600
//SYSEXEC  DD DSN=L&CEN.&AMBL.00.SYSTEM.INPUT&TESTLIB,DISP=SHR          00001600
//PARMDD   DD *,SYMBOLS=JCLONLY
RTC(&RTC),STEP(&STEP),
MAIL(&MAIL),CHIAVE(&CHIAVE),DB2(&DB2),ULTIMO(&ULTIMO)
//ELENCO   DD DISP=SHR,DSN=L&CEN.&AMBL.00.SYSTEM.INPUT&TESTLIB(&MAILB)
//FILEIN   DD DUMMY
//SYSTSPRT DD SYSOUT=*
//MAILJOB  DD SYSOUT=(K,INTRDR),LRECL=132,RECFM=FB,DSORG=PS
//SYSTSIN  DD DUMMY
//SYSPRINT DD SYSOUT=*,DCB=(LRECL=121,RECFM=FBA,BLKSIZE=121)
//SYSIN    DD DUMMY
