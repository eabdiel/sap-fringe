*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_MAT_QUERY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zagtr_sqa_mat_query.
INCLUDE zagti_sqa_mat_query_sel.
INCLUDE zagti_sqa_mat_query_c01.
INCLUDE zagti_sqa_display.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_varia.
  lcl_sqa_display=>f4_layout( CHANGING cv_varia = p_varia ).

START-OF-SELECTION.
  lcl_sqa_mat=>get_data( ).
  IF lt_data IS NOT INITIAL.
    lcl_sqa_display=>display( EXPORTING iv_varia = p_varia
                              CHANGING im_itab = lt_data ).
  ENDIF.
