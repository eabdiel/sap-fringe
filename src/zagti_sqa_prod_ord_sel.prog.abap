*&---------------------------------------------------------------------*
*&  Include           ZAGTR_SQA_PROD_ORD_SEL
*&---------------------------------------------------------------------*

TABLES : afko,
         afpo.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-s01.
SELECT-OPTIONS: s_aufnr FOR afko-aufnr MEMORY ID anr,
                s_gamng FOR afko-gamng,
                s_plnbez FOR afko-plnbez MEMORY ID mat,
                s_pflos  FOR afko-prueflos MEMORY ID qls,
                s_terkz FOR afko-terkz,
                s_arsps FOR afko-arsps,
                s_verid FOR afpo-verid MEMORY ID ver,
                s_dauat FOR afpo-dauat MEMORY ID aat,
                s_charg FOR afpo-charg MEMORY ID cha,
                s_dwerk FOR afpo-dwerk MEMORY ID wrk,
                s_lgort FOR afpo-lgort MEMORY ID lag,
                s_ftrmi FOR afko-ftrmi.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
