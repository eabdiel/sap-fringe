*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_MAT_QUERY_C01
*&---------------------------------------------------------------------*
DATA lt_data TYPE TABLE OF zagts_sqa_mat.
CLASS  lcl_sqa_mat DEFINITION FINAL .
  PUBLIC SECTION.
    CLASS-METHODS : get_data.
ENDCLASS.
CLASS lcl_sqa_mat IMPLEMENTATION.
  METHOD get_data .
    SELECT marc~werks,
           marc~sernp,
           marc~matnr,
           mara~spart,
           mvke~vkorg,
           mvke~vtweg,
           mard~lgort,
           lqua~verme,
           lqua~meins,
           lqua~charg
    FROM ( mchb
           INNER JOIN marc
           ON  marc~matnr = mchb~matnr
           AND marc~werks = mchb~werks
           INNER JOIN mara
           ON  mara~matnr = marc~matnr
           INNER JOIN mvke
           ON  mvke~matnr = mara~matnr
           INNER JOIN mard
           ON  mard~werks = mvke~dwerk
           AND mard~matnr = mvke~matnr
           INNER JOIN lqua
           ON  lqua~lgort = mard~lgort
           AND lqua~matnr = mard~matnr
           AND lqua~werks = mard~werks )
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
         WHERE mchb~clabs IN @s_clabs
           AND marc~werks IN @s_werks
           AND marc~mmsta IN @s_mmsta
           AND marc~lvorm IN @s_lvorm
           AND marc~sernp IN @s_sernp
           AND mara~spart IN @s_spart
           AND mara~lvorm IN @s_lvorma
           AND mvke~matnr IN @s_matnr
           AND mvke~vkorg IN @s_vkorg
           AND mvke~vtweg IN @s_vtweg
           AND mvke~mtpos IN @s_mtpos
           AND mvke~lvorm IN @s_lvorme
           AND mard~lgort IN @s_lgort
           AND lqua~lgnum IN @s_lgnum
           AND lqua~lgtyp IN @s_lgtyp
           AND lqua~verme IN @s_verme .
  ENDMETHOD.
ENDCLASS.
