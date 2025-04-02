*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_US001_FIN_SEL
*&---------------------------------------------------------------------*
TABLES: marc,
        mkal,
        plpo,
        plko,
        mast,
        stko,
        mchb.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-s01.
SELECT-OPTIONS: s_werks FOR marc-werks MEMORY ID wrk,
                s_herkl FOR marc-herkl MEMORY ID lnd,
                s_fevor FOR marc-fevor MEMORY ID cfv,
                s_bdatu FOR mkal-bdatu,
                s_adatu FOR mkal-adatu,
                s_verid FOR mkal-verid MEMORY ID ver,
                s_plnnr FOR plpo-plnnr MEMORY ID pln,
                s_plnty FOR plpo-plnty MEMORY ID pty,
                s_stlan FOR mast-stlan MEMORY ID csv,
                s_stlty FOR stko-stlty,
                s_steus FOR plpo-steus,
                s_clabs FOR mchb-clabs,
                s_stlal FOR plko-stlal,
                s_zaehl FOR plko-zaehl,
                s_werks1 FOR mchb-werks MEMORY ID wrk,
                s_lgort FOR mchb-lgort MEMORY ID lag,
                s_charg FOR mchb-charg MEMORY ID cha.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
