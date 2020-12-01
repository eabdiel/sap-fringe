*&---------------------------------------------------------------------*
*& ALV report of program change information; display last change/creation
*& for audit purposes
*&---------------------------------------------------------------------*
REPORT zed_zprog_chgreport.
TABLES: d010sinf.
SELECT-OPTIONS: s_pname FOR d010sinf-prog,
                s_athgrp FOR d010sinf-secu,
                s_chgby FOR d010sinf-unam,
                s_chgon FOR d010sinf-udat,
                s_crtby FOR d010sinf-cnam,
                s_crton FOR d010sinf-cdat.

DATA: i_d010sinf TYPE TABLE OF d010sinf,
      k_d010sinf TYPE d010sinf,
      alv        TYPE REF TO cl_salv_table,
      columns    TYPE REF TO cl_salv_columns_table,
      column     TYPE REF TO cl_salv_column.

PERFORM get_program_data.

PERFORM initialize_alv.

PERFORM display_alv.
*&---------------------------------------------------------------------*
*&      Form  GET_PROGRAM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_program_data .
  SELECT * FROM d010sinf
    INTO TABLE i_d010sinf
    WHERE
    prog IN s_pname AND
    secu IN s_athgrp AND
    unam IN s_chgby AND
    udat IN s_chgon AND
    cnam IN s_crtby AND
    cdat IN s_crton.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize_alv .
  DATA message TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
      IMPORTING
        r_salv_table = alv
      CHANGING
        t_table = i_d010sinf ).
    CATCH cx_salv_msg INTO message.
      "error handling here
  ENDTRY.

  columns = alv->get_columns( ).
  columns->set_optimize( ).


  PERFORM hide_columns.
  PERFORM set_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv .
  alv->display( ).
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HIDE_COLUMNS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM hide_columns .
  DATA not_found TYPE REF TO cx_salv_not_found.

  TRY.
      column = columns->get_column( 'MANDT' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.

  TRY.
      column = columns->get_column( 'R3STATE' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'SQLX' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'EDTX' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'DBNA' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'CLAS' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'TYPE' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'OCCURS' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
    TRY.
      column = columns->get_column( 'SUBC' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'APPL' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'VERN' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'LEVL' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'RSTAT' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'RMAND' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'RLOAD' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
    TRY.
      column = columns->get_column( 'UTIME' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'DATALG' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'VARCL' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'DBAPL' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'FIXPT' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'SSET' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
    TRY.
      column = columns->get_column( 'SDATE' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'STIME' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
    TRY.
      column = columns->get_column( 'IDATE' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'ITIME' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'LDBNAME' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'UCCHECK' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.
  TRY.
      column = columns->get_column( 'MAXLINELN' ).
      column->set_visible( if_salv_c_bool_sap=>false ).
    CATCH cx_salv_not_found INTO not_found.
  ENDTRY.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_TOOLBAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_toolbar .
  DATA functions TYPE REF TO cl_salv_functions_list.

  functions = alv->get_functions( ).
  functions->set_all( ).
ENDFORM.
