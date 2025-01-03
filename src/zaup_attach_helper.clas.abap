CLASS zaup_attach_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_xtable,
             document TYPE xstring,
             FileName TYPE string,
             FileSize TYPE string,
             MimeType TYPE string,
           END OF ty_xtable,

           tty_xtable TYPE TABLE OF ty_xtable.

    TYPES: BEGIN OF ty_table,
             document TYPE string,
             FileName TYPE string,
             FileSize TYPE string,
             MimeType TYPE string,
           END OF ty_table,

           tty_table TYPE TABLE OF ty_table.

    TYPES: ty_object TYPE c LENGTH 10,
           ty_objid  TYPE c LENGTH 50.

    TYPES: BEGIN OF ty_metadata,
             content_type TYPE string,
             media_src    TYPE string,
           END OF ty_metadata,

           BEGIN OF ty_result,
             __metadata                   TYPE ty_metadata,
             DocumentInfoRecordDocType    TYPE string,
             DocumentInfoRecordDocNumber  TYPE string,
             DocumentInfoRecordDocVersion TYPE string,
             DocumentInfoRecordDocPart    TYPE string,
             LogicalDocument              TYPE string,
             ArchiveDocumentID            TYPE string,
             LinkedSAPObjectKey           TYPE string,
             BusinessObjectTypeName       TYPE string,
             FileSize                     TYPE string,
             FileName                     TYPE string,
             "DocumentURL": "",
             MimeType                     TYPE string,
             BusinessObjectType           TYPE string,
             "StorageCategory": "SOMU",
             "ArchiveLinkRepository": "",
             "SAPObjectType": "BillingDocument",
             "HarmonizedDocumentType": "GOS",
             Source                       TYPE string,
           END OF ty_result,

           BEGIN OF ty_response,
             results TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY,
           END OF ty_response,

           BEGIN OF ty_d,
             d TYPE ty_response,
           END OF ty_d.


    CLASS-METHODS get_attach_files
      IMPORTING sap_object   TYPE ty_object
                object_id    TYPE ty_objid
      EXPORTING
                tab_string   TYPE tty_table
                tab_xstring  TYPE tty_xtable
                tab_messages TYPE bapirettab
      RAISING
                cx_web_http_client_error
                /iwbep/cx_gateway.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZAUP_ATTACH_HELPER IMPLEMENTATION.


  METHOD get_attach_files.

    DATA: lv_url TYPE string.
    DATA: ls_response TYPE ty_d.

    DATA: ls_table  TYPE ty_table,
          ls_xtable TYPE ty_xtable.

*    lv_url = |https://myxxxxxx-api.s4hana.cloud.sap:443/sap/opu/odata/sap/API_CV_ATTACHMENT_SRV/GetAllOriginals?BusinessObjectTypeName='{ sap_object }'&LinkedSAPObjectKey='{ object_id }'|.

    " STEP 1: Istanza HTTP CLIENT per recuperare lista allegati
    TRY.
        "alternatively create HTTP destination via destination service
*        data(http_destination2) = cl_http_destination_provider=>create_by_cloud_destination( i_name = '<...>'
*                                                                                            i_service_instance_name = '<...>' ).
*        SAP Help: https://help.sap.com/viewer/65de2977205c403bbc107264b8eccf4b/Cloud/en-US/f871712b816943b0ab5e04b60799e518.html

        DATA(http_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                   comm_scenario  = 'ZAUP_CSCEN_ATTACH'
                                   service_id     = 'ZAUP_OUT_ATTACH_REST'
*                                   comm_system_id =
                                 ).

        DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination =  http_destination ) ."cl_http_destination_provider=>create_by_url( i_url = lv_url ) ).


        http_client->get_http_request( )->set_authorization_basic(
            i_username = 'ABAP_USER'
            i_password = 'xxxxxxxxxxxxxxxxxxxx'
        ).

      CATCH cx_http_dest_provider_error.
    ENDTRY.

    " Aggiungo parametri Header
    DATA(lo_web_http_request) = http_client->get_http_request( ).
    lo_web_http_request->set_header_fields( VALUE #(
    (  name = 'DataServiceVersion' value = '2.0' )
    (  name = 'Accept' value = 'application/json' )
     ) ).

    " Aggiungo filtro su documento
    lo_web_http_request->set_query( query = |BusinessObjectTypeName='{ sap_object }'&LinkedSAPObjectKey='{ object_id }'| ).

    " GET e recupero lista in JSON
    DATA(lo_web_http_response) = http_client->execute( if_web_http_client=>get ).
    DATA(lv_response) = lo_web_http_response->get_text( ).

    " Deserializzo JSON in struttura ABAP
    /ui2/cl_json=>deserialize(
        EXPORTING
            json = lv_response
            pretty_name = /ui2/cl_json=>pretty_mode-user
        CHANGING
            data = ls_response ).

    CLEAR: tab_string, tab_xstring, tab_messages.

    IF ls_response IS NOT INITIAL.

      LOOP AT ls_response-d-results INTO DATA(ls_result).

        IF ls_result-__metadata-media_src IS NOT INITIAL.

          TRY.
              DATA(http_client_att) = cl_web_http_client_manager=>create_by_http_destination( i_destination =  cl_http_destination_provider=>create_by_url( i_url = ls_result-__metadata-media_src ) ).
            CATCH cx_http_dest_provider_error.
          ENDTRY.
          "alternatively create HTTP destination via destination service
*        "cl_http_destination_provider=>create_by_cloud_destination( i_name = '<...>'
*        "                            i_service_instance_name = '<...>' )
*        "SAP Help: https://help.sap.com/viewer/65de2977205c403bbc107264b8eccf4b/Cloud/en-US/f871712b816943b0ab5e04b60799e518.html
*

          http_client_att->get_http_request( )->set_authorization_basic(
              i_username = 'ABAP_USER'
              i_password = 'xxxxxxxxxxxxxxxxxxxx'
          ).

          "set request method and execute request
          DATA(lo_web_http_response_att) = http_client_att->execute( if_web_http_client=>get ).
          DATA(lv_response_att) = lo_web_http_response_att->get_text( ).
          DATA(lv_response_bin) = lo_web_http_response_att->get_binary( ).

          IF lv_response_att IS NOT INITIAL.
            MOVE-CORRESPONDING ls_result TO ls_table.
            ls_table-document = lv_response_att. APPEND ls_table TO tab_string.
          ENDIF.

          IF lv_response_bin IS NOT INITIAL.
            MOVE-CORRESPONDING ls_result TO ls_xtable.
            ls_xtable-document = lv_response_bin. APPEND ls_xtable TO tab_xstring.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
