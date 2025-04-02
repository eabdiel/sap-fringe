*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_MATLOOKUP_C01
*&---------------------------------------------------------------------*
DATA lt_data TYPE TABLE OF zagts_sqa_matlookup.
CLASS lcl_sqa_matlookup DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.
ENDCLASS.
CLASS lcl_sqa_matlookup IMPLEMENTATION.
  METHOD get_data.

    SELECT mchb~matnr,
           mchb~charg,
           mchb~werks,
           mchb~lgort,
           marc~sernp,
           marc~mmsta,
           mara~spart,
           mara~mtpos_mara,
           mara~matkl,
           mara~tragr,
           mvke~vkorg,
           mvke~vtweg,
           mvke~mvgr2,
           mvke~mtpos,
           lqua~lgnum,
           lqua~lgtyp,
           lqua~lgpla,
           lqua~verme,
           lqua~meins
    FROM ( mchb
           INNER JOIN marc
           ON  marc~matnr = mchb~matnr
           AND marc~werks = mchb~werks
           INNER JOIN mara
           ON  mara~matnr = marc~matnr
           INNER JOIN mvke
           ON  mvke~matnr = mara~matnr
           INNER JOIN lqua
           ON  lqua~charg = mchb~charg
           AND lqua~lgort = mchb~lgort
           AND lqua~matnr = mchb~matnr
           AND lqua~werks = mchb~werks
           AND lqua~matnr = mvke~matnr )
      INTO CORRESPONDING FIELDS OF TABLE  @lt_data
         WHERE mchb~matnr IN @s_matnr
           AND mchb~charg IN @s_charg
           AND mchb~werks IN @s_werks
           AND mchb~lgort IN @s_lgort
           AND marc~sernp IN @s_sernp
           AND marc~mmsta IN @s_mmsta
           AND mara~spart IN @s_spart
           AND mara~mtpos_mara IN @s_mara
           AND mara~matkl IN @s_matkl
           AND mara~tragr IN @s_tragr
           AND mvke~vkorg IN @s_vkorg
           AND mvke~vtweg IN @s_vtweg
           AND mvke~mvgr2 IN @s_mvgr2
           AND mvke~mtpos IN @s_mtpos
           AND lqua~lgtyp IN @s_lgtyp
           AND lqua~verme IN @s_verme
         ORDER BY lqua~verme  DESCENDING .

  ENDMETHOD.
ENDCLASS.
