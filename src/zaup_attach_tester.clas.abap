CLASS zaup_attach_tester DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZAUP_ATTACH_TESTER IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lt_attach TYPE zaup_attach_helper=>tty_xtable.

    TRY.
        zaup_attach_helper=>get_attach_files(
          EXPORTING
            sap_object   = 'BKPF' "'VBRK'
            object_id    = 'SN1060010000752023' "'0090000099'
          IMPORTING
*        tab_string   =
            tab_xstring  = lt_attach
*        tab_messages =
        ).
      CATCH cx_web_http_client_error.
      CATCH /iwbep/cx_gateway.
    ENDTRY.


  ENDMETHOD.
ENDCLASS.
