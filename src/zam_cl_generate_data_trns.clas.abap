CLASS zam_cl_generate_data_trns DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    METHODS constructor.

  PRIVATE SECTION.
    CONSTANTS scg_client       TYPE c LENGTH 3   VALUE '100'.
    CONSTANTS scg_currency_usd TYPE waers_curc   VALUE 'USD'.

    CONSTANTS: BEGIN OF scg_tables,
                 tt_products TYPE tabname VALUE 'zam_D_PRODUCT',
                 tt_markets  TYPE tabname VALUE 'zam_d_mrkt_trl',
                 tt_orders   TYPE tabname VALUE 'zam_D_MRKT_ORDER',
               END OF scg_tables.

    CONSTANTS: BEGIN OF scg_filling_methods,
                 get_products TYPE string VALUE 'GET_PRODUCTS',
                 get_markets  TYPE string VALUE 'GET_MARKETS',
                 get_orders   TYPE string VALUE 'GET_ORDERS',
               END OF   scg_filling_methods.

    CONSTANTS: BEGIN OF scg_types_mt_mapping,
                 tt_products TYPE tabname VALUE 'MT_PRODUCTS',
                 tt_markets  TYPE tabname VALUE 'MT_MARKETS',
                 tt_orders   TYPE tabname VALUE 'MT_ORDERS',
               END OF  scg_types_mt_mapping.

    CONSTANTS scg_sec_in_day  TYPE i VALUE 86400.
    CONSTANTS scg_sec_in_year TYPE i VALUE 31536000.

    TYPES tt_products TYPE STANDARD TABLE OF zam_d_product WITH DEFAULT KEY.
    TYPES tt_markets  TYPE STANDARD TABLE OF zam_d_mrkt_trl WITH DEFAULT KEY.
    TYPES tt_orders   TYPE STANDARD TABLE OF zam_d_mrkt_order WITH DEFAULT KEY.

    DATA mt_products       TYPE tt_products.
    DATA mt_markets        TYPE tt_markets.
    DATA mt_orders         TYPE tt_orders.
    DATA mv_phase_id       TYPE zam_phase_id.
    DATA mv_base_date_time TYPE timestampl.
    DATA mo_rnd            TYPE REF TO cl_abap_random.

    METHODS get_uuid
      RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.

    METHODS get_products
      RETURNING VALUE(rt_result) TYPE REF TO data.

    METHODS get_markets
      RETURNING VALUE(rt_result) TYPE REF TO data.

    METHODS get_orders
      RETURNING VALUE(rt_result) TYPE REF TO data.

    METHODS set_mt_tables
      IMPORTING ir_table TYPE REF TO data.

    METHODS insert_to_db_table
      IMPORTING it_data TYPE data OPTIONAL.

ENDCLASS.

CLASS zam_cl_generate_data_trns IMPLEMENTATION.
  METHOD constructor.
    GET TIME STAMP FIELD DATA(lv_current_date_time).
    mo_rnd = cl_abap_random=>create( seed = cl_abap_random=>seed( ) ).

    mv_base_date_time = cl_abap_tstmp=>add( tstmp = lv_current_date_time
                                            secs  = scg_sec_in_year * 3 * -1 ).
  ENDMETHOD.

  METHOD get_markets.
    DATA lt_markets            TYPE tt_markets.
    DATA lv_start_date         TYPE d.
    DATA lv_end_date           TYPE d.
    DATA lv_creation_date_time TYPE timestampl.

    SELECT FROM zam_d_market FIELDS mrktid, code INTO TABLE @DATA(lt_country).

    LOOP AT lt_country ASSIGNING FIELD-SYMBOL(<fs_market>) FROM 1 TO 3.
      DATA(lv_index_start) = mo_rnd->intinrange( low  = 1
                                                 high = 2 ).
      DATA(lv_index_end) = mo_rnd->intinrange( low  = 3
                                               high = 4 ).
      DATA(lv_market_uuid) = get_uuid( ).

      LOOP AT mt_products ASSIGNING FIELD-SYMBOL(<fs_product>) FROM lv_index_start TO lv_index_end.
        DATA(lv_sec_creation_shift) = mo_rnd->intinrange( low  = 1
                                                          high = 5 ) * scg_sec_in_day.

        lv_creation_date_time = cl_abap_tstmp=>add( tstmp = mv_base_date_time
                                                    secs  = lv_sec_creation_shift ).
        TRY.
            CONVERT TIME STAMP lv_creation_date_time
                    TIME ZONE cl_abap_context_info=>get_user_time_zone( )
                    INTO DATE DATA(lv_creation_date).
          CATCH cx_abap_context_info_error.
        ENDTRY.

        DATA(lv_days_start_shift) = mo_rnd->intinrange( low  = 1
                                                        high = 5  ) * 10.
        DATA(lv_days_end_shift)   = mo_rnd->intinrange( low  = 10
                                                        high = 30 ) * 1000.

        lv_start_date = lv_creation_date + lv_days_start_shift.
        lv_end_date   = lv_creation_date + lv_days_end_shift.

        lt_markets = VALUE #( BASE lt_markets
                              ( client     = scg_client
                                prod_uuid  = <fs_product>-prod_uuid
                                mrkt_uuid  = lv_market_uuid
                                mrktid    = <fs_market>-mrktid
                                status_confirm    = abap_true
                                start_date = lv_start_date
                                end_date   = lv_end_date
                                created_by = sy-uname
                                creation_time = lv_creation_date_time
                                changed_by = sy-uname
                                change_time = lv_creation_date_time ) ).
      ENDLOOP.
    ENDLOOP.

    DATA(lr_markets) = NEW tt_markets( lt_markets ).

    set_mt_tables( lr_markets ).
    rt_result = lr_markets.
  ENDMETHOD.

  METHOD get_orders.
    DATA lt_orders             TYPE tt_orders.
    DATA lv_delivery_date      TYPE d.
    DATA lv_netamount          TYPE p LENGTH 15 DECIMALS 2.
    DATA lv_grossamount        TYPE p LENGTH 15 DECIMALS 2.
    DATA lv_net_k              TYPE p LENGTH 3  DECIMALS 2.
    DATA lv_creation_date_time TYPE timestampl.

    LOOP AT mt_markets ASSIGNING FIELD-SYMBOL(<fs_market>).
      DATA(lv_order_quan) = mo_rnd->intinrange( low  = 1
                                                high = 10 ) * 73.
      lv_net_k = mo_rnd->intinrange( low  = 7
                                     high = 9 ) / 10.

      DATA(lv_price) = VALUE #( mt_products[ prod_uuid = <fs_market>-prod_uuid ]-price DEFAULT 0 ).

      DO lv_order_quan TIMES.
        DATA(lv_items_quan) = mo_rnd->intinrange( low  = 1
                                                  high = 10 ) .
        lv_grossamount = lv_items_quan * lv_price.
        lv_netamount   = lv_items_quan * lv_price * lv_net_k.

        DATA(lv_sec_creation_shift) = mo_rnd->intinrange( low  = 10
                                                          high = 1000 ) * scg_sec_in_day.

        lv_creation_date_time = cl_abap_tstmp=>add( tstmp = mv_base_date_time
                                                    secs  = lv_sec_creation_shift ).
        TRY.
            CONVERT TIME STAMP lv_creation_date_time
                    TIME ZONE cl_abap_context_info=>get_user_time_zone( )
                    INTO DATE lv_delivery_date.
          CATCH cx_abap_context_info_error.
        ENDTRY.

        lt_orders = VALUE #( BASE lt_orders
                             ( client                  = scg_client
                               prod_uuid               = <fs_market>-prod_uuid
                               mrkt_uuid               = <fs_market>-mrkt_uuid
                               order_uuid              = get_uuid( )
                               orderid                = sy-index
                               quantity               = lv_items_quan
                               calendar_year           = lv_delivery_date(4)
                               delivery_date           = lv_delivery_date
                               netamount              = lv_netamount
                               grossamount            = lv_grossamount
                               amountcurr             = scg_currency_usd
                               created_by              = sy-uname
                               creation_time              = lv_creation_date_time
                               changed_by              = sy-uname
                               change_time             = lv_creation_date_time


                           ) ).
      ENDDO.
    ENDLOOP.

    DATA(lr_orders) = NEW tt_orders( lt_orders ).
    set_mt_tables( lr_orders ).

    rt_result = lr_orders.
  ENDMETHOD.


  METHOD get_products.
    DATA lt_products      TYPE tt_products.
    DATA lv_creation_date TYPE timestampl.

    SELECT * FROM zam_d_prod_group INTO TABLE @DATA(lt_prod_group).

    IF lt_prod_group IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_prod_group ASSIGNING FIELD-SYMBOL(<fs_prod_group>).
      DATA(lv_sec_creation_shift) = mo_rnd->intinrange( low  = 1
                                                        high = 5 ) * scg_sec_in_day.

      lv_creation_date = cl_abap_tstmp=>add( tstmp = mv_base_date_time
                                             secs  = lv_sec_creation_shift ).

      DATA(lv_height) = mo_rnd->intinrange( low  = 5
                                            high = 10 ) * 100.
      DATA(lv_width)  = mo_rnd->intinrange( low  = 1
                                            high = 5  ) * 100.
      DATA(lv_depth)  = mo_rnd->intinrange( low  = 7
                                            high = 10 ) * 100.
      DATA(lv_price)  = mo_rnd->intinrange( low  = 1
                                            high = 3  ) * 100.

      DATA(lv_product_id) = |{ <fs_prod_group>-pgid }{ mv_phase_id }-{ <fs_prod_group>-pgname(1) }|.

      lt_products =
        VALUE #( BASE lt_products
                 ( client          = scg_client
                   prod_uuid       = get_uuid( )
                   prodid         = lv_product_id
                   pgname       = |{ <fs_prod_group>-pgname } { lv_product_id }|
                   phase        = mv_phase_id
                   height         = lv_height
                   depth          = lv_depth
                   width          = lv_width
                   sizam_uom        = 'CM'
                   price          = lv_price
                   price_currency  = scg_currency_usd
                   taxrate        = 18
                   created_by      = sy-uname
                   creation_time      = lv_creation_date
                   changed_by      = sy-uname
                   change_time      = lv_creation_date
                   ) ).
    ENDLOOP.

    DATA(lr_products) = NEW tt_products( lt_products ).
    set_mt_tables( lr_products ).

    rt_result = lr_products.
  ENDMETHOD.

  METHOD get_uuid.
    TRY.
        rv_uuid = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ).
      CATCH cx_uuid_error.
    ENDTRY.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    DATA lr_table TYPE REF TO data.

    DATA(lt_methods) = CAST cl_abap_structdescr(
                              cl_abap_structdescr=>describe_by_data( scg_filling_methods )
                            )->components.

    DELETE FROM zam_d_product.
    DELETE FROM zam_d_mrkt_trl.
    DELETE FROM zam_d_mrkt_order.
    COMMIT WORK AND WAIT.

    DO 4 TIMES.
      mv_phase_id = sy-index.

      LOOP AT lt_methods ASSIGNING FIELD-SYMBOL(<fs_methods>).
        ASSIGN COMPONENT <fs_methods>-name OF STRUCTURE scg_filling_methods TO FIELD-SYMBOL(<fs_method_name>).

        CALL METHOD (<fs_method_name>)
          RECEIVING
            rt_result = lr_table.

        ASSIGN lr_table->* TO FIELD-SYMBOL(<fs_table>).

        insert_to_db_table( <fs_table> ).
      ENDLOOP.
    ENDDO.
  ENDMETHOD.

  METHOD insert_to_db_table.
    DATA lr_table TYPE REF TO data.

    CREATE DATA lr_table LIKE it_data.
    ASSIGN lr_table->* TO FIELD-SYMBOL(<fs_table>).
    <fs_table> = it_data.

    DATA(lv_type_name) = cl_abap_tabledescr=>describe_by_data( <fs_table> )->get_relative_name( ).
    ASSIGN COMPONENT lv_type_name OF STRUCTURE scg_tables TO FIELD-SYMBOL(<fs_table_name>).

    IF <fs_table> IS INITIAL.
      RETURN.
    ENDIF.

    INSERT (<fs_table_name>) FROM TABLE @<fs_table> ACCEPTING DUPLICATE KEYS.
    COMMIT WORK AND WAIT.
  ENDMETHOD.

  METHOD set_mt_tables.
    DATA lr_table TYPE REF TO data.

    FIELD-SYMBOLS <fs_table> TYPE ANY TABLE.

    DATA(lv_type_name) = cl_abap_tabledescr=>describe_by_data_ref( ir_table )->get_relative_name( ).
    DATA(lt_scg_mt_tabs_comp) = CAST cl_abap_structdescr(
                                       cl_abap_structdescr=>describe_by_data( scg_types_mt_mapping )
                                     )->components.

    ASSIGN COMPONENT lv_type_name OF STRUCTURE scg_types_mt_mapping TO FIELD-SYMBOL(<fs_mt_tab_name>).

    ASSIGN ir_table->* TO <fs_table>.
    ASSIGN (<fs_mt_tab_name>) TO FIELD-SYMBOL(<fs_target_table>) .
    <fs_target_table> = <fs_table>.
  ENDMETHOD.
ENDCLASS.

