*&---------------------------------------------------------------------*
*& Report  ZED_ALVFACTORY_SAMPLEUSE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ZED_ALVFACTORY_SAMPLEUSE.
*
CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
*
*   Data Selection Tables - Header Data
    TYPES: BEGIN OF ty_vbrk,
           vbeln TYPE vbrk-vbeln,
           kunnr TYPE vbrk-kunag,
           expand   TYPE char01,    "Column for Expand / Collapse
           END   OF ty_vbrk.
*
*   Data Selection Tables - Line Item Data
    TYPES: BEGIN OF ty_vbrp,
           vbeln TYPE vbap-vbeln,
           posnr TYPE vbap-posnr,
           matnr TYPE vbrp-matnr,
           fkimg TYPE vbrp-fkimg,
           netwr TYPE vbrp-netwr,
           END   OF ty_vbrp.
*
*   Final Header output table
    TYPES: BEGIN OF op_vbrk,
           kunnr TYPE vbrk-kunag,
           expand   TYPE char01,    "Column for Expand / Collapse
           END   OF op_vbrk.
*
*   FInal Item output table
    TYPES: BEGIN OF op_vbrp,
           matnr TYPE vbrp-matnr,
           fkimg TYPE vbrp-fkimg,
           netwr TYPE vbrp-netwr,
           END   OF op_vbrp.
*   Standard internal tables
    DATA: t_vbrk TYPE STANDARD TABLE OF ty_vbrk,
          t_vbrp TYPE STANDARD TABLE OF ty_vbrp,
          o_vbrk TYPE STANDARD TABLE OF op_vbrk,
          o_vbrp TYPE STANDARD TABLE OF op_vbrp.

* Define Work Areas
    DATA: wa_vbrk   TYPE                   ty_vbrk,
          wa_vbrp   TYPE                   ty_vbrp,
          wa_o_vbrk TYPE                   op_vbrk,
          wa_o_vbrp TYPE                   op_vbrp.
*

*   Hierarchical ALV reference
    DATA: o_hs_alv TYPE REF TO cl_salv_hierseq_table. "for hierarchy list view

*   ALV view
    DATA: o_alv TYPE REF TO cl_salv_table. "for alv table
*
    METHODS:
*     data selection
      get_data,
*
*     Generating output
      generate_output.

ENDCLASS.                    "lcl_report DEFINITION



*
*
START-OF-SELECTION.
  DATA: lo_report TYPE REF TO lcl_report.
*
  CREATE OBJECT lo_report.
*
  lo_report->get_data( ).
*
  lo_report->generate_output( ).
*
*----------------------------------------------------------------------*
*       CLASS lcl_report IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.
*
  METHOD get_data.
*   data selection - Header
    SELECT vbeln kunag
           INTO  TABLE t_vbrk
           FROM  vbrk
           UP TO 100 ROWS.
*
**   data selection - Item
    CHECK NOT t_vbrk IS INITIAL.
    SELECT vbeln posnr matnr fkimg netwr
           INTO  TABLE t_vbrp
           FROM  vbrp
           FOR   ALL ENTRIES IN t_vbrk
           WHERE vbeln = t_vbrk-vbeln.
*
   IF NOT t_vbrk[] IS INITIAL.
     CLEAR wa_vbrk. REFRESH o_vbrk.
     LOOP AT t_vbrk INTO wa_vbrk.
        MOVE-CORRESPONDING wa_vbrk TO wa_o_vbrk.
        APPEND wa_o_vbrk TO o_vbrk.
        CLEAR wa_o_vbrk.
     ENDLOOP.
   ENDIF.

  IF NOT t_vbrp[] IS INITIAL.
     CLEAR wa_vbrp. REFRESH o_vbrp.
     LOOP AT t_vbrp INTO wa_vbrp.
        MOVE-CORRESPONDING wa_vbrp TO wa_o_vbrp.
        APPEND wa_o_vbrp TO o_vbrp.
        CLEAR wa_o_vbrp.
     ENDLOOP.
   ENDIF.
  ENDMETHOD.                    "get_data
*
*.......................................................................
  METHOD generate_output.

    DATA: lx_data_err   TYPE REF TO cx_salv_data_error,
          lx_not_found  TYPE REF TO cx_salv_not_found.
*
*   Populate the Binding table.
    DATA: lt_bind TYPE salv_t_hierseq_binding,
          la_bind LIKE LINE OF lt_bind.
*
    la_bind-master = 'VBELN'.
    la_bind-slave  = 'VBELN'.
    APPEND la_bind TO lt_bind.
*
*   call factory method to generate the output in hierarchy list view
*    TRY.
*        CALL METHOD cl_salv_hierseq_table=>factory
*          EXPORTING
*            t_binding_level1_level2 = lt_bind
*          IMPORTING
*            r_hierseq               = o_hs_alv
*          CHANGING
*            t_table_level1          = t_vbrk
*            t_table_level2          = t_vbrp.
*
*      CATCH cx_salv_data_error INTO lx_data_err.
*      CATCH cx_salv_not_found  INTO lx_not_found.
*    ENDTRY.
*  "Display the hierarchy list
*   o_hs_alv->display( ).

    "Call factory method to generate ALV
    TRY.
      CALL METHOD cl_salv_table=>factory( IMPORTING r_salv_table = o_alv CHANGING t_table = t_vbrk ).
    ENDTRY.

* Displaying the ALV
    o_alv->display( ).
*
  ENDMETHOD.                    "generate_output
*
ENDCLASS.                    "lcl_report IMPLEMENTATION
