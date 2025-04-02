*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_TOOLKIT_C04
*&---------------------------------------------------------------------*
CLASS lcl_sqa_file_viewer DEFINITION.
  PUBLIC SECTION.
    DATA: mv_file                TYPE char255,
          mv_replac              TYPE char255,
          mv_fileto              TYPE char255,
          mv_makecp              TYPE char1,
          mv_chgall              TYPE char1,
          mv_single              TYPE char1,
          mv_find                TYPE char1,
          mv_fullfile            TYPE string,
          mv_data                TYPE string,
          mv_datax               TYPE xstring,
          mv_unixmsg             TYPE char50,
          mt_dlist               TYPE TABLE OF epsfili,
          mv_op_length           TYPE i,
          mt_binary              TYPE STANDARD TABLE OF x255,
          mv_data_text           TYPE string,
          mt_string_t            TYPE string_t,
          mv_encrypted_file_name TYPE string,
          mv_decrypted_file_name TYPE string,
          mv_msg                 TYPE char50,
          mv_str                 TYPE string,
          mv_check_file          TYPE fileextern.
    CONSTANTS : mc_e TYPE char1 VALUE 'E',
                mc_s TYPE char1 VALUE 'S'.
    METHODS: constructor,
      file_viewer.
  PRIVATE SECTION.
    METHODS: get_file_list,
      open_infiles CHANGING lv_file TYPE any,
      file_to_string CHANGING lv_file TYPE any,
      find_text CHANGING lv_file TYPE any,
      change_text  CHANGING lv_file TYPE any,
      clear_variable.
ENDCLASS.
CLASS lcl_sqa_file_viewer IMPLEMENTATION.
  METHOD constructor.
    mv_file = p_file.
    mv_replac = p_replac.
    mv_fileto = p_fileto.
    mv_makecp = p_makecp.
    mv_chgall = p_chgall.
    mv_single = p_single.
    mv_find   = p_find.

    IF mv_file IS INITIAL.
      MESSAGE TEXT-m06
      TYPE mc_s DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ELSEIF mv_replac IS INITIAL AND mv_find IS INITIAL.
      MESSAGE TEXT-m07
      TYPE mc_s DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.
  METHOD file_viewer.
    IF mv_chgall IS NOT INITIAL.
      me->get_file_list( ).
      LOOP AT mt_dlist INTO DATA(ls_dlist).
        CONCATENATE mv_file '/' ls_dlist-name INTO mv_fullfile.
        me->open_infiles( CHANGING lv_file =  mv_fullfile ).
        IF mv_unixmsg IS NOT INITIAL.
          CLEAR mv_unixmsg.
          CONTINUE.
        ENDIF.
        me->file_to_string( CHANGING lv_file = mv_fullfile ).
        mv_datax = mv_data.
        IF mv_find IS NOT INITIAL.
          mv_fileto = ''.
          me->find_text( CHANGING lv_file = mv_fullfile ). " Find text
        ELSE.
          me->change_text( CHANGING lv_file = mv_fullfile ).  "replace text
        ENDIF.
        me->clear_variable( ).
      ENDLOOP.
    ELSEIF mv_single IS NOT INITIAL.
      me->open_infiles( CHANGING lv_file = mv_file ).

      me->file_to_string( CHANGING lv_file = mv_file ).
      mv_datax = mv_data.
      IF mv_find IS NOT INITIAL.
        mv_fileto = ''.
        me->find_text( CHANGING lv_file = mv_fullfile ).

      ELSE.
        me->change_text( CHANGING lv_file = mv_file )."replace text on single file
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD get_file_list.
    DATA: lv_file TYPE epsf-epsdirnam.
    lv_file = mv_file.

    CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'
      EXPORTING
        dir_name               = lv_file
      TABLES
        dir_list               = mt_dlist
      EXCEPTIONS
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        read_directory_failed  = 5
        too_many_read_errors   = 6
        empty_directory_list   = 7
        OTHERS                 = 8.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE TEXT-m08 TYPE mc_s
      DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.
  METHOD open_infiles.
    DATA: l_sysid       TYPE char3.
    CLEAR mv_check_file.
    mv_check_file  = lv_file.

    l_sysid = sy-sysid(3).

    CALL FUNCTION 'AUTHORITY_CHECK_DATASET'
      EXPORTING
        activity         = 'READ'
        filename         = mv_check_file
      EXCEPTIONS
        no_authority     = 1
        activity_unknown = 2
        OTHERS           = 3.
    IF sy-subrc  IS INITIAL.

      OPEN DATASET lv_file FOR INPUT IN TEXT MODE MESSAGE mv_unixmsg
                   ENCODING DEFAULT IGNORING CONVERSION ERRORS.

      IF mv_unixmsg IS NOT INITIAL.
        DATA(lv_msg) = |{ mv_unixmsg } |
        & |Error while opening  | & |{ lv_file }| .
        MESSAGE lv_msg TYPE mc_s DISPLAY LIKE mc_e.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ELSE.
      MESSAGE 'No Authorization ' TYPE mc_s DISPLAY LIKE mc_e.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDMETHOD.
  METHOD file_to_string.
    DATA  lv_string TYPE string.
    DO.
      READ DATASET lv_file INTO lv_string.
      IF sy-subrc = 0.
        IF mv_data IS INITIAL.
          mv_data = lv_string.
        ELSE.
          mv_data = |{ mv_data }{ cl_abap_char_utilities=>newline }{ lv_string }|.  "To keep current format

        ENDIF.
      ELSE.
        EXIT. "required or else infinite loop
      ENDIF.
    ENDDO.

    CLOSE DATASET lv_file.
    CLEAR: lv_string.

  ENDMETHOD.
  METHOD find_text.
    DATA: lv_message_decrypted TYPE xstring,
          lv_offset            TYPE i,
          lv_length            TYPE i,
          lv_found             TYPE string.


    DATA: result_tab TYPE match_result_tab.

    FIELD-SYMBOLS <match> LIKE LINE OF result_tab.

    "Converting the data - From string format to xstring.
*    TRY.
    mv_datax = cl_bcs_convert=>string_to_xstring(
    iv_string = mv_data    " Input data
  ).
*      CATCH cx_bcs INTO DATA(lo_msg).
*        IF lo_msg IS BOUND.
*          MESSAGE lo_msg->get_text( ) TYPE mc_e.
*        ENDIF.
*    ENDTRY.




    "Convert from xstring to binary so we can keep unicode characters
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = mv_datax
      IMPORTING
        output_length = mv_op_length
      TABLES
        binary_tab    = mt_binary.
    IF mt_binary IS NOT INITIAL.

      "then Binary to string
      CALL FUNCTION 'SCMS_BINARY_TO_STRING'
        EXPORTING
          input_length = mv_op_length
        IMPORTING
          text_buffer  = mv_data_text
        TABLES
          binary_tab   = mt_binary
        EXCEPTIONS
          failed       = 1
          OTHERS       = 2.
      IF sy-subrc  IS INITIAL.

        APPEND mv_data_text TO mt_string_t.
*  IF p_makecp IS NOT INITIAL.
*    CONCATENATE p_file '.copy' INTO v_decrypted_file_name.
*  ELSE.
*    v_decrypted_file_name = p_file.
*  ENDIF.
**  CONDENSE v_decrypted_file_name.
*  OPEN DATASET v_decrypted_file_name IN TEXT MODE FOR OUTPUT MESSAGE v_msg ENCODING DEFAULT IGNORING CONVERSION ERRORS.

*  IF v_msg IS INITIAL.
        "Loop at all the line
        LOOP AT mt_string_t INTO mv_str.  "will be 1 unless 'select all files' is checked

          IF mv_replac IS NOT INITIAL.
*
            FIND ALL OCCURRENCES OF mv_replac IN mv_str RESULTS result_tab.
            IF result_tab IS NOT INITIAL.
              FORMAT COLOR COL_POSITIVE.
              WRITE: 'Found in: ', mv_file, /.

              LOOP AT result_tab ASSIGNING <match>.  "there can be multiple occurances of the same text per file

                lv_offset = <match>-offset - 25.
                IF lv_offset < 0.
                  lv_offset = 1.
                ENDIF.
                lv_length = <match>-length + 100.

                CATCH SYSTEM-EXCEPTIONS OTHERS = 1.
                  lv_found = mv_str+lv_offset(lv_length).
                ENDCATCH.
                IF sy-subrc <> 0.
                  lv_found = mv_str+<match>-offset(<match>-length).
                ELSE.
                  lv_found = mv_str+lv_offset(lv_length).
                ENDIF.



                FORMAT COLOR COL_TOTAL.
                WRITE: sy-tabix, ' : ', lv_found, /.

              ENDLOOP.
              CLEAR: result_tab.
            ENDIF.
          ELSEIF mv_replac IS INITIAL.
*            DATA lt_output TYPE STANDARD TABLE OF tdline.
*            LV_STR1 = CONV #( MV_STR ).
*            CALL FUNCTION 'RKD_WORD_WRAP'
*              EXPORTING
*                textline  = LV_STR1
*               DELIMITER = ' '
*                outputlen = 128
*             IMPORTING
*               OUT_LINE1 =
*               OUT_LINE2 =
*               OUT_LINE3 =
*              TABLES
*                out_lines = lt_output
*             EXCEPTIONS
*               OUTPUTLEN_TOO_LARGE       = 1
*               OTHERS    = 2
*              .
*            IF sy-subrc <> 0.
* Implement suitable error handling here
*            ENDIF.
            cl_demo_output=>display( mt_string_t ).
*            WRITE : mv_str , /.
          ENDIF.
        ENDLOOP.

        CLOSE DATASET mv_file.
      ENDIF.
    ENDIF.
    CLEAR: mv_str, mt_string_t.
  ENDMETHOD.
  METHOD change_text.
    DATA: lv_message_decrypted TYPE xstring.

    "Converting the data - From string format to xstring. You can use any other method or function module which converts the string to xstring format
    TRY.
        mv_datax = cl_bcs_convert=>string_to_xstring(
        iv_string = mv_data    " Input data
      ).
      CATCH cx_bcs INTO DATA(lo_msg1).
        IF lo_msg1 IS BOUND.
          MESSAGE lo_msg1->get_text( ) TYPE mc_e.
        ENDIF.
    ENDTRY.


    "Convert from xstring to binary so we can keep unicode characters
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = mv_datax
      IMPORTING
        output_length = mv_op_length
      TABLES
        binary_tab    = mt_binary.
    IF mt_binary IS NOT INITIAL.

      "then Binary to string
      CALL FUNCTION 'SCMS_BINARY_TO_STRING'
        EXPORTING
          input_length = mv_op_length
        IMPORTING
          text_buffer  = mv_data_text
        TABLES
          binary_tab   = mt_binary
        EXCEPTIONS
          failed       = 1
          OTHERS       = 2.
      IF sy-subrc IS INITIAL.

        APPEND mv_data_text TO mt_string_t.
        IF mv_makecp IS NOT INITIAL.
          CONCATENATE mv_file '.copy'
          INTO mv_decrypted_file_name.
        ELSE.
          mv_decrypted_file_name = p_file.
        ENDIF.
*  CONDENSE v_decrypted_file_name.

        CLEAR mv_check_file.
        mv_check_file  = lv_file.
        CALL FUNCTION 'AUTHORITY_CHECK_DATASET'
          EXPORTING
            activity         = 'WRITE'
            filename         = mv_check_file
          EXCEPTIONS
            no_authority     = 1
            activity_unknown = 2
            OTHERS           = 3.
        IF sy-subrc  IS INITIAL.
          OPEN DATASET mv_decrypted_file_name
          IN TEXT MODE FOR OUTPUT MESSAGE mv_msg
          ENCODING DEFAULT IGNORING CONVERSION ERRORS.

          IF mv_msg IS INITIAL.
            "Loop at all the line
            LOOP AT mt_string_t INTO mv_str.
              REPLACE ALL OCCURRENCES OF mv_replac IN mv_str WITH p_fileto.
              IF sy-subrc = 0.
                IF mv_makecp IS INITIAL.
                  FORMAT COLOR COL_POSITIVE.
                  WRITE:mv_file, 'Updated Successfully.', /.
                ELSE.
                  FORMAT COLOR COL_POSITIVE.
                  WRITE: mv_file, 'Modified Copy created Successfully.', /.
                ENDIF.
              ELSE.
                FORMAT COLOR COL_TOTAL.
                WRITE: 'No change for: ', mv_file, /.
              ENDIF.
              TRANSFER mv_str TO mv_decrypted_file_name.
            ENDLOOP.

            CLOSE DATASET mv_file.
          ELSE.
            CONDENSE mv_msg.
            FORMAT COLOR COL_NEGATIVE.
            WRITE:'Error found for file: ', mv_decrypted_file_name, ' ', mv_msg, /.
            CLEAR: mv_msg.
          ENDIF.
        ELSE.
          MESSAGE 'No Authorization ' TYPE mc_s DISPLAY LIKE mc_e.
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD clear_variable.
    FREE: mt_string_t,
       mt_binary.

    CLEAR:
      mv_data,
      mv_data_text,
      mv_datax,
      mv_encrypted_file_name,
      mv_decrypted_file_name,
      mv_str,
      mv_op_length,
      mv_unixmsg.
  ENDMETHOD.
ENDCLASS.
