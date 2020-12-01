*&---------------------------------------------------------------------*
*& Report  ZED_GUIBASED_PROGRESSBAR
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ZED_GUIBASED_PROGRESSBAR.
DATA val TYPE i VALUE 0.

DO 20 TIMES.

  val = val + 5.
   CALL FUNCTION 'PROGRESS_POPUP'
   EXPORTING
     btn_txt = 'Cancel'
     curval = val
     maxval = 100
     stat = '1'
     text_1 = 'Text 1'
     text_2 = 'Text 2'
     text_3 = 'Text 3'
     title = 'My Title'
     winid = 100.
   ENDDO.

   CALL FUNCTION 'PROGRESS_POPUP'
   EXPORTING
     stat = '2'
     winid = 100.

   CALL FUNCTION 'GRAPH_DIALOG'
   EXPORTING
     close = 'X'.
