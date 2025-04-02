*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_MAT_QUERY_SEL
*&---------------------------------------------------------------------*
TABLES : mvke,
         mara,
         mard,
         marc,
         lqua,
         mchb.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS:  s_matnr FOR mvke-matnr MEMORY ID mat,
                 s_vkorg FOR mvke-vkorg MEMORY ID vko,
                 s_vtweg FOR mvke-vtweg MEMORY ID vtw,
                 s_spart FOR mara-spart MEMORY ID spa,
                 s_werks FOR marc-werks MEMORY ID wrk,
                 s_lgort FOR mard-lgort MEMORY ID lag,
                 s_mtpos FOR mvke-mtpos,
                 s_mmsta FOR marc-mmsta,
                 s_lvorm FOR marc-lvorm,
                 s_lvorma FOR mara-lvorm,
                 s_lvorme FOR mvke-lvorm,
                 s_sernp FOR marc-sernp,
                 s_lgnum FOR lqua-lgnum MEMORY ID lgn,
                 s_lgtyp FOR lqua-lgtyp MEMORY ID lgt,
                 s_verme FOR lqua-verme,
                 s_clabs FOR mchb-clabs.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
