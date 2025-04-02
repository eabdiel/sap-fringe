*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_CUSTOMER_RPT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zagtr_sqa_customer_rpt.

INCLUDE zagti_sqa_customer_rpt_sel.
INCLUDE zagti_sqa_customer_rpt_c01.
INCLUDE zagti_sqa_display.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_varia.           " when user request for saved layout

  lcl_sqa_display=>f4_layout( CHANGING cv_varia = p_varia ).

START-OF-SELECTION.

  lcl_sqa_customer_rpt=>get_data( ).
  IF lt_data IS NOT INITIAL.
    lcl_sqa_display=>display( EXPORTING iv_varia = p_varia
                              CHANGING  im_itab  = lt_data ).
  ENDIF.
