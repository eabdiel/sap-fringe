*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_CUSTOMER_RPT_SEL
*&---------------------------------------------------------------------*

TABLES : kna1,
         knvv,
         knkk.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS : s_land1  FOR kna1-land1,
                 s_brsch  FOR kna1-brsch,
                 s_ktokd  FOR kna1-ktokd MEMORY ID kgd,
                 s_vkorg  FOR knvv-vkorg MEMORY ID vko,
                 s_spart  FOR knvv-spart MEMORY ID spa,
                 s_vtweg  FOR knvv-vtweg MEMORY ID vtw,
                 s_kunnr  FOR knvv-kunnr MEMORY ID kun,
                 s_aufsd  FOR kna1-aufsd,
                 s_faksd  FOR kna1-faksd,
                 s_lifsd  FOR kna1-lifsd,
                 s_loevm  FOR kna1-loevm,
                 s_loevm1 FOR knvv-loevm,
                 s_aufsd1 FOR knvv-aufsd,
                 s_kdgrp  FOR knvv-kdgrp MEMORY ID vkd,
                 s_bzirk  FOR knvv-bzirk MEMORY ID bzi,
                 s_lifsd1 FOR knvv-lifsd,
                 s_autlf  FOR knvv-autlf,
                 s_kzazu  FOR knvv-kzazu,
                 s_lprio  FOR knvv-lprio,
                 s_vsbed  FOR knvv-vsbed,
                 s_faksd1 FOR knvv-faksd,
                 s_chspl  FOR knvv-chspl,
                 s_ktgrd  FOR knvv-ktgrd,
                 s_vkgrp  FOR knvv-vkgrp MEMORY ID vkg,
                 s_vkbur  FOR knvv-vkbur MEMORY ID vkb,
                 s_cassd  FOR knvv-cassd,
                 s_freigh FOR knvv-zzfreight,
                 s_kkber  FOR knkk-kkber MEMORY ID kkb,
                 s_crblb  FOR knkk-crblb,
                 s_uedat  FOR knkk-uedat.
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_varia TYPE disvariant-variant.         " layout
SELECTION-SCREEN END OF BLOCK b2.
