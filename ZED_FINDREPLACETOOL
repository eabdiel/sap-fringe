**********************************************************************
*&---------------------------------------------------------------------*
*& Report
*&
*&---------------------------------------------------------------------*
*&
*& This utility program will find and replace a string on an external file
*&---------------------------------------------------------------------*
REPORT z80spectrum_unixpathchange        NO STANDARD PAGE HEADING
        MESSAGE-ID zf
        LINE-SIZE  150
        LINE-COUNT 58(0).

TABLES: rlgrap.
TYPE-POOLS: abap.

DATA: i_string_t            TYPE string_t, "to convert back and forth from xstring
      i_binary              TYPE STANDARD TABLE OF x255, "For the decryption
      v_string              TYPE string,
      v_data                TYPE string,
      v_data_text           TYPE string,
      v_datax               TYPE xstring,
      v_result              TYPE xstring,
      v_encrypted_file_name TYPE string,
      v_decrypted_file_name TYPE string,
      v_msg(50),
      v_str                 TYPE string,
      v_length              TYPE i,
      unixmsg(50)           TYPE c.

DATA: BEGIN OF it_filedir OCCURS 10.
        INCLUDE STRUCTURE salfldir.
      DATA: END OF it_filedir.

DATA: gv_file     TYPE string,
      gv_fullfile TYPE string,
      gv_filename TYPE string,
      gv_pathname TYPE string,
      gv_return   TYPE bapiret2.

DATA: i_dlist TYPE STANDARD TABLE OF epsfili INITIAL SIZE 0,  "Files Table
      k_dlist LIKE LINE OF i_dlist.

DATA: gb_valid_path      TYPE sap_bool,
      gb_list_processing TYPE sap_bool.

PARAMETERS: p_file(255)   LOWER CASE, "should point to FTP server directory; see AL11 for path info
            p_replac(255) LOWER CASE,
            p_fileto(255) LOWER CASE,
            p_makecp      AS CHECKBOX,
            p_chgall      RADIOBUTTON GROUP rb1 DEFAULT 'X',
            p_single      RADIOBUTTON GROUP rb1,
            p_find        AS CHECKBOX DEFAULT 'X'.

**---------------
** initialization
**---------------
INITIALIZATION.
" no init

  "*----------Start of program

START-OF-SELECTION.

  IF p_chgall IS NOT INITIAL.
    PERFORM get_file_list.
    LOOP AT i_dlist INTO k_dlist.
      CONCATENATE p_file k_dlist-name INTO gv_fullfile.
      PERFORM open_infiles CHANGING gv_fullfile.
      IF unixmsg IS NOT INITIAL.
        CLEAR unixmsg.
        CONTINUE.
      ENDIF.
      PERFORM file_to_string CHANGING gv_fullfile.
      v_datax = v_data.
      IF p_find IS NOT INITIAL.
        p_fileto = ''.
        PERFORM find_text CHANGING gv_fullfile.  " find text
      ELSE.
        PERFORM change_text CHANGING gv_fullfile. "replace text
      ENDIF.
*      CLEAR: v_data, v_datax, unixmsg.
      PERFORM clear_variables.
    ENDLOOP.
  ELSEIF p_single IS NOT INITIAL.
    PERFORM open_infiles CHANGING p_file.
    IF unixmsg IS NOT INITIAL.
      MESSAGE e102 WITH p_file unixmsg.
    ENDIF.
    PERFORM file_to_string CHANGING p_file.
    v_datax = v_data.
    IF p_find IS NOT INITIAL.
      p_fileto = ''.
      PERFORM find_text CHANGING gv_fullfile.  " find text
    ELSE.
      PERFORM change_text CHANGING p_file.  "replace text on single file
    ENDIF.
  ENDIF.


  PERFORM clear_variables.
*&---------------------------------------------------------------------*
*&      Form  OPEN_INFILES
*&---------------------------------------------------------------------*
*       Procedure will open the processing input file and issue error
*       messages as necessary.
*----------------------------------------------------------------------*
FORM open_infiles CHANGING p_file TYPE any.

  DATA: l_sysid(3).

  l_sysid = sy-sysid(3).
  OPEN DATASET p_file FOR INPUT IN TEXT MODE MESSAGE unixmsg
               ENCODING DEFAULT IGNORING CONVERSION ERRORS.
  IF unixmsg IS NOT INITIAL.
*    MESSAGE e102 WITH p_file unixmsg.
    WRITE: unixmsg, 'Error while opening ', p_file, /.
  ENDIF.

ENDFORM.                               " OPEN_INFILES
*&---------------------------------------------------------------------*
*&      Form  FILE_TO_STRING
*&---------------------------------------------------------------------*
*       Read dataset, and copy content to string table
*       then concatenate string values into
*----------------------------------------------------------------------*

FORM file_to_string CHANGING p_file TYPE any.

  DO.
    READ DATASET p_file INTO v_string.
    IF sy-subrc = 0.
      IF v_data IS INITIAL.
        v_data = v_string.
      ELSE.
        v_data = |{ v_data }{ cl_abap_char_utilities=>newline }{ v_string }|.  "To keep current format

      ENDIF.
    ELSE.
      EXIT. "required or else infinite loop
    ENDIF.
  ENDDO.

  CLOSE DATASET p_file.
  CLEAR: v_string.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  change text
*&---------------------------------------------------------------------*
*       Mass replace a string with another
*----------------------------------------------------------------------*
FORM change_text CHANGING p_file TYPE any.
  DATA: lv_message_decrypted TYPE xstring.

  "Converting the data - From string format to xstring. You can use any other method or function module which converts the string to xstring format
  v_datax = cl_bcs_convert=>string_to_xstring(
  iv_string = v_data    " Input data
).


  "Convert from xstring to binary so we can keep unicode characters
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = v_datax
    IMPORTING
      output_length = v_length
    TABLES
      binary_tab    = i_binary.

  "then Binary to string
  CALL FUNCTION 'SCMS_BINARY_TO_STRING'
    EXPORTING
      input_length = v_length
    IMPORTING
      text_buffer  = v_data_text
    TABLES
      binary_tab   = i_binary
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  APPEND v_data_text TO i_string_t.
  IF p_makecp IS NOT INITIAL.
    CONCATENATE p_file '.copy' INTO v_decrypted_file_name.
  ELSE.
    v_decrypted_file_name = p_file.
  ENDIF.
*  CONDENSE v_decrypted_file_name.
  OPEN DATASET v_decrypted_file_name IN TEXT MODE FOR OUTPUT MESSAGE v_msg ENCODING DEFAULT IGNORING CONVERSION ERRORS.

  IF v_msg IS INITIAL.
    "Loop at all the line
    LOOP AT i_string_t INTO v_str.
      REPLACE ALL OCCURRENCES OF p_replac IN v_str WITH p_fileto.
      IF sy-subrc = 0.
        IF p_makecp IS INITIAL.
          FORMAT COLOR COL_POSITIVE.
          WRITE: p_file, 'Updated Successfully.', /.
        ELSE.
          FORMAT COLOR COL_POSITIVE.
          WRITE: p_file, 'Modified Copy created Successfully.', /.
        ENDIF.
      ELSE.
        FORMAT COLOR COL_TOTAL.
        WRITE: 'No change for: ', p_file, /.
      ENDIF.
      TRANSFER v_str TO v_decrypted_file_name.
    ENDLOOP.

    CLOSE DATASET p_file.
  ELSE.
    CONDENSE v_msg.
    FORMAT COLOR COL_NEGATIVE.
    WRITE:  'Error found for file: ', v_decrypted_file_name, ' ', v_msg, /.
    CLEAR: v_msg.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CLEAR_VARIABLES
*&---------------------------------------------------------------------*
*       Clear Variables
*----------------------------------------------------------------------*
FORM clear_variables .
  CLEAR: i_string_t,
      i_binary,
      v_string,
      v_data,
      v_data_text,
      v_datax,
      v_result,
      v_encrypted_file_name,
      v_decrypted_file_name,
      v_str,
      v_length,
      unixmsg.
ENDFORM.
*eject
*&---------------------------------------------------------------------*
*&      Form  get_unix_filename
*& This subroutine allows users select file from application server.
*&---------------------------------------------------------------------*
FORM get_unix_filename CHANGING p_file TYPE any.

  CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
*   EXPORTING
*     DIRECTORY          = ' '
*     FILEMASK           = ' '
    IMPORTING
      serverfile       = p_file
    EXCEPTIONS
      canceled_by_user = 1
      OTHERS           = 2.

  ##NEEDED
  IF sy-subrc <> 0.
*    Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_FILE_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_file_list .
  DATA: lv_file TYPE epsf-epsdirnam.
  lv_file = p_file.

  CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'
    EXPORTING
      dir_name               = lv_file
*     FILE_MASK              = PFILE
    TABLES
      dir_list               = i_dlist
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      read_directory_failed  = 5
      too_many_read_errors   = 6
      empty_directory_list   = 7
      OTHERS                 = 8.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FIND_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GV_FULLFILE  text
*----------------------------------------------------------------------*
FORM find_text  CHANGING p_file TYPE any.

  DATA: lv_message_decrypted TYPE xstring,
        lv_offset             TYPE i,
        lv_length             TYPE i,
        lv_found              TYPE string.

  DATA: result_tab TYPE match_result_tab.

  FIELD-SYMBOLS <match> LIKE LINE OF result_tab.

  "Converting the data - From string format to xstring. You can use any other method or function module which converts the string to xstring format
  v_datax = cl_bcs_convert=>string_to_xstring(
  iv_string = v_data    " Input data
).


  "Convert from xstring to binary so we can keep unicode characters
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = v_datax
    IMPORTING
      output_length = v_length
    TABLES
      binary_tab    = i_binary.

  "then Binary to string
  CALL FUNCTION 'SCMS_BINARY_TO_STRING'
    EXPORTING
      input_length = v_length
    IMPORTING
      text_buffer  = v_data_text
    TABLES
      binary_tab   = i_binary
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  APPEND v_data_text TO i_string_t.
*  IF p_makecp IS NOT INITIAL.
*    CONCATENATE p_file '.copy' INTO v_decrypted_file_name.
*  ELSE.
*    v_decrypted_file_name = p_file.
*  ENDIF.
**  CONDENSE v_decrypted_file_name.
*  OPEN DATASET v_decrypted_file_name IN TEXT MODE FOR OUTPUT MESSAGE v_msg ENCODING DEFAULT IGNORING CONVERSION ERRORS.

*  IF v_msg IS INITIAL.
  "Loop at all the line
  LOOP AT i_string_t INTO v_str.  "will be 1 unless 'select all files' is checked
      FIND ALL OCCURRENCES OF p_replac IN v_str RESULTS result_tab.
      IF result_tab IS NOT INITIAL.
         FORMAT COLOR COL_POSITIVE.
         WRITE: 'Found in: ', p_file, /.

        LOOP AT result_tab ASSIGNING <match>.  "there can be multiple occurances of the same text per file

           lv_offset = <match>-offset - 25.
           IF lv_offset < 0.
             lv_offset = 1.
           ENDIF.
           lv_length = <match>-length + 100.


           CATCH SYSTEM-EXCEPTIONS OTHERS = 1.
             lv_found = v_str+lv_offset(lv_length).
           ENDCATCH.
           IF sy-subrc <> 0.
             lv_found = v_str+<match>-offset(<match>-length).
             ELSE.
               lv_found = v_str+lv_offset(lv_length).
           ENDIF.



            FORMAT COLOR COL_TOTAL.
           WRITE: sy-tabix, ' : ', lv_found, /.

        ENDLOOP.
        CLEAR: result_tab.
      ENDIF.
  ENDLOOP.

  CLOSE DATASET p_file.
  CLEAR: v_str, i_string_t.


ENDFORM.
