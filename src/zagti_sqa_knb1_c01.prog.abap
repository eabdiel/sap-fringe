*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_KNB1_C01
*&---------------------------------------------------------------------*

DATA lt_data TYPE TABLE OF zagts_sqa_knb1.

CLASS lcl_sqa_knb1 DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_knb1 IMPLEMENTATION.
  METHOD get_data.

    SELECT knb1~bukrs
           knb1~kunnr
           knb1~pernr
           bsid~belnr
           bsid~dmbtr
           bsid~bldat
           bsid~zfbdt
   FROM ( knb1
          INNER JOIN bsid
          ON  bsid~bukrs = knb1~bukrs
          AND bsid~kunnr = knb1~kunnr )
      INTO CORRESPONDING FIELDS OF TABLE lt_data
        WHERE knb1~bukrs IN s_bukrs
          AND knb1~kunnr IN s_kunnr
          AND bsid~belnr IN s_belnr
          AND bsid~zfbdt IN s_zfbdt
          AND bsid~gjahr IN s_gjhar
          AND bsid~bldat IN s_bldat
          AND bsid~augbl IN s_augbl.

  ENDMETHOD.
ENDCLASS.
