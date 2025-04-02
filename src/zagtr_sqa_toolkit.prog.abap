*&---------------------------------------------------------------------*
*& Report ZAGTR_SQA_TOOLKIT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

REPORT zagtr_sqa_toolkit.

INCLUDE zagti_sqa_toolkit_sel.
INCLUDE zagti_sqa_toolkit_c01.

INITIALIZATION.
  lcl_sqa_toolkit=>initialization( ).

AT SELECTION-SCREEN.

  lcl_sqa_toolkit=>tab_switch( ).

START-OF-SELECTION.

  DATA(ob_sqa) = NEW lcl_sqa_toolkit( ).
  IF ob_sqa IS BOUND.

    CASE tab-activetab.
      WHEN ob_sqa->mc_tab1 OR ob_sqa->mc_push1.
        DATA(ob_report) = NEW lcl_sqa_reportfunction( ob_sqa ).
        ob_report->report_processing( ).
      WHEN ob_sqa->mc_tab2 OR ob_sqa->mc_push2.
        DATA(ob_design) = NEW lcl_sqa_reportfunction( ob_sqa ).
        ob_design->query_designer( ).
      when ob_sqa->mc_tab8 or ob_sqa->mc_push8.
        SUBMIT zagtr_sqa_assist AND RETURN.
      WHEN OTHERS.
    ENDCASE.

  ENDIF.
