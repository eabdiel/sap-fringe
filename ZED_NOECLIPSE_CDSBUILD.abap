*& ------------------------------------------------------ *
*& Report ZED_NOECLIPSE_CDSBUILD
*& ------------------------------------------------------ *
*& Creating a dynamic CDS and Dictionary object
*& without eclipse's ABAP editor using 'beta'handler 
*& 
*& The program will create a CDS called ZSP_CDS_999 based
*& on fields from sflight and a dictionary called zcds_999
*&-------------------------------------------------------- *

REPORT ZED_NOECLIPSE_CDSBUILD
"Data definitions
DATA : ls_ddddlsrcv TYPE DDDDLSRCV,
       lt_DDDLSRCV TYPE TABLE OF DDDDLSRCV,
       lv_ddl_source(40) TYPE c VALUE 'ZCDS_999'.  "this will define the name for the dictionary
 

"Start of logic
 ls_ddddlsrcv-ddtext = 'Test CDS View'
 ls_ddddlsrcv-ddlanguage = sy-langu.
 ls_ddddlsrcv-ddlname = lv_ddl_source.
 ls_ddddlsrcv-source = '@AbapCatalog.sqlViewName: ''ZCDS_999'' define view zsp_CDS_
 999 as select from sflight as soi {soi.connid as so_connid, soi.fldate as so_fldate, soi.price as so_price}'.
 
 DATA(lref_dd_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).
 DATA : lv_putstate TYPE OBJSTATE VALUE 'N',
        name TYPE DDLNAME VALUE 'ZSP_CDS_999'. "This defines the CDS
        
 TRY.
  CALL METHOD lref_dd_ddl_handler->save
        EXPORTING
         name         = lv_ddl_source
         put_state    = lv_putstate
         ddddlsrcv_wa = ls_ddddlsrcv
*        prid         = -1

    CATCH cx_dd_ddl_activate .
  ENDTRY.
  
"To display the CDS view as ALV just use this one line of code;
 cl_salv_gui_table_ida=>create_for_cds_view( 'ZSP_CDS_999' )->fullscreen( )->display( ).
