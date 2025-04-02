*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_MATLOOKUP_SEL
*&---------------------------------------------------------------------*
TABLES: mchb,
        mvke,
        mara,
        marc,
        lqua.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-s01.
SELECT-OPTIONS: s_matnr FOR mchb-matnr MEMORY ID mat,
                s_charg FOR mchb-charg MEMORY ID cha,
                s_werks FOR mchb-werks MEMORY ID wrk,
                s_lgort FOR mchb-lgort MEMORY ID lag,
                s_vkorg FOR mvke-vkorg MEMORY ID vko,
                s_vtweg FOR mvke-vtweg MEMORY ID vtw,
                s_spart FOR mara-spart MEMORY ID spa,
                s_sernp FOR marc-sernp,
                s_mara  FOR mara-mtpos_mara,
                s_matkl FOR mara-matkl MEMORY ID mkl,
                s_mvgr2 FOR mvke-mvgr2,
                s_mtpos FOR mvke-mtpos,
                s_lgtyp FOR lqua-lgtyp MEMORY ID lgt,
                s_verme FOR lqua-verme,
                s_mmsta FOR marc-mmsta,
                s_tragr FOR mara-tragr.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
