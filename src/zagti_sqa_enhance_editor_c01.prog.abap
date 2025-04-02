*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_ENHANCE_EDITOR_C01
*&---------------------------------------------------------------------*


CLASS lcl_sqa_enhance_editor DEFINITION DEFERRED.
* Save option
DATA: BEGIN OF ls_options,
        name          TYPE zagtt_sqa_query-text,
        visibility    TYPE zagtt_sqa_query-visibility,
        visibilitygrp TYPE usr02-class,
      END OF ls_options.
* Screen objects
DATA: ob_splitter TYPE REF TO cl_gui_splitter_container,

* Tabs objects (editor, ddic, alv)
      BEGIN OF ls_tab_active,
        ob_textedit   TYPE REF TO cl_gui_abapedit,
        ob_tree_ddic  TYPE REF TO cl_gui_column_tree,
        lt_node_ddic  TYPE treev_ntab,
        lt_item_ddic  TYPE TABLE OF mtreeitm,
        ob_alv_result TYPE REF TO cl_gui_alv_grid,
        lv_row_height TYPE i,
      END OF ls_tab_active,
      t_tabs LIKE TABLE OF ls_tab_active.

CONTROLS w_tabstrip TYPE TABSTRIP.

CLASS lcl_sqa_enhance_editor DEFINITION FINAL.
  PUBLIC SECTION.
* Global types
    TYPES : BEGIN OF lty_fieldlist,
              field     TYPE string,
              ref_table TYPE string,
              ref_field TYPE string,
            END OF lty_fieldlist,
            lt_fieldlist_table TYPE STANDARD TABLE OF lty_fieldlist.
    DATA : BEGIN OF s_customize,
             default_rows    TYPE i VALUE 100,
             paste_break(1)  TYPE c VALUE space, "abap_true to break
             techname(1)     TYPE c VALUE space, "abap_true for technical
             auth_object(20) TYPE c VALUE 'ZTOAD_AUTH',
             actvt_select    TYPE tactt-actvt VALUE '03',
             actvt_insert    TYPE tactt-actvt VALUE '01',
             actvt_update    TYPE tactt-actvt VALUE '02',
             actvt_delete    TYPE tactt-actvt VALUE '06',
             actvt_native    TYPE tactt-actvt VALUE '16',
             auth_select     TYPE string VALUE '*',
             auth_insert     TYPE string VALUE space, "'*',
             auth_update     TYPE string VALUE space, "'*',
             auth_delete     TYPE string VALUE space, "'*',
             auth_native(1)  TYPE c VALUE space, "abap_true,
           END OF s_customize.

** Screen objects
    DATA: ob_container            TYPE REF TO cl_gui_custom_container,
          ob_splitter_top         TYPE REF TO cl_gui_splitter_container,
          ob_splitter_top_right   TYPE REF TO cl_rsawb_splitter_for_toolbar,
          ob_container_top        TYPE REF TO cl_gui_container,
          ob_container_top_right  TYPE REF TO cl_gui_container,
          ob_container_repository TYPE REF TO cl_gui_container,
          ob_container_query      TYPE REF TO cl_gui_container,
          ob_container_ddic       TYPE REF TO cl_gui_container,
          ob_container_result     TYPE REF TO cl_gui_container,

* Repository data
          ob_tree_repository      TYPE REF TO cl_gui_simple_tree,
          BEGIN OF s_node_repository.
            INCLUDE TYPE treev_node. "mtreesnode.
            DATA :  text(100) TYPE c,
            edit(1)   TYPE c,
            queryid   TYPE zagtt_sqa_query-queryid,
          END OF s_node_repository,
          t_node_repository      LIKE TABLE OF s_node_repository,

* DDIC data
          w_dragdrop_handle_tree TYPE i,
* DDIC toolbar
          o_toolbar              TYPE REF TO cl_gui_toolbar,
* ZSPRO data
          t_node_zspro           LIKE ls_tab_active-lt_node_ddic,
          t_item_zspro           LIKE ls_tab_active-lt_item_ddic,

* Keep last loaded id
          w_last_loaded_query    TYPE zagtt_sqa_query-queryid,

* Count number of runs
          w_run                  TYPE i.

* Constants
    CONSTANTS : lc_ddic_col1            TYPE mtreeitm-item_name
                                        VALUE 'col1',       "#EC NOTEXT
                lc_ddic_col2            TYPE mtreeitm-item_name
                                        VALUE 'col2',       "#EC NOTEXT
                lc_visibility_all       TYPE zagtt_sqa_query-visibility VALUE '2',
                lc_visibility_shared    TYPE zagtt_sqa_query-visibility VALUE '1',
                lc_visibility_my        TYPE zagtt_sqa_query-visibility VALUE '0',
                lc_nodekey_repo_my      TYPE mtreesnode-node_key VALUE 'MY',
                lc_nodekey_repo_shared  TYPE mtreesnode-node_key
                                        VALUE 'SHARED',
                lc_nodekey_repo_history TYPE mtreesnode-node_key
                                        VALUE 'HISTO',
                lc_line_max             TYPE i VALUE 255,
                lc_msg_success          TYPE c VALUE 'S',
                lc_msg_error            TYPE c VALUE 'E',
                lc_msg_a                TYPE c VALUE 'A',
                lc_vers_active          TYPE as4local VALUE 'A',
                lc_ddic_dtelm           TYPE comptype VALUE 'E',
                lc_native_command       TYPE string VALUE 'NATIVE',
                lc_query_max_exec       TYPE i VALUE 1000,

                lc_xmlnode_root         TYPE string VALUE 'root', "#EC NOTEXT
                lc_xmlnode_file         TYPE string VALUE 'query', "#EC NOTEXT
                lc_xmlattr_visibility   TYPE string VALUE 'visibility', "#EC NOTEXT
                lc_xmlattr_text         TYPE string VALUE 'description'. "#EC NOTEXT



    METHODS : initialise_screen,  " Initialse editor screen
      query_process IMPORTING fw_display  TYPE c
                              fw_download TYPE c,
      options_load,
      screen_init_splitter,
      repo_init,
      ddic_toolbar_init,
      ddic_init,
      editor_init,
      result_init,
      screen_exit,
      repo_save_current_query,
      repo_fill,
      repo_focus_query IMPORTING fw_queryid TYPE zagtt_sqa_query-queryid,
      ddic_f4,
      ddic_find_in_tree,
      ddic_refresh_tree,
      ddic_get_field_from_node IMPORTING fw_node_key  TYPE tv_nodekey
                                         fw_relat_key TYPE tv_nodekey
                               CHANGING  fw_text      TYPE string,
      ddic_set_tree IMPORTING  fw_from TYPE string,
      editor_get_default_query CHANGING  ft_query TYPE STANDARD TABLE,
      editor_get_query IMPORTING fw_force_last TYPE c
                       CHANGING  fw_query      TYPE string,
      editor_paste IMPORTING fw_text TYPE string
                             fw_line TYPE i
                             fw_pos  TYPE i,
      query_load IMPORTING fw_queryid TYPE zagtt_sqa_query-queryid
                 CHANGING  ft_query   TYPE  STANDARD TABLE ,
      query_parse  IMPORTING fw_query     TYPE string
                   CHANGING  fw_select    TYPE string
                             fw_from      TYPE string
                             fw_where     TYPE string
                             fw_union     TYPE string
                             fw_rows      TYPE n
                             fw_noauth    TYPE c
                             fw_newsyntax TYPE c
                             fw_error     TYPE c,
      query_parse_noselect IMPORTING fw_query   TYPE string
                           CHANGING  fw_noauth  TYPE c
                                     fw_command TYPE string
                                     fw_table   TYPE string
                                     fw_param   TYPE string,
      repo_delete_history IMPORTING fw_node_key TYPE tv_nodekey
                          CHANGING  fw_subrc    TYPE i,
      tab_update_title IMPORTING fw_query TYPE string,
      leave_current_tab,
      query_generate IMPORTING fw_select    TYPE string
                               fw_from      TYPE string
                               fw_where     TYPE string
                               fw_display   TYPE c
                               fw_newsyntax TYPE c
                     CHANGING  fw_program   TYPE sy-repid
                               fw_rows      TYPE n
                               ft_fieldlist TYPE lt_fieldlist_table
                               fw_count     TYPE c,
      add_line_to_table IMPORTING fw_line  TYPE string
                        CHANGING  ft_table TYPE  STANDARD TABLE,
      query_generate_noselect IMPORTING fw_command TYPE string
                                        fw_table   TYPE string
                                        fw_param   TYPE string
                                        fw_display TYPE c
                              CHANGING  fw_program TYPE sy-repid,
      query_process_native IMPORTING fw_command TYPE string,
      result_display IMPORTING fo_result    TYPE REF TO data " Alv output
                               ft_fieldlist TYPE lt_fieldlist_table
                               fw_title     TYPE string,
      result_save_file IMPORTING fo_result TYPE REF TO data    " dowmload output in XLSX format
                                 ft_fields TYPE lt_fieldlist_table,
      repo_save_query,  " save query in database
      screen_init_listbox_0200,
      export_xml,
      import_xml,
      clear_screen,

* Handle F1 call on ABAP editor
      hnd_editor_f1
        FOR EVENT f1 OF cl_gui_abapedit,
* Handle Node double clic on ddic tree
      hnd_ddic_item_dblclick
                  FOR EVENT item_double_click OF cl_gui_column_tree
        IMPORTING node_key,
* Handle context menu display on repository tree
      hnd_repo_context_menu
      FOR EVENT node_context_menu_request
                  OF cl_gui_simple_tree
        IMPORTING menu,
* Handle context menu clic on repository tree
      hnd_repo_context_menu_sel
      FOR EVENT node_context_menu_select
                  OF cl_gui_simple_tree
        IMPORTING fcode,
* Handle Node double clic on repository tree
      hnd_repo_dblclick
                  FOR EVENT node_double_click OF cl_gui_simple_tree
        IMPORTING node_key,
* Handle toolbar display on ALV result
      hnd_result_toolbar
                  FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object,
* Handle toolbar clic on ALV result
      hnd_result_user_command
                  FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
* Handle DDIC tree drag
      hnd_ddic_drag
                  FOR EVENT on_drag OF cl_gui_column_tree
        IMPORTING node_key drag_drop_object,
* Handle editor drop
      hnd_editor_drop
                  FOR EVENT on_drop OF cl_gui_abapedit
        IMPORTING line pos dragdrop_object,
* Handle ddic toolbar clic
      hnd_ddic_toolbar_clic
                  FOR EVENT function_selected OF cl_gui_toolbar
        IMPORTING fcode.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_drag_object DEFINITION
*----------------------------------------------------------------------*
*       Class to store object on drag & drop from DDIC to sql editor
*----------------------------------------------------------------------*
CLASS lcl_drag_object DEFINITION FINAL.
  PUBLIC SECTION.
    DATA field TYPE string.
ENDCLASS."lcl_drag_object DEFINITION

CLASS lcl_sqa_enhance_editor IMPLEMENTATION .
  METHOD initialise_screen.
    IF ob_container IS INITIAL.
      options_load( ).
      screen_init_splitter( ).
      repo_init( ).
      ddic_toolbar_init( ).
      ddic_init( ).
      editor_init( ).
      result_init( ).
    ENDIF.
  ENDMETHOD.
  METHOD query_process.
    DATA : lw_query         TYPE string,
           lw_select        TYPE string,
           lw_from          TYPE string,
           lw_where         TYPE string,
           lw_union         TYPE string,
           lw_query2        TYPE string,
           lw_command       TYPE string,
           lw_rows(6)       TYPE n,
           lw_program       TYPE sy-repid,
           lo_result        TYPE REF TO data,
           lo_result2       TYPE REF TO data,
           lt_fieldlist     TYPE lt_fieldlist_table,
           lt_fieldlist2    TYPE lt_fieldlist_table,
           lw_count_only(1) TYPE c,
           lw_time          TYPE p LENGTH 8 DECIMALS 2,
           lw_time2         LIKE lw_time,
           lw_count         TYPE i,
           lw_count2        LIKE lw_count,
           lw_charnumb(12)  TYPE c,
           lw_msg           TYPE string,
           lw_noauth(1)     TYPE c,
           lw_newsyntax(1)  TYPE c,
           lw_answer(1)     TYPE c,
           lw_from_concat   LIKE lw_from,
           lw_error(1)      TYPE c.

    FIELD-SYMBOLS : <lft_data>  TYPE STANDARD TABLE,
                    <lft_data2> TYPE STANDARD TABLE.

* Get only usefull code for current query
    me->editor_get_query( EXPORTING fw_force_last = space
                          CHANGING  fw_query = lw_query ).

* Parse SELECT Query
    me->query_parse( EXPORTING fw_query = lw_query
                        CHANGING fw_select = lw_select
                                 fw_from = lw_from
                                 fw_where = lw_where
                                 fw_union = lw_union
                                 fw_rows = lw_rows
                                 fw_noauth = lw_noauth
                                 fw_newsyntax =  lw_newsyntax
                                 fw_error = lw_error ).
    IF lw_error NE space.
      MESSAGE 'Cannot parse the query'(m07) TYPE lc_msg_error.
    ENDIF.

* Not a select query
    IF lw_select IS INITIAL.
      MESSAGE 'Curd Operation is not Allowed'(m66) TYPE lc_msg_error.
*      me->query_parse_noselect( EXPORTING fw_query = lw_query
*                                   CHANGING fw_noauth = lw_noauth
*                                            fw_command = lw_command
*                                            fw_table = lw_from
*                                            fw_param = lw_where ).
*      IF lw_noauth NE space.
*        me->ddic_set_tree( EXPORTING fw_from = lw_from ).
*        RETURN.
*      ENDIF.
*
* For native sql command, execute it directly
*      IF lw_command = lc_native_command.
*        me->ddic_set_tree( lw_from ).
*        me->query_process_native( lw_where ).
*        RETURN.
*      ENDIF.
*
* For other no select command, generate program
*      IF w_run LT lc_query_max_exec.
*        me->query_generate_noselect( EXPORTING fw_command = lw_command
*                                               fw_table = lw_from
*                                               fw_param =  lw_where
*                                               fw_display = fw_display
*                                       CHANGING fw_program  = lw_program ).
*        w_run = w_run + 1.
*      ELSE.
*        MESSAGE 'No more run available. Please restart program'(m50)
*                TYPE lc_msg_error.
*      ENDIF.
*      IF fw_display IS INITIAL.
*        me->ddic_set_tree( lw_from ).
*        CONCATENATE 'Are you sure you want to do a'(m31) lw_command
*                    'on table'(m32) lw_from '?'(m33)
*                    INTO lw_msg SEPARATED BY space.
*        CALL FUNCTION 'POPUP_TO_CONFIRM'
*          EXPORTING
*            titlebar              = 'Warning : critical operation'(t04)
*            text_question         = lw_msg
*            default_button        = '2'
*            display_cancel_button = space
*          IMPORTING
*            answer                = lw_answer
*          EXCEPTIONS
*            text_not_found        = 1
*            OTHERS                = 2.
*        IF sy-subrc NE 0 OR lw_answer NE '1'.
*          RETURN.
*        ENDIF.
*      ENDIF.
*      lw_count_only = abap_true. "no result grid to display
    ELSEIF lw_noauth NE space.
      me->ddic_set_tree( lw_from ).
      RETURN.
    ELSEIF lw_from IS INITIAL.
      me->ddic_set_tree( lw_from ).
      MESSAGE 'Cannot parse the query'(m07) TYPE lc_msg_error.
    ELSE.
* Generate SELECT subroutine
      IF w_run LT lc_query_max_exec.
        me->query_generate( EXPORTING fw_select = lw_select
                                      fw_from = lw_from
                                      fw_where = lw_where
                                      fw_display = fw_display
                                      fw_newsyntax = lw_newsyntax
                             CHANGING fw_program = lw_program
                                      fw_rows = lw_rows
                                      ft_fieldlist = lt_fieldlist
                                      fw_count = lw_count_only ).
        IF lw_program IS INITIAL.
          me->ddic_set_tree( lw_from ).
          RETURN.
        ENDIF.
        w_run = w_run + 1.
      ELSE.
        MESSAGE 'No more run available. Please restart program'(m50)
                TYPE lc_msg_error.
      ENDIF.
    ENDIF.


* Call the generated subroutine
    IF NOT lw_program IS INITIAL.
      PERFORM run_sql IN PROGRAM (lw_program)
                      CHANGING lo_result lw_time lw_count.
      lw_from_concat = lw_from.
* For union, process second (and further) query
      WHILE NOT lw_union IS INITIAL.
* Parse Query
        lw_query2 = lw_union.
        me->query_parse( EXPORTING fw_query = lw_query2
                       CHANGING fw_select = lw_select
                                fw_from = lw_from
                                fw_where = lw_where
                                fw_union = lw_union
                                fw_rows = lw_rows
                                fw_noauth = lw_noauth
                                fw_newsyntax =  lw_newsyntax
                                fw_error = lw_error ).

        CONCATENATE lw_from_concat 'JOIN' lw_from INTO lw_from_concat.
        IF lw_noauth NE space.
          me->ddic_set_tree( lw_from_concat ).
          RETURN.
        ELSEIF lw_select IS INITIAL OR lw_from IS INITIAL
        OR lw_error = abap_true.
          me->ddic_set_tree( lw_from_concat ).
          MESSAGE 'Cannot parse the unioned query'(m08) TYPE lc_msg_error.
          EXIT. "exit while
        ENDIF.
* Generate subroutine
        IF w_run LT lc_query_max_exec.
          me->query_generate( EXPORTING fw_select = lw_select
                                        fw_from   = lw_from
                                        fw_where  = lw_where
                                        fw_display   = fw_display
                                        fw_newsyntax = lw_newsyntax
                             CHANGING fw_program = lw_program
                                      fw_rows = lw_rows
                                      ft_fieldlist = lt_fieldlist2
                                      fw_count = lw_count_only ).

          IF lw_program IS INITIAL.
            me->ddic_set_tree( lw_from_concat ).
            RETURN.
          ENDIF.
          w_run = w_run + 1.
        ELSE.
          MESSAGE 'No more run available. Please restart program'(m50)
                  TYPE lc_msg_error.
        ENDIF.
* Call the generated subroutine
        PERFORM run_sql IN PROGRAM (lw_program)
                        CHANGING lo_result2 lw_time2 lw_count2.

* Append lines of the further queries to the first query
        ASSIGN lo_result->* TO <lft_data>.
        ASSIGN lo_result2->* TO <lft_data2>.
        APPEND LINES OF <lft_data2> TO <lft_data>.
        REFRESH <lft_data2>.
        lw_time = lw_time + lw_time2.
        lw_count = lw_count + lw_count2.
      ENDWHILE.

      me->ddic_set_tree( lw_from_concat ).

* Display message
      lw_charnumb = lw_time.
      CONCATENATE 'Query executed in'(m09) lw_charnumb INTO lw_msg
                  SEPARATED BY space.
      lw_charnumb = lw_count.
      IF NOT lw_select IS INITIAL.
        CONCATENATE lw_msg 'seconds.'(m10)
                    lw_charnumb 'entries found'(m11)
                    INTO lw_msg SEPARATED BY space.
      ELSE.
        CONCATENATE lw_msg 'seconds.'(m10)
                    lw_charnumb 'entries affected'(m12)
                    INTO lw_msg SEPARATED BY space.
      ENDIF.
      CONDENSE lw_msg.
      MESSAGE lw_msg TYPE lc_msg_success.


* Display result except for count(*)
      IF lw_count_only IS INITIAL.
        IF fw_download = space.
          me->result_display( EXPORTING fo_result = lo_result
                                        ft_fieldlist = lt_fieldlist
                                        fw_title = lw_query ).
        ELSE.
          me->result_save_file( EXPORTING fo_result = lo_result
                                          ft_fields = lt_fieldlist ).
        ENDIF.
      ENDIF.

      me->repo_save_current_query(  ).
    ENDIF.
  ENDMETHOD.
  METHOD options_load.
    DATA : lw_options  TYPE usr05-parva,
           lw_rows(10) TYPE c.
    GET PARAMETER ID 'ZAGTT_SQA_QUERY' FIELD lw_options.    "#EC EXISTS
    IF sy-subrc = 0.
      SPLIT lw_options AT ';' INTO lw_rows
                                   s_customize-paste_break
                                   s_customize-techname
                                   lw_options. "dummy
      s_customize-default_rows = lw_rows.
    ENDIF.
  ENDMETHOD.
  METHOD screen_init_splitter.
* Create the custom container
    CREATE OBJECT ob_container
      EXPORTING
        container_name = 'CUSTCONT'.

* Insert splitter into this container
    CREATE OBJECT ob_splitter
      EXPORTING
        parent  = ob_container
        rows    = 2
        columns = 1.

* Get the first row of the main splitter
    CALL METHOD ob_splitter->get_container
      EXPORTING
        row       = 1
        column    = 1
      RECEIVING
        container = ob_container_top.

*  Spliter for the high part (first row)
    CREATE OBJECT ob_splitter_top
      EXPORTING
        parent  = ob_container_top
        rows    = 1
        columns = 3.

* Get the right part of the top part
    CALL METHOD ob_splitter_top->get_container
      EXPORTING
        row       = 1
        column    = 3
      RECEIVING      "container = ob_container_ddic.
        container = ob_container_top_right.

* Add a toolbar to the DDIC container
    CREATE OBJECT ob_splitter_top_right
      EXPORTING
        i_r_container = ob_container_top_right.

* Affect an object to each "cell" of the high sub splitter
    CALL METHOD ob_splitter_top->get_container
      EXPORTING
        row       = 1
        column    = 1
      RECEIVING
        container = ob_container_repository.

    CALL METHOD ob_splitter_top->get_container
      EXPORTING
        row       = 1
        column    = 2
      RECEIVING
        container = ob_container_query.

    CALL METHOD ob_splitter_top_right->get_controlcontainer
      RECEIVING
        e_r_container_control = ob_container_ddic.

    CALL METHOD ob_splitter->get_container
      EXPORTING
        row       = 2
        column    = 1
      RECEIVING
        container = ob_container_result.

* Initial repartition :
*   line 1 = 100% (code+repo+ddic)
*   line 2 = 0% (result)
*   line 1 col 1 & 3 = 20% (repo & ddic)
*   line 1 col 2 = 60% (code)
    CALL METHOD ob_splitter->set_row_height
      EXPORTING
        id     = 1
        height = 100.

    CALL METHOD ob_splitter_top->set_column_width
      EXPORTING
        id    = 1
        width = 20.
    CALL METHOD ob_splitter_top->set_column_width
      EXPORTING
        id    = 3
        width = 20.
  ENDMETHOD.
  METHOD repo_init.
    DATA: lt_event TYPE cntl_simple_events,
          ls_event TYPE cntl_simple_event.

* Create a tree control
    CREATE OBJECT ob_tree_repository
      EXPORTING
        parent              = ob_container_repository
        node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single
      EXCEPTIONS
        lifetime_error      = 1
        cntl_system_error   = 2
        create_error        = 3
        failed              = 4
        OTHERS              = 5.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Catch double clic to open query
    ls_event-eventid = cl_gui_simple_tree=>eventid_node_double_click.
    ls_event-appl_event = abap_true. " no PAI if event occurs
    APPEND ls_event TO lt_event.

* Catch context menu call
    ls_event-eventid = cl_gui_simple_tree=>eventid_node_context_menu_req.
    ls_event-appl_event = abap_true. " no PAI if event occurs
    APPEND ls_event TO lt_event.

    CALL METHOD ob_tree_repository->set_registered_events
      EXPORTING
        events                    = lt_event
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Assign event handlers in the application class to each desired event
    SET HANDLER me->hnd_repo_dblclick
        FOR ob_tree_repository.
    SET HANDLER me->hnd_repo_context_menu
        FOR ob_tree_repository.
    SET HANDLER me->hnd_repo_context_menu_sel
        FOR ob_tree_repository.

    me->repo_fill( ).
  ENDMETHOD.
  METHOD ddic_toolbar_init.
    DATA: lt_button TYPE ttb_button,
          ls_button LIKE LINE OF lt_button,
          lt_events TYPE cntl_simple_events,
          ls_events LIKE LINE OF lt_events.

*  Toolbar already created by class CL_RSAWB_SPLITTER_FOR_TOOLBAR
    o_toolbar = ob_splitter_top_right->get_toolbar( ).

* Add buttons to toolbar
    CLEAR ls_button.
    ls_button-function = 'REFRESH'.
    ls_button-icon = '@42@'.
    ls_button-quickinfo = 'Refresh DDIC tree'(m41).
    ls_button-text = 'Refresh'(m40).
    ls_button-butn_type = 0.
    APPEND ls_button TO lt_button.

    CLEAR ls_button.
    ls_button-function = 'FIND'.
    ls_button-icon = '@13@'.
    ls_button-quickinfo = 'Search in DDIC tree'(m43).
    ls_button-text = 'Find'(m42).
    ls_button-butn_type = 0.
    APPEND ls_button TO lt_button.

*    CLEAR ls_button.
*    ls_button-function = 'F4'.
*    ls_button-icon = '@6T@'.
*    ls_button-quickinfo = 'Display values of sel. field'(m54).
*    ls_button-text = 'Value list'(m55).
*    ls_button-butn_type = 0.
*    APPEND ls_button TO lt_button.

    CALL METHOD o_toolbar->add_button_group
      EXPORTING
        data_table = lt_button.

* Register events
    ls_events-eventid = cl_gui_toolbar=>m_id_function_selected.
    ls_events-appl_event = space.
    APPEND ls_events TO lt_events.
    CALL METHOD o_toolbar->set_registered_events
      EXPORTING
        events = lt_events.

    SET HANDLER  me->hnd_ddic_toolbar_clic FOR o_toolbar.
  ENDMETHOD.
  METHOD ddic_init.
    DATA : ls_header   TYPE treev_hhdr,
           ls_event    TYPE cntl_simple_event,
           lt_events   TYPE cntl_simple_events,
           lo_dragdrop TYPE REF TO cl_dragdrop,
           lw_mode     TYPE i.

    ls_header-heading = 'SAP Table/Fields'(t02).
    ls_header-width = 30.
    lw_mode = cl_gui_column_tree=>node_sel_mode_single.

    CREATE OBJECT ls_tab_active-ob_tree_ddic
      EXPORTING
        parent                      = ob_container_ddic
        node_selection_mode         = lw_mode
        item_selection              = abap_true
        hierarchy_column_name       = lc_ddic_col1
        hierarchy_header            = ls_header
      EXCEPTIONS
        cntl_system_error           = 1
        create_error                = 2
        failed                      = 3
        illegal_node_selection_mode = 4
        illegal_column_name         = 5
        lifetime_error              = 6.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Column2
    CALL METHOD ls_tab_active-ob_tree_ddic->add_column
      EXPORTING
        name                         = lc_ddic_col2
        width                        = 21
        header_text                  = 'Description'(t03)
      EXCEPTIONS
        column_exists                = 1
        illegal_column_name          = 2
        too_many_columns             = 3
        illegal_alignment            = 4
        different_column_types       = 5
        cntl_system_error            = 6
        failed                       = 7
        predecessor_column_not_found = 8.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Manage Item clic event to copy value in clipboard
    ls_event-eventid = cl_gui_column_tree=>eventid_item_double_click.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    CALL METHOD ls_tab_active-ob_tree_ddic->set_registered_events
      EXPORTING
        events                    = lt_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Manage Drag from DDIC editor
    CREATE OBJECT lo_dragdrop.
    CALL METHOD lo_dragdrop->add
      EXPORTING
        flavor     = 'EDIT_INSERT'
        dragsrc    = abap_true
        droptarget = space
        effect     = cl_dragdrop=>copy.
    CALL METHOD lo_dragdrop->get_handle
      IMPORTING
        handle = w_dragdrop_handle_tree.

    SET HANDLER me->hnd_ddic_item_dblclick FOR ls_tab_active-ob_tree_ddic.
    SET HANDLER me->hnd_ddic_drag FOR ls_tab_active-ob_tree_ddic.
*
** Calculate ZSPRO nodes to add at the bottom of the ddic tree
*  PERFORM ddic_add_tree_zspro IN PROGRAM (sy-repid) IF FOUND.

  ENDMETHOD.
  METHOD editor_init.
    DATA : lt_events     TYPE cntl_simple_events,
           ls_event      TYPE cntl_simple_event,
           lt_default    TYPE TABLE OF string,
           lw_queryid    TYPE zagtt_sqa_query-queryid,
           lo_dragrop    TYPE REF TO cl_dragdrop,
           lw_dummy_date TYPE timestamp.                    "#EC NEEDED

* For first tab, Get last query used
    IF t_tabs IS INITIAL.
      CONCATENATE sy-uname '#%' INTO lw_queryid.
* aedat is not used but added in select for compatibility reason
      SELECT queryid aedat
             INTO (lw_queryid, lw_dummy_date)
             FROM zagtt_sqa_query
             UP TO 1 ROWS
             WHERE queryid LIKE lw_queryid
             AND owner = sy-uname
             ORDER BY aedat DESCENDING.
      ENDSELECT.
      IF sy-subrc = 0.
        me->query_load( EXPORTING fw_queryid = lw_queryid
                           CHANGING ft_query = lt_default ).
*        PERFORM repo_focus_query USING lw_queryid.
        me->repo_focus_query( lw_queryid ).
      ENDIF.
    ENDIF.

* If no last query found, use default template
    IF lt_default IS INITIAL.
      me->editor_get_default_query( CHANGING ft_query = lt_default ).
    ENDIF.

* Create the sql editor
    CREATE OBJECT ls_tab_active-ob_textedit
      EXPORTING
        parent = ob_container_query.

* Register events

    SET HANDLER me->hnd_editor_f1 FOR ls_tab_active-ob_textedit.
    SET HANDLER me->hnd_editor_drop FOR ls_tab_active-ob_textedit.

    ls_event-eventid = cl_gui_textedit=>event_f1.
    APPEND ls_event TO lt_events.

    CALL METHOD ls_tab_active-ob_textedit->set_registered_events
      EXPORTING
        events                    = lt_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.
    IF sy-subrc <> 0.
      IF sy-msgno IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                DISPLAY LIKE lc_msg_error
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 .
      ENDIF.
    ENDIF.

    DATA lo_completer TYPE REF TO cl_abap_parser.
    CALL METHOD ls_tab_active-ob_textedit->('INIT_COMPLETER').
    CALL METHOD ls_tab_active-ob_textedit->('GET_COMPLETER')
      RECEIVING
        m_parser = lo_completer.
    SET HANDLER lo_completer->handle_completion_request FOR ls_tab_active-ob_textedit.
    SET HANDLER lo_completer->handle_insertion_request FOR ls_tab_active-ob_textedit.
    SET HANDLER lo_completer->handle_quickinfo_request FOR ls_tab_active-ob_textedit.
    ls_tab_active-ob_textedit->register_event_completion( ).
    ls_tab_active-ob_textedit->register_event_quick_info( ).
    ls_tab_active-ob_textedit->register_event_insert_pattern( ).


* Manage Drop on SQL editor
    CREATE OBJECT lo_dragrop.
    CALL METHOD lo_dragrop->add
      EXPORTING
        flavor     = 'EDIT_INSERT'
        dragsrc    = space
        droptarget = abap_true
        effect     = cl_dragdrop=>copy.
    CALL METHOD ls_tab_active-ob_textedit->set_dragdrop
      EXPORTING
        dragdrop = lo_dragrop.

* Set Default template
    CALL METHOD ls_tab_active-ob_textedit->set_text
      EXPORTING
        table  = lt_default
      EXCEPTIONS
        OTHERS = 0.

* Set focus
    CALL METHOD cl_gui_control=>set_focus
      EXPORTING
        control = ls_tab_active-ob_textedit
      EXCEPTIONS
        OTHERS  = 0.

    me->ddic_refresh_tree( ).
  ENDMETHOD.
  METHOD result_init.

* Create ALV
    CREATE OBJECT ls_tab_active-ob_alv_result
      EXPORTING
        i_parent = ob_container_result.

* Register event toolbar to add button
    SET HANDLER me->hnd_result_toolbar FOR ls_tab_active-ob_alv_result.
    SET HANDLER me->hnd_result_user_command FOR ls_tab_active-ob_alv_result.

  ENDMETHOD.
  METHOD screen_exit.

    DATA : lw_status    TYPE i,
           lw_answer(1) TYPE c,
           lw_size      TYPE i,
           lw_string    TYPE string.

* Check if grid is displayed
    CALL METHOD ob_splitter->get_row_height
      EXPORTING
        id     = 1
      IMPORTING
        result = lw_size.
    CALL METHOD cl_gui_cfw=>flush.

* If grid is displayed, BACK action is only to close the grid
    IF lw_size < 100.
      CALL METHOD ob_splitter->set_row_height
        EXPORTING
          id     = 1
          height = 100.
      RETURN.
    ENDIF.

* Check if textedit is modified
    CALL METHOD ls_tab_active-ob_textedit->get_textmodified_status
      IMPORTING
        status = lw_status.
    IF lw_status NE 0.
      CONCATENATE 'Current query is not saved. Do you want'(m22)
  'to exit without saving or save into history then exit ?'(m56)
                  INTO lw_string SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          text_question         = lw_string
          text_button_1         = 'Exit'(m23)
          icon_button_1         = '@2M@'
          text_button_2         = 'Save & exit'(m24)
          icon_button_2         = '@2L@'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lw_answer.
      IF lw_answer = '2'.
        me->repo_save_current_query( ).
      ENDIF.
    ENDIF.

    LEAVE TO SCREEN 0.
  ENDMETHOD.
  METHOD repo_save_current_query.

    DATA : lt_query         TYPE soli_tab,
           ls_query         LIKE LINE OF lt_query,
           lw_query_with_cr TYPE string,
           ls_ztoad         TYPE zagtt_sqa_query,
           lw_number(3)     TYPE n,
           lw_timestamp(14) TYPE c,
           lw_dummy(1)      TYPE c,                         "#EC NEEDED
           lw_query_last    TYPE string,
           lw_date(10)      TYPE c,
           lw_time(8)       TYPE c,
           lw_dummy_date    TYPE timestamp.                 "#EC NEEDED

* Get content of abap edit box
    CALL METHOD ls_tab_active-ob_textedit->get_text
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      MESSAGE 'Failed to get Editor text'(m67) TYPE lc_msg_a.
    ENDIF.

* Serialize query into a string
    CLEAR lw_query_with_cr.
    LOOP AT lt_query INTO ls_query.
      CONCATENATE lw_query_with_cr ls_query cl_abap_char_utilities=>cr_lf
                  INTO lw_query_with_cr.
    ENDLOOP.

* Define timestamp
    lw_timestamp(8) = sy-datum.
    lw_timestamp+8 = sy-uzeit.
    ls_ztoad-aedat = lw_timestamp.

* Search if query is same as last loaded
    SELECT SINGLE query INTO lw_query_last
           FROM zagtt_sqa_query
           WHERE queryid = w_last_loaded_query.
    IF sy-subrc = 0 AND lw_query_last = lw_query_with_cr.
      RETURN.
    ENDIF.

* Get usergroup
    SELECT SINGLE class INTO ls_ztoad-visibility_group
           FROM usr02
           WHERE bname = sy-uname.

    CLEAR lw_number.

* Get last query from history
    CONCATENATE sy-uname '#%' INTO ls_ztoad-queryid.
* aedat is not used but added in select for compatibility reason
    SELECT queryid aedat
           INTO (ls_ztoad-queryid, lw_dummy_date)
           FROM zagtt_sqa_query
           UP TO 1 ROWS
           WHERE queryid LIKE ls_ztoad-queryid
           AND owner = sy-uname
           ORDER BY aedat DESCENDING.
    ENDSELECT.
    IF sy-subrc = 0.
      SPLIT ls_ztoad-queryid AT '#' INTO lw_dummy lw_number.
    ENDIF.

    lw_number = lw_number + 1.

* For history query, guid = <sy-uname>#NN
    CONCATENATE sy-uname '#' lw_number INTO ls_ztoad-queryid.
    ls_ztoad-owner = sy-uname.
    ls_ztoad-visibility = lc_visibility_my.

* Define text for query as timestamp
    WRITE sy-datlo TO lw_date.
    WRITE sy-timlo TO lw_time.
    CONCATENATE lw_date lw_time INTO ls_ztoad-text SEPARATED BY space.

    ls_ztoad-query = lw_query_with_cr.
    MODIFY zagtt_sqa_query  FROM ls_ztoad.

    w_last_loaded_query = ls_ztoad-queryid.

* Reset the modified status
    ls_tab_active-ob_textedit->set_textmodified_status( ).

* Refresh repository
    me->repo_fill( ).

* Focus on new query
    me->repo_focus_query( EXPORTING fw_queryid = ls_ztoad-queryid ).
  ENDMETHOD.
  METHOD repo_fill.

    DATA : lw_usergroup TYPE usr02-class,
           BEGIN OF ls_query,
             queryid    TYPE zagtt_sqa_query-queryid,
             aedat      TYPE zagtt_sqa_query-aedat,
             visibility TYPE zagtt_sqa_query-visibility,
             text       TYPE zagtt_sqa_query-text,
             query      TYPE zagtt_sqa_query-query,
           END OF ls_query,
           lt_query_my     LIKE TABLE OF ls_query,
           lt_query_shared LIKE TABLE OF ls_query,
           lw_node_key(6)  TYPE n,
           lw_queryid      TYPE zagtt_sqa_query-queryid,
           lw_dummy(1)     TYPE c.                          "#EC NEEDED

* Get usergroup
    SELECT SINGLE class INTO lw_usergroup
           FROM usr02
           WHERE bname = sy-uname.

* Get all my queries
    SELECT queryid aedat visibility text query INTO TABLE lt_query_my
           FROM zagtt_sqa_query
           WHERE owner = sy-uname.

* Get all queries that i can use
    SELECT queryid aedat visibility text query INTO TABLE lt_query_shared
           FROM zagtt_sqa_query
           WHERE owner NE sy-uname
           AND ( visibility = lc_visibility_all
                 OR ( visibility = lc_visibility_shared
                      AND visibility_group = lw_usergroup )
               ).
    REFRESH t_node_repository.

    CALL METHOD ob_tree_repository->delete_all_nodes.

    CLEAR s_node_repository.
    s_node_repository-node_key = lc_nodekey_repo_my.
    s_node_repository-isfolder = abap_true.
    s_node_repository-text = 'My queries'(m16).
    APPEND s_node_repository TO t_node_repository.

    CLEAR lw_node_key.
    CONCATENATE sy-uname '+++' INTO lw_queryid.
    LOOP AT lt_query_my INTO ls_query WHERE queryid NP lw_queryid.
      lw_node_key = lw_node_key + 1.
      CLEAR s_node_repository.
      s_node_repository-node_key = lw_node_key.
      s_node_repository-relatkey = lc_nodekey_repo_my.
      s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
      IF ls_query-visibility = lc_visibility_my.
        s_node_repository-n_image = s_node_repository-exp_image = '@LC@'.
      ELSE.
        s_node_repository-n_image = s_node_repository-exp_image = '@L9@'.
      ENDIF.
      s_node_repository-text = ls_query-text.
      s_node_repository-queryid = ls_query-queryid.
      s_node_repository-edit = abap_true.
      APPEND s_node_repository TO t_node_repository.
    ENDLOOP.

    CLEAR s_node_repository.
    s_node_repository-node_key = lc_nodekey_repo_shared.
    s_node_repository-isfolder = abap_true.
    s_node_repository-text = 'Shared queries'(m17).
    APPEND s_node_repository TO t_node_repository.

    LOOP AT lt_query_shared INTO ls_query.
      lw_node_key = lw_node_key + 1.
      CLEAR s_node_repository.
      s_node_repository-node_key = lw_node_key.
      s_node_repository-relatkey = lc_nodekey_repo_shared.
      s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
      s_node_repository-n_image = s_node_repository-exp_image = '@L9@'.
      s_node_repository-text = ls_query-text.
      s_node_repository-queryid = ls_query-queryid.
      s_node_repository-edit = space.
      APPEND s_node_repository TO t_node_repository.
    ENDLOOP.

* Add history node
    CLEAR s_node_repository.
    s_node_repository-node_key = lc_nodekey_repo_history.
    s_node_repository-isfolder = abap_true.
    s_node_repository-text = 'History'(m18).
    APPEND s_node_repository TO t_node_repository.

    DELETE lt_query_my WHERE queryid NP lw_queryid.
    SORT lt_query_my BY aedat DESCENDING.
    LOOP AT lt_query_my INTO ls_query.
      lw_node_key = lw_node_key + 1.
      CLEAR s_node_repository.
      s_node_repository-node_key = lw_node_key.
      s_node_repository-relatkey = lc_nodekey_repo_history.
      s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
      s_node_repository-n_image = s_node_repository-exp_image = '@LC@'.
      s_node_repository-text = ls_query-text.
      s_node_repository-queryid = ls_query-queryid.
      s_node_repository-edit = abap_true.
      IF ls_query-query(1) = '*'.
        SPLIT ls_query-query+1 AT cl_abap_char_utilities=>cr_lf
              INTO ls_query-query lw_dummy.
        CONCATENATE s_node_repository-text ':' ls_query-query
                    INTO s_node_repository-text SEPARATED BY space.
      ENDIF.
      APPEND s_node_repository TO t_node_repository.
    ENDLOOP.

    CALL METHOD ob_tree_repository->add_nodes
      EXPORTING
        table_structure_name           = 'MTREESNODE'
        node_table                     = t_node_repository
      EXCEPTIONS
        failed                         = 1
        error_in_node_table            = 2
        dp_error                       = 3
        table_structure_name_not_found = 4
        OTHERS                         = 5.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

* Exand all root nodes (my, shared, history)
    CALL METHOD ob_tree_repository->expand_root_nodes.
  ENDMETHOD.
  METHOD repo_focus_query.
    READ TABLE t_node_repository INTO s_node_repository
             WITH KEY queryid = fw_queryid.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

    CALL METHOD ob_tree_repository->set_selected_node
      EXPORTING
        node_key = s_node_repository-node_key.

  ENDMETHOD.

  METHOD ddic_f4.
    DATA : lw_table      TYPE dfies-tabname,
           lw_field      TYPE dfies-fieldname,
           lt_val        TYPE TABLE OF ddshretval,
           ls_val        LIKE LINE OF lt_val,
           lw_nodekey    TYPE tv_nodekey,
           lw_item       TYPE tv_itmname,                   "#EC NEEDED
           ls_node       LIKE LINE OF ls_tab_active-lt_node_ddic,
           ls_item       LIKE LINE OF ls_tab_active-lt_item_ddic,
           lw_line_start TYPE i,
           lw_pos_start  TYPE i,
           lw_line_end   TYPE i,
           lw_pos_end    TYPE i,
           lw_val        TYPE string,
           lw_dummy      TYPE c.                            "#EC NEEDED

* Get selection in ddic tree
    CALL METHOD ls_tab_active-ob_tree_ddic->get_selected_node "line selected
      IMPORTING
        node_key = lw_nodekey.
    IF lw_nodekey IS INITIAL.
      CALL METHOD ls_tab_active-ob_tree_ddic->get_selected_item "item selected
        IMPORTING
          node_key  = lw_nodekey
          item_name = lw_item.
    ENDIF.
    IF lw_nodekey IS INITIAL.
      RETURN.
    ENDIF.

* Check selection is a field
    READ TABLE ls_tab_active-lt_node_ddic INTO ls_node
               WITH KEY node_key = lw_nodekey.
    IF sy-subrc NE 0 OR ls_node-isfolder = abap_true.
      RETURN.
    ENDIF.

* Get field name
    READ TABLE ls_tab_active-lt_item_ddic INTO ls_item
               WITH KEY node_key = lw_nodekey
                        item_name = lc_ddic_col1.
    lw_field = ls_item-text.

* Get table name
    READ TABLE ls_tab_active-lt_item_ddic INTO ls_item
               WITH KEY node_key = ls_node-relatkey
                        item_name = lc_ddic_col1.
    SPLIT ls_item-text AT ' AS ' INTO lw_table lw_dummy.

* Display standard value-list
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
      EXPORTING
        fieldname  = lw_field
        tabname    = lw_table
      TABLES
        return_tab = lt_val
      EXCEPTIONS
        OTHERS     = 1.

    IF sy-subrc = 0.
      READ TABLE lt_val INTO ls_val INDEX 1.
      CONCATENATE '''' ls_val-fieldval '''' INTO lw_val.
      CONCATENATE space lw_val INTO lw_val RESPECTING BLANKS.

* Get current cursor position/selection in editor
      CALL METHOD ls_tab_active-ob_textedit->get_selection_pos
        IMPORTING
          from_line = lw_line_start
          from_pos  = lw_pos_start
          to_line   = lw_line_end
          to_pos    = lw_pos_end
        EXCEPTIONS
          OTHERS    = 4.
      IF sy-subrc NE 0.
        MESSAGE 'Cannot get cursor position'(m35) TYPE lc_msg_error.
      ENDIF.

*   If text is selected/highlighted, delete it
      IF lw_line_start NE lw_line_end
      OR lw_pos_start NE lw_pos_end.
        CALL METHOD ls_tab_active-ob_textedit->delete_text
          EXPORTING
            from_line = lw_line_start
            from_pos  = lw_pos_start
            to_line   = lw_line_end
            to_pos    = lw_pos_end.
      ENDIF.

      me->editor_paste( EXPORTING fw_text  = lw_val
                                    fw_line  = lw_line_start
                                      fw_pos = lw_pos_start ).

    ENDIF.

  ENDMETHOD.
  METHOD ddic_find_in_tree.
    DATA : ls_sval        TYPE sval,
           lt_sval        LIKE TABLE OF ls_sval,
           lw_returncode  TYPE c,
           lw_search      TYPE string,
           lt_search      LIKE TABLE OF lw_search,
           ls_item_ddic   LIKE LINE OF ls_tab_active-lt_item_ddic,
           lw_search_term TYPE string,
           lw_search_line TYPE i,
           lw_rest        TYPE i,
           lw_node_key    TYPE tv_nodekey,
           lt_nodekey     TYPE TABLE OF tv_nodekey.

* Build search table
    REFRESH lt_search.
    LOOP AT ls_tab_active-lt_item_ddic INTO ls_item_ddic.
      lw_search = ls_item_ddic-text.
      APPEND lw_search TO lt_search.
      APPEND ls_item_ddic-node_key TO lt_nodekey.
    ENDLOOP.

* Ask for selection search
    ls_sval-tabname = 'RSDXX'.
    ls_sval-fieldname = 'FINDSTR'.
    ls_sval-value = space.
    APPEND ls_sval TO lt_sval.
    DO.
      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
          popup_title     = space
        IMPORTING
          returncode      = lw_returncode
        TABLES
          fields          = lt_sval
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.
      IF sy-subrc NE 0 OR lw_returncode NE space.
        EXIT. "exit do
      ENDIF.
      READ TABLE lt_sval INTO ls_sval INDEX 1.
      IF ls_sval-value = space.
        EXIT. "exit do
      ENDIF.

* For new search, start from line 1
      IF lw_search_term NE ls_sval-value.
        lw_search_term = ls_sval-value.
        lw_search_line = 1.
* For next result of same search, start from next line
      ELSE.
        lw_rest = lw_search_line MOD 2.
        lw_search_line = lw_search_line + 1 + lw_rest.
      ENDIF.

      FIND FIRST OCCURRENCE OF ls_sval-value IN TABLE lt_search
           FROM lw_search_line
           IN CHARACTER MODE IGNORING CASE
           MATCH LINE lw_search_line.

* Search string &1 not found
      IF sy-subrc NE 0 AND lw_search_line = 1.
        MESSAGE s065(0k) WITH lw_search_term DISPLAY LIKE lc_msg_error.
        CLEAR lw_search_line.
        CLEAR lw_search_term.

* Last selected entry reached
      ELSEIF sy-subrc NE 0.
        MESSAGE s066(0k) DISPLAY LIKE lc_msg_error.
        CLEAR lw_search_line.
        CLEAR lw_search_term.

* Found
      ELSE.
        MESSAGE 'String found'(m04) TYPE lc_msg_success.
        READ TABLE lt_nodekey INTO lw_node_key INDEX lw_search_line.
        CALL METHOD ls_tab_active-ob_tree_ddic->set_selected_node
          EXPORTING
            node_key = lw_node_key.
        CALL METHOD ls_tab_active-ob_tree_ddic->ensure_visible
          EXPORTING
            node_key = lw_node_key.
      ENDIF.

    ENDDO.
  ENDMETHOD.
  METHOD ddic_refresh_tree.
    DATA : lw_query        TYPE string,
           lw_query2       TYPE string,
           lw_select       TYPE string,
           lw_from         TYPE string,
           lw_from2        TYPE string,
           lw_where        TYPE string,
           lw_union        TYPE string,
           lw_rows(6)      TYPE n,
           lw_noauth(1)    TYPE c,
           lw_newsyntax(1) TYPE c,
           lw_error(1)     TYPE c.

* Get only usefull code for current query
    me->editor_get_query( EXPORTING fw_force_last = space
                          CHANGING fw_query = lw_query ).

* Parse Query
    me->query_parse( EXPORTING fw_query = lw_query
                     CHANGING  fw_select = lw_select
                               fw_from = lw_from
                               fw_where = lw_where
                               fw_union = lw_union
                               fw_rows = lw_rows
                               fw_noauth = lw_noauth
                               fw_newsyntax = lw_newsyntax
                               fw_error = lw_error ).

    IF lw_noauth NE space OR lw_error NE space.
      RETURN.
    ELSEIF lw_select IS INITIAL.
      me->query_parse_noselect( EXPORTING fw_query = lw_query
                                   CHANGING fw_noauth = lw_noauth
                                            fw_command =  lw_select
                                            fw_table =  lw_from
                                            fw_param = lw_where ).
      IF lw_noauth NE space OR lw_select = lc_native_command.
        RETURN.
      ENDIF.
    ENDIF.
* Manage unioned queries
    WHILE NOT lw_union IS INITIAL.
* Parse Query
      lw_query2 = lw_union.
      me->query_parse( EXPORTING fw_query = lw_query2
                       CHANGING  fw_select =  lw_select
                                 fw_from =    lw_from2
                                 fw_where = lw_where
                                 fw_union =  lw_union
                                 fw_rows = lw_rows
                                 fw_noauth = lw_noauth
                                 fw_newsyntax =  lw_newsyntax
                                 fw_error = lw_error ).
      IF NOT lw_from2 IS INITIAL.
        CONCATENATE lw_from 'JOIN' lw_from2
                    INTO lw_from SEPARATED BY space.
      ENDIF.
      IF lw_noauth NE space OR lw_error NE space.
        RETURN.
      ENDIF.
    ENDWHILE.

    me->tab_update_title( EXPORTING fw_query = lw_query ).

* Refresh ddic tree with list of table/fields of the actual query
    me->ddic_set_tree( EXPORTING fw_from = lw_from ).

  ENDMETHOD.
  METHOD ddic_get_field_from_node.
    DATA : ls_item        LIKE LINE OF ls_tab_active-lt_item_ddic,
           ls_item_parent LIKE LINE OF ls_tab_active-lt_item_ddic,
           lw_table       TYPE string,
           lw_alias       TYPE string.

* Get field name
    READ TABLE ls_tab_active-lt_item_ddic INTO ls_item
               WITH KEY node_key = fw_node_key
                        item_name = lc_ddic_col1.

* Get table name
    READ TABLE ls_tab_active-lt_item_ddic INTO ls_item_parent
               WITH KEY node_key = fw_relat_key
                        item_name = lc_ddic_col1.

* Search for alias
    SPLIT ls_item_parent-text AT ' AS ' INTO lw_table lw_alias.
    IF NOT lw_alias IS INITIAL.
      lw_table = lw_alias.
    ENDIF.

* Build tablename~fieldname
    CONCATENATE lw_table '~' ls_item-text INTO fw_text.
    CONCATENATE space fw_text space INTO fw_text RESPECTING BLANKS.
  ENDMETHOD.
  METHOD ddic_set_tree.
    DATA : lw_from   TYPE string,
           lt_split  TYPE TABLE OF string,
           lw_string TYPE string,
           lw_tabix  TYPE i,
           BEGIN OF ls_table_list,
             table(30),
             alias(30),
           END OF ls_table_list,
           lt_table_list     LIKE TABLE OF ls_table_list,
           lw_node_number(6) TYPE n,
           ls_node           LIKE LINE OF ls_tab_active-lt_node_ddic,
           ls_item           LIKE LINE OF ls_tab_active-lt_item_ddic,
           lw_parent_node    LIKE ls_node-node_key,
           BEGIN OF ls_ddic_fields,
             tabname   TYPE dd03l-tabname,
             fieldname TYPE dd03l-fieldname,
             position  TYPE dd03l-position,
             keyflag   TYPE dd03l-keyflag,
             ddtext1   TYPE dd03t-ddtext,
             ddtext2   TYPE dd04t-ddtext,
           END OF ls_ddic_fields,
           lt_ddic_fields LIKE TABLE OF ls_ddic_fields.

    CONCATENATE 'FROM' fw_from INTO lw_from SEPARATED BY space.

    TRANSLATE lw_from TO UPPER CASE.

    SPLIT lw_from AT space INTO TABLE lt_split.
    LOOP AT lt_split INTO lw_string.
      lw_tabix = sy-tabix + 1.
      CHECK sy-tabix = 1 OR lw_string = 'JOIN'.
* Read next line (table name)
      READ TABLE lt_split INTO lw_string INDEX lw_tabix.
      CHECK sy-subrc = 0.

      CLEAR ls_table_list.
      ls_table_list-table = lw_string.

      lw_tabix = lw_tabix + 1.
* Read next line (search alias)
      READ TABLE lt_split INTO lw_string INDEX lw_tabix.
      IF sy-subrc = 0 AND lw_string = 'AS'.
        lw_tabix = lw_tabix + 1.
        READ TABLE lt_split INTO lw_string INDEX lw_tabix.
        IF sy-subrc = 0.
          ls_table_list-alias = lw_string.
        ENDIF.
      ENDIF.
      APPEND ls_table_list TO lt_table_list.
    ENDLOOP.

* Get list of fields for selected tables
    IF NOT lt_table_list IS INITIAL.
      SELECT dd03l~tabname dd03l~fieldname dd03l~position
             dd03l~keyflag dd03t~ddtext dd04t~ddtext
             INTO TABLE lt_ddic_fields
             FROM dd03l
             LEFT OUTER JOIN dd03t
             ON dd03l~tabname = dd03t~tabname
             AND dd03l~fieldname = dd03t~fieldname
             AND dd03l~as4local = dd03t~as4local
             AND dd03t~ddlanguage = sy-langu
             LEFT OUTER JOIN dd04t
             ON dd03l~rollname = dd04t~rollname
             AND dd03l~as4local = dd04t~as4local
             AND dd04t~ddlanguage = sy-langu
             FOR ALL ENTRIES IN lt_table_list
             WHERE dd03l~tabname = lt_table_list-table
             AND dd03l~as4local = lc_vers_active
             AND dd03l~as4vers = space
             AND ( dd03l~comptype = lc_ddic_dtelm
             OR    dd03l~comptype = space ).
      SORT lt_ddic_fields BY tabname keyflag DESCENDING position.
      DELETE ADJACENT DUPLICATES FROM lt_ddic_fields
                                 COMPARING tabname fieldname.
    ENDIF.

* Build Node & Item tree
    REFRESH : ls_tab_active-lt_node_ddic,
              ls_tab_active-lt_item_ddic.
    lw_node_number = 0.
    LOOP AT lt_table_list INTO ls_table_list.
* Check table exists (has at least one field)
      READ TABLE lt_ddic_fields TRANSPORTING NO FIELDS
                 WITH KEY tabname = ls_table_list-table.
      IF sy-subrc NE 0.
        DELETE lt_table_list.
        CONTINUE.
      ENDIF.

      lw_node_number = lw_node_number + 1.
      CLEAR ls_node.
      ls_node-node_key = lw_node_number.
      ls_node-isfolder = abap_true.
      ls_node-n_image = '@PO@'.
      ls_node-exp_image = '@PO@'.
      ls_node-expander = abap_true.
      APPEND ls_node TO ls_tab_active-lt_node_ddic.

      CLEAR ls_item.
      ls_item-node_key = lw_node_number.
      ls_item-class = cl_gui_column_tree=>item_class_text.
      ls_item-item_name = lc_ddic_col1.
      IF ls_table_list-alias IS INITIAL.
        ls_item-text = ls_table_list-table.
      ELSE.
        CONCATENATE ls_table_list-table 'AS' ls_table_list-alias
                     INTO ls_item-text SEPARATED BY space.
      ENDIF.
      APPEND ls_item TO ls_tab_active-lt_item_ddic.
      ls_item-item_name = lc_ddic_col2.
      SELECT SINGLE ddtext INTO ls_item-text
             FROM dd02t
             WHERE tabname = ls_table_list-table
             AND ddlanguage = sy-langu
             AND as4local = lc_vers_active
             AND as4vers = space.
      IF sy-subrc NE 0.
        ls_item-text = ls_table_list-table.
      ENDIF.
      APPEND ls_item TO ls_tab_active-lt_item_ddic.

* Display list of fields
      lw_parent_node = ls_node-node_key.
      LOOP AT lt_ddic_fields INTO ls_ddic_fields
              WHERE tabname = ls_table_list-table.
        CLEAR ls_node.
        lw_node_number = lw_node_number + 1.
        ls_node-node_key = lw_node_number.
        ls_node-relatkey = lw_parent_node.
        ls_node-relatship = cl_gui_column_tree=>relat_last_child.
        IF ls_ddic_fields-keyflag = space.
          ls_node-n_image = '@3W@'.
          ls_node-exp_image = '@3W@'.
        ELSE.
          ls_node-n_image = '@3V@'.
          ls_node-exp_image = '@3V@'.
        ENDIF.
        ls_node-dragdropid = w_dragdrop_handle_tree.
        APPEND ls_node TO ls_tab_active-lt_node_ddic.

        CLEAR ls_item.
        ls_item-node_key = lw_node_number.
        ls_item-class = cl_gui_column_tree=>item_class_text.
        ls_item-item_name = lc_ddic_col1.
        ls_item-text = ls_ddic_fields-fieldname.
        APPEND ls_item TO ls_tab_active-lt_item_ddic.
        ls_item-item_name = lc_ddic_col2.
        IF NOT ls_ddic_fields-ddtext1 IS INITIAL.
          ls_item-text = ls_ddic_fields-ddtext1.
        ELSE.
          ls_item-text = ls_ddic_fields-ddtext2.
        ENDIF.
        APPEND ls_item TO ls_tab_active-lt_item_ddic.
      ENDLOOP.
    ENDLOOP.

* Add User defined tree from ZSPRO (if relevant)
    IF NOT t_node_zspro IS INITIAL.
      APPEND LINES OF t_node_zspro TO ls_tab_active-lt_node_ddic.
      APPEND LINES OF t_item_zspro TO ls_tab_active-lt_item_ddic.
    ENDIF.

    CALL METHOD ls_tab_active-ob_tree_ddic->delete_all_nodes.

    CALL METHOD ls_tab_active-ob_tree_ddic->add_nodes_and_items
      EXPORTING
        node_table                     = ls_tab_active-lt_node_ddic
        item_table                     = ls_tab_active-lt_item_ddic
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 3
        error_in_tables                = 4
        dp_error                       = 5
        table_structure_name_not_found = 6.
    IF sy-subrc <> 0.
      MESSAGE a000(tree_control_msg).
    ENDIF.

    DESCRIBE TABLE lt_table_list LINES lw_tabix.

* If no table found, display message
    IF lw_tabix = 0.
      MESSAGE 'No valid table found'(m15) TYPE lc_msg_success
              DISPLAY LIKE lc_msg_error.
* If 1 table found, expand it
    ELSEIF lw_tabix = 1.
      ls_tab_active-ob_tree_ddic->expand_root_nodes( ).
    ENDIF.
  ENDMETHOD.
  METHOD  editor_get_default_query .
    DATA lw_string TYPE string.

    APPEND '* Type here your query title' TO ft_query.      "#EC NOTEXT
    APPEND '' TO ft_query.
    APPEND 'SELECT *' TO ft_query.                          "#EC NOTEXT
    APPEND 'FROM <table_name>' TO ft_query.                 "#EC NOTEXT

    IF s_customize-default_rows NE 0.
      lw_string = s_customize-default_rows.
      CONDENSE lw_string NO-GAPS.
      CONCATENATE 'UP TO'
                  lw_string
                  'ROWS'
                  INTO lw_string SEPARATED BY space.
      APPEND lw_string TO ft_query.                         "#EC NOTEXT
    ENDIF.

    APPEND 'WHERE <conditions>' TO ft_query.                "#EC NOTEXT
    APPEND '.' TO ft_query.                                 "#EC NOTEXT

  ENDMETHOD.
  METHOD editor_get_query.
    DATA : lt_query         TYPE soli_tab,
           ls_query         LIKE LINE OF lt_query,
           ls_find          TYPE match_result,
           lt_find          TYPE match_result_tab,
           lt_find_sub      TYPE match_result_tab,
           lw_lines         TYPE i,
           lw_cursor_line   TYPE i,
           lw_cursor_pos    TYPE i,
           lw_delto_line    TYPE i,
           lw_delto_pos     TYPE i,
           lw_cursor_offset TYPE i,
           lw_last          TYPE c.

    CLEAR fw_query.

* Get selected content
    CALL METHOD ls_tab_active-ob_textedit->get_selected_text_as_table
      IMPORTING
        table = lt_query[].

* if no selected content, get complete content of abap edit box
    IF lt_query[] IS INITIAL.
      CALL METHOD ls_tab_active-ob_textedit->get_text
        IMPORTING
          table  = lt_query[]
        EXCEPTIONS
          OTHERS = 1.
      IF sy-subrc <> 0.
        MESSAGE 'Failed to get Editor text'(m67) TYPE lc_msg_a.
      ELSEIF lt_query IS INITIAL.
        MESSAGE 'Please Write Query to get the output'(m69) TYPE lc_msg_error.
      ENDIF.
    ENDIF.


* Remove * comment
    LOOP AT lt_query INTO ls_query WHERE line(1) = '*'.
      CLEAR ls_query-line.
      MODIFY lt_query FROM ls_query.
    ENDLOOP.

* Remove " comment
    LOOP AT lt_query INTO ls_query WHERE line CS '"'.
*    condense ls_query-line.
      FIND ALL OCCURRENCES OF '"' IN ls_query-line RESULTS lt_find.
      IF sy-subrc NE 0. "may not occurs
        CONTINUE.
      ENDIF.
      LOOP AT lt_find INTO ls_find.
        IF ls_find-offset GT 0.
* Search open '
          FIND ALL OCCURRENCES OF '''' IN ls_query-line(ls_find-offset)
               RESULTS lt_find_sub.
          IF sy-subrc = 0.
            DESCRIBE TABLE lt_find_sub LINES lw_lines.
            lw_lines = lw_lines MOD 2.
            IF lw_lines = 1.
              CONTINUE.
            ENDIF.
          ENDIF.
          ls_query-line = ls_query-line(ls_find-offset).
          EXIT. "exit loop
        ELSE.
          CLEAR ls_query-line.
          EXIT. "exit loop
        ENDIF.
      ENDLOOP.
      MODIFY lt_query FROM ls_query.
    ENDLOOP.

* Find active query
    CALL METHOD ls_tab_active-ob_textedit->get_selection_pos
      IMPORTING
        from_line = lw_cursor_line
        from_pos  = lw_cursor_pos.
    lw_cursor_offset = lw_cursor_pos - 1.

    FIND ALL OCCURRENCES OF '.' IN TABLE lt_query RESULTS lt_find.
    CLEAR : lw_delto_line,
            lw_delto_pos,
            lw_last.
    LOOP AT lt_find INTO ls_find.
      AT LAST.
        lw_last = abap_true.
      ENDAT.
* Search for open '
      IF ls_find-offset GT 0.
        READ TABLE lt_query INTO ls_query INDEX ls_find-line.
        FIND ALL OCCURRENCES OF '''' IN ls_query(ls_find-offset)
             RESULTS lt_find_sub.
        DESCRIBE TABLE lt_find_sub LINES lw_lines.
        lw_lines = lw_lines MOD 2.
* If open ' found, ignore the dot
        IF lw_lines = 1.
          CONTINUE.
        ENDIF.
      ENDIF.

* Active Query
      IF ls_find-line GT lw_cursor_line
      OR ( ls_find-line = lw_cursor_line
           AND ls_find-offset GE lw_cursor_offset )
      OR ( lw_last = abap_true AND fw_force_last = abap_true ).
* Delete all query after query active
        ls_find-line = ls_find-line + 1.
        DELETE lt_query FROM ls_find-line.
        ls_find-line = ls_find-line - 1.
* Do not keep the . for active query
        IF ls_find-offset = 0.
          DELETE lt_query FROM ls_find-line.
        ELSE.
          ls_query-line = ls_query-line(ls_find-offset).
          MODIFY lt_query FROM ls_query INDEX ls_find-line.
        ENDIF.
        EXIT.
* Query before active
      ELSE.
        lw_delto_line = ls_find-line.
        lw_delto_pos = ls_find-offset + 1.
      ENDIF.
    ENDLOOP.

* Delete all query before query active
    IF NOT lw_delto_line IS INITIAL.
      IF lw_delto_line GT 1.
        lw_delto_line = lw_delto_line - 1.
        DELETE lt_query FROM 1 TO lw_delto_line.
      ENDIF.
      READ TABLE lt_query INTO ls_query INDEX 1.
      ls_query-line(lw_delto_pos) = ''.
      MODIFY lt_query FROM ls_query INDEX 1.
    ENDIF.

* Delete empty lines
    DELETE lt_query WHERE line CO ' .'.

* Build query string & Remove unnessential spaces
    LOOP AT lt_query INTO ls_query.
      CONDENSE ls_query-line.
      SHIFT ls_query-line LEFT DELETING LEADING space.
      CONCATENATE fw_query ls_query-line INTO fw_query SEPARATED BY space.
    ENDLOOP.
    IF NOT fw_query IS INITIAL.
      fw_query = fw_query+1.
    ENDIF.

* If no query selected, try to get the last one
    IF lt_query IS INITIAL AND fw_force_last = space.
      me->editor_get_query( EXPORTING fw_force_last = abap_true
                               CHANGING  fw_query = fw_query ).
    ENDIF.
  ENDMETHOD.
  METHOD editor_paste.
    DATA : lt_text    TYPE TABLE OF string,
           lw_pos     TYPE i,
           lw_line    TYPE i,
           lw_message TYPE string.

*   Set text with new line
    APPEND fw_text TO lt_text.
    IF s_customize-paste_break = abap_true.
      lw_pos = fw_pos - 1.
      CLEAR lw_message.
      DO lw_pos TIMES.
        CONCATENATE lw_message space INTO lw_message RESPECTING BLANKS.
      ENDDO.
      APPEND lw_message TO lt_text.
    ENDIF.

    CALL METHOD ls_tab_active-ob_textedit->insert_block_at_position
      EXPORTING
        line     = fw_line
        pos      = fw_pos
        text_tab = lt_text
      EXCEPTIONS
        OTHERS   = 0.

* Set cursor at end of pasted field
    IF s_customize-paste_break = abap_true.
      lw_pos = fw_pos.
      lw_line = fw_line + 1.
    ELSE.
      lw_pos = strlen( fw_text ).
      lw_pos = lw_pos + fw_pos.
      lw_line = fw_line.
    ENDIF.

    CALL METHOD ls_tab_active-ob_textedit->set_selection_pos_in_line
      EXPORTING
        line   = lw_line
        pos    = lw_pos
      EXCEPTIONS
        OTHERS = 0.

* Focus on editor
    CALL METHOD cl_gui_control=>set_focus
      EXPORTING
        control = ls_tab_active-ob_textedit
      EXCEPTIONS
        OTHERS  = 0.

    CONCATENATE fw_text 'pasted to SQL Editor'(m27)
                INTO lw_message SEPARATED BY space.
    MESSAGE lw_message TYPE lc_msg_success.
  ENDMETHOD.
  METHOD query_load .
    DATA lw_query_with_cr TYPE string.
    REFRESH ft_query.

    SELECT SINGLE query INTO lw_query_with_cr
           FROM zagtt_sqa_query
           WHERE queryid = fw_queryid.
    IF sy-subrc = 0.
      SPLIT lw_query_with_cr AT cl_abap_char_utilities=>cr_lf
                             INTO TABLE ft_query.
    ENDIF.
    w_last_loaded_query = fw_queryid.
  ENDMETHOD.
  METHOD query_parse.
    DATA : ls_find_select TYPE match_result,
           ls_find_from   TYPE match_result,
           ls_find_where  TYPE match_result,
           ls_sub         LIKE LINE OF ls_find_select-submatches,
           lw_offset      TYPE i,
           lw_length      TYPE i,
           lw_query       TYPE string,
           lo_regex       TYPE REF TO cl_abap_regex,
           lt_split       TYPE TABLE OF string,
           lw_string      TYPE string,
           lw_tabix       TYPE i,
           lw_table       TYPE tabname.

    CLEAR : fw_select,
            fw_from,
            fw_where,
            fw_rows,
            fw_union,
            fw_noauth,
            fw_newsyntax.

    lw_query = fw_query.

* Search union
    FIND FIRST OCCURRENCE OF ' UNION SELECT ' IN lw_query
         RESULTS ls_find_select IGNORING CASE.
    IF sy-subrc = 0.
      lw_offset = ls_find_select-offset + 7.
      fw_union = lw_query+lw_offset.
      lw_query = lw_query(ls_find_select-offset).
    ENDIF.

* Search UP TO xxx ROWS.
* Catch the number of rows, delete command in query
    CREATE OBJECT lo_regex
      EXPORTING
        pattern     = 'UP TO ([0-9]+) ROWS'
        ignore_case = abap_true.
    FIND FIRST OCCURRENCE OF REGEX lo_regex
         IN lw_query RESULTS ls_find_select.
    IF sy-subrc = 0.
      READ TABLE ls_find_select-submatches INTO ls_sub INDEX 1.
      IF sy-subrc = 0.
        fw_rows = lw_query+ls_sub-offset(ls_sub-length).
      ENDIF.
      REPLACE FIRST OCCURRENCE OF REGEX lo_regex IN lw_query WITH ''.
    ELSE.
* Set default number of rows
      fw_rows = s_customize-default_rows.
    ENDIF.

* Remove unused INTO (CORRESPONDING FIELDS OF)(TABLE)
* Detect new syntax in internal table name
    CONCATENATE '(INTO|APPENDING)( TABLE'
                '| CORRESPONDING FIELDS OF TABLE |'
                'CORRESPONDING FIELDS OF | )(\S*)'
                INTO lw_string SEPARATED BY space.
    CREATE OBJECT lo_regex
      EXPORTING
        pattern     = lw_string
        ignore_case = abap_true.
    FIND FIRST OCCURRENCE OF REGEX lo_regex
         IN lw_query RESULTS ls_find_select.
    IF sy-subrc = 0.
      IF ls_find_select-length NE 0
      AND fw_query+ls_find_select-offset(ls_find_select-length) CS '@'.
        fw_newsyntax = abap_true.
      ENDIF.
      REPLACE FIRST OCCURRENCE OF REGEX lo_regex IN lw_query WITH ''.
    ENDIF.

* Search SELECT
    FIND FIRST OCCURRENCE OF 'SELECT ' IN lw_query
         RESULTS ls_find_select IGNORING CASE.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

* Search FROM
    FIND FIRST OCCURRENCE OF ' FROM '
         IN SECTION OFFSET ls_find_select-offset OF lw_query
         RESULTS ls_find_from IGNORING CASE.
    IF sy-subrc NE 0.
      fw_error = abap_true.
      RETURN.
    ENDIF.

* Search WHERE / GROUP BY / HAVING / ORDER BY
    FIND FIRST OCCURRENCE OF ' WHERE '
         IN SECTION OFFSET ls_find_from-offset OF lw_query
         RESULTS ls_find_where IGNORING CASE.
    IF sy-subrc NE 0.
      FIND FIRST OCCURRENCE OF ' GROUP BY ' IN lw_query
           RESULTS ls_find_where IGNORING CASE.
    ENDIF.
    IF sy-subrc NE 0.
      FIND FIRST OCCURRENCE OF ' HAVING ' IN lw_query
           RESULTS ls_find_where IGNORING CASE.
    ENDIF.
    IF sy-subrc NE 0.
      FIND FIRST OCCURRENCE OF ' ORDER BY ' IN lw_query
           RESULTS ls_find_where IGNORING CASE.
    ENDIF.

    lw_offset = ls_find_select-offset + 7.
    lw_length = ls_find_from-offset - ls_find_select-offset - 7.
    IF lw_length LE 0.
      fw_error = abap_true.
      RETURN.
    ENDIF.
    fw_select = lw_query+lw_offset(lw_length).

* Detect new syntax in comma field select separator
    IF fw_select CS ','.
      fw_newsyntax = abap_true.
    ENDIF.

    lw_offset = ls_find_from-offset + 6.
    IF ls_find_where IS INITIAL.
      fw_from = lw_query+lw_offset.
      fw_where = ''.
    ELSE.
      lw_length = ls_find_where-offset - ls_find_from-offset - 6.
      fw_from = lw_query+lw_offset(lw_length).
      lw_offset = ls_find_where-offset.
      fw_where = lw_query+lw_offset.
    ENDIF.

* Authority-check on used select tables
    IF s_customize-auth_object NE space OR s_customize-auth_select NE '*'.
      CONCATENATE 'JOIN' fw_from INTO lw_string SEPARATED BY space.
      TRANSLATE lw_string TO UPPER CASE.
      SPLIT lw_string AT space INTO TABLE lt_split.
      LOOP AT lt_split INTO lw_string.
        lw_tabix = sy-tabix + 1.
        CHECK lw_string = 'JOIN'.
* Read next line (table name)
        READ TABLE lt_split INTO lw_table INDEX lw_tabix.
        CHECK sy-subrc = 0.

        IF s_customize-auth_object NE space.
*        AUTHORITY-CHECK OBJECT s_customize-auth_object
*                 ID 'TABLE' FIELD lw_table
*                 ID 'ACTVT' FIELD s_customize-actvt_select.
        ELSEIF s_customize-auth_select NE '*'
        AND NOT lw_table CP s_customize-auth_select.
          sy-subrc = 4.
        ENDIF.
        IF sy-subrc NE 0.
          CONCATENATE 'No Authorisation for table'(m13) lw_table
                      INTO lw_string SEPARATED BY space.
          MESSAGE lw_string TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          CLEAR fw_from.
          fw_noauth = abap_true.
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD  query_parse_noselect.
    DATA : lw_query TYPE string,
           lw_table TYPE tabname.

    CLEAR : fw_noauth,
            fw_table,
            fw_command,
            fw_param.

    lw_query = fw_query.
    SPLIT lw_query AT space INTO fw_command lw_query.
    TRANSLATE fw_command TO UPPER CASE.
    CASE fw_command.
      WHEN 'INSERT'.
        SPLIT lw_query AT space INTO fw_table fw_param.
        TRANSLATE fw_table TO UPPER CASE.
        CLEAR sy-subrc.
        IF s_customize-auth_object NE space.
          lw_table = fw_table.
          AUTHORITY-CHECK OBJECT s_customize-auth_object
                   ID 'TABLE' FIELD lw_table
                   ID 'ACTVT' FIELD s_customize-actvt_insert.
        ELSEIF s_customize-auth_insert NE '*'
        AND fw_table NP s_customize-auth_insert.
          sy-subrc = 4.
        ENDIF.
        IF sy-subrc NE 0.
          CONCATENATE 'No Authorisation for table'(m13) fw_table
                      INTO lw_query SEPARATED BY space.
          MESSAGE lw_query TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          fw_noauth = abap_true.
          RETURN.
        ENDIF.

      WHEN 'UPDATE'.
        SPLIT lw_query AT space INTO fw_table fw_param.
        TRANSLATE fw_table TO UPPER CASE.
        CLEAR sy-subrc.
        IF s_customize-auth_object NE space.
          lw_table = fw_table.
          AUTHORITY-CHECK OBJECT s_customize-auth_object
                   ID 'TABLE' FIELD lw_table
                   ID 'ACTVT' FIELD s_customize-actvt_update.
        ELSEIF s_customize-auth_update NE '*'
        AND fw_table NP s_customize-auth_update.
          sy-subrc = 4.
        ENDIF.
        IF sy-subrc NE 0.
          CONCATENATE 'No Authorisation for table'(m13) fw_table
                      INTO lw_query SEPARATED BY space.
          MESSAGE lw_query TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          fw_noauth = abap_true.
          RETURN.
        ENDIF.

      WHEN 'DELETE'.
        SPLIT lw_query AT space INTO fw_table fw_param.
        TRANSLATE fw_table TO UPPER CASE.
        IF fw_table = 'FROM'.
          SPLIT fw_param AT space INTO fw_table fw_param.
          TRANSLATE fw_table TO UPPER CASE.
        ENDIF.
        CLEAR sy-subrc.
        IF s_customize-auth_object NE space.
          lw_table = fw_table.
          AUTHORITY-CHECK OBJECT s_customize-auth_object
                   ID 'TABLE' FIELD lw_table
                   ID 'ACTVT' FIELD s_customize-actvt_delete.
        ELSEIF s_customize-auth_delete NE '*'
        AND NOT fw_table CP s_customize-auth_delete.
          sy-subrc = 4.
        ENDIF.
        IF sy-subrc NE 0.
          CONCATENATE 'No Authorisation for table'(m13) fw_table
                      INTO lw_query SEPARATED BY space.
          MESSAGE lw_query TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          fw_noauth = abap_true.
          RETURN.
        ENDIF.

      WHEN lc_native_command.
        IF s_customize-auth_object NE space.
          AUTHORITY-CHECK OBJECT s_customize-auth_object
                   ID 'ACTVT' FIELD s_customize-actvt_native.
        ELSEIF s_customize-auth_native NE abap_true.
          sy-subrc = 4.
        ENDIF.
        IF sy-subrc NE 0.
          CONCATENATE 'SQL command not allowed :'(m25) fw_command
                      INTO lw_query.
          MESSAGE lw_query TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          fw_noauth = abap_true.
          RETURN.
        ENDIF.
* For native command, replace ' by "
        TRANSLATE lw_query USING '''"'.
        fw_param = lw_query.

      WHEN OTHERS.
        CONCATENATE 'SQL command not allowed :'(m25) fw_command
                    INTO lw_query.
        MESSAGE lw_query TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
        fw_noauth = abap_true.
        RETURN.
    ENDCASE.
  ENDMETHOD.
  METHOD repo_delete_history.
    DATA ls_histo LIKE s_node_repository.

    READ TABLE t_node_repository INTO ls_histo
               WITH KEY node_key = fw_node_key.
    IF sy-subrc = 0 AND ls_histo-edit NE space.
      DELETE FROM zagtt_sqa_query WHERE queryid = ls_histo-queryid.
      IF sy-subrc = 0.
        CALL METHOD ob_tree_repository->delete_node
          EXPORTING
            node_key          = fw_node_key
          EXCEPTIONS
            failed            = 1
            node_not_found    = 2
            cntl_system_error = 3
            OTHERS            = 4.
        IF sy-subrc <> 0.
          fw_subrc = sy-subrc.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD tab_update_title.
    DATA : lw_name(30) TYPE c,
           lt_query    TYPE soli_tab,
           ls_query    LIKE LINE OF lt_query,
           lw_query    TYPE string.
    FIELD-SYMBOLS <fs> TYPE any.
    IF w_tabstrip-activetab IS INITIAL.
      lw_name = 'S_TAB-TITLE1'.
    ELSE.
      CONCATENATE 'S_TAB-TITLE' w_tabstrip-activetab+3 INTO lw_name.
    ENDIF.
    ASSIGN (lw_name) TO <fs>.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

* Basic read query to check if first line is a comment
    CALL METHOD ls_tab_active-ob_textedit->get_text ##SUBRC_OK
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.
    READ TABLE lt_query INTO ls_query INDEX 1.
    IF sy-subrc NE 0.
      <fs> = 'Empty tab'(m65).
      RETURN.
    ENDIF.
    IF ls_query(1) = '*'.
      <fs> = ls_query+1.
      RETURN.
    ENDIF.

* Query given, use it as title
    IF NOT fw_query IS INITIAL.
      <fs> = fw_query.
      RETURN.
    ENDIF.

* If no query given, try to read it
    me->editor_get_query( EXPORTING fw_force_last = space
                          CHANGING  fw_query = lw_query ).
    <fs> = lw_query.


  ENDMETHOD.
  METHOD leave_current_tab.
* hide current editor / ddic / alv
    CALL METHOD ls_tab_active-ob_textedit->set_visible
      EXPORTING
        visible = space.

    CALL METHOD ls_tab_active-ob_tree_ddic->set_visible
      EXPORTING
        visible = space.

    IF NOT ls_tab_active-ob_alv_result IS INITIAL.
      CALL METHOD ls_tab_active-ob_alv_result->set_visible
        EXPORTING
          visible = space.
    ENDIF.
* Save ALV split height
    CALL METHOD ob_splitter->get_row_height
      EXPORTING
        id     = 1
      IMPORTING
        result = ls_tab_active-lv_row_height.
    CALL METHOD cl_gui_cfw=>flush.

    me->tab_update_title( space ).

    MODIFY t_tabs FROM ls_tab_active INDEX w_tabstrip-activetab+3.
    CLEAR ls_tab_active.
  ENDMETHOD.
  METHOD query_generate.
    DATA : lt_code_string TYPE TABLE OF string,
           lt_split       TYPE TABLE OF string,
           lw_string      TYPE string,
           lw_string2     TYPE string,
           BEGIN OF ls_table_alias,
             table(50) TYPE c,
             alias(50) TYPE c,
           END OF ls_table_alias,
           lt_table_alias      LIKE TABLE OF ls_table_alias,
           lw_select           TYPE string,
           lw_from             TYPE string,
           lw_index            TYPE i,
           lw_select_distinct  TYPE c,
           lw_select_length    TYPE i,
           lw_char_10(10)      TYPE c,
           lw_field_number(6)  TYPE n,
           lw_current_line     TYPE i,
           lw_current_length   TYPE i,
           lw_struct_line      TYPE string,
           lw_struct_line_type TYPE string,
           lw_select_table     TYPE string,
           lw_select_field     TYPE string,
           lw_dd03l_fieldname  TYPE dd03l-fieldname,
           lw_position_dummy   TYPE dd03l-position,
           lw_mess(255),
           lw_line             TYPE i,
           lw_word(30),
           ls_fieldlist        TYPE lty_fieldlist,
           lw_strlen_string    TYPE string,
           lw_explicit         TYPE string.

    DEFINE c.
      lw_strlen_string = &1.
       me->add_line_to_table( EXPORTING fw_line = lw_strlen_string
                                CHANGING ft_table = lt_code_string ).
    END-OF-DEFINITION.

    CLEAR : lw_select_distinct,
            fw_count.

* Write Header
    c 'PROGRAM SUBPOOL.'.
    c '** GENERATED PROGRAM * DO NOT CHANGE IT **'.
    c 'TYPE-POOLS: slis.'.                                  "#EC NOTEXT
    c ''.

    lw_select = fw_select.
    TRANSLATE lw_select TO UPPER CASE.

    lw_from = fw_from.
    TRANSLATE lw_from TO UPPER CASE.

* Search special term "single" or "distinct"
    lw_select_length = strlen( lw_select ).
    IF lw_select_length GE 7.
      lw_char_10 = lw_select(7).
      IF lw_char_10 = 'SINGLE'.
* Force rows number = 1 for select single
        fw_rows = 1.
        lw_select = lw_select+7.
        lw_select_length = lw_select_length - 7.
      ENDIF.
    ENDIF.
    IF lw_select_length GE 9.
      lw_char_10 = lw_select(9).
      IF lw_char_10 = 'DISTINCT'.
        lw_select_distinct = abap_true.
        lw_select = lw_select+9.
        lw_select_length = lw_select_length - 9.
      ENDIF.
    ENDIF.

* Search for special syntax "count( * )"
    IF lw_select = 'COUNT( * )'.
      fw_count = abap_true.
    ENDIF.

* Create alias table mapping
    SPLIT lw_from AT space INTO TABLE lt_split.
    LOOP AT lt_split INTO lw_string.
      IF lw_string IS INITIAL OR lw_string CO space.
        DELETE lt_split.
      ENDIF.
    ENDLOOP.
    DO.
      READ TABLE lt_split TRANSPORTING NO FIELDS WITH KEY table_line  = 'AS'.
      IF sy-subrc NE 0.
        EXIT. "exit do
      ENDIF.
      lw_index = sy-tabix - 1.
      READ TABLE lt_split INTO lw_string INDEX lw_index.
      ls_table_alias-table = lw_string.
      DELETE lt_split INDEX lw_index. "delete table field
      DELETE lt_split INDEX lw_index. "delete keywork AS
      READ TABLE lt_split INTO lw_string INDEX lw_index.
      ls_table_alias-alias = lw_string.
      DELETE lt_split INDEX lw_index. "delete alias field
      APPEND ls_table_alias TO lt_table_alias.
    ENDDO.
* If no alias table found, create just an entry for "*"
    IF lt_table_alias[] IS INITIAL.
      READ TABLE lt_split INTO lw_string INDEX 1.
      ls_table_alias-table = lw_string.
      ls_table_alias-alias = '*'.
      APPEND ls_table_alias TO lt_table_alias.
    ENDIF.
    SORT lt_table_alias BY alias.

* Write Data declaration
    c '***************************************'.            "#EC NOTEXT
    c '*      Begin of data declaration      *'.            "#EC NOTEXT
    c '*   Used to store lines of the query  *'.            "#EC NOTEXT
    c '***************************************'.            "#EC NOTEXT
    c 'DATA: BEGIN OF s_result'.                            "#EC NOTEXT
    lw_field_number = 1.

    lw_string = lw_select.
    IF fw_newsyntax = abap_true.
      TRANSLATE lw_string USING ', '.
      CONDENSE lw_string.
    ENDIF.
    SPLIT lw_string AT space INTO TABLE lt_split.

    LOOP AT lt_split INTO lw_string.
      lw_current_line = sy-tabix.
      IF lw_string IS INITIAL OR lw_string CO space.
        CONTINUE.
      ENDIF.
      IF lw_string = 'AS'.
        DELETE lt_split INDEX lw_current_line. "delete AS
        DELETE lt_split INDEX lw_current_line. "delete the alias name
        CONTINUE.
      ENDIF.
      lw_current_length = strlen( lw_string ).

      CLEAR ls_fieldlist.
      ls_fieldlist-ref_field = lw_string.

* Manage new syntax "Case"
      IF fw_newsyntax = abap_true AND lw_string = 'CASE'.
        lw_index = lw_current_line.
        DO.
          lw_index = lw_index + 1.
          READ TABLE lt_split INTO lw_string INDEX lw_index.
          IF sy-subrc NE 0.
            MESSAGE 'Incorrect syntax in Case statement'(m62)
                     TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
            RETURN.
          ENDIF.
          IF lw_string = 'END'.
            lw_index = lw_index + 1.
            READ TABLE lt_split INTO lw_string INDEX lw_index.
            IF lw_string NE 'AS'.
              lw_index = lw_index - 1.
              CONTINUE.
            ENDIF.
            lw_index = lw_index + 1.
            READ TABLE lt_split INTO lw_string INDEX lw_index.

            CLEAR ls_fieldlist.
            CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
            CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.
            CONCATENATE lw_struct_line 'TYPE string'        "#EC NOTEXT
                        INTO lw_struct_line SEPARATED BY space.
            c lw_struct_line.
            ls_fieldlist-ref_table = ''.
            ls_fieldlist-ref_field = lw_string.
            APPEND ls_fieldlist TO ft_fieldlist.
            lw_field_number = lw_field_number + 1.

            lw_index = lw_index - lw_current_line + 1.
            DO lw_index TIMES.
              DELETE lt_split INDEX lw_current_line. "delete the case element
            ENDDO.
            EXIT.
          ENDIF.
        ENDDO.
        CONTINUE.
      ENDIF.

* Manage "Count"
      IF lw_current_length GE 6.
        lw_char_10 = lw_string(6).
      ELSE.
        CLEAR lw_char_10.
      ENDIF.
      IF lw_char_10 = 'COUNT('.
        CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
        CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

        lw_index = lw_current_line + 1.
        DO.
          SEARCH lw_string FOR ')'.
          IF sy-subrc = 0.
            EXIT.
          ELSE.
* If there is space in the "count()", delete next lines
            READ TABLE lt_split INTO lw_string INDEX lw_index.
            IF sy-subrc NE 0.
              EXIT.
            ENDIF.
            CONCATENATE ls_fieldlist-ref_field lw_string
                        INTO ls_fieldlist-ref_field SEPARATED BY space.
            DELETE lt_split INDEX lw_index.
          ENDIF.
        ENDDO.
        CONCATENATE lw_struct_line 'TYPE i'                 "#EC NOTEXT
                    INTO lw_struct_line SEPARATED BY space.
        c lw_struct_line.
        APPEND ls_fieldlist TO ft_fieldlist.
        lw_field_number = lw_field_number + 1.
        CONTINUE.
      ENDIF.

* Manage Agregate AVG
      IF lw_current_length GE 4.
        lw_char_10 = lw_string(4).
      ELSE.
        CLEAR lw_char_10.
      ENDIF.
      IF lw_char_10 = 'AVG('.
        CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
        CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

        lw_index = lw_current_line + 1.
        DO.
          SEARCH lw_string FOR ')'.
          IF sy-subrc = 0.
            EXIT.
          ELSE.
* If there is space in the agregate, delete next lines
            READ TABLE lt_split INTO lw_string INDEX lw_index.
            IF sy-subrc NE 0.
              EXIT.
            ENDIF.
            CONCATENATE ls_fieldlist-ref_field lw_string
                        INTO ls_fieldlist-ref_field SEPARATED BY space.
            DELETE lt_split INDEX lw_index.
          ENDIF.
        ENDDO.
        CONCATENATE lw_struct_line 'TYPE f'                 "#EC NOTEXT
                    INTO lw_struct_line SEPARATED BY space.
        c lw_struct_line.
        APPEND ls_fieldlist TO ft_fieldlist.
        lw_field_number = lw_field_number + 1.
        CONTINUE.
      ENDIF.

* Manage agregate SUM, MAX, MIN
      IF lw_current_length GE 4.
        lw_char_10 = lw_string(4).
      ELSE.
        CLEAR lw_char_10.
      ENDIF.
      IF lw_char_10 = 'SUM(' OR lw_char_10 = 'MAX('
      OR lw_char_10 = 'MIN('.
        CLEAR lw_string2.
        lw_index = lw_current_line + 1.
        DO.
          SEARCH lw_string FOR ')'.
          IF sy-subrc = 0.
            EXIT.
          ELSE.
* Search name of the field in next lines.
            READ TABLE lt_split INTO lw_string INDEX lw_index.
            IF sy-subrc NE 0.
              EXIT.
            ENDIF.
            CONCATENATE ls_fieldlist-ref_field lw_string
                        INTO ls_fieldlist-ref_field SEPARATED BY space.
            IF lw_string2 IS INITIAL.
              lw_string2 = lw_string.
            ENDIF.
* Delete lines of agregage in field table
            DELETE lt_split INDEX lw_index.
          ENDIF.
        ENDDO.
        lw_string = lw_string2.
      ENDIF.

* Now lw_string contain a field name.
* We have to find the field description
      SPLIT lw_string AT '~' INTO lw_select_table lw_select_field.
      IF lw_select_field IS INITIAL.
        lw_select_field = lw_select_table.
        lw_select_table = '*'.
      ENDIF.
* Search if alias table used
      CLEAR ls_table_alias.
      READ TABLE lt_table_alias INTO ls_table_alias
                 WITH KEY alias = lw_select_table           "#EC WARNOK
                 BINARY SEARCH.
      IF sy-subrc = 0.
        lw_select_table = ls_table_alias-table.
      ENDIF.
      ls_fieldlist-ref_table = lw_select_table.
      IF lw_string = '*' OR lw_select_field = '*'. " expansion table~*
        CLEAR lw_explicit.
        SELECT fieldname position
        INTO   (lw_dd03l_fieldname,lw_position_dummy)
        FROM   dd03l
        WHERE  tabname    = lw_select_table
        AND    fieldname <> 'MANDT'
        AND    as4local   = lc_vers_active
        AND    as4vers    = space
        AND (  comptype   = lc_ddic_dtelm
            OR comptype   = space )
        ORDER BY position.

          lw_select_field = lw_dd03l_fieldname.

          CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
          ls_fieldlist-ref_field = lw_select_field.
          APPEND ls_fieldlist TO ft_fieldlist.
          CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

          CONCATENATE lw_select_table '-' lw_select_field
                      INTO lw_struct_line_type.
          CONCATENATE lw_struct_line 'TYPE' lw_struct_line_type
                      INTO lw_struct_line
                      SEPARATED BY space.
          c lw_struct_line.
          lw_field_number = lw_field_number + 1.
* Explicit list of fields instead of *
* Generate longer query but mandatory in case of T1~* or MARA~*
* Required also in some special cases, for example if table use include
          IF ls_table_alias-alias = space OR ls_table_alias-alias = '*'.
            CONCATENATE lw_explicit lw_select_table
                        INTO lw_explicit SEPARATED BY space.
          ELSE.
            CONCATENATE lw_explicit ls_table_alias-alias
                        INTO lw_explicit SEPARATED BY space.
          ENDIF.
          CONCATENATE lw_explicit '~' lw_select_field INTO lw_explicit.
        ENDSELECT.
        IF sy-subrc NE 0.
          MESSAGE e701(1r) WITH lw_select_table. "table does not exist
        ENDIF.
        IF NOT lw_explicit IS INITIAL.
          REPLACE FIRST OCCURRENCE OF lw_string
                  IN lw_select WITH lw_explicit.
        ENDIF.

      ELSE. "Simple field
        CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
        ls_fieldlist-ref_field = lw_select_field.
        APPEND ls_fieldlist TO ft_fieldlist.

        CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

        CONCATENATE lw_select_table '-' lw_select_field
                    INTO lw_struct_line_type.
        CONCATENATE lw_struct_line 'TYPE' lw_struct_line_type
                    INTO lw_struct_line
                    SEPARATED BY space.
        c lw_struct_line.
        lw_field_number = lw_field_number + 1.
      ENDIF.
    ENDLOOP.

* Add a count field
    CLEAR ls_fieldlist.
    ls_fieldlist-field = 'COUNT'.
    ls_fieldlist-ref_table = ''.
    ls_fieldlist-ref_field = 'Count'.                       "#EC NOTEXT
    APPEND ls_fieldlist TO ft_fieldlist.
    c ', COUNT type i'.                                     "#EC NOTEXT

* End of data definition
    c ', END OF s_result'.                                  "#EC NOTEXT
    c ', t_result like table of s_result'.                  "#EC NOTEXT
    c ', w_timestart type timestampl'.                      "#EC NOTEXT
    c ', w_timeend type timestampl.'.                       "#EC NOTEXT

* Write the dynamic subroutine that run the SELECT
    c 'FORM run_sql CHANGING fo_result TYPE REF TO data'.   "#EC NOTEXT
    c '                      fw_time type p'.               "#EC NOTEXT
    c '                      fw_count type i.'.             "#EC NOTEXT
    c 'field-symbols <fs_result> like s_result.'.           "#EC NOTEXT
    c '***************************************'.            "#EC NOTEXT
    c '*            Begin of query           *'.            "#EC NOTEXT
    c '***************************************'.            "#EC NOTEXT
    c 'get TIME STAMP FIELD w_timestart.'.                  "#EC NOTEXT
    IF fw_count = abap_true.
      CONCATENATE 'SELECT SINGLE' lw_select                 "#EC NOTEXT
                  INTO lw_select SEPARATED BY space.
      c lw_select.
      IF fw_newsyntax = abap_true.
        c 'INTO @s_result-f000001'.                         "#EC NOTEXT
      ELSE.
        c 'INTO s_result-f000001'.                          "#EC NOTEXT
      ENDIF.
    ELSE.
      IF lw_select_distinct NE space.
        CONCATENATE 'SELECT DISTINCT' lw_select             "#EC NOTEXT
                    INTO lw_select SEPARATED BY space.
      ELSE.
        CONCATENATE 'SELECT' lw_select                      "#EC NOTEXT
                    INTO lw_select SEPARATED BY space.
      ENDIF.
      c lw_select.
      IF fw_newsyntax = abap_true.
        c 'INTO TABLE @t_result'.                           "#EC NOTEXT
      ELSE.
        c 'INTO TABLE t_result'.                            "#EC NOTEXT
      ENDIF.

* Add UP TO xxx ROWS
      IF NOT fw_rows IS INITIAL.
        c 'UP TO'.                                          "#EC NOTEXT
        c fw_rows.
        c 'ROWS'.                                           "#EC NOTEXT
      ENDIF.
    ENDIF.

    c 'FROM'.                                               "#EC NOTEXT
    c lw_from.

* Where, group by, having, order by
    IF NOT fw_where IS INITIAL.
      c fw_where.
    ENDIF.
    c '.'.

* Display query execution time
    c 'get TIME STAMP FIELD w_timeend.'.                    "#EC NOTEXT
    c 'fw_time = w_timeend - w_timestart.'.                 "#EC NOTEXT
    c 'fw_count = sy-dbcnt.'.                               "#EC NOTEXT

* If select count( * ), display number of results
    IF fw_count NE space.
      c 'MESSAGE i753(TG) WITH s_result-f000001.'.          "#EC NOTEXT
    ENDIF.
    c 'loop at t_result assigning <fs_result>.'.            "#EC NOTEXT
    c ' <fs_result>-count = 1.'.                            "#EC NOTEXT
    c 'endloop.'.                                           "#EC NOTEXT
    c 'GET REFERENCE OF t_result INTO fo_result.'.          "#EC NOTEXT
    c 'ENDFORM.'.                                           "#EC NOTEXT
    CLEAR : lw_line,
            lw_word,
            lw_mess.
    SYNTAX-CHECK FOR lt_code_string PROGRAM sy-repid
                 MESSAGE lw_mess LINE lw_line WORD lw_word.
    IF sy-subrc NE 0 AND fw_display = space.
      MESSAGE lw_mess TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      CLEAR fw_program.
      RETURN.
    ENDIF.

    IF fw_display = space.
      GENERATE SUBROUTINE POOL lt_code_string NAME fw_program.
    ELSE.
      IF lw_mess IS NOT INITIAL.
        lw_explicit = lw_line.
        CONCATENATE lw_mess '(line'(m28) lw_explicit ',word'(m29)
                    lw_word ')'(m30)
                    INTO lw_mess SEPARATED BY space.
        MESSAGE lw_mess TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      ENDIF.
      EDITOR-CALL FOR lt_code_string DISPLAY-MODE
                  TITLE 'Generated code for current query'(t01).
    ENDIF.
  ENDMETHOD.
  METHOD add_line_to_table.
    DATA : lw_length TYPE i,
           lw_offset TYPE i,
           ls_find   TYPE match_result.

    lw_length = strlen( fw_line ).
    lw_offset = 0.
    DO.
      IF lw_length LE lc_line_max.
        APPEND fw_line+lw_offset(lw_length) TO ft_table.
        EXIT. "exit do
      ELSE.
        FIND ALL OCCURRENCES OF REGEX '\s' "search space
             IN SECTION OFFSET lw_offset LENGTH lc_line_max
             OF fw_line RESULTS ls_find.
        IF sy-subrc NE 0.
          APPEND fw_line+lw_offset(lc_line_max) TO ft_table.
          lw_length = lw_length - lc_line_max.
          lw_offset = lw_offset + lc_line_max.
        ELSE.
          ls_find-length = ls_find-offset - lw_offset.
          APPEND fw_line+lw_offset(ls_find-length) TO ft_table.
          lw_length = lw_length + lw_offset - ls_find-offset - 1.
          lw_offset = ls_find-offset + 1.
        ENDIF.
      ENDIF.
    ENDDO.

  ENDMETHOD.
  METHOD query_generate_noselect.
    DATA : lt_code_string      TYPE TABLE OF string,
           lw_mess(255),
           lw_line             TYPE i,
           lw_word(30),
           lw_strlen_string    TYPE string,
           lw_explicit         TYPE string,
           lw_length           TYPE i,
           lw_pos              TYPE i,
           lw_fieldnum         TYPE i,
           lw_fieldval         TYPE string,
           lw_fieldname        TYPE string,
           lw_wait_name(1)     TYPE c,
           lw_char(1)          TYPE c,
           lw_started(1)       TYPE c,
           lw_started_field(1) TYPE c.

    DEFINE c.
      lw_strlen_string = &1.
      me->add_line_to_table( EXPORTING  fw_line = lw_strlen_string
                                CHANGING  ft_table = lt_code_string ).
    END-OF-DEFINITION.

* Write Header
    c 'PROGRAM SUBPOOL.'.                                   "#EC NOTEXT
    c '** GENERATED PROGRAM * DO NOT CHANGE IT **'.         "#EC NOTEXT
    c 'type-pools: slis.'.                                  "#EC NOTEXT
    c 'DATA : w_timestart type timestampl,'.                "#EC NOTEXT
    c '       w_timeend type timestampl.'.                  "#EC NOTEXT
    c ''.
    IF fw_command = 'INSERT'.
      c 'DATA s_insert type'.                               "#EC NOTEXT
      c fw_table.
      c '.'.                                                "#EC NOTEXT
      c 'FIELD-SYMBOLS <fs> TYPE ANY.'.                     "#EC NOTEXT
      c '.'.                                                "#EC NOTEXT
    ENDIF.

* Write the dynamic subroutine that run the SELECT
    c 'FORM run_sql CHANGING fo_result TYPE REF TO data'.   "#EC NOTEXT
    c '                      fw_time TYPE p'.               "#EC NOTEXT
    c '                      fw_count TYPE i.'.             "#EC NOTEXT
    c '***************************************'.            "#EC NOTEXT
    c '*            Begin of query           *'.            "#EC NOTEXT
    c '***************************************'.            "#EC NOTEXT
    c 'CLEAR fw_count.'.                                    "#EC NOTEXT
    c 'GET TIME STAMP FIELD w_timestart.'.                  "#EC NOTEXT

    CASE fw_command.
      WHEN 'UPDATE'.
        c fw_command.
        c fw_table.
        c fw_param.
        c '.'.
      WHEN 'DELETE'.
        c fw_command.
        c 'FROM'.                                           "#EC NOTEXT
        c fw_table.
        c fw_param.
        c '.'.
      WHEN 'INSERT'.

        IF fw_param(6) = 'VALUES'.
          lw_length = strlen( fw_param ).
          lw_pos = 6.
          lw_fieldnum = 0.
          WHILE lw_pos < lw_length.
            lw_char = fw_param+lw_pos(1).
            lw_pos = lw_pos + 1.
            IF lw_started = space.
              IF lw_char NE '('. "begin of the list
                CONTINUE.
              ENDIF.
              lw_started = abap_true.
              CONTINUE.
            ENDIF.
            IF lw_started_field = space.
              IF lw_char = ')'. "end of the list
                EXIT. "exit while
              ENDIF.

              IF lw_char NE ''''. "field value must start by '
                CONTINUE.
              ENDIF.
              lw_started_field = abap_true.
              lw_fieldval = lw_char.
              lw_fieldnum = lw_fieldnum + 1.
              CONTINUE.
            ENDIF.
            IF lw_char = space.
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval
                          SEPARATED BY space.
            ELSE.
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
            ENDIF.
            IF lw_char = ''''. "end of a field ?
              IF lw_pos < lw_length.
                lw_char = fw_param+lw_pos(1).
              ELSE.
                CLEAR lw_char.
              ENDIF.
              IF lw_char = ''''. "not end !
                CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
                lw_pos = lw_pos + 1.
                CONTINUE.
              ELSE. "end of a field!
                c 'ASSIGN COMPONENT'.                       "#EC NOTEXT
                c lw_fieldnum.
                c 'OF STRUCTURE s_insert TO <fs>.'.         "#EC NOTEXT
                c '<fs> = '.                                "#EC NOTEXT
                c lw_fieldval.
                c '.'.                                      "#EC NOTEXT
                lw_started_field = space.
              ENDIF.
            ENDIF.
          ENDWHILE.
        ELSEIF fw_param(3) = 'SET'.


          lw_length = strlen( fw_param ).
          lw_pos = 3.
          lw_fieldnum = 0.
          lw_wait_name = abap_true.
          WHILE lw_pos < lw_length.
            lw_char = fw_param+lw_pos(1).
            lw_pos = lw_pos + 1.
            IF lw_wait_name = abap_true.
              TRANSLATE lw_char TO UPPER CASE.
              IF lw_char = space OR NOT sy-abcde CS lw_char.
                CONTINUE. "not a begin of fieldname
              ENDIF.
              lw_wait_name = space.
              lw_started = abap_true.
              CONCATENATE 's_insert-' lw_char
                          INTO lw_fieldname.                "#EC NOTEXT
              CONTINUE.
            ENDIF.

            IF lw_started = abap_true.
              IF lw_char = space.
                CONCATENATE lw_fieldname lw_char INTO lw_fieldname
                            SEPARATED BY space.
              ELSE.
                CONCATENATE lw_fieldname lw_char INTO lw_fieldname.
              ENDIF.
              IF lw_char = '='. "end of the field name
                lw_started = space.
              ENDIF.

              CONTINUE.
            ENDIF.

            IF lw_started_field NE abap_true.
              IF lw_char NE ''''. "field value must start by '
                CONTINUE.
              ENDIF.
              lw_started_field = abap_true.
              lw_fieldval = lw_char.
              CONTINUE.
            ENDIF.

            IF lw_char = space.
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval
                          SEPARATED BY space.
            ELSE.
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
            ENDIF.
            IF lw_char = ''''. "end of a field ?
              IF lw_pos < lw_length.
                lw_char = fw_param+lw_pos(1).
              ELSE.
                CLEAR lw_char.
              ENDIF.
              IF lw_char = ''''. "not end !
                CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
                lw_pos = lw_pos + 1.
                CONTINUE.
              ELSE. "end of a field!
                c lw_fieldname.
                c lw_fieldval.
                c '.'.
                lw_started_field = space.
                lw_wait_name = abap_true.
              ENDIF.
            ENDIF.
          ENDWHILE.
        ELSE.
          MESSAGE 'Error in INSERT syntax : VALUES / SET required'(m26)
                  TYPE lc_msg_error.
        ENDIF. "if fw_param(6) = 'VALUES'.
        c fw_command.
        c 'INTO'.                                           "#EC NOTEXT
        c fw_table.
        c 'VALUES s_insert.'.                               "#EC NOTEXT
    ENDCASE.

* Get query execution time & affected lines
    c 'IF sy-subrc = 0.'.                                   "#EC NOTEXT
    c '  fw_count = sy-dbcnt.'.                             "#EC NOTEXT
    c 'ENDIF.'.                                             "#EC NOTEXT
    c 'GET TIME STAMP FIELD w_timeend.'.                    "#EC NOTEXT
    c 'fw_time = w_timeend - w_timestart.'.                 "#EC NOTEXT
    c 'ENDFORM.'.                                           "#EC NOTEXT

    CLEAR : lw_line,
            lw_word,
            lw_mess.
    SYNTAX-CHECK FOR lt_code_string PROGRAM sy-repid
                 MESSAGE lw_mess LINE lw_line WORD lw_word.
    IF sy-subrc NE 0 AND fw_display = space.
      MESSAGE lw_mess TYPE lc_msg_error.
    ENDIF.

    IF fw_display = space.
      GENERATE SUBROUTINE POOL lt_code_string NAME fw_program.
    ELSE.
      IF lw_mess IS NOT INITIAL.
        lw_explicit = lw_line.
        CONCATENATE lw_mess '(line'(m28) lw_explicit ',word'(m29)
                    lw_word ')'(m30)
                    INTO lw_mess SEPARATED BY space.
        MESSAGE lw_mess TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      ENDIF.
      EDITOR-CALL FOR lt_code_string DISPLAY-MODE
                  TITLE 'Generated code for current query'(t01).
    ENDIF.
  ENDMETHOD.
  METHOD query_process_native .
    DATA : lw_lines        TYPE i,
           lw_sql_code     TYPE i,
           lw_sql_msg(255) TYPE c,
           lw_row_num      TYPE i,
           lw_command(255) TYPE c,
           lw_msg          TYPE string,
           lw_timestart    TYPE timestampl,
           lw_timeend      TYPE timestampl,
           lw_time         TYPE p LENGTH 8 DECIMALS 2,
           lw_charnumb(12) TYPE c,
           lw_answer(1)    TYPE c.

* Have a user confirmation before execute Native SQL Command
    CONCATENATE 'Are you sure you want to do a'(m31) fw_command
                '?'(m33)
                INTO lw_msg SEPARATED BY space.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Warning : critical operation'(t04)
        text_question         = lw_msg
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = lw_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc NE 0 OR lw_answer NE '1'.
      RETURN.
    ENDIF.

    lw_command = fw_command.
    lw_lines = strlen( lw_command ).
    GET TIME STAMP FIELD lw_timestart.
    CALL 'C_DB_EXECUTE'
         ID 'STATLEN' FIELD lw_lines
         ID 'STATTXT' FIELD lw_command
         ID 'SQLERR'  FIELD lw_sql_code
         ID 'ERRTXT'  FIELD lw_sql_msg
         ID 'ROWNUM'  FIELD lw_row_num.
    IF sy-subrc NE 0.
      MESSAGE lw_sql_msg TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      RETURN.
    ELSE.
      GET TIME STAMP FIELD lw_timeend.
      lw_time = cl_abap_tstmp=>subtract(
                  tstmp1 = lw_timeend
                  tstmp2 = lw_timestart
                ).
      lw_charnumb = lw_time.
      CONCATENATE 'Query executed in'(m09) lw_charnumb 'seconds.'(m10)
                  INTO lw_msg SEPARATED BY space.
      CONDENSE lw_msg.
      MESSAGE lw_msg TYPE lc_msg_success.
    ENDIF.
  ENDMETHOD.
  METHOD result_display.
    DATA : ls_layout    TYPE lvc_s_layo,
           lt_fieldcat  TYPE lvc_t_fcat,
           ls_fieldlist TYPE lty_fieldlist,
           ls_fieldcat  LIKE LINE OF lt_fieldcat.
    DATA : lo_descr_table TYPE REF TO cl_abap_tabledescr,
           lo_descr_line  TYPE REF TO cl_abap_structdescr,
           ls_compx       TYPE abap_compdescr,
           lw_height      TYPE i.

    FIELD-SYMBOLS: <lft_data> TYPE ANY TABLE.

    ASSIGN fo_result->* TO <lft_data>.

* Get data type for COUNT & AVG fields
    lo_descr_table ?=
      cl_abap_typedescr=>describe_by_data_ref( fo_result ).
    lo_descr_line ?= lo_descr_table->get_table_line_type( ).

    LOOP AT ft_fieldlist INTO ls_fieldlist.
      CLEAR ls_fieldcat.
      ls_fieldcat-fieldname = ls_fieldlist-field.

      IF NOT ls_fieldlist-ref_table IS INITIAL.
        ls_fieldcat-ref_field = ls_fieldlist-ref_field.
        ls_fieldcat-ref_table = ls_fieldlist-ref_table.
        IF s_customize-techname = space.
          ls_fieldcat-reptext = ls_fieldlist-ref_field.
        ELSE.
          ls_fieldcat-reptext = ls_fieldlist-ref_field.
          ls_fieldcat-scrtext_s = ls_fieldlist-ref_field.
          ls_fieldcat-scrtext_m = ls_fieldlist-ref_field.
          ls_fieldcat-scrtext_l = ls_fieldlist-ref_field.
        ENDIF.
      ELSE. "COUNT & AVG field
        CLEAR ls_compx.
        READ TABLE lo_descr_line->components INTO ls_compx
                   WITH KEY name = ls_fieldlist-field.      "#EC WARNOK
        ls_fieldcat-intlen = ls_compx-length.
        ls_fieldcat-decimals = ls_compx-decimals.
        ls_fieldcat-inttype = ls_compx-type_kind.
        ls_fieldcat-reptext = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_s = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_m = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_l = ls_fieldlist-ref_field.
      ENDIF.
      APPEND ls_fieldcat TO lt_fieldcat.
    ENDLOOP.

    ls_layout-smalltitle = abap_true.
    ls_layout-zebra = abap_true.
    ls_layout-cwidth_opt = abap_true.
    ls_layout-grid_title = fw_title.
    ls_layout-countfname = 'COUNT'.

* Set the grid config and content
    CALL METHOD ls_tab_active-ob_alv_result->set_table_for_first_display
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = <lft_data>
        it_fieldcatalog = lt_fieldcat.

* Search if grid is currently displayed
    CALL METHOD ob_splitter->get_row_height
      EXPORTING
        id     = 1
      IMPORTING
        result = lw_height.
    CALL METHOD cl_gui_cfw=>flush.

* If grid is hidden, display it
    IF lw_height = 100.
      CALL METHOD ob_splitter->set_row_height
        EXPORTING
          id     = 1
          height = 20.
    ENDIF.
  ENDMETHOD.
  METHOD result_save_file.
    DATA: ls_field_in        LIKE LINE OF ft_fields,
          lt_file_export     TYPE filetable,
          lv_rc_export       TYPE i,
          lv_file_export     TYPE string,
          gt_len             TYPE i,
          lr_excel_structure TYPE REF TO data,
          lv_content         TYPE xstring,
          lt_binary_tab      TYPE TABLE OF sdokcntasc,
          ob_ref             TYPE REF TO  cx_salv_export_error.

    CONSTANTS : lc_extent TYPE string  VALUE 'XLSX',    " Default extension
                lc_filter TYPE string  VALUE '*xlsx',
                lc_dir    TYPE string  VALUE 'C:\',
                lc_bin    TYPE char10  VALUE 'BIN',
                lc_title  TYPE string  VALUE 'Select output file path'. "#EC NOTEXT
    FIELD-SYMBOLS: <lft_data> TYPE ANY TABLE.


    CALL METHOD cl_gui_frontend_services=>file_open_dialog
      EXPORTING
        window_title            = lc_title
        default_extension       = lc_extent
        file_filter             = lc_filter
        initial_directory       = lc_dir
      CHANGING
        file_table              = lt_file_export
        rc                      = lv_rc_export
      EXCEPTIONS
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        not_supported_by_gui    = 4
        OTHERS                  = 5.

    IF sy-subrc IS INITIAL AND lt_file_export IS NOT INITIAL.
      ASSIGN lt_file_export[ 1 ] TO FIELD-SYMBOL(<ls_file_export>).
      lv_file_export = <ls_file_export>-filename.
      ASSIGN fo_result->* TO <lft_data>.

      GET REFERENCE OF <lft_data> INTO lr_excel_structure.
      "excel instantiate
      DATA(lo_tool_xls) = cl_salv_export_tool_ats_xls=>create_for_excel(
                                EXPORTING r_data =  lr_excel_structure  ) .

      "Add columns to sheet
      DATA(lo_config) = lo_tool_xls->configuration( ).

      LOOP AT ft_fields INTO ls_field_in.
        lo_config->add_column(
         EXPORTING
           header_text        =  ls_field_in-ref_field
           field_name         =  ls_field_in-field
           display_type       =  if_salv_bs_model_column=>uie_text_view ).
      ENDLOOP.


      TRY.
          lo_tool_xls->read_result(  IMPORTING content  = lv_content  ).
        CATCH cx_salv_export_error  INTO ob_ref.
          DATA(lv_long_text) = ob_ref->get_longtext( ).
          IF lv_long_text IS NOT INITIAL.
            MESSAGE lv_long_text TYPE 'S'.
          ENDIF.
      ENDTRY.

      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING
          buffer        = lv_content
        IMPORTING
          output_length = gt_len
        TABLES
          binary_tab    = lt_binary_tab.

      CALL METHOD cl_gui_frontend_services=>gui_download
        EXPORTING
          bin_filesize            = gt_len
          filename                = lv_file_export
          filetype                = lc_bin
        CHANGING
          data_tab                = lt_binary_tab
        EXCEPTIONS
          file_write_error        = 1
          no_batch                = 2
          gui_refuse_filetransfer = 3
          invalid_type            = 4
          no_authority            = 5
          unknown_error           = 6
          header_not_allowed      = 7
          separator_not_allowed   = 8
          filesize_not_allowed    = 9
          header_too_long         = 10
          dp_error_create         = 11
          dp_error_send           = 12
          dp_error_write          = 13
          unknown_dp_error        = 14
          access_denied           = 15
          dp_out_of_memory        = 16
          disk_full               = 17
          dp_timeout              = 18
          file_not_found          = 19
          dataprovider_exception  = 20
          control_flush_error     = 21
          OTHERS                  = 22.

      IF sy-subrc <> 0.
        MESSAGE 'Fail to download output file'(m68)
        TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      ELSE.
        CALL METHOD cl_gui_frontend_services=>execute
          EXPORTING
            document = lv_file_export.
      ENDIF.
    ENDIF.


  ENDMETHOD.
  METHOD repo_save_query.
    DATA : lt_query         TYPE soli_tab,
           ls_query         LIKE LINE OF lt_query,
           lw_query_with_cr TYPE string,
           lw_guid          TYPE guid_32,
           ls_ztoad         TYPE zagtt_sqa_query,
           lw_timestamp(14) TYPE c.

* Set default options
    SELECT SINGLE class INTO ls_options-visibilitygrp
           FROM usr02
           WHERE bname = sy-uname.
    ls_options-visibility = '0'.

* Ask for options / query name
    CALL SCREEN 0200 STARTING AT 10 5
                     ENDING AT 60 7.
    IF ls_options IS INITIAL.
      MESSAGE 'Action cancelled'(m14) TYPE lc_msg_success
              DISPLAY LIKE lc_msg_error.
      RETURN.
    ENDIF.

* Get content of abap edit box
    CALL METHOD ls_tab_active-ob_textedit->get_text ##SUBRC_OK
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.

* Serialize query into a string
    CLEAR lw_query_with_cr.
    LOOP AT lt_query INTO ls_query.
      CONCATENATE lw_query_with_cr ls_query cl_abap_char_utilities=>cr_lf
                  INTO lw_query_with_cr.
    ENDLOOP.

* Generate new GUID
    DO 100 TIMES.
* Old function to get an unique id
*      CALL FUNCTION 'GUID_CREATE'
*        IMPORTING
*          ev_guid_32 = lw_guid.
* New function to get an unique id (do not work on older sap system)
      TRY.
          lw_guid = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          EXIT. "exit do
      ENDTRY.

* Check that this uid is not already used
      SELECT SINGLE queryid INTO ls_ztoad-queryid
             FROM zagtt_sqa_query
             WHERE queryid = lw_guid.
      IF sy-subrc NE 0.
        EXIT. "exit do
      ENDIF.
    ENDDO.

    ls_ztoad-queryid = lw_guid.
    ls_ztoad-owner = sy-uname.
    lw_timestamp(8) = sy-datum.
    lw_timestamp+8 = sy-uzeit.
    ls_ztoad-aedat = lw_timestamp.
    ls_ztoad-text = ls_options-name.
    ls_ztoad-visibility = ls_options-visibility.
    ls_ztoad-visibility_group = ls_options-visibilitygrp.
    ls_ztoad-query = lw_query_with_cr.
    INSERT zagtt_sqa_query FROM ls_ztoad.
    IF sy-subrc = 0.
      MESSAGE s031(r9). "Query saved
    ELSE.
      MESSAGE e220(iqapi). "Error when saving the query
    ENDIF.

* Reset the modified status
    ls_tab_active-ob_textedit->set_textmodified_status( ).

* Refresh repository to display new saved query
    me->repo_fill( ).

* Focus repository on new saved query
    me->repo_focus_query( lw_guid ).
  ENDMETHOD.
  METHOD screen_init_listbox_0200.
    TYPE-POOLS vrm.
    DATA : lt_visibility TYPE vrm_values,
           ls_visibility LIKE LINE OF lt_visibility.
    CONSTANTS lc_id TYPE vrm_id VALUE 'ls_options-VISIBILITY'. "#EC NOTEXT

    FREE lt_visibility.

    ls_visibility-key = lc_visibility_my.
    ls_visibility-text = 'Personal'(m19).
    APPEND ls_visibility TO lt_visibility.

    ls_visibility-key = lc_visibility_shared.
    ls_visibility-text = 'User group'(m20).
    APPEND ls_visibility TO lt_visibility.

    ls_visibility-key = lc_visibility_all.
    ls_visibility-text = 'All'(m21).
    APPEND ls_visibility TO lt_visibility.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = lc_id
        values = lt_visibility.
  ENDMETHOD.

  METHOD  export_xml.
    DATA : BEGIN OF ls_xml,
             line(256) TYPE x,
           END OF ls_xml,
           lt_xml      LIKE TABLE OF ls_xml,

           lw_filename TYPE string,
           lw_path     TYPE string,
           lw_fullpath TYPE string.
    DATA : lo_xml           TYPE REF TO if_ixml,
           lo_document      TYPE REF TO if_ixml_document,
           lo_root          TYPE REF TO if_ixml_element,
           lo_element       TYPE REF TO if_ixml_element,
           lw_string        TYPE string,
           lo_streamfactory TYPE REF TO if_ixml_stream_factory,
           lo_ostream       TYPE REF TO if_ixml_ostream,
           lo_renderer      TYPE REF TO if_ixml_renderer,
           lw_title         TYPE string,
           lw_filter        TYPE string,
           lw_name          TYPE string,
           BEGIN OF ls_ztoad,
             queryid    TYPE zagtt_sqa_query-queryid,
             visibility TYPE zagtt_sqa_query-visibility_group,
             text       TYPE zagtt_sqa_query-text,
             query      TYPE zagtt_sqa_query-query,
           END OF ls_ztoad,
           lt_ztoad LIKE TABLE OF ls_ztoad.

* Ask name of file to generate
    lw_title = 'Choose file to create'(m57).
    lw_filter = 'XML File (*.xml)|*.xml'(m58).
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
      EXPORTING
        window_title = lw_title
        file_filter  = lw_filter
      CHANGING
        path         = lw_path
        filename     = lw_filename
        fullpath     = lw_fullpath
      EXCEPTIONS
        OTHERS       = 1.
    IF sy-subrc NE 0 OR lw_filename IS INITIAL OR lw_path IS INITIAL.
      MESSAGE 'Action cancelled'(m14) TYPE lc_msg_success
              DISPLAY LIKE lc_msg_error.
      RETURN.
    ENDIF.

    CONCATENATE sy-uname '#%' INTO lw_name.
    CONDENSE lw_name NO-GAPS.

* Get all saved query (but not history)
    SELECT queryid visibility text query
           INTO TABLE lt_ztoad
           FROM zagtt_sqa_query
           WHERE owner = sy-uname
           AND NOT queryid LIKE lw_name.

    lo_xml = cl_ixml=>create( ).
    lo_document = lo_xml->create_document( ).

    lo_root  = lo_document->create_simple_element( name = lc_xmlnode_root
                                                   parent = lo_document ).
    LOOP AT lt_ztoad INTO ls_ztoad.
      lo_element  = lo_document->create_simple_element( name = lc_xmlnode_file
                                                        parent = lo_root ).
      lw_string = ls_ztoad-visibility.
      lo_element->set_attribute( name = lc_xmlattr_visibility value = lw_string ).

      lw_string = ls_ztoad-text.
      lo_element->set_attribute( name = lc_xmlattr_text value = lw_string ).

      lw_string = ls_ztoad-query.
      lo_element->set_value( lw_string ).
    ENDLOOP.

    lo_streamfactory = lo_xml->create_stream_factory( ).

    lo_ostream  = lo_streamfactory->create_ostream_itable( lt_xml ).

    lo_renderer = lo_xml->create_renderer( ostream  = lo_ostream
                                           document = lo_document ).
    lo_ostream->set_pretty_print( abap_true ).
    lo_renderer->render( ).

    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename = lw_fullpath
        filetype = 'BIN'
      CHANGING
        data_tab = lt_xml.
  ENDMETHOD.
  METHOD import_xml.
    DATA : lt_filetab       TYPE filetable,
           ls_file          TYPE file_table,
           lw_filename      TYPE string,
           lw_subrc         LIKE sy-subrc,
           lw_xmldata       TYPE xstring,
           lo_xml           TYPE REF TO if_ixml,
           lo_document      TYPE REF TO if_ixml_document,
           lo_streamfactory TYPE REF TO if_ixml_stream_factory,
           lo_stream        TYPE REF TO if_ixml_istream,
           lo_parser        TYPE REF TO if_ixml_parser.
    DATA : lo_iterator  TYPE REF TO if_ixml_node_iterator,
           lo_node      TYPE REF TO if_ixml_node,
           lw_node_name TYPE string,
           lo_element   TYPE REF TO if_ixml_element,
           lw_title     TYPE string,
           lw_filter    TYPE string,
           lw_guid      TYPE guid_32,
           lw_group     TYPE usr02-class,
           lw_string    TYPE string,
           ls_ztoad     TYPE zagtt_sqa_query,
           lt_ztoad     LIKE TABLE OF ls_ztoad.

* Choose file to import
    lw_title = 'Choose file to import'(m59).
    lw_filter = 'XML File (*.xml)|*.xml'(m58).
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
      EXPORTING
        window_title   = lw_title
        file_filter    = lw_filter
        multiselection = space
      CHANGING
        file_table     = lt_filetab
        rc             = lw_subrc.

* Check user action (1 OPEN, 2 CANCEL)
    IF lw_subrc NE 1.
      MESSAGE 'Action cancelled'(m14) TYPE lc_msg_success
              DISPLAY LIKE lc_msg_error.
      RETURN.
    ENDIF.

* Read filetable
    READ TABLE lt_filetab INTO ls_file INDEX 1.
    lw_filename = ls_file-filename.

* Get xml flow from file
* Or alternatively (if method does not exist) use the method
* cl_gui_frontend_services=>gui_upload and then convert the
* x-tab to xstring
    TRY.
        lw_xmldata = cl_openxml_helper=>load_local_file( lw_filename ).
      CATCH cx_openxml_not_found.
        MESSAGE 'Error when opening the input XML file'(m60)
                TYPE lc_msg_error.
        RETURN.
    ENDTRY.

    lo_xml = cl_ixml=>create( ).

    lo_document = lo_xml->create_document( ).
    lo_streamfactory = lo_xml->create_stream_factory( ).
    lo_stream = lo_streamfactory->create_istream_xstring( string = lw_xmldata ).

    lo_parser = lo_xml->create_parser( stream_factory = lo_streamfactory
                                       istream        = lo_stream
                                       document       = lo_document ).
*-- parse the stream
    IF lo_parser->parse( ) NE 0.
      IF lo_parser->num_errors( ) NE 0.
        MESSAGE 'Error when parsing the input XML file'(m61)
                TYPE lc_msg_error.
        RETURN.
      ENDIF.
    ENDIF.

*-- we don't need the stream any more, so let's close it...
    CALL METHOD lo_stream->close( ).
    CLEAR lo_stream.

* Get usergroup
    SELECT SINGLE class INTO lw_group
           FROM usr02
           WHERE bname = sy-uname.

* Rebuild itab t_zspro
    lo_iterator = lo_document->create_iterator( ).
    lo_node = lo_iterator->get_next( ).
    WHILE NOT lo_node IS INITIAL.
      lw_node_name = lo_node->get_name( ).
      IF lw_node_name = lc_xmlnode_file.
* Cast node to element
        lo_element ?= lo_node. "->query_interface( ixml_iid_element ).
        CLEAR ls_ztoad.
        ls_ztoad-visibility_group = lw_group.
        ls_ztoad-owner = sy-uname.
        CONCATENATE sy-datum sy-uzeit INTO lw_string.
        ls_ztoad-aedat = lw_string.

* Generate new GUID
        DO 100 TIMES.
* Old function to get an unique id
*          CALL FUNCTION 'GUID_CREATE'
*            IMPORTING
*              ev_guid_32 = lw_guid.
* New function to get an unique id (do not work on older sap system)
          TRY.
              lw_guid = cl_system_uuid=>create_uuid_c32_static( ).
            CATCH cx_uuid_error.
              EXIT. "exit do
          ENDTRY.

* Check that this uid is not already used
          SELECT SINGLE queryid INTO ls_ztoad-queryid
                 FROM zagtt_sqa_query
                 WHERE queryid = lw_guid.
          IF sy-subrc NE 0.
            READ TABLE lt_ztoad WITH KEY queryid = lw_guid TRANSPORTING NO FIELDS.
            IF sy-subrc NE 0.
              EXIT. "exit do
            ENDIF.
          ENDIF.
        ENDDO.
        ls_ztoad-queryid = lw_guid.
        lw_string = lo_element->get_attribute( name = lc_xmlattr_visibility ).
        ls_ztoad-visibility = lw_string.
        lw_string = lo_element->get_attribute( name = lc_xmlattr_text ).
        ls_ztoad-text = lw_string.
        lw_string = lo_element->get_value( ).
        ls_ztoad-query = lw_string.
        APPEND ls_ztoad TO lt_ztoad.
      ENDIF.
      lo_node = lo_iterator->get_next( ).
    ENDWHILE.

    INSERT zagtt_sqa_query FROM TABLE lt_ztoad.
    IF sy-subrc = 0.
      MESSAGE s031(r9). "Query saved
    ELSE.
      MESSAGE e220(iqapi). "Error when saving the query
    ENDIF.

* Refresh repository to display new saved query
    me->repo_fill( ).

  ENDMETHOD.
  METHOD clear_screen.
    IF  ls_tab_active-ob_textedit IS BOUND.
      ls_tab_active-ob_textedit->delete_text( from_line = 1
                                             from_pos = 1
                                             to_line = 100
                                             to_pos = 200  ).
    ENDIF.
  ENDMETHOD.

*********************************************************************
  METHOD hnd_repo_context_menu.
    DATA l_node_key TYPE tv_nodekey.

    CALL METHOD ob_tree_repository->get_selected_node
      IMPORTING
        node_key = l_node_key.
* For History node, add a "delete all" entry
* Only if there is at least 1 history entry
    IF l_node_key = 'HISTO'.
      READ TABLE t_node_repository TRANSPORTING NO FIELDS
        WITH KEY relatkey = 'HISTO'.
      IF sy-subrc = 0.
        CALL METHOD menu->add_function
          EXPORTING
            text  = 'Delete All'(m36)
            icon  = '@02@'
            fcode = 'DELETE_HIST'.
      ENDIF.
      RETURN.
    ENDIF.

* Add Delete option only for own queries
    READ TABLE t_node_repository INTO s_node_repository
               WITH KEY node_key = l_node_key.
    IF sy-subrc NE 0 OR s_node_repository-edit = space.
      RETURN.
    ENDIF.

    CALL METHOD menu->add_function
      EXPORTING
        text  = 'Delete'(m01)
        icon  = '@02@'
        fcode = 'DELETE_QUERY'.
  ENDMETHOD.                    "hnd_repo_context_menu

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_repo_context_menu_sel
*&---------------------------------------------------------------------*
*       Handle context menu clic on repository tree
*----------------------------------------------------------------------*
  METHOD hnd_repo_context_menu_sel.
    DATA : l_node_key TYPE tv_nodekey,
           l_subrc    TYPE i,
           ls_histo   LIKE s_node_repository,
           lw_queryid LIKE ls_histo-queryid.
* Delete stored query
    CASE fcode.
      WHEN 'DELETE_QUERY'.
        CALL METHOD ob_tree_repository->get_selected_node
          IMPORTING
            node_key = l_node_key.
        me->repo_delete_history( EXPORTING fw_node_key = l_node_key
                                  CHANGING fw_subrc = l_subrc ).
        IF l_subrc = 0.
          MESSAGE 'Query deleted'(m02) TYPE lc_msg_success.
        ELSE.
          MESSAGE 'Error when deleting the query'(m03)
                  TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
          RETURN.
        ENDIF.

      WHEN 'DELETE_HIST'.
        CONCATENATE sy-uname '+++' INTO lw_queryid.
        LOOP AT t_node_repository INTO ls_histo
                WHERE queryid CP lw_queryid.
          me->repo_delete_history( EXPORTING fw_node_key = ls_histo-node_key
                                   CHANGING  fw_subrc = l_subrc ).
          IF l_subrc NE 0.
            MESSAGE 'Error when deleting the query'(m03)
                    TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
            RETURN.
          ENDIF.
        ENDLOOP.
        MESSAGE 'All history entries deleted'(m37) TYPE lc_msg_success.
    ENDCASE.
  ENDMETHOD.                    "hnd_repo_context_menu_sel

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_editor_f1
*&---------------------------------------------------------------------*
*       Handle F1 call on ABAP editor
*----------------------------------------------------------------------*
  METHOD hnd_editor_f1.
    DATA : lw_cursor_line_from TYPE i,
           lw_cursor_line_to   TYPE i,
           lw_cursor_pos_from  TYPE i,
           lw_cursor_pos_to    TYPE i,
           lw_offset           TYPE i,
           lw_length           TYPE i,
           lt_query            TYPE soli_tab,
           ls_query            LIKE LINE OF lt_query,
           lw_sel              TYPE string.

* Find active query
    CALL METHOD ls_tab_active-ob_textedit->get_selection_pos
      IMPORTING
        from_line = lw_cursor_line_from
        from_pos  = lw_cursor_pos_from
        to_line   = lw_cursor_line_to
        to_pos    = lw_cursor_pos_to.

* If nothing selected, no help to display
    IF lw_cursor_line_from = lw_cursor_line_to
    AND lw_cursor_pos_to = lw_cursor_pos_from.
      RETURN.
    ENDIF.

* Get content of abap edit box
    CALL METHOD ls_tab_active-ob_textedit->get_text ##SUBRC_OK
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.


    READ TABLE lt_query INTO ls_query INDEX lw_cursor_line_from.
    IF lw_cursor_line_from = lw_cursor_line_to.
      lw_length = lw_cursor_pos_to - lw_cursor_pos_from.
      lw_offset = lw_cursor_pos_from - 1.
      lw_sel = ls_query+lw_offset(lw_length).
    ELSE.
      lw_offset = lw_cursor_pos_from - 1.
      lw_sel = ls_query+lw_offset.
    ENDIF.
    CALL FUNCTION 'ABAP_DOCU_START'
      EXPORTING
        word = lw_sel.
  ENDMETHOD.                    "hnd_editor_f1

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_item_dblclick
*&---------------------------------------------------------------------*
*       Handle Node double clic on ddic tree
*----------------------------------------------------------------------*
  METHOD hnd_ddic_item_dblclick.
    DATA : ls_node       LIKE LINE OF ls_tab_active-lt_node_ddic,
           lw_line_start TYPE i,
           lw_pos_start  TYPE i,
           lw_line_end   TYPE i,
           lw_pos_end    TYPE i,
           lw_data       TYPE string.

* Check clicked node is valid
    READ TABLE ls_tab_active-lt_node_ddic INTO ls_node
               WITH KEY node_key = node_key.
    IF sy-subrc NE 0 OR ls_node-isfolder = abap_true.
      RETURN.
    ENDIF.

* Get text for the node selected
*    PERFORM ddic_get_field_from_node USING node_key ls_node-relatkey
*                                     CHANGING lw_data.
    me->ddic_get_field_from_node( EXPORTING  fw_node_key = node_key
                                             fw_relat_key =  ls_node-relatkey
                                        CHANGING  fw_text = lw_data ).

* Get current cursor position/selection in editor
    CALL METHOD ls_tab_active-ob_textedit->get_selection_pos
      IMPORTING
        from_line = lw_line_start
        from_pos  = lw_pos_start
        to_line   = lw_line_end
        to_pos    = lw_pos_end
      EXCEPTIONS
        OTHERS    = 4.
    IF sy-subrc NE 0.
      MESSAGE 'Cannot get cursor position'(m35) TYPE lc_msg_error.
    ENDIF.

*   If text is selected/highlighted, delete it
    IF lw_line_start NE lw_line_end
    OR lw_pos_start NE lw_pos_end.
      CALL METHOD ls_tab_active-ob_textedit->delete_text
        EXPORTING
          from_line = lw_line_start
          from_pos  = lw_pos_start
          to_line   = lw_line_end
          to_pos    = lw_pos_end.
    ENDIF.

    me->editor_paste( EXPORTING fw_text = lw_data
                                 fw_line =   lw_line_start
                                 fw_pos =  lw_pos_start ).
  ENDMETHOD.                    "hnd_ddic_item_dblclick

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_repo_dblclick
*&---------------------------------------------------------------------*
*       Handle Node double clic on repository tree
*----------------------------------------------------------------------*
  METHOD hnd_repo_dblclick.
    DATA lt_query TYPE TABLE OF string.
    READ TABLE t_node_repository INTO s_node_repository
               WITH KEY node_key = node_key.
    IF sy-subrc = 0 AND NOT s_node_repository-relatkey IS INITIAL.
      me->query_load( EXPORTING fw_queryid = s_node_repository-queryid
                         CHANGING ft_query = lt_query ).

      CALL METHOD ls_tab_active-ob_textedit->set_text
        EXPORTING
          table  = lt_query
        EXCEPTIONS
          OTHERS = 0.
      me->ddic_refresh_tree( ).
    ENDIF.
  ENDMETHOD. "hnd_repo_dblclick

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_result_toolbar
*&---------------------------------------------------------------------*
*       Handle grid toolbar to add specific button
*----------------------------------------------------------------------*
  METHOD hnd_result_toolbar.
    DATA: ls_toolbar  TYPE stb_button.

* Add Separator
    CLEAR ls_toolbar.
    ls_toolbar-function = '&&SEP99'.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

* Add button to close the grid
    CLEAR ls_toolbar.
    ls_toolbar-function = 'CLOSE_GRID'.
    ls_toolbar-icon = '@3X@'.
    ls_toolbar-quickinfo = 'Close Grid'(m05).
    ls_toolbar-text = 'Close'(m06).
    ls_toolbar-butn_type = 0.
    ls_toolbar-disabled = space.
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.                    "hnd_result_toolbar

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_result_user_command
*&---------------------------------------------------------------------*
*       Handle grid user command to manage specific fcode
*       (menus & toolbar)
*----------------------------------------------------------------------*
  METHOD hnd_result_user_command.
    IF e_ucomm = 'CLOSE_GRID'.
      CALL METHOD ob_splitter->set_row_height
        EXPORTING
          id     = 1
          height = 100.
    ENDIF.
  ENDMETHOD. "hnd_result_user_command

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_drag
*&---------------------------------------------------------------------*
*       Handle drag on DDIC field (store fieldname)
*----------------------------------------------------------------------*
  METHOD hnd_ddic_drag.
    DATA : lo_drag_object TYPE REF TO lcl_drag_object,
           ls_node        LIKE LINE OF ls_tab_active-lt_node_ddic,
           lw_text        TYPE string.

    READ TABLE ls_tab_active-lt_node_ddic INTO ls_node
               WITH KEY node_key = node_key.
    IF sy-subrc NE 0 OR ls_node-isfolder = abap_true. "may not append
      MESSAGE 'Only fields can be drag&drop to editor'(m34)
               TYPE lc_msg_success DISPLAY LIKE lc_msg_error.
      RETURN.
    ENDIF.

* Get text for the node selected
    me->ddic_get_field_from_node( EXPORTING fw_node_key = node_key
                                            fw_relat_key = ls_node-relatkey
                                    CHANGING fw_text = lw_text ).

* Store the node text
    CREATE OBJECT lo_drag_object.
    lo_drag_object->field = lw_text.
    drag_drop_object->object = lo_drag_object.

  ENDMETHOD."hnd_ddic_drag

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_editor_drop
*&---------------------------------------------------------------------*
*       Handle drop on SQL Editor : paste fieldname at cursor position
*----------------------------------------------------------------------*
  METHOD hnd_editor_drop.
    DATA lo_drag_object TYPE REF TO lcl_drag_object.

    lo_drag_object ?= dragdrop_object->object.
    IF lo_drag_object IS INITIAL OR lo_drag_object->field IS INITIAL.
      RETURN.
    ENDIF.

* Paste fieldname to editor at drop position
    me->editor_paste( EXPORTING fw_text = lo_drag_object->field
                                fw_line = line
                                fw_pos =  pos ).

  ENDMETHOD."hnd_editor_drop

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_toolbar_clic
*&---------------------------------------------------------------------*
*       Handle DDIC toolbar button clic
*----------------------------------------------------------------------*
  METHOD hnd_ddic_toolbar_clic.

    CASE fcode.
      WHEN 'REFRESH'.
        me->ddic_refresh_tree( ).
      WHEN 'FIND'.
        me->ddic_find_in_tree( ).
      WHEN 'F4'.
        me->ddic_f4( ).
    ENDCASE.
  ENDMETHOD.


ENDCLASS.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  DATA ob_screen TYPE REF TO lcl_sqa_enhance_editor.
  IF ob_screen IS NOT BOUND.
    ob_screen = NEW lcl_sqa_enhance_editor( ).
    ob_screen->initialise_screen( ).

    SET PF-STATUS 'STATUS100'.
    SET TITLEBAR 'TITLE100'.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  IF ob_screen IS BOUND.
    CASE sy-ucomm.
      WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
        ob_screen->screen_exit( ).
      WHEN 'EXECUTE'.
        ob_screen->query_process( EXPORTING fw_display = space
                                            fw_download = space ).
      WHEN 'DOWNLOAD'.
        ob_screen->query_process( EXPORTING fw_display = space
                                            fw_download = abap_true ).
      WHEN 'SAVE'.
        ob_screen->repo_save_query( ).
      WHEN 'CLEAR'.
        ob_screen->clear_screen( ).
      WHEN 'XML'.
        ob_screen->export_xml( ).
      WHEN 'XML1'.
        ob_screen->import_xml( ).
      WHEN OTHERS.
        IF sy-ucomm(3) = 'TAB' AND w_tabstrip-activetab NE sy-ucomm.
          ob_screen->leave_current_tab( ).

          READ TABLE t_tabs INTO ls_tab_active INDEX sy-ucomm+3.
* Display editor / ddic / alv
          CALL METHOD ls_tab_active-ob_textedit->set_visible
            EXPORTING
              visible = abap_true.
          CALL METHOD ls_tab_active-ob_tree_ddic->set_visible
            EXPORTING
              visible = abap_true.
          IF NOT ls_tab_active-ob_alv_result IS INITIAL.
            CALL METHOD ls_tab_active-ob_alv_result->set_visible
              EXPORTING
                visible = abap_true.
          ENDIF.
          CALL METHOD ob_splitter->set_row_height
            EXPORTING
              id     = 1
              height = ls_tab_active-lv_row_height.
          w_tabstrip-activetab = sy-ucomm.
        ENDIF.
    ENDCASE.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  IF ob_screen IS BOUND.
    ob_screen->screen_init_listbox_0200( ).
    SET PF-STATUS 'STATUS200'.
    SET TITLEBAR 'T200'.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  IF ob_screen IS BOUND.
    CASE sy-ucomm.
      WHEN 'CLOSE'.
        CLEAR ls_options.
        LEAVE TO SCREEN 0.
      WHEN 'OK'.
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDIF.

ENDMODULE.
