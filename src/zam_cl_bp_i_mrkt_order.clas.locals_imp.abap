CLASS lhc_MrktOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculate_amount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MrktOrder~calculate_amount.

    METHODS calculate_orderid FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MrktOrder~calculate_orderid.

    METHODS set_calendar_year FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MrktOrder~set_calendar_year.
    METHODS VALIDATE_DELIVERY_DATE FOR VALIDATE ON SAVE
      IMPORTING keys FOR MrktOrder~VALIDATE_DELIVERY_DATE.

ENDCLASS.

CLASS lhc_MrktOrder IMPLEMENTATION.

  METHOD calculate_amount.
    " Считываем данные создаваемых заказов
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY MrktOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<ls_order>).
      " Получаем данные продукта через ассоциацию или напрямую
      READ ENTITIES OF zam_i_product IN LOCAL MODE
        ENTITY Product
          FIELDS ( price price_currency ) WITH VALUE #( ( prod_uuid = <ls_order>-prod_uuid ) )
        RESULT DATA(lt_products).

      CHECK lt_products IS NOT INITIAL.
      DATA(ls_product) = lt_products[ 1 ].

      " Формулы из задания 1.4.4
      <ls_order>-netamount   = <ls_order>-quantity * ls_product-price.
      <ls_order>-grossamount = <ls_order>-netamount + ( <ls_order>-netamount * 2 / 100 ). " Используем 2% как на Pic 1.4.4
      <ls_order>-amountcurr  = ls_product-price_currency.

      " Обновляем запись в базе
      MODIFY ENTITIES OF zam_i_product IN LOCAL MODE
        ENTITY MrktOrder
          UPDATE FIELDS ( netamount grossamount amountcurr )
          WITH VALUE #( ( %tky = <ls_order>-%tky
                           netamount   = <ls_order>-netamount
                           grossamount = <ls_order>-grossamount
                           amountcurr  = <ls_order>-amountcurr ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD calculate_orderid.
    " Считываем все существующие заказы для данного продукта и рынка
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY MrktOrder
        FIELDS ( orderid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    " Удаляем те, у которых уже есть ID (чтобы не менять существующие)
    DELETE lt_orders WHERE orderid IS NOT INITIAL.
    CHECK lt_orders IS NOT INITIAL.

    " Получаем максимальный текущий номер из базы
    SELECT MAX( orderid ) FROM zam_d_mrkt_order INTO @DATA(lv_max_id).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<ls_order>).
      lv_max_id += 1. " Увеличиваем на 1
      <ls_order>-orderid = lv_max_id.

      " Обновляем запись
      MODIFY ENTITIES OF zam_i_product IN LOCAL MODE
        ENTITY MrktOrder
          UPDATE FIELDS ( orderid )
          WITH VALUE #( ( %tky = <ls_order>-%tky
                           orderid = <ls_order>-orderid ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD set_calendar_year.
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY MrktOrder
        FIELDS ( delivery_date ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<ls_order>).
      IF <ls_order>-delivery_date IS NOT INITIAL.
        " Вырезаем год (первые 4 символа даты YYYYMMDD)
        <ls_order>-calendar_year = <ls_order>-delivery_date+0(4).

        MODIFY ENTITIES OF zam_i_product IN LOCAL MODE
          ENTITY MrktOrder
            UPDATE FIELDS ( calendar_year )
            WITH VALUE #( ( %tky = <ls_order>-%tky
                             calendar_year = <ls_order>-calendar_year ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

 METHOD validate_delivery_date.
    " 1. Читаем данные заказов
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY MrktOrder
        FIELDS ( delivery_date mrkt_uuid )
        WITH CORRESPONDING #( keys ) " ВАЖНО: Пробел перед скобкой!
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      " 2. Читаем даты рынка для каждого заказа
      READ ENTITIES OF zam_i_product IN LOCAL MODE
        ENTITY Market
          FIELDS ( start_date end_date )
          WITH VALUE #( ( mrkt_uuid = ls_order-mrkt_uuid ) )
        RESULT DATA(lt_markets).

      READ TABLE lt_markets INTO DATA(ls_market) INDEX 1.
      IF sy-subrc = 0.

        " Проверка 1: Раньше даты начала
        IF ls_order-delivery_date < ls_market-start_date.
          APPEND VALUE #( %tky = ls_order-%tky ) TO failed-mrktorder.
          APPEND VALUE #( %tky = ls_order-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'Delivery date must be greater than Market Start Date' )
                          %element-delivery_date = if_abap_behv=>mk-on ) TO reported-mrktorder.

        " Проверка 2: Позже даты конца
        ELSEIF ls_market-end_date IS NOT INITIAL AND ls_order-delivery_date > ls_market-end_date.
          APPEND VALUE #( %tky = ls_order-%tky ) TO failed-mrktorder.
          APPEND VALUE #( %tky = ls_order-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'Delivery date must be less than or equal to Market End Date' )
                          %element-delivery_date = if_abap_behv=>mk-on ) TO reported-mrktorder.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
