*&---------------------------------------------------------------------*
*&  Include           ZAGTI_MATERIAL_SEL
*&---------------------------------------------------------------------*
TABLES: mvke,
        mard,
        mchb,
        marc.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-s01.
SELECT-OPTIONS : s_matnr FOR mvke-matnr MEMORY ID mat,
                 s_vkorg FOR mvke-vkorg MEMORY ID vko,
                 s_vtweg FOR mvke-vtweg MEMORY ID vtw,
                 s_werks FOR marc-werks MEMORY ID wrk,
                 s_lgort FOR mard-lgort MEMORY ID lag,
                 s_mtpos FOR mvke-mtpos,
                 s_clabs FOR mchb-clabs,
                 s_mmsta FOR marc-mmsta,
                 s_sernp FOR marc-sernp,
                 s_lvorm FOR marc-lvorm,
                 s_lvorm1 FOR mvke-lvorm,
                 s_charg FOR mchb-charg MEMORY ID cha.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-s02.
PARAMETERS: p_varia  TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
