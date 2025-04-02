*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_CUSTOMER_RPT_C01
*&---------------------------------------------------------------------*

DATA lt_data TYPE TABLE OF zagts_sqa_customer.
CLASS lcl_sqa_customer_rpt DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_customer_rpt IMPLEMENTATION.
  METHOD get_data.

    FREE lt_data.
    SELECT kna1~kunnr,
           knvv~vkorg,
           knvv~vtweg,
           knvv~spart,
           knkk~kkber,
           knkk~uedat
         FROM ( kna1
                INNER JOIN knvv
                ON  knvv~kunnr = kna1~kunnr
                INNER JOIN knkk
                ON  knkk~kunnr = knvv~kunnr )
          INTO  CORRESPONDING FIELDS OF TABLE  @lt_data
              WHERE kna1~land1 IN @s_land1
                AND kna1~brsch IN @s_brsch
                AND kna1~ktokd IN @s_ktokd
                AND kna1~aufsd IN @s_aufsd
                AND kna1~faksd IN @s_faksd
                AND kna1~lifsd IN @s_lifsd
                AND kna1~loevm IN @s_loevm
                AND knvv~vkorg IN @s_vkorg
                AND knvv~vtweg IN @s_vtweg
                AND knvv~spart IN @s_spart
                AND knvv~kunnr IN @s_kunnr
                AND knvv~loevm IN @s_loevm1
                AND knvv~aufsd IN @s_aufsd1
                AND knvv~kdgrp IN @s_kdgrp
                AND knvv~bzirk IN @s_bzirk
                AND knvv~lifsd IN @s_lifsd1
                AND knvv~autlf IN @s_autlf
                AND knvv~kzazu IN @s_kzazu
                AND knvv~lprio IN @s_lprio
                AND knvv~vsbed IN @s_vsbed
                AND knvv~faksd IN @s_faksd1
                AND knvv~chspl IN @s_chspl
                AND knvv~ktgrd IN @s_ktgrd
                AND knvv~vkgrp IN @s_vkgrp
                AND knvv~vkbur IN @s_vkbur
                AND knvv~cassd IN @s_cassd
                AND knvv~zzfreight IN @s_freigh
                AND knkk~kkber IN @s_kkber
                AND knkk~crblb IN @s_crblb
                AND knkk~uedat IN @s_uedat .

  ENDMETHOD.

ENDCLASS.
