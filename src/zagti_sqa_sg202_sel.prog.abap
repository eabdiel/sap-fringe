*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_SG202_SEL
*&---------------------------------------------------------------------*
TABLES : mast,
         mchb.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_matnr FOR mast-matnr MEMORY ID mat,
                s_werks FOR mast-werks MEMORY ID wrk,
                s_stlan FOR mast-stlan MEMORY ID csv,
                s_stlal FOR mast-stlal,
                s_clabs FOR mchb-clabs,
                s_charg FOR mchb-charg MEMORY ID cha,
                s_lgort FOR mchb-lgort MEMORY ID lag,
                s_werksm FOR mchb-werks MEMORY ID wrk.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
