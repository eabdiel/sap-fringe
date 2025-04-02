*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_SG202_RPT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zagtr_sqa_sg202_rpt.

INCLUDE zagti_sqa_sg202_sel.
INCLUDE zagti_sqa_sg202_c01.
INCLUDE zagti_sqa_display.

AT SELECTION-SCREEN  ON VALUE-REQUEST FOR p_varia.
  lcl_sqa_display=>f4_layout( CHANGING cv_varia = p_varia ).

START-OF-SELECTION.

  lcl_sqa_sg202=>get_data( ).
  IF lt_data IS NOT INITIAL.
    lcl_sqa_display=>display( EXPORTING  iv_varia = p_varia
                              CHANGING  im_itab   = lt_data ).
  ENDIF.
