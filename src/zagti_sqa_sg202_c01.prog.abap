*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_SG202_C01
*&---------------------------------------------------------------------*

DATA lt_data TYPE TABLE OF zagts_sqa_sg202.

CLASS lcl_sqa_sg202 DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_sg202 IMPLEMENTATION.
  METHOD get_data.

    SELECT mast~matnr,
           mast~werks,
           stpo~idnrk,
           mchb~charg,
           mchb~clabs,
           mchb~lgort
        FROM ( mast
               INNER JOIN stpo
               ON  stpo~stlnr = mast~stlnr
               INNER JOIN mchb
               ON  mchb~matnr = stpo~idnrk )
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
             WHERE mast~matnr IN @s_matnr
               AND mast~werks IN @s_werks
               AND mast~stlan IN @s_stlan
               AND mast~stlal IN @s_stlal
               AND mchb~clabs IN @s_clabs
               AND mchb~charg IN @s_charg
               AND mchb~lgort IN @s_lgort
               AND mchb~werks IN @s_werksm .

  ENDMETHOD.
ENDCLASS.
