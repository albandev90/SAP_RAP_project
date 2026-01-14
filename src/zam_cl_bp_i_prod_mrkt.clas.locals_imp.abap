CLASS lhc_Market DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validate_end_date FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validate_end_date.

    METHODS validate_market FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validate_market.

    METHODS validate_start_date FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validate_start_date.
    METHODS CHECK_DUPLICATES FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~CHECK_DUPLICATES.
    METHODS CONFIRM FOR MODIFY
      IMPORTING keys FOR ACTION Market~CONFIRM RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Market RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Market RESULT result.

ENDCLASS.

CLASS lhc_Market IMPLEMENTATION.

  METHOD validate_end_date.
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market FIELDS ( start_date end_date ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-end_date IS NOT INITIAL.
        " Проверка 1: Больше сегодня
        IF ls_market-end_date <= lv_today.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #( %tky = ls_market-%tky
                          %msg = new_message_with_text( text = 'End Date must be greater than today'
                                                        severity = if_abap_behv_message=>severity-error )
                          %element-end_date = if_abap_behv=>mk-on ) TO reported-market.
        " Проверка 2: Больше даты начала
        ELSEIF ls_market-start_date IS NOT INITIAL AND ls_market-end_date <= ls_market-start_date.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #( %tky = ls_market-%tky
                          %msg = new_message_with_text( text = 'End Date must be greater than Start Date'
                                                        severity = if_abap_behv_message=>severity-error )
                          %element-end_date = if_abap_behv=>mk-on ) TO reported-market.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_market.

    " 1. Читаем данные, которые пользователь пытается сохранить
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( mrktid )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    " 2. Проверяем каждую строку
    LOOP AT lt_markets INTO DATA(ls_market).
      " Проверяем, есть ли такой ID в таблице-справочнике
      SELECT SINGLE @abap_true
        FROM zam_d_market
        WHERE mrktid = @ls_market-mrktid
        INTO @DATA(lv_exists).

      IF lv_exists <> abap_true.
        " 3. Если рынка нет в справочнике — блокируем сохранение (failed)
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        " 4. Выводим сообщение об ошибке на экран (reported)
        APPEND VALUE #( %tky = ls_market-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Market doesn''t exist' )
                        %element-mrktid = if_abap_behv=>mk-on ) TO reported-market.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validate_start_date.

    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market FIELDS ( start_date ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-start_date IS NOT INITIAL AND ls_market-start_date < lv_today.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
        APPEND VALUE #( %tky = ls_market-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Start Date must be greater than today' )
                        %element-start_date = if_abap_behv=>mk-on ) TO reported-market.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD check_duplicates.
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market FIELDS ( prod_uuid mrktid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      " Ищем в базе записи с таким же продуктом и таким же рынком
      SELECT SINGLE @abap_true FROM zam_d_mrkt_trl
        WHERE prod_uuid = @ls_market-prod_uuid
          AND mrktid    = @ls_market-mrktid
          AND mrkt_uuid <> @ls_market-mrkt_uuid " Исключаем саму себя
        INTO @DATA(lv_exists).

      IF lv_exists = abap_true.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
        APPEND VALUE #( %tky = ls_market-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'This market is already assigned to the product' )
                        %element-mrktid = if_abap_behv=>mk-on ) TO reported-market.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD confirm.
    " Исправленный тест: выводим сообщение при нажатии
    APPEND VALUE #( %tky = keys[ 1 ]-%tky
                    %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-success
                             text     = 'Button clicked!' ) ) TO reported-market.

    " 1. Обновление статуса в памяти (буфере)
    MODIFY ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market
        UPDATE FIELDS ( status_confirm )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        status_confirm = abap_true ) )
    FAILED failed
    REPORTED reported.

    " 2. Читаем результат, чтобы UI увидел изменения (status_confirm и StatusCriticality)
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    " 3. Возвращаем результат на фронтенд
    result = VALUE #( FOR ls_market IN lt_markets ( %tky = ls_market-%tky
                                                    %param = ls_market ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( status_confirm ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    result = VALUE #( FOR ls_market IN lt_markets
      ( %tky = ls_market-%tky
        " Условие активности кнопки
        %action-confirm = COND #( WHEN ls_market-status_confirm = abap_true
                                  THEN if_abap_behv=>fc-o-disabled
                                  ELSE if_abap_behv=>fc-o-enabled )
      ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.
