*----------------------------------------------------------------------*
*    This program takes a file, and encodes it using 128bit AES        *
*    with a custom key.  It also provides the oportunity to decrypt    *
*    the file.                                                         *
*----------------------------------------------------------------------*
REPORT Z80SPECTRUMENCODING        NO STANDARD PAGE HEADING
        MESSAGE-ID zf
        LINE-SIZE  150
        LINE-COUNT 58(0).

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
      v_str                 TYPE string,
      v_length              TYPE i,
      unixmsg(50) TYPE c,
      v_key                 TYPE xstring VALUE '38451B52187A3A4AECA26B2718391392'.  "This is the key, but it can be generated on-demand if needed

PARAMETERS: p_file(255)   LOWER CASE,
*            p_struc(255),
            p_enc        RADIOBUTTON GROUP rad1,
            p_dec        RADIOBUTTON GROUP rad1.

PERFORM open_infiles CHANGING p_file.

PERFORM file_to_string.

IF p_enc IS NOT INITIAL.
  PERFORM encrypt.
  WRITE: 'File Encrypted'.
ELSEIF p_dec IS NOT INITIAL.
  v_datax = v_data.
  PERFORM decrypt.
  WRITE: 'File Decrypted.'.
ELSE.
  MESSAGE 'Radio Button Selection Error' TYPE 'E'.
ENDIF.

PERFORM clear_variables.
*&---------------------------------------------------------------------*
*&      Form  OPEN_INFILES
*&---------------------------------------------------------------------*
*       Procedure will open the processing input file and issue error
*       messages as necessary.
*----------------------------------------------------------------------*
FORM open_infiles CHANGING p_file.
  "Make sure your p_file has a valid path
  OPEN DATASET p_file FOR INPUT IN TEXT MODE MESSAGE unixmsg
               ENCODING DEFAULT IGNORING CONVERSION ERRORS.
  IF sy-subrc NE 0.
    MESSAGE e102 WITH p_file unixmsg.
  ENDIF.

ENDFORM.                               " OPEN_INFILES
*&---------------------------------------------------------------------*
*&      Form  FILE_TO_STRING
*&---------------------------------------------------------------------*
*       Read dataset, and copy content to string table
*       then concatenate string values into
*----------------------------------------------------------------------*

FORM file_to_string .
*  DATA: li_string_table TYPE string_t,
*        lv_string_line TYPE string.

  DO.
    READ DATASET p_file INTO v_string.
    IF sy-subrc = 0.
*      APPEND v_string TO li_string_table.
      IF v_data IS INITIAL.
        v_data = v_string.
      ELSE.
        IF p_enc IS NOT INITIAL.
        v_data = |{ v_data }{ cl_abap_char_utilities=>newline }{ v_string }|.  "separate by line if encoding
        ELSEIF p_dec IS NOT INITIAL.
        v_data = |{ v_data }{ v_string }|.                                     "don't separate by line if decoding
        ENDIF.
      ENDIF.
      ELSE.
        EXIT. "required or else infinite loop
    ENDIF.
  ENDDO.

  CLOSE DATASET p_file.
  CLEAR: v_string.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ENCRYPT
*&---------------------------------------------------------------------*
*       If Encryption is selected, file will be converted to xstring
*       and encrypted based on SAPs SEC_SXML Class methods
*----------------------------------------------------------------------*
FORM encrypt .

  "Converting the data - From string format to xstring. You can use any other method or function module which converts the string to xstring format
  v_datax = cl_bcs_convert=>string_to_xstring(
  iv_string = v_data    " Input data
).

  "Encrypt the data using the key
  cl_sec_sxml_writer=>encrypt(
    EXPORTING
      plaintext =  v_datax
      key       =  v_key
      algorithm =  cl_sec_sxml_writer=>co_aes128_algorithm
    IMPORTING
      ciphertext = v_result ).

  v_str = v_result.

  "Split at 132 position
  CALL FUNCTION 'CONVERT_STRING_TO_TABLE'
    EXPORTING
      i_string         = v_str
      i_tabline_length = 500
    TABLES
      et_table         = i_string_t.

  CONCATENATE p_file '.nc' INTO v_encrypted_file_name.
  CONDENSE v_encrypted_file_name.

*  OPEN DATASET v_encrypted_file_name FOR OUTPUT IN TEXT MODE  ENCODING DEFAULT.
  OPEN DATASET v_encrypted_file_name FOR output IN TEXT MODE MESSAGE unixmsg
               ENCODING NON-UNICODE.

  IF sy-subrc <> 0. "Regular open data set failed, try appending
    WRITE: 'Failed to open target data set'.
  ENDIF.

  "Loop at all the line
  LOOP AT i_string_t INTO v_str.
    TRANSFER v_str TO v_encrypted_file_name.
  ENDLOOP.

  CLOSE DATASET p_file.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DECRYPT
*&---------------------------------------------------------------------*
*       If Decryption is selected, file will be unconverted from xstring
*       and decrypted based on SAPs SEC_SXML Class methods
*----------------------------------------------------------------------*
FORM decrypt .
  DATA: lv_message_decrypted TYPE xstring.

cl_sec_sxml_writer=>decrypt(
EXPORTING
  ciphertext = v_datax
  key = v_key
  algorithm = cl_sec_sxml_writer=>co_aes128_algorithm
  IMPORTING
    plaintext = lv_message_decrypted ).

"Convert from xstring to binary so we can keep unicode characters
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_message_decrypted
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

  CONCATENATE p_file '.raw' INTO v_decrypted_file_name.
  CONDENSE v_decrypted_file_name.
  OPEN DATASET v_decrypted_file_name IN TEXT MODE FOR OUTPUT ENCODING DEFAULT.

  "Loop at all the line
  LOOP AT i_string_t INTO v_str.
    TRANSFER v_str TO v_decrypted_file_name.
  ENDLOOP.

  CLOSE DATASET p_file.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_FILE_STRUCTURES
*&---------------------------------------------------------------------*
*       A Table type has to be created and used to process the file
*----------------------------------------------------------------------*
*  Created for future development (only if xstring is not enough for file)
*----------------------------------------------------------------------*
FORM get_file_structures .
*  DATA: w_tabname TYPE w_tabname,
*        w_dref    TYPE REF TO data.
*
*  FIELD-SYMBOLS: <t_itab> TYPE ANY TABLE.
*  w_tabname = p_struc.
*  CREATE DATA w_dref TYPE TABLE OF (w_tabname).
*  ASSIGN w_dref->* TO <t_itab>.  "w_dref will have become a table reference of the type entered on the parameter
*  "you can assign the value to the field symbol, and the field symbol will
*  "point to the table reference in order to be processed


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
      v_key.
ENDFORM.
