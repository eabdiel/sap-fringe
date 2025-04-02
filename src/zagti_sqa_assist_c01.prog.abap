*&---------------------------------------------------------------------*
*&  Include           ZAGTI_SQA_ASSIST_C01
*&---------------------------------------------------------------------*
CLASS lcl_sqa_assist DEFINITION.
  PUBLIC SECTION.
    DATA: container TYPE REF TO cl_gui_custom_container, " Custom container for HTML viewer
          html      TYPE REF TO cl_gui_html_viewer, " HTML viewer control
          lt_html   TYPE TABLE OF char255, "Table for HTML content
          ls_html   TYPE char255, " HTML content to be displayed
          lv_url    TYPE char255. " URL to display HTML content
    " Define the URL to be displayed
    DATA: website_url TYPE string VALUE 'https://progretech.com/?page_id=33'.

    METHODS : center_container_browser. "Create and initialize GUI container and HTML viewer

ENDCLASS.
CLASS lcl_sqa_assist IMPLEMENTATION.
  METHOD center_container_browser.
    " Define HTML content
    ls_html = '<html><body><iframe src="' && website_url &&
   '" width="100%" height="100%" frameborder="0"></iframe></body></html>'.

    ls_html = '<html><body><script src="https://app.aminos.ai/js/chat_form_plugin.js" data-bot-id="27794"></script><div id="chat_form"></div></body></html>'.

    " Create custom container if it does not exist
    IF container IS INITIAL.
      CREATE OBJECT container
        EXPORTING
          repid          = sy-repid
          dynnr          = sy-dynnr
          container_name = 'CONTAINER'.
    ENDIF.

    " Create HTML viewer if it does not exist
    IF html IS INITIAL.
      CREATE OBJECT html
        EXPORTING
          parent = container.
    ENDIF.

    APPEND ls_html TO lt_html.

    " Load HTML content into the HTML viewer
    CALL METHOD html->load_data
      IMPORTING
        assigned_url         = lv_url
      CHANGING
        data_table           = lt_html " Ensure lt_html is in correct format
      EXCEPTIONS
        dp_invalid_parameter = 1
        dp_error_general     = 2
        cntl_error           = 3
        OTHERS               = 4.
    IF sy-subrc IS INITIAL.
      " Display the HTML content
      CALL METHOD html->show_url
        EXPORTING
          url = lv_url.
    ENDIF.

  ENDMETHOD.


ENDCLASS.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'PF_100'.
  SET TITLEBAR 'T100'.
  DATA ob_assist TYPE REF TO  lcl_sqa_assist.
  IF ob_assist IS NOT BOUND.
    ob_assist = NEW lcl_sqa_assist( ).
    ob_assist->center_container_browser( ).
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
