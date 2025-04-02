*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_DISPLAY
*&---------------------------------------------------------------------*
CLASS lcl_sqa_display DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS : display IMPORTING iv_varia TYPE disvariant-variant OPTIONAL
                            CHANGING  im_itab  TYPE STANDARD TABLE ,
      f4_layout CHANGING cv_varia TYPE disvariant-variant.
ENDCLASS.
CLASS lcl_sqa_display IMPLEMENTATION.
  METHOD display.

    DATA : lr_table   TYPE REF TO cl_salv_table,
           lr_columns TYPE REF TO cl_salv_columns_table,
           lr_layout  TYPE REF TO cl_salv_layout.
    DATA : lv_string    TYPE string,
           lo_msg       TYPE REF TO cx_salv_msg,
           ls_key       TYPE salv_s_layout_key,
           lr_functions TYPE REF TO cl_salv_functions_list,
           lc_i         TYPE char1 VALUE 'E'.

*Get New Instance for ALV Table Object
    TRY.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = lr_table
          CHANGING
            t_table      = im_itab.

      CATCH cx_salv_msg INTO lo_msg .
        lv_string = lo_msg->get_text( ).
        MESSAGE lv_string TYPE lc_i.
    ENDTRY.

*Set all toolbar functions
    lr_functions = lr_table->get_functions( ).
    lr_functions->set_all( abap_true ).
    lr_columns = lr_table->get_columns( ).
    lr_columns->set_optimize(  ).


    ls_key-report = sy-repid.                                       " saving layout
    lr_layout = lr_table->get_layout( ).
    lr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
    lr_layout->set_key( ls_key ).

    IF iv_varia IS NOT INITIAL.                                       " setting layout that is selected in selection screen
      lr_layout->set_initial_layout( iv_varia ).
    ENDIF.


    lr_table->display( ).


  ENDMETHOD.
  METHOD f4_layout.

    DATA: ls_layout  TYPE salv_s_layout_info,
          ls_key     TYPE salv_s_layout_key,
          i_restrict TYPE salv_de_layout_restriction.

    ls_key-report = sy-repid.

    ls_layout = cl_salv_layout_service=>f4_layouts(
    s_key    = ls_key
    restrict = i_restrict ).

    cv_varia = ls_layout-layout.

  ENDMETHOD.
ENDCLASS.
