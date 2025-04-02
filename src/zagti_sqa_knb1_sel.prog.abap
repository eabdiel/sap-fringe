*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_KNB1_SEL
*&---------------------------------------------------------------------*

TABLES: knb1,
        bsid.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_bukrs FOR knb1-bukrs MEMORY ID buk,
                s_belnr FOR bsid-belnr MEMORY ID bln,
                s_kunnr FOR knb1-kunnr MEMORY ID kun,
                s_zfbdt FOR bsid-zfbdt,
                s_gjhar FOR bsid-gjahr MEMORY ID gjr,
                s_bldat FOR bsid-bldat,
                s_augbl FOR bsid-augbl.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
