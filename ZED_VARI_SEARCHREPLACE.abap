*&---------------------------------------------------------------------*
*& Report  ZED_VARI_SEARCHREPLACE
*&
*&---------------------------------------------------------------------*
*& search and replace variant values 
*&
*&---------------------------------------------------------------------*
REPORT ZED_VARI_SEARCHREPLACE NO STANDARD PAGE HEADING
                              LINE-SIZE 180
                              LINE-COUNT 45.

*---------------------------------------------------------------------*
*                         DATA DECLARATION                            *
*---------------------------------------------------------------------*

DATA: v_repname TYPE varid-report,
      v_vari    TYPE varid-variant.

DATA: v_repo TYPE raldb_repo,
      v_vart TYPE raldb_vari.

DATA: i_varid  TYPE STANDARD TABLE OF varid,
      wa_varid TYPE varid.

DATA: i_valtab  TYPE STANDARD TABLE OF rsparams,
      wa_valtab TYPE rsparams.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-001.

SELECT-OPTIONS: s_repo FOR v_repname,
                s_vari FOR v_vari.

PARAMETERS: p_txt TYPE char50,
            p_old TYPE char50,
            p_new TYPE char50,
            p_tst TYPE char1 AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN: END OF BLOCK blk1.

*---------------------------------------------------------------------*
*                    START OF SELECTION                               *
*---------------------------------------------------------------------*

START-OF-SELECTION.

* --- Get the report variants as per selection criteria

  SELECT * FROM varid
         INTO TABLE i_varid
         WHERE report IN s_repo
         AND variant IN s_vari.

  IF sy-subrc NE 0.
*-- Please Put your message here
  ENDIF.

  WRITE: /5  'REPORT NAME' COLOR 2,
          45 'VARIANT' COLOR 2,
          80 'SELECTION VAR.' COLOR 2,
          100 'OLD VALUE' COLOR 2,
          130 'NEW VALUE' COLOR 2.
  SKIP.

  LOOP AT i_varid INTO wa_varid.

    v_repo = wa_varid-report.
    v_vart = wa_varid-variant.

    CLEAR i_valtab.

*--- Read the variant contents
    CALL FUNCTION 'RS_VARIANT_CONTENTS'
      EXPORTING
        report               = v_repo
        variant              = v_vart
      TABLES
        valutab              = i_valtab
      EXCEPTIONS
        variant_non_existent = 1
        variant_obsolete     = 2
        OTHERS               = 3.
    IF sy-subrc <> 0.
*    Capture Messages here
    ENDIF.

    LOOP AT i_valtab INTO wa_valtab.

*--- Here we check if the text in our example BUKRS is part of the program select-options or parameters
      IF wa_valtab-selname CS p_txt.
        IF wa_valtab-low CS p_old.

          WRITE: /5  v_repo,
                 45  v_vart,
                 80  wa_valtab-selname,
                 100 wa_valtab-low,
                 130 p_new.
          wa_valtab-low = p_new.
          MODIFY i_valtab FROM wa_valtab.

        ELSEIF wa_valtab-high CS p_old.
          WRITE: /5  v_repo,
                 45  v_vart,
                 80  wa_valtab-selname,
                 100 wa_valtab-high,
                 130 p_new.

          wa_valtab-high = p_new.
          MODIFY i_valtab FROM wa_valtab.
        ENDIF.
      ENDIF.

    ENDLOOP.

*----- test run option

    IF p_tst IS INITIAL.

      CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT'
        EXPORTING
          curr_report               = v_repo
          curr_variant              = v_vart
          vari_desc                 = wa_varid
        TABLES
          vari_contents             = i_valtab
        EXCEPTIONS
          illegal_report_or_variant = 1
          illegal_variantname       = 2
          not_authorized            = 3
          not_executed              = 4
          report_not_existent       = 5
          report_not_supplied       = 6
          variant_doesnt_exist      = 7
          variant_locked            = 8
          selections_no_match       = 9
          OTHERS                    = 10.
      IF sy-subrc <> 0.
*  error handling here
      ENDIF.

    ENDIF.

  ENDLOOP.
