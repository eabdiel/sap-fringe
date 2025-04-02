*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_KNB1_RPT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zagtr_sqa_knb1_rpt.

INCLUDE zagti_sqa_knb1_sel.
INCLUDE zagti_sqa_knb1_c01.
INCLUDE zagti_sqa_display.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_varia.
  lcl_sqa_display=>f4_layout( CHANGING cv_varia = p_varia ).

START-OF-SELECTION.
  lcl_sqa_knb1=>get_data( ).
  IF lt_data IS NOT INITIAL.
    lcl_sqa_display=>display( EXPORTING iv_varia = p_varia
                              CHANGING  im_itab  = lt_data ).
  ENDIF.
