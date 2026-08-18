/* REXX */
TRACE o
/*------------------------------------------------------------------*/
/*-          - INTERFACCIA PER COMANDI SQL TRAMITE DSNREXX         -*/
/*- V0123 Risolto problema di connessione con DB2='*' quando       -*/
/*-       si chiude il DB2                                         -*/
/*- V0127 Risolta anomalia in sviluppo per conn. sempre a SDEA     -*/
/*- V0128 Non considero X012 quando DB2=* perch} non } V12         -*/
/*-                                                                -*/
/*- METODI DI CHIAMATA                                             -*/
/*-   1     : Interpret REXSQL(DB2_ID,COMANDO_SQL)                 -*/
/*-   2     : Interpret REXSQL(DB2_ID,CONNECT)                     -*/
/*-   3     : Interpret REXSQL(DB2_ID,COMANDO_SQL,NOCONNECT)       -*/
/*-   3bis  : Interpret REXSQL(DB2_ID,SQL,NOCONNECT,n,p1,p2,...)   -*/
/*-   4     : Interpret REXSQL(DB2_ID,DISCONNECT)                  -*/
/*-                                                                -*/
/*-           impostando DB2_ID='*' si connette a un db2 qualunque -*/
/*-                                                                -*/
/*-           nella modalita' NOCONNECT, se si specifica           -*/
/*-           DB2_ID='NOCOMMIT' non fa la commit dopo gli SQL      -*/
/*-           non SELECT                                           -*/
/*-                                                                -*/
/*- METODO 1 - EFFETTUA CONNECT + QUERY + DISCONNECT               -*/
/*- METODO 2 - EFFETTUA SOLO CONNECT                               -*/
/*- METODO 3 - EFFETTUA SOLO QUERY                                 -*/
/*-     3bis - accetta delle variabili che saranno sostituite ai   -*/
/*-            punti interrogativi inseriti nel comando sql.       -*/
/*-            Se si lascia vuoto il terzo parametro effettua anche-*/
/*-            connect e disconnect                                -*/
/*- METODO 4 - EFFETTUA SOLO DISCONNECT                            -*/
/*-                                                                -*/
/*- NOTA: IN REALTA' IL METODO 4 EFFETTUA CONNECT + DISCONNECT     -*/
/*-       PER EVITARE UN ABEND SE GIA' DISCONNESSO                 -*/
/*-                                                                -*/
/*-                                                                -*/
/*- VARIABILI IMPOSTATE AD USO DELLA CLIST CHIAMANTE:              -*/
/*-                                                                -*/
/*- (SELECT)    SQLROWS        = NUMERO DI RIGHE SELEZIONATE       -*/
/*- (SELECT)    SQLCOLS        = NUMERO DI COLONNE SELEZIONATE     -*/
/*- (SELECT)    NOME_COLONNA.X = CONTENUTO CAMPI RIGA X            -*/
/*- (SELECT)    SQLCOL_NAME.X  = NOMI COLONNE(X=1 TO SQLCOLS)      -*/
/*- (SELECT)    SQLOK (LOGIC)  = VERO SE SQLCODE=100 & SQLROWS>0   -*/
/*- (NO SELECT) SQLOK (LOGIC)  = VERO SE SQLCODE=0                 -*/
/*-             SQLCA          = SQLCA COMPLETA                    -*/
/*-             SQLCODE        = SQLCODE                           -*/
/*-             SQLSTATE       = SQLSTATE                          -*/
/*-             SQLERRMC       = SQLERRMC                          -*/
/*-             SQLERRP        = SQLERRP                           -*/
/*-             RESULT         = 16 (PARAMETRI ERRATI O MANCANTI)  -*/
/*-                                                                -*/
/*- Se la variabile Numparam } negativa verr{ fatta una PARSE ARG  -*/
/*- per mantenere i caratteri minuscoli                            -*/
/*------------------------------------------------------------------*/
 ARG Db2,Comando_Sql,NoConnect,NumParam,p.1,p.2,p.3,p.4,
  ,p.5,p.6,p.7,p.8,p.9,p.10,p.11,p.12,p.13,p.14,p.15,p.16,p.17,p.18,
  ,p.19,p.20,p.21,p.22,p.23,p.24,p.25,p.26,p.27,p.28,p.29,p.30

 if numparam < 0 & numparam <> '' then do
   parse ARG Db2,Comando_Sql,NoConnect,NumParam,p.1,p.2,p.3,p.4,
   ,p.5,p.6,p.7,p.8,p.9,p.10,p.11,p.12,p.13,p.14,p.15,p.16,p.17,p.18,
   ,p.19,p.20,p.21,p.22,p.23,p.24,p.25,p.26,p.27,p.28,p.29,p.30
   if numparam = -999 then numparam = 0
         /* trik per mantenere minuscolo senza parametri */
   numparam = abs(numparam)
 end
 IF DB2='' | Comando_Sql='' THEN DO
           SAY "---------------------------------------------------"
           SAY " REXSQL  - PARAMETRI ERRATI O MANCANTI             "
           SAY "           PARAMETRI RICHIESTI: 'DB2ID,COMANDO SQL'"
           SAY "           ELABORAZIONE INTERROTTA                 "
           SAY "---------------------------------------------------"
           RETURN 'RESULT=16'
 END
 IF NumParam > 30  THEN DO
           SAY "NumParam=" NumParam
           SAY "---------------------------------------------------"
           SAY " REXSQL  - NUMERO PARAMETRI TROPPO ELEVATO         "
           SAY "           IL MASSIMO E' ATTUALMENTE 30            "
           SAY "           ELABORAZIONE INTERROTTA                 "
           SAY "---------------------------------------------------"
           RETURN 'RESULT=16'
 END

 /* sempre prima del primo richiamo di CONCAT */
 address tso 'NEWSTACK'
 /* */
 STRING_LMAX=250        /* lunghezza max di una stringa in rexx */
 STACK_BUF_LMAX = 65528 /*   (2**16)-8 */
 STACK_BUF=''

 SQLOK=0
 SQLCODE='-9999 ERRORE| NON CONNESSO AL DB2'
 RiS=0
 FattoOpen=0
 IF Comando_Sql='CONNECT' THEN DO
    CALL CONNETTI
    CALL SQLCA
    SIGNAL USCITA
 END

 IF Comando_Sql='DISCONNECT' THEN DO
    CALL CONNETTI
    IF RESULT=0 THEN CALL DISCONNETTI
    SIGNAL USCITA
 END

 IF NOCONNECT<>'NOCONNECT' THEN DO
                      CALL CONNETTI
                      IF RESULT<>0 THEN DO
                                   CALL SQLCA
                                   SIGNAL USCITA
                      END
 END

 USNG = ''
 CONTA=0
 if NumParam>0 then do  i = 1 to NumParam
    IF CONTA=0 THEN USNG = ' USING '; ELSE ;USNG=USNG||','
    CONTA = CONTA+1
    PARM.CONTA = P.i
    USNG = USNG ' :PARM.'||CONTA
 END
/* IF USNG<>'' THEN SAY 'USNG='USNG  */
 IF WORD(Comando_Sql,1)<>'SELECT' &  ,
    WORD(Comando_Sql,1)<>'WITH' ,
 THEN CALL NO_SELECT
                                  ELSE CALL SELECT

IF NOCONNECT<>'NOCONNECT' & Comando_Sql<>'CONNECT' THEN CALL DISCONNETTI

USCITA:

 RESULT=ris
 CALL CONCAT('RESULT')
 CALL CONCAT_finale
 EXIT ,
        "DO WHILE QUEUED()>0;" ,
        "   PARSE PULL @@REXSQLK;INTERPRET @@REXSQLK;",
        "END;" ,
        "ADDRESS TSO DELSTACK;"
/*================================================================*/
/*-                        SELECT                                -*/
/*----------------------------------------------------------------*/
SELECT:
 ADDRESS DSNREXX
"EXECSQL DECLARE C1 CURSOR FOR S1"
 IF SQLCODE <> 0 THEN DO
                      CALL SQLCA
                      RETURN
 END

"EXECSQL PREPARE S1 INTO :SQLDA     FROM :Comando_Sql"
 IF SQLCODE <> 0 THEN DO
                      CALL SQLCA
                      RETURN
 END

"EXECSQL OPEN C1"||USNG
 IF SQLCODE <>0 THEN DO
                      CALL SQLCA
                      RETURN
 END
 FattoOpen=1

/*----------------------------------------------------------------*/
/*- ASSEGNAZIONE CONTENUTO SQLDA A VARIBILI STEM (COLONNA.*)      */
/*----------------------------------------------------------------*/
 SQLCOLS=SQLDA.SQLD                          /* NUMERO COLONNE */

 CUR=0
 DO UNTIL SQLCODE<>0
   "EXECSQL FETCH C1 USING DESCRIPTOR :SQLDA"
    IF SQLCODE>=0 & SQLCODE<>100 THEN DO
     /* MODIFICA PER GESTIRE SQLCODE POSITIVI */
     IF SQLCODE>0 & WARNINGSQLCODEPOSITIVO<>'YES' THEN DO
      SAY '**************************************************'
      SAY '*'
      SAY '* WARNING FETCH: INTERCETTATO SQLCODE 'SQLCODE
      SAY '*'
      SAY '**************************************************'
      WARNINGSQLCODEPOSITIVO='YES'
     END
     SQLCODE=0
     /**/
       CUR=CUR+1
       DO I=1 TO SQLDA.SQLD
        IF SQLDA.I.SQLNAME=' ' THEN SQLDA.I.SQLNAME='NONAME'I
          X=VALUE(SQLDA.I.SQLNAME".CUR",SQLDA.I.SQLDATA)
          IF CUR=1 THEN DO
                        SQLCOL_NAME.I=SQLDA.I.SQLNAME
                        CALL CONCAT('SQLCOL_NAME.'I)
                        END
          CALL CONCAT(STRIP(SQLDA.I.SQLNAME)'.'CUR)
       END
    END
 END

 SQLROWS=CUR
 CALL CONCAT('SQLROWS')
 CALL CONCAT('SQLCOLS')

 IF SQLCODE=100 & SQLROWS>0 THEN SQLOK=1

 CALL SQLCA
RETURN

/*================================================================*/
/*-                  ALTRI COMANDI SQL                           -*/
/*----------------------------------------------------------------*/

NO_SELECT:
ADDRESS DSNREXX
IF USNG<>'' THEN DO
    "EXECSQL PREPARE S12 INTO :SQLDI2 FROM :COMANDO_SQL"
 IF SQLCODE <> 0 THEN DO
                      CALL SQLCA
                      RETURN
 END
 "EXECSQL EXECUTE S12 "||USNG
END
ELSE DO
    "EXECSQL "Comando_Sql
END
 IF SQLCODE = 0 & DB2 <> 'NOCOMMIT' THEN DO
                      SQLOK=1
                     "EXECSQL COMMIT"
 END
 CALL SQLCA
RETURN

/*----------------------------------------------------------------*/
/*-                  COSTRUZIONE SQLCA                           -*/
/*----------------------------------------------------------------*/

SQLCA:
 CALL CONCAT('SQLOK')
 CALL CONCAT('SQLCODE')
 CALL CONCAT('SQLSTATE')
 CALL CONCAT('SQLERRMC')
 CALL CONCAT('SQLERRP')
                               /*- COSTRUZIONE VARIABILE SQLCA -*/
 SQLCA=SQLSTATE
 DO I=1 TO 10
    SQLCA=SQLCA' 'SQLWARN.I
    CALL CONCAT('SQLWARN.'||I)
 END
 DO I=1 TO 6
    SQLCA=SQLCA' 'SQLERRD.I
    CALL CONCAT('SQLERRD.'||I)
 END
 SQLCA=SQLCA' 'SQLERRMC' 'SQLERRP' 'SQLCODE
 CALL CONCAT('SQLCA')

 IF FattoOpen THEN CALL CLOSE
 if SQLCODE < 0 then
   ADDRESS DSNREXX "EXECSQL ROLLBACK"

RETURN
                  /**** FINE ESECUZIONE ****/

/*================================================================*/

/*----------------------------------------------------------------*/
/*-     ROUTINE CONCATENAZIONE VARIABILI A STRINGA DI RISPOSTA    */
/*----------------------------------------------------------------*/
Concat:
 arg varname

 varname_val=value(varname)

 if length(varname_val) > string_lmax
 then do
      queue 'PARSE PULL 'VARNAME' ;'
      queue varname_val
      return 0
 end
 if pos('"',varname_val) > 0
 then do
      queue 'PARSE PULL 'VARNAME' ;'
      queue varname_val
      return 0
 end
 com_stm = varname'="'||varname_val||'";'
 if length(stack_buf) + length(com_stm) > stack_buf_lmax
 then do
      queue stack_buf
      stack_buf = com_stm
      return 0
 end
 stack_buf=stack_buf||com_stm

return 0

Concat_finale:

if length(stack_buf) = 0 then return 0
queue stack_buf

return 0
/*----------------------------------------------------------------*/
CONNETTI:
 ADDRESS TSO "SUBCOM DSNREXX"             /*VERIFICA ESISTENZA DSNREXX*/
 IF RC THEN                               /* SE 1 HOST NOT FOUND   */
 S_RC = RXSUBCOM('ADD','DSNREXX','DSNREXX') /*ADD NUOVO HOST CMD ENV */

 CPU = MVSVAR('SYMDEF','SYSNAME')
 if DB2='*' & SUBSTR(CPU,1,3)<>'SYA' then do
    /* Accedo a SDSF per trovare un DB2 disponibile */
    IsfRC = isfcalls( "ON" )
    if IsfRC<>0 then do ; say '---errore ISFCALLS(ON): rc=' isfrc
       result=12 ;end
    ISFPREFIX='*DBM1' /* imposta prefix jobname */
    ISFSORT='JNAME D' /* IMPOSTA JOB-id DECRESCENTE*/
    ISFSYSNAME = CPU  /* Imposta partizione corrente */
 /* IF SYSVAR(SYSENV) = 'BACK' THEN,
       say '-- Cerco addresspace ' isfprefix  */
    Address SDSF "ISFEXEC DA"  /* accede a sdsf : DA */
    if rc<>0 then do
      say '---errore ISFEXEC: rc=' rc
      if rc = 16 then say "Potrebbe essere necessario inserire ",
      "//ISFMIGDS DD DUMMY nel JCL "
      result=12
    end
    /* IF SYSVAR(SYSENV) = 'BACK' THEN,
       say 'isfrows ' isfrows 'jobs '  */
    trovato = 'NO'
    do j=1 to isfrows until trovato = 'SI' /* loop su jobs in sdsf */
       /*  col = word(isfcols,i) */
       /* say jname.j jobid.j */
       PARSE VAR JNAME.J DB2'DBM1'
       IF DB2 <>'X012' then do
          ADDRESS DSNREXX "CONNECT" DB2
          if sqlcode > 0 then sqlcode = 0
          if sqlcode >= 0 then trovato='SI'
          IF SYSVAR(SYSENV) = 'BACK' THEN,
            say 'Connessione a:' DB2 'SQLCODE' sqlcode 'VALIDO:' trovato
       end
    end
    if trovato<>'SI' then do
       result=12
       say 'Impossibile connettersi al DB2'
       call sqlca
    end
 end
 ELSE DO
   IF SUBSTR(CPU,1,3)='SYA' & DB2='*' THEN do
      DB2='SDEA'
      /* IN SVILUPPO FORZO LA CONNESSIONE A SDEA             */
      IF SYSVAR(SYSENV) = 'BACK' THEN  say 'Connessione a:' DB2
   end
   ADDRESS DSNREXX "CONNECT" DB2
   if sqlcode > 0 then sqlcode = 0
 END
RETURN SQLCODE
/*----------------------------------------------------------------*/
DISCONNETTI:
 ADDRESS DSNREXX "DISCONNECT"
RETURN
/*----------------------------------------------------------------*/
CLOSE:
ADDRESS DSNREXX "EXECSQL CLOSE C1"
FattoOpen=0
RETURN
/*----------------------------------------------------------------*/
