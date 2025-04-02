*&---------------------------------------------------------------------*
*&  Include           ZAGTR_SQA_PROD_ORD_C01
*&---------------------------------------------------------------------*
DATA lt_data TYPE TABLE OF zagts_sqa_prod_ord.
CLASS lcl_sqa_prod_ord DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_prod_ord IMPLEMENTATION.
  METHOD get_data.

    SELECT afko~aufnr,
           afko~gamng,
           afko~plnbez,
           afko~terkz,
           afko~prueflos,
           afko~arsps,
           afko~ftrmi,
           afpo~verid,
           afpo~dauat,
           afpo~charg,
           afpo~dwerk,
           afpo~lgort
    FROM ( afko
           INNER JOIN afpo
           ON  afpo~aufnr = afko~aufnr )
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
         WHERE afko~aufnr IN @s_aufnr
           AND afko~gamng IN @s_gamng
           AND afko~plnbez IN @s_plnbez
           AND afko~prueflos IN @s_pflos
           AND afko~terkz IN @s_terkz
           AND afko~arsps IN @s_arsps
           AND afko~ftrmi IN @s_ftrmi
           AND afpo~verid IN @s_verid
           AND afpo~dauat IN @s_dauat
           AND afpo~charg IN @s_charg
           AND afpo~dwerk IN @s_dwerk
           AND afpo~lgort IN @s_lgort.
  ENDMETHOD.
ENDCLASS.
