*&---------------------------------------------------------------------*
*&  Include           ZAGTI_MATERAIL_CO1
*&---------------------------------------------------------------------*

DATA lt_data TYPE TABLE OF zagts_sqa_material.
CLASS lcl_sqa_material DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_data.


ENDCLASS.
CLASS lcl_sqa_material IMPLEMENTATION.
  METHOD get_data.

    FREE lt_data.
    SELECT mvke~matnr,
           mvke~vkorg,
           mvke~vtweg,
           mvke~mtpos,
           marc~werks,
           marc~sernp,
           mchb~clabs,
           mchb~charg,
           mchb~lgort
        FROM ( mvke INNER JOIN marc
               ON  marc~werks = mvke~dwerk
               AND marc~matnr = mvke~matnr
               INNER JOIN mard
               ON  mard~matnr = marc~matnr
               AND mard~werks = marc~werks
               INNER JOIN mchb
               ON  mchb~lgort = mard~lgort
               AND mchb~matnr = mard~matnr
               AND mchb~werks = mard~werks )
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
             WHERE mvke~matnr IN @s_matnr
               AND mvke~vkorg IN @s_vkorg
               AND mvke~vtweg IN @s_vtweg
               AND mvke~mtpos IN @s_mtpos
               AND mvke~lvorm IN @s_lvorm1
               AND marc~werks IN @s_werks
               AND marc~mmsta IN @s_mmsta
               AND marc~sernp IN @s_sernp
               AND marc~lvorm IN @s_lvorm
               AND mard~lgort IN @s_lgort
               AND mchb~clabs IN @s_clabs
               AND mchb~charg IN @s_charg .


  ENDMETHOD.
ENDCLASS.
