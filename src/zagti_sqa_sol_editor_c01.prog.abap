
*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_SOL_EDITOR_C01
*&---------------------------------------------------------------------*



CLASS lcl_sql_editor DEFINITION FINAL.
  PUBLIC SECTION.

    TYPES: BEGIN OF lty_sql ,
             tdline TYPE tline-tdline,
           END OF lty_sql,
           BEGIN OF typ_tablename,
             tabname TYPE dd02l-tabname,
             alias   TYPE dd02l-tabname,
           END OF typ_tablename.


    CLASS-DATA: cc_sql    TYPE REF TO cl_gui_custom_container,
                cc_inst   TYPE REF TO cl_gui_custom_container,
                sqltext   TYPE REF TO cl_gui_textedit,
                inst_text TYPE REF TO cl_gui_textedit,
                mt_inst   TYPE TABLE OF lty_sql.

    DATA : mt_sql          TYPE TABLE OF lty_sql,
           mt_fcat         TYPE TABLE OF lvc_s_fcat,
           mv_program      TYPE string,
           mv_select_query TYPE boolean,
           mv_where_exits  TYPE boolean,
           mv_where_index  TYPE sy-tabix.

    CONSTANTS : mc_e       TYPE char1 VALUE 'E',
                mc_i       TYPE char1 VALUE 'I',
                mc_w       TYPE char1 VALUE 'W',
                mc_cc_sql  TYPE char6 VALUE 'CC_SQL',
                mc_cc_inst TYPE char10 VALUE 'CC_INST'.


    CLASS-METHODS :prepare_editor_screen,
      free_object,
      clear_editor_screen.
    METHODS main.

  PRIVATE SECTION.
    METHODS:get_sql_command,
      check_operation,
      create_dynamic_sql ,
      create_field_catalog ,
      create_dyntable .


ENDCLASS.

CLASS lcl_sql_editor IMPLEMENTATION.

  METHOD prepare_editor_screen.
    IF cc_sql IS NOT BOUND.
      cc_sql = NEW cl_gui_custom_container( mc_cc_sql ).
      IF sqltext IS NOT BOUND.
        sqltext = NEW cl_gui_textedit( wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
                                              parent = cc_sql ).
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD get_sql_command.
    FREE mt_sql.

    sqltext->get_text_as_r3table( IMPORTING  table =  mt_sql[] ).    " get sql command into internal table.


    IF mt_sql IS NOT INITIAL.
      DELETE mt_sql WHERE tdline IS INITIAL.

      LOOP AT mt_sql ASSIGNING FIELD-SYMBOL(<fs_sql>).             " condense and convert to upercase.
        TRANSLATE <fs_sql>-tdline TO UPPER CASE .
        CONDENSE <fs_sql>-tdline.
      ENDLOOP.
    ELSE.
      MESSAGE TEXT-t03 TYPE mc_e. "  Please Write SQl Query to get the output
    ENDIF.


  ENDMETHOD.
  METHOD  check_operation .

    DATA lv_join_count TYPE i VALUE 0.
    IF mt_sql IS NOT INITIAL.
      LOOP AT mt_sql ASSIGNING FIELD-SYMBOL(<fs_sql1>).
        IF <fs_sql1> IS ASSIGNED.
          IF <fs_sql1>-tdline   CS 'DELETE'
            OR <fs_sql1>-tdline CS 'UPDATE'
            OR <fs_sql1>-tdline CS 'INSERT'.
            MESSAGE TEXT-t04 TYPE mc_e. "Data base Delete/Insert/Update operation is not allowed
          ENDIF.
          IF <fs_sql1>-tdline CS 'JOIN'.
            lv_join_count = lv_join_count + 1.
          ENDIF.
          IF <fs_sql1>-tdline CS 'WHERE'.
            CLEAR: mv_where_exits,
                   mv_where_index.
            mv_where_exits = abap_true.
            mv_where_index = sy-tabix.
          ENDIF.
        ENDIF.
      ENDLOOP.
      UNASSIGN <fs_sql1>.
    ENDIF.

    IF lv_join_count > 3.
      MESSAGE TEXT-t05 TYPE mc_e.
      CLEAR lv_join_count.
    ENDIF.

  ENDMETHOD.
  METHOD create_dynamic_sql.
    CONSTANTS : lc_line1 TYPE string VALUE 'REPORT ZSQL_INNER_DYNAMICPRG.'  ##NO_TEXT,
                lc_line2 TYPE string VALUE 'FORM call_sql TABLES p_it_return ' ##NO_TEXT,
                lc_line3 TYPE string VALUE 'CHANGING p_subrc LIKE sy-subrc.' ##NO_TEXT,
                lc_line4 TYPE string VALUE 'FREE p_it_return. p_subrc = 4.' ##NO_TEXT,
                lc_line5 TYPE string VALUE 'INTO CORRESPONDING FIELDS OF TABLE p_it_return' ##NO_TEXT,
                lc_line6 TYPE string VALUE '.' ##NO_TEXT,
                lc_line7 TYPE string VALUE 'p_subrc = SY-SUBRC.' ##NO_TEXT,
                lc_line8 TYPE string VALUE 'ENDFORM.' ##NO_TEXT.

    TYPES : BEGIN OF lty_line,
              line TYPE char72,
            END OF lty_line.
    DATA : lt_line    TYPE TABLE OF lty_line,
           lv_message TYPE string.
    FREE lt_line.

    lt_line = VALUE #( ( line = lc_line1 )
                     ( line = lc_line2 )
                     ( line = lc_line3 )
                     ( line = lc_line4 )
  ).

    CLEAR mv_select_query.
    READ TABLE mt_sql ASSIGNING FIELD-SYMBOL(<fs_sql2>) INDEX 1.
    IF sy-subrc IS INITIAL.
      IF <fs_sql2>-tdline CS 'SELECT'.
        mv_select_query = abap_true.
      ENDIF.
    ENDIF.
    LOOP AT mt_sql ASSIGNING FIELD-SYMBOL(<fs_sql3>).
      IF <fs_sql3> IS ASSIGNED.
        IF mv_where_exits EQ abap_true.
          IF <fs_sql3>-tdline CS 'WHERE'
            AND mv_select_query = abap_true.
            APPEND lc_line5 TO lt_line[].
            APPEND <fs_sql3>-tdline  TO lt_line[].
          ELSE.
            APPEND <fs_sql3>-tdline  TO lt_line[].
          ENDIF.
        ELSE.
          IF <fs_sql3>-tdline CS 'FROM'
              AND mv_select_query = abap_true.
            APPEND lc_line5 TO lt_line[].
            APPEND <fs_sql3>-tdline  TO lt_line[].
          ELSE.
            APPEND <fs_sql3>-tdline  TO lt_line[].
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
    APPEND lc_line6 TO lt_line[].
    APPEND lc_line7 TO lt_line[].
    APPEND lc_line8 TO lt_line[].


    CLEAR : mv_program , lv_message .

    TRY.
        GENERATE SUBROUTINE POOL lt_line NAME mv_program
         MESSAGE lv_message .

        IF sy-subrc IS NOT INITIAL.
          MESSAGE lv_message TYPE mc_e.
        ENDIF.
      CATCH cx_sy_generate_subpool_full INTO DATA(lo_msg).
        MESSAGE lo_msg->get_text( ) TYPE mc_e.
      CATCH cx_sy_gen_source_too_wide INTO DATA(lo_msg1).
        MESSAGE lo_msg1->get_text( ) TYPE mc_e.

    ENDTRY.

  ENDMETHOD.
  METHOD create_field_catalog.
    TYPES: BEGIN OF typ_selfields,
             tabname   TYPE lvc_s_fcat-tabname,
             fieldname TYPE lvc_s_fcat-fieldname,
           END OF typ_selfields,
           BEGIN OF lty_split ,
             str TYPE lvc_s_fcat-tabname,
           END OF lty_split.

    DATA: lt_tablename   TYPE TABLE OF typ_tablename,
          ls_tablename   TYPE typ_tablename,
          lt_selfields   TYPE TABLE OF typ_selfields,
          lt_wherefields TYPE TABLE OF typ_selfields,
          ls_selfields   TYPE typ_selfields,
          ls_fcat        TYPE  lvc_s_fcat,
          lt_split       TYPE TABLE OF lty_split,
          ls_split       TYPE lty_split,
          lv_willexit    TYPE boolean.

    FREE :mt_fcat,
    lt_tablename,
    lt_selfields,
    lt_wherefields.

*"  get table name in sql.

    LOOP AT mt_sql  ASSIGNING FIELD-SYMBOL(<fs_mt>)
      WHERE tdline CS 'FROM'
          OR tdline CS 'JOIN'
          OR tdline CS 'UPDATE'.
      IF <fs_mt> IS ASSIGNED.
        FREE lt_split.
        CLEAR ls_split.
        SPLIT <fs_mt>-tdline+sy-fdpos AT space INTO TABLE lt_split.
        DELETE lt_split WHERE str IS INITIAL
                            OR str = '('
                            OR str = ')'.

        CLEAR ls_split.
        READ TABLE lt_split INTO ls_split INDEX 2.
        CHECK ls_split-str IS NOT INITIAL.
        ls_tablename-tabname = ls_split-str.
        CLEAR ls_split.
        READ TABLE lt_split INTO ls_split INDEX 3.
        IF ls_split-str = 'AS'.
          CLEAR ls_split.
          READ TABLE lt_split INTO ls_split INDEX 4.
          ls_tablename-alias = ls_split-str.
        ENDIF.
        APPEND ls_tablename TO lt_tablename.
        CLEAR ls_tablename.
      ENDIF.
    ENDLOOP.
*" Check to verify that query has atleast one key field.

    DATA: lt_keyfield TYPE TABLE OF cacs_s_cond_keyfields.
    CLEAR ls_tablename.
    FREE : lt_keyfield .

    IF lt_tablename IS NOT INITIAL.

      READ TABLE lt_tablename INTO ls_tablename INDEX 1.
      IF sy-subrc IS INITIAL.
        DATA(lv_tabname) = ls_tablename-tabname.
      ENDIF.

      CALL FUNCTION 'CACS_GET_TABLE_FIELDS'   " Get key field of the table
        EXPORTING
          i_tabname  = lv_tabname   " Table Name
        TABLES
          t_keyfield = lt_keyfield. " Key Fields

      IF mv_where_exits EQ abap_true.

        LOOP AT mt_sql INTO DATA(ls_sql_v) FROM mv_where_index.

          CONDENSE ls_sql_v-tdline.
          FREE lt_split.
          SPLIT ls_sql_v-tdline AT space INTO TABLE lt_split.
          DELETE lt_split WHERE str IS INITIAL
                              OR str = 'WHERE'
                              OR str = '='
                              OR str = 'EQ'
                              OR str = 'NE'
                              OR str = 'AND'
                              OR str = 'OR'
                              OR str = 'IN'
                              or str(1) ca |'|
                              or str(1) ca |(|.
          CLEAR ls_split.
          LOOP AT lt_split INTO ls_split.
            IF ls_split-str CA '~'.
              SPLIT ls_split-str AT '~' INTO ls_selfields-tabname
              ls_selfields-fieldname.
            ELSE.
              ls_selfields-fieldname = ls_split-str.
            ENDIF.

            APPEND ls_selfields TO lt_wherefields.
            CLEAR ls_selfields.
          ENDLOOP.
        ENDLOOP.

        CLEAR ls_selfields.
        SORT lt_keyfield BY fieldname.
        LOOP AT lt_wherefields INTO ls_selfields.
          READ TABLE lt_keyfield INTO DATA(ls_keyfield1)
           WITH KEY fieldname = ls_selfields-fieldname BINARY SEARCH.
          IF sy-subrc EQ 0 AND ls_selfields-fieldname NE 'MANDT'.   " exclude mandt as key field
            DATA(lv_key_field) = abap_true.
            CLEAR ls_keyfield1.
          ENDIF.
        ENDLOOP.


        IF lv_key_field NE abap_true .
          MESSAGE TEXT-t06 TYPE mc_e.  "Where clause should have atleast one key field
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR lv_key_field.

*"   get field name in sql query

* Get Selection Fields
    LOOP AT mt_sql INTO DATA(ls_sql).

      CONDENSE ls_sql-tdline.

      IF ls_sql-tdline CS 'FROM' OR
         ls_sql-tdline CS 'UPDATE'.
        IF sy-fdpos = 0.
          EXIT.
        ENDIF.
        ls_sql-tdline = ls_sql-tdline(sy-fdpos).
        lv_willexit = abap_true.
      ENDIF.

      FREE lt_split.
      SPLIT ls_sql-tdline AT space INTO TABLE lt_split.
      DELETE lt_split WHERE str IS INITIAL
                          OR str = 'SELECT'
                          OR str = 'SINGLE'
                          OR str = '*'
                          OR str = 'INSERT'
                          OR str = 'UPDATE'
                          OR str = 'MODIFY'
                          OR str = 'DELETE'.
      CLEAR ls_split.
      LOOP AT lt_split INTO ls_split.
        IF ls_split-str CA '~'.
          SPLIT ls_split-str AT '~' INTO ls_selfields-tabname
          ls_selfields-fieldname.
        ELSE.
          ls_selfields-fieldname = ls_split-str.
        ENDIF.

        APPEND ls_selfields TO lt_selfields.
        CLEAR ls_selfields.
      ENDLOOP.

      CHECK lv_willexit = abap_true.
      EXIT.
    ENDLOOP.

*"  Convert Alias to TableName

    CLEAR : ls_tablename , ls_selfields.
    LOOP AT lt_tablename  INTO ls_tablename WHERE alias IS NOT INITIAL.
      ls_selfields-tabname = ls_tablename-tabname.
      MODIFY lt_selfields FROM ls_selfields
      TRANSPORTING tabname
      WHERE tabname = ls_tablename-alias.
    ENDLOOP.


*"   Fill fieldcatalog

    IF lt_selfields[] IS INITIAL.
*" *   Select * case fieldcatalog
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = lv_tabname
        CHANGING
          ct_fieldcat            = mt_fcat
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
        MESSAGE TEXT-t07 TYPE mc_e.
      ENDIF.
    ELSE.
*"   Select fields case fieldcatalog

      CLEAR : ls_selfields , ls_fcat.
      LOOP AT lt_selfields INTO ls_selfields.
        READ TABLE mt_fcat INTO ls_fcat
        WITH KEY fieldname = ls_selfields-fieldname.
        CHECK sy-subrc <> 0.
        ls_fcat-fieldname = ls_selfields-fieldname.
        ls_fcat-ref_table = ls_selfields-tabname.
        ls_fcat-ref_field = ls_selfields-fieldname.
        APPEND ls_fcat TO mt_fcat.
        CLEAR ls_fcat.
      ENDLOOP.

*"   Fill ref_table value of row, if they initial

      LOOP AT mt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>)
        WHERE ref_table IS INITIAL.
        IF <fs_fcat> IS ASSIGNED.
          <fs_fcat>-ref_table = lv_tabname.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD create_dyntable.
*"  Create output table

    DATA: lt_newtable TYPE REF TO data,
          lv_subrc    TYPE sy-subrc.
    FIELD-SYMBOLS: <lt_dyntable> TYPE STANDARD TABLE.
    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog = mt_fcat
      IMPORTING
        ep_table        = lt_newtable.

    ASSIGN lt_newtable->* TO <lt_dyntable>.
    IF  <lt_dyntable> IS ASSIGNED.

      PERFORM ('CALL_SQL') IN PROGRAM (mv_program)
          TABLES <lt_dyntable> CHANGING lv_subrc  IF FOUND.
      IF lv_subrc IS NOT INITIAL.
        MESSAGE TEXT-t01 TYPE mc_e DISPLAY LIKE mc_w.
        LEAVE  LIST-PROCESSING.
      ELSEIF <lt_dyntable>[] IS INITIAL.
        MESSAGE TEXT-t02 TYPE mc_e DISPLAY LIKE mc_i.
        LEAVE  LIST-PROCESSING.
      ENDIF.
    ENDIF.

* ALV output
    TRY.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = DATA(lr_table)
          CHANGING
            t_table      = <lt_dyntable>.

        DATA(lr_funct) = lr_table->get_functions( ).
        lr_funct->set_all( ).
        lr_table->display( ).
      CATCH cx_salv_msg INTO DATA(lo_msg).
        MESSAGE lo_msg->get_text( ) TYPE lo_msg->msgty .

    ENDTRY.

  ENDMETHOD.
  METHOD free_object.

    IF cc_sql IS NOT INITIAL.
      cc_sql->free( ).   " free custom container
    ENDIF.

    IF sqltext IS NOT INITIAL.
      sqltext->free( ).  " free Editor screen
    ENDIF.

    IF cc_inst IS NOT INITIAL.
      cc_inst->free( ).
    ENDIF.
    IF inst_text IS NOT INITIAL.
      inst_text->free( ).
    ENDIF.

    cl_gui_cfw=>flush( ).

  ENDMETHOD.
  METHOD clear_editor_screen.

    IF sqltext IS BOUND.
      sqltext->delete_text( ).
    ENDIF.

  ENDMETHOD.

  METHOD main.

*" get Sql query from  Editor screen.
    get_sql_command( ).
*" check there is no CURD operation other than select.
    check_operation( ).
*" generate subroutine Pool.
    create_dynamic_sql(  ).
*" craete fieldcatalog.
    create_field_catalog( ).
*" create dynamic table and display.
    create_dyntable( ).

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSQL'.
  SET TITLEBAR 'ZSQL_EDITOR'.
*" Create Editor screen.
  lcl_sql_editor=>prepare_editor_screen( ).


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.

      lcl_sql_editor=>free_object( ).       " Free all objects.
      LEAVE TO SCREEN 0.

    WHEN 'CLEAR'.
      lcl_sql_editor=>clear_editor_screen( ). "clear screen.

    WHEN 'RUN'.

      DATA(o_sql) = NEW lcl_sql_editor(  ).   "Run command.
      o_sql->main( ).
      FREE o_sql.

  ENDCASE.

ENDMODULE.
