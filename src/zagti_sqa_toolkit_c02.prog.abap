*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_TOOLKIT_C02
*&---------------------------------------------------------------------*

CLASS lcl_variant_maintanance DEFINITION.
  PUBLIC SECTION.
    TYPES :BEGIN OF lty_data,
             report         TYPE vari-report,
             variant        TYPE vari-variant,
             sel_field      TYPE rsparams-selname,
             kind           TYPE rsparams-kind,
             option         TYPE rsparams-option,
             sign           TYPE rsparams-sign,
             old_value_low  TYPE rsparams-low,
             new_value_low  TYPE rsparams-low,
             old_value_high TYPE rsparams-high,
             new_value_high TYPE rsparams-high,
             status         TYPE string,
           END OF lty_data,
           lty_repo TYPE RANGE OF vari-report,
           lty_vari TYPE RANGE OF vari-variant.

    DATA: lt_repo       TYPE lty_repo,
          lt_vari       TYPE lty_vari,
          lt_varid      TYPE STANDARD TABLE OF varid,
          ls_varid      TYPE varid,
          lt_valtab     TYPE STANDARD TABLE OF rsparams,
          lt_data       TYPE TABLE OF lty_data,
          ls_data       TYPE lty_data,
          handler_added TYPE abap_bool,
          lr_table      TYPE REF TO cl_salv_table.

    CONSTANTS:lc_sel_field      TYPE lvc_fname VALUE 'SEL_FIELD', "#EC NOTEXT
              lc_old_value      TYPE lvc_fname VALUE 'OLD_VALUE_LOW', "#EC NOTEXT
              lc_new_value      TYPE lvc_fname VALUE 'NEW_VALUE_LOW', "#EC NOTEXT
              lc_old_value_high TYPE lvc_fname VALUE 'OLD_VALUE_HIGH', "#EC NOTEXT
              lc_new_value_high TYPE lvc_fname VALUE 'NEW_VALUE_HIGH', "#EC NOTEXT
              lc_status_f       TYPE lvc_fname VALUE 'STATUS', "#EC NOTEXT
              lc_sel            TYPE scrtext_m VALUE 'Selection Field', "#EC NOTEXT
              lc_old            TYPE scrtext_m VALUE 'Old Value Low', "#EC NOTEXT
              lc_new            TYPE scrtext_m VALUE 'New Value Low', "#EC NOTEXT
              lc_old_high       TYPE scrtext_m VALUE 'Old Value High', "#EC NOTEXT
              lc_new_high       TYPE scrtext_m VALUE 'New Value High', "#EC NOTEXT
              lc_status         TYPE scrtext_m VALUE 'Status', "#EC NOTEXT
              lc_text_type      TYPE lvc_ddict VALUE 'M',   "#EC NOTEXT
              lc_e              TYPE char1     VALUE 'E',   "#EC NOTEXT
              lc_s              TYPE char1     VALUE 'S'.   "#EC NOTEXT
    METHODS: constructor,
      variant_maintanance.
  PRIVATE SECTION.
    METHODS : get_variant_data,
      update_variant,
      dispaly,
      evh_after_refresh   FOR EVENT after_refresh  OF cl_gui_alv_grid
        IMPORTING sender,
      evh_data_changed    FOR EVENT data_changed   OF cl_gui_alv_grid
        IMPORTING er_data_changed,
      evh_added_function  FOR EVENT added_function OF cl_salv_events_table
        IMPORTING e_salv_function sender.
ENDCLASS.
CLASS lcl_variant_maintanance IMPLEMENTATION.
  METHOD constructor.
    lt_repo = s_repo[].
    lt_vari = s_vari[].

    IF lt_repo IS INITIAL AND  lt_vari IS INITIAL.
      MESSAGE TEXT-m03 TYPE lc_s DISPLAY LIKE lc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.
  METHOD variant_maintanance.
* get variant Meta data
    get_variant_data( ).
* Display with editable
    dispaly( ).

  ENDMETHOD.


  METHOD evh_after_refresh.

    CHECK handler_added EQ abap_false.

    SET HANDLER me->evh_data_changed FOR sender.

    sender->get_frontend_fieldcatalog(
      IMPORTING
        et_fieldcatalog = DATA(fcat)    " Field Catalog
    ).

    "editable fields
    ASSIGN fcat[ fieldname = lc_new_value ] TO FIELD-SYMBOL(<fcat>).
    IF sy-subrc EQ 0. <fcat>-edit = abap_true. ENDIF.
    ASSIGN fcat[ fieldname =  lc_new_value_high ] TO <fcat>.
    IF sy-subrc EQ 0.
      <fcat>-edit = abap_true.
    ENDIF.

    sender->set_frontend_fieldcatalog( it_fieldcatalog = fcat ).

    sender->register_edit_event(
      EXPORTING
        i_event_id = sender->mc_evt_modified ).


    sender->set_ready_for_input(
        i_ready_for_input = 1 ).

    handler_added = abap_true.
    sender->refresh_table_display( ).

  ENDMETHOD.
  METHOD  evh_data_changed.

    READ TABLE er_data_changed->mt_good_cells ASSIGNING FIELD-SYMBOL(<cell>) INDEX 1.
    IF sy-subrc IS INITIAL.
      READ TABLE me->lt_data ASSIGNING FIELD-SYMBOL(<fs_data>) INDEX <cell>-row_id.
      IF sy-subrc IS INITIAL.

        CASE <cell>-fieldname.
          WHEN lc_new_value.
            <fs_data>-new_value_low = <cell>-value.
          WHEN lc_new_value_high.
            <fs_data>-new_value_high = <cell>-value.
        ENDCASE.
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD evh_added_function.

    CASE e_salv_function .
      WHEN 'SAVE'.
        update_variant( ).
    ENDCASE.

  ENDMETHOD.

  METHOD get_variant_data.
* Get the report variants as per selection criteria

    SELECT *
       FROM varid
           INTO TABLE lt_varid
           WHERE report IN lt_repo
           AND variant IN lt_vari.

    IF sy-subrc NE 0.
      MESSAGE TEXT-m02 TYPE lc_e.
    ENDIF.

    CLEAR ls_varid.
    LOOP AT lt_varid INTO ls_varid.
      FREE lt_valtab.

*Read the variant contents
      CALL FUNCTION 'RS_VARIANT_CONTENTS'
        EXPORTING
          report               = ls_varid-report
          variant              = ls_varid-variant
        TABLES
          valutab              = lt_valtab
        EXCEPTIONS
          variant_non_existent = 1
          variant_obsolete     = 2
          OTHERS               = 3.
      IF sy-subrc <> 0.
        MESSAGE TEXT-m02 TYPE lc_e.
      ENDIF.

      LOOP AT lt_valtab INTO DATA(ls_valtab).

        ls_data = VALUE #(
                  report = ls_varid-report
                   variant = ls_varid-variant
                   sel_field = ls_valtab-selname
                   kind = ls_valtab-kind
                   option = ls_valtab-option
                   sign = ls_valtab-sign
                   old_value_low = ls_valtab-low
                   old_value_high = ls_valtab-high ).
        APPEND ls_data TO lt_data.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD update_variant.

    LOOP AT lt_varid INTO DATA(wa_varid).
      FREE :  lt_valtab.

      DATA(lv_repo) = wa_varid-report.
      DATA(lv_vart) = wa_varid-variant.

*--- Read the variant contents
      CALL FUNCTION 'RS_VARIANT_CONTENTS'
        EXPORTING
          report               = lv_repo
          variant              = lv_vart
        TABLES
          valutab              = lt_valtab
        EXCEPTIONS
          variant_non_existent = 1
          variant_obsolete     = 2
          OTHERS               = 3.
      IF sy-subrc <> 0.
        MESSAGE TEXT-m02 TYPE lc_e.
      ENDIF.

      LOOP AT lt_valtab ASSIGNING FIELD-SYMBOL(<fs_valtab>).
        READ TABLE lt_data ASSIGNING FIELD-SYMBOL(<fs_data1>)
        WITH KEY report = lv_repo
                 variant = lv_vart
                 kind = <fs_valtab>-kind
                 sel_field = <fs_valtab>-selname
                 old_value_low = <fs_valtab>-low
                 old_value_high = <fs_valtab>-high.

        IF sy-subrc IS INITIAL.
          IF <fs_data1>-new_value_low IS NOT INITIAL.
            <fs_data1>-old_value_low = <fs_data1>-new_value_low.
            <fs_valtab>-low = <fs_data1>-new_value_low.
            CLEAR <fs_data1>-new_value_low.
            DATA(lv_update) = abap_true.
          ENDIF.
          IF <fs_data1>-new_value_high IS NOT INITIAL.
            <fs_data1>-old_value_high = <fs_data1>-new_value_high.
            <fs_valtab>-high = <fs_data1>-new_value_high.
            CLEAR <fs_data1>-new_value_high.
            lv_update = abap_true.
          ENDIF.

          IF  lv_update EQ abap_true.

            CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT'
              EXPORTING
                curr_report               = lv_repo
                curr_variant              = lv_vart
                vari_desc                 = wa_varid
              TABLES
                vari_contents             = lt_valtab
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
              <fs_data1>-status = TEXT-m01.
            ELSEIF sy-subrc EQ 0.
              <fs_data1>-status =  |Variant field |
               & |{ <fs_data1>-sel_field } | & |Updated Sucessfully|.
            ENDIF.
            CLEAR lv_update.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    lr_table->refresh( ).
  ENDMETHOD.
  METHOD dispaly.

    TRY.
        CALL METHOD cl_salv_table=>factory
          EXPORTING
            list_display = abap_false
          IMPORTING
            r_salv_table = lr_table
          CHANGING
            t_table      = lt_data.
      CATCH cx_salv_msg  INTO DATA(lo_msg).
        MESSAGE lo_msg->get_text( ) TYPE 'E' DISPLAY LIKE 'S'.
    ENDTRY.

* pf status with custom save button
    lr_table->set_screen_status(
     pfstatus      =  'ZVARI_STATUS'
     report        =  sy-repid
     set_functions = lr_table->c_functions_all ).

    TRY.
* set Alv Heading
        DATA(lr_display) = lr_table->get_display_settings( ).
        lr_display->set_list_header( TEXT-s18 ).
* Optimize column width
        DATA(lr_columns) = lr_table->get_columns( ).
        lr_columns->set_optimize( abap_true ).
* change column name
        DATA(l_column) = lr_columns->get_column( lc_sel_field ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_sel ).

        l_column = lr_columns->get_column( lc_old_value ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_old ).

        l_column = lr_columns->get_column( lc_new_value ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_new ).


        l_column = lr_columns->get_column( lc_old_value_high ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_old_high ).

        l_column = lr_columns->get_column( lc_new_value_high ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_new_high ).

        l_column = lr_columns->get_column( lc_status_f ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_status ).
        l_column->set_optimized( abap_true ).


      CATCH cx_salv_not_found INTO DATA(lo_msg_s).
        MESSAGE lo_msg_s->get_text( ) TYPE lc_e DISPLAY LIKE lc_s.
    ENDTRY.

    "Setting handler for event after_refresh for all grids
    SET HANDLER evh_after_refresh FOR ALL INSTANCES.

    "Event for User Command and etc. of SALV
    DATA(lo_events) = lr_table->get_event( ).
    SET HANDLER evh_added_function FOR lo_events.

    lr_table->display( ).

  ENDMETHOD.

ENDCLASS.
