*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_US001_FIN_C01
*&---------------------------------------------------------------------*
DATA lt_data TYPE TABLE OF zagts_sqa_us001_fin.
CLASS lcl_sqa_us001_fin DEFINITION .
  PUBLIC SECTION.
    METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_us001_fin IMPLEMENTATION.
  METHOD get_data.

    SELECT marc~matnr,
           marc~werks,
           mkal~verid,
           mchb~clabs
    FROM ( marc
           INNER JOIN mkal
           ON  mkal~matnr = marc~matnr
           AND mkal~werks = marc~werks
           INNER JOIN plko
           ON  plko~plnnr = mkal~plnnr
           AND plko~plnty = mkal~plnty
           INNER JOIN plpo
           ON  plpo~plnnr = plko~plnnr
           AND plpo~plnty = plko~plnty
           AND plpo~zaehl = plko~zaehl
           INNER JOIN mast
           ON  mast~matnr = mkal~matnr
           AND mast~stlal = mkal~stlal
           AND mast~stlan = mkal~stlan
           AND mast~werks = mkal~werks
           INNER JOIN stko
           ON  stko~stlal = mast~stlal
           AND stko~stlnr = mast~stlnr
           INNER JOIN stas
           ON  stas~stlal = stko~stlal
           AND stas~stlnr = stko~stlnr
           AND stas~stlty = stko~stlty
           INNER JOIN stpo
           ON  stpo~stlkn = stas~stlkn
           AND stpo~stlnr = stas~stlnr
           AND stpo~stlty = stas~stlty
           INNER JOIN mchb
           ON  mchb~matnr = stpo~idnrk )
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
         WHERE marc~werks IN @s_werks
           AND marc~herkl IN @s_herkl
           AND marc~fevor IN @s_fevor
           AND mkal~bdatu IN @s_bdatu
           AND mkal~adatu IN @s_adatu
           AND mkal~verid IN @s_verid
           AND plko~stlal IN @s_stlal
           AND plko~zaehl IN @s_zaehl
           AND plpo~plnnr IN @s_plnnr
           AND plpo~plnty IN @s_plnty
           AND plpo~steus IN @s_steus
           AND mast~stlan IN @s_stlan
           AND stko~stlty IN @s_stlty
           AND mchb~clabs IN @s_clabs
           AND mchb~werks IN @s_werks1
           AND mchb~lgort IN @s_lgort
           AND mchb~charg IN @s_charg .



  ENDMETHOD.
ENDCLASS.
