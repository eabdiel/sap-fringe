*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_TOOLKIT_C03
*&---------------------------------------------------------------------*
CLASS lcl_last_change_report DEFINITION.
  PUBLIC SECTION.
    TYPES: lty_pname  TYPE RANGE OF d010sinf-prog,
           lty_athgrp TYPE RANGE OF d010sinf-secu,
           lty_chgby  TYPE RANGE OF d010sinf-unam,
           lty_chgon  TYPE RANGE OF d010sinf-udat,
           lty_crtby  TYPE RANGE OF d010sinf-cnam,
           lty_crton  TYPE RANGE OF d010sinf-cdat,
           BEGIN OF lty_d010,
             prog TYPE d010sinf-prog,
             secu TYPE d010sinf-secu,
             cnam TYPE d010sinf-cnam,
             cdat TYPE d010sinf-cdat,
             unam TYPE d010sinf-unam,
             udat TYPE d010sinf-udat,
           END OF lty_d010.
    DATA :mt_pname  TYPE  lty_pname,
          mt_athgrp TYPE  lty_athgrp,
          mt_chgby  TYPE  lty_chgby,
          mt_chgon  TYPE  lty_chgon,
          mt_crtby  TYPE  lty_crtby,
          mt_crton  TYPE  lty_crton,
          mt_table  TYPE TABLE OF lty_d010.
    CONSTANTS : mc_e TYPE char1 VALUE 'E',
                mc_s TYPE char1 VALUE 'S'.
    METHODS: constructor,
      last_change_report.
  PRIVATE SECTION.
    METHODS: get_data,
      display_data.
ENDCLASS.
CLASS lcl_last_change_report IMPLEMENTATION.
  METHOD constructor.
    mt_pname = s_pname[].
    mt_athgrp = s_athgrp[].
    mt_chgby = s_chgby[].
    mt_chgon = s_chgon[].
    mt_crtby = s_crtby[].
    mt_crton = s_crton[].

    IF mt_pname IS INITIAL
      AND mt_athgrp IS INITIAL
      AND mt_chgby  IS INITIAL
      AND mt_chgon  IS INITIAL
      AND mt_crtby  IS INITIAL
      AND mt_crton  IS INITIAL.
      MESSAGE TEXT-m04
      TYPE mc_s DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDMETHOD.
  METHOD last_change_report.
    me->get_data( ).
    me->display_data( ).
  ENDMETHOD.
  METHOD get_data.

    SELECT prog
           secu
           cnam
           cdat
           unam
           udat
       FROM d010sinf
   INTO TABLE mt_table
   WHERE
   prog IN mt_pname AND
   secu IN mt_athgrp AND
   unam IN mt_chgby AND
   udat IN mt_chgon AND
   cnam IN mt_crtby AND
   cdat IN mt_crton.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE TEXT-m05 TYPE mc_s
      DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDMETHOD.
  METHOD display_data.
    CONSTANTS: lc_text_type TYPE lvc_ddict VALUE 'M',
               lc_secu      TYPE lvc_fname VALUE 'SECU',
               lc_secu_text TYPE scrtext_m
               VALUE 'Authorization Group'. "#EC NOTEXT

    TRY.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = DATA(lr_table)
          CHANGING
            t_table      = mt_table.
      CATCH cx_salv_msg  INTO DATA(lo_msg).
        MESSAGE lo_msg->get_text( ) TYPE mc_e
        DISPLAY LIKE mc_s.
    ENDTRY.

    TRY.
* Set tool bar function
        DATA(lr_funct) = lr_table->get_functions( ).
        lr_funct->set_all( abap_true ).
* set Alv Heading
        DATA(lr_display) = lr_table->get_display_settings( ).
        lr_display->set_list_header( TEXT-s19 ).
* Optimize column width
        DATA(lr_columns) = lr_table->get_columns( ).
        lr_columns->set_optimize( abap_true ).
* change column name
        DATA(l_column) = lr_columns->get_column( lc_secu ).
        l_column->set_fixed_header_text( lc_text_type ).
        l_column->set_medium_text( lc_secu_text ).
      CATCH cx_salv_not_found INTO DATA(lo_msg_s).
        MESSAGE lo_msg_s->get_text( ) TYPE mc_e DISPLAY LIKE mc_s.
    ENDTRY.

    lr_table->display( ).

  ENDMETHOD.

ENDCLASS.
