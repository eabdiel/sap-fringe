*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_US001_FIN_RPT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zagtr_sqa_us001_fin_rpt.

INCLUDE zagti_sqa_us001_fin_sel.
INCLUDE zagti_sqa_us001_fin_c01.
INCLUDE zagti_sqa_display.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_varia.
  lcl_sqa_display=>f4_layout( CHANGING cv_varia = p_varia ).

START-OF-SELECTION.
  DATA(ob_sqa) = NEW lcl_sqa_us001_fin( ).
  ob_sqa->get_data( ).
  IF lt_data IS NOT INITIAL.
    lcl_sqa_display=>display( EXPORTING iv_varia = p_varia
                              CHANGING  im_itab  = lt_data ).
  ENDIF.
