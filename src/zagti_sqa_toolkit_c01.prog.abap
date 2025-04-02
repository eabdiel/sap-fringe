*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_TOOLKIT_C01
*&---------------------------------------------------------------------*

CLASS lcl_sqa_toolkit DEFINITION FINAL.
  PUBLIC SECTION.
    DATA : v_rb1  TYPE char1,
           v_rb2  TYPE char1,
           v_rb3  TYPE char1,
           v_rb4  TYPE char1,
           v_rb5  TYPE char1,
           v_rb6  TYPE char1,
           v_rb7  TYPE char1,
           v_rb8  TYPE char1,
           v_rb9  TYPE char1,
           v_rb10 TYPE char1,
           v_rb11 TYPE char1.

    CONSTANTS: mc_push1 TYPE string VALUE 'PUSH1',
               mc_push2 TYPE string VALUE 'PUSH2',
               mc_push3 TYPE string VALUE 'PUSH3',
               mc_push4 TYPE string VALUE 'PUSH4',
               mc_push5 TYPE string VALUE 'PUSH5',
               mc_push6 TYPE string VALUE 'PUSH6',
               mc_push7 TYPE string VALUE 'PUSH7',
               mc_push8 TYPE string VALUE 'PUSH8',
               mc_tab1  TYPE string VALUE 'TAB1',
               mc_tab2  TYPE string VALUE 'TAB2',
               mc_tab3  TYPE string VALUE 'TAB3',
               mc_tab4  TYPE string VALUE 'TAB4',
               mc_tab5  TYPE string VALUE 'TAB5',
               mc_tab6  TYPE string VALUE 'TAB6',
               mc_tab7  TYPE string VALUE 'TAB7',
               mc_tab8  TYPE string VALUE 'TAB8',
               mc_200   TYPE i VALUE 200,
               mc_300   TYPE i VALUE 300,
               mc_400   TYPE i VALUE 400,
               mc_500   TYPE i VALUE 500,
               mc_600   TYPE i VALUE 600,
               mc_700   TYPE i VALUE 700,
               mc_800   TYPE i VALUE 800,
               mc_900   TYPE i VALUE 900,
               mc_1000  TYPE i VALUE 1000.


    CLASS-METHODS : initialization,
      tab_switch.
    METHODS: constructor.

ENDCLASS.
CLASS lcl_sqa_toolkit IMPLEMENTATION.
  METHOD constructor.
    me->v_rb1 = p_rb1.
    me->v_rb2 = p_rb2.
    me->v_rb4 = p_rb4.
    me->v_rb5 = p_rb5.
    me->v_rb6 = p_rb6.
    me->v_rb7 = p_rb7.
    me->v_rb8 = p_rb8.
    me->v_rb9 = p_rb9.
    me->v_rb10 = p_rb10.
    me->v_rb11 = p_rb11.

  ENDMETHOD.
  METHOD initialization.
    tab1 = TEXT-s01.
    tab2 = TEXT-s02.
    tab3 = TEXT-s03.
    tab4 = TEXT-s04.
    tab5 = TEXT-s05.
    tab6 = TEXT-s06.
    tab7 = TEXT-s07.
    tab8 = TEXT-s08.
    tab-prog = sy-repid.
    tab-dynnr = mc_200.
    tab-activetab = mc_tab1.


  ENDMETHOD.

  METHOD tab_switch.
    CASE sy-dynnr.
      WHEN mc_1000.
        CASE sy-ucomm.
          WHEN mc_push1.
            tab-dynnr = mc_200.
            tab-activetab = mc_tab1. "TAB1

          WHEN mc_push2 .

            tab-dynnr = mc_300.
            tab-activetab = mc_tab2. "TAB2

          WHEN mc_push3.
            tab-dynnr = mc_400.
            tab-activetab = mc_tab3. "TAB3

          WHEN mc_push4.
            tab-dynnr = mc_500.
            tab-activetab = mc_tab4. "TAB4

          WHEN mc_push5.
            tab-dynnr = mc_600.
            tab-activetab = mc_tab5. "TAB5

          WHEN mc_push6.
            tab-dynnr = mc_700.
            tab-activetab = mc_tab6. "TAB6

          WHEN mc_push7.
            tab-dynnr = mc_800.
            tab-activetab = mc_tab7. "TAB7

          WHEN mc_push8.
            tab-dynnr = mc_900.
            tab-activetab = mc_tab8. "TAB8
        ENDCASE.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.


CLASS lcl_sqa_reportfunction DEFINITION.
  PUBLIC SECTION.
    DATA ob_sqa TYPE REF TO lcl_sqa_toolkit.
    METHODS: constructor IMPORTING io_sel TYPE REF TO lcl_sqa_toolkit,
      report_processing,
      query_designer.
ENDCLASS.
CLASS lcl_sqa_reportfunction IMPLEMENTATION.
  METHOD constructor.
    me->ob_sqa = io_sel.
  ENDMETHOD.
  METHOD report_processing.
    CASE abap_true.
      WHEN ob_sqa->v_rb1.
        SUBMIT zagtr_sqa_customer_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb2.
        SUBMIT zagtr_material_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb4.
        SUBMIT zagtr_sqa_matlookup_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb5.
        SUBMIT zagtr_sqa_us001_fin_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb6.
        SUBMIT zagtr_sqa_prod_ord_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb7.
        SUBMIT zagtr_sqa_mat_query VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb8.
        SUBMIT zagtr_sqa_sg202_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN ob_sqa->v_rb9.
        SUBMIT zagtr_sqa_knb1_rpt VIA SELECTION-SCREEN AND RETURN.
      WHEN OTHERS.

    ENDCASE.
  ENDMETHOD.
  METHOD query_designer.
    IF ob_sqa->v_rb10 EQ abap_true.
      SUBMIT zagtr_sqa_sql_editor VIA SELECTION-SCREEN AND RETURN.
    ELSEIF ob_sqa->v_rb11 EQ abap_true.
      SUBMIT zagtr_sqa_enhance_sql_editor VIA SELECTION-SCREEN AND RETURN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
