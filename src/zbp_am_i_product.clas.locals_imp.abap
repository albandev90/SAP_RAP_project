CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Product RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Product RESULT result.
    METHODS SET_FIRST_PHASE FOR DETERMINE ON SAVE
      IMPORTING keys FOR Product~SET_FIRST_PHASE.
    METHODS VALIDATE_PG FOR VALIDATE ON SAVE
      IMPORTING keys FOR Product~VALIDATE_PG.
    METHODS VALIDATE_PRODID FOR VALIDATE ON SAVE
      IMPORTING keys FOR Product~VALIDATE_PRODID.
    METHODS MAKE_COPY FOR MODIFY
      IMPORTING keys FOR ACTION Product~MAKE_COPY.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Product RESULT result.

    METHODS MOVE_TO_NEXT_PHASE FOR MODIFY
      IMPORTING keys FOR ACTION Product~MOVE_TO_NEXT_PHASE RESULT result.
    METHODS VALIDATE_DATA FOR VALIDATE ON SAVE
      IMPORTING keys FOR Product~VALIDATE_DATA.

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD SET_FIRST_PHASE.
  READ ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
      ENTITY Product
      FIELDS ( phase ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products).
      DELETE lt_products WHERE phase IS NOT INITIAL.
      IF lt_products IS NOT INITIAL.
      MODIFY ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
        ENTITY Product
        UPDATE FIELDS ( phase )
        WITH VALUE #( FOR product IN lt_products (
                         %tky  = product-%tky
                         phase = 'PLAN' ) )
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.

METHOD VALIDATE_PG.
  " 1. Читаем введенные значения pgname
  READ ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
    ENTITY Product
    FIELDS ( pgname ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_products).

  " 2. Подготавливаем список уникальных имен для проверки (убираем пустые)
  DATA(lt_pg_to_check) = lt_products.
  DELETE lt_pg_to_check WHERE pgname IS INITIAL.
  SORT lt_pg_to_check BY pgname.
  DELETE ADJACENT DUPLICATES FROM lt_pg_to_check COMPARING pgname.

  IF lt_pg_to_check IS NOT INITIAL.
    " 3. Читаем ВСЕ группы из справочника в память
    SELECT pgname FROM zam_d_prod_group INTO TABLE @DATA(lt_db_groups).

    " 4. Проходим по введенным продуктам
    LOOP AT lt_products INTO DATA(ls_product) WHERE pgname IS NOT INITIAL.

      " Переводим ввод пользователя в UPPER для сравнения
      DATA(lv_input_upper) = to_upper( ls_product-pgname ).
      DATA(lv_exists)      = abap_false.

      " Ищем в считанной таблице, переводя каждое значение из базы в UPPER
      LOOP AT lt_db_groups INTO DATA(ls_db).
        IF to_upper( ls_db-pgname ) = lv_input_upper.
          lv_exists = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

      " 5. Если совпадение не найдено — выдаем ошибку
      IF lv_exists = abap_false.
        APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.

        APPEND VALUE #( %tky = ls_product-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Product Group doesn''t exist' )
                        %element-pgname = if_abap_behv=>mk-on ) TO reported-product.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMETHOD.

  METHOD VALIDATE_PRODID.
  READ ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
    ENTITY Product
    FIELDS ( prodid ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_products).

  IF lt_products IS NOT INITIAL.
    SELECT FROM zam_d_product
      FIELDS prodid
      FOR ALL ENTRIES IN @lt_products
      WHERE prodid = @lt_products-prodid
      INTO TABLE @DATA(lt_duplicates).

    LOOP AT lt_products INTO DATA(ls_product).
      IF line_exists( lt_duplicates[ prodid = ls_product-prodid ] ).

        APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.

        APPEND VALUE #( %tky = ls_product-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Product ID already exists.' )
                        %element-prodid = if_abap_behv=>mk-on ) TO reported-product.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMETHOD.

  METHOD MAKE_COPY.
  " 1. Получаем новый ID из того, что пользователь ввел во всплывающем окне
  DATA(lv_new_id) = keys[ 1 ]-%param-Product_ID.

  " 2. Проверка на дубликаты (как в твоем предыдущем задании)
  SELECT SINGLE FROM zam_d_product " Имя твоей таблицы базы данных
    FIELDS prodid
    WHERE prodid = @lv_new_id
    INTO @DATA(lv_exists).

  IF lv_exists IS NOT INITIAL.
    " Если такой ID уже есть, выводим ошибку 'Product ID already exists'
    APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-product.
    APPEND VALUE #( %tky = keys[ 1 ]-%tky
                    %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = 'Product ID already exists.' )
                  ) TO reported-product.
    RETURN.
  ENDIF.

  " 3. Читаем данные оригинала, который мы выбрали для копирования
  READ ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
    ENTITY Product
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_original).

  " 4. Создаем новую запись через MODIFY
  MODIFY ENTITIES OF ZAM_I_PRODUCT IN LOCAL MODE
    ENTITY Product
    CREATE FIELDS ( prodid pgname phase price taxrate price_currency )
    WITH VALUE #( FOR ls_orig IN lt_original (
       %cid   = keys[ 1 ]-%cid
       prodid = lv_new_id
       pgname = ls_orig-pgname
       phase  = 'PLAN'
       price = ls_orig-price
       taxrate  = ls_orig-taxrate
       price_currency = ls_orig-price_currency
    ) )
    MAPPED mapped
    FAILED failed
    REPORTED reported.
  ENDMETHOD.

  METHOD get_instance_features.
  " 1. Читаем фазу для каждой записи
  READ ENTITIES OF zam_i_product IN LOCAL MODE
    ENTITY Product
      FIELDS ( phase ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_products).

  LOOP AT lt_products INTO DATA(ls_product).
    " Определяем состояние полей в зависимости от фазы
    CASE ls_product-phase.

      WHEN 'PLAN'. " Согласно image_8d868c.png
        APPEND VALUE #( %tky = ls_product-%tky
                        %field-prodid = if_abap_behv=>fc-f-mandatory
                        %field-pgname = if_abap_behv=>fc-f-mandatory
                      ) TO result.

      WHEN 'DEV'. " Поля размеров и цены становятся обязательными
        APPEND VALUE #( %tky = ls_product-%tky
                        %field-prodid = if_abap_behv=>fc-f-read_only
                        %field-pgname = if_abap_behv=>fc-f-read_only
                        %field-height         = if_abap_behv=>fc-f-mandatory
                        %field-depth          = if_abap_behv=>fc-f-mandatory
                        %field-width          = if_abap_behv=>fc-f-mandatory
                        %field-sizam_uom       = if_abap_behv=>fc-f-mandatory
                        %field-price          = if_abap_behv=>fc-f-mandatory
                        %field-price_currency = if_abap_behv=>fc-f-mandatory
                        %field-taxrate        = if_abap_behv=>fc-f-mandatory
                      ) TO result.

      WHEN 'PROD' OR 'OUT'.
          APPEND VALUE #(
              %tky = ls_product-%tky

              " Переводим АБСОЛЮТНО ВСЕ бизнес-поля в режим Read Only
              %field-prodid         = if_abap_behv=>fc-f-read_only
              %field-pgname         = if_abap_behv=>fc-f-read_only
              %field-height         = if_abap_behv=>fc-f-read_only
              %field-depth          = if_abap_behv=>fc-f-read_only
              %field-width          = if_abap_behv=>fc-f-read_only
              %field-sizam_uom      = if_abap_behv=>fc-f-read_only
              %field-price          = if_abap_behv=>fc-f-read_only
              %field-price_currency = if_abap_behv=>fc-f-read_only
              %field-taxrate        = if_abap_behv=>fc-f-read_only
          ) TO result.
    ENDCASE.
  ENDLOOP.
ENDMETHOD.

  METHOD move_to_next_phase.
    " Читаем данные продукта и связанных рынков
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Product
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products)
      ENTITY Product BY \_Market
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    " Объявляем промежуточную таблицу для фильтрации рынков
    DATA lt_my_markets LIKE lt_markets.

    LOOP AT lt_products ASSIGNING FIELD-SYMBOL(<ls_product>).
      CLEAR lt_my_markets.

      " Фильтруем рынки для конкретного продукта
      lt_my_markets = VALUE #( FOR m IN lt_markets
                               WHERE ( prod_uuid = <ls_product>-prod_uuid )
                               ( m ) ).

      DATA(lv_next_phase) = <ls_product>-phase.
      DATA(lv_error_text) = VALUE string( ).

      CASE <ls_product>-phase.
        WHEN 'PLAN'.
          IF lines( lt_my_markets ) > 0.
            lv_next_phase = 'DEV'.
          ELSE.
            lv_error_text = 'Product must have at least one assigned Market'.
          ENDIF.

        WHEN 'DEV'.
          IF line_exists( lt_my_markets[ status_confirm = abap_true ] ).
            lv_next_phase = 'PROD'.
          ELSE.
            lv_error_text = 'At least one market must be confirmed (Status Yes)'.
          ENDIF.

        WHEN 'PROD'.
          DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
          DATA(lv_all_finished) = abap_true.

          IF lines( lt_my_markets ) > 0.
            LOOP AT lt_my_markets ASSIGNING FIELD-SYMBOL(<ls_market_row>).
              IF <ls_market_row>-end_date > lv_today.
                lv_all_finished = abap_false.
                EXIT.
              ENDIF.
            ENDLOOP. " ИСПРАВЛЕНО: было LOOP, должно быть ENDLOOP

            IF lv_all_finished = abap_true.
              lv_next_phase = 'OUT'.
            ELSE.
              lv_error_text = 'All markets must be finished (End Date <= today)'.
            ENDIF.
          ELSE.
            lv_error_text = 'No markets found to finish'.
          ENDIF.
      ENDCASE.

      " Если есть ошибка - выводим её в reported
      IF lv_error_text IS NOT INITIAL.
        APPEND VALUE #( %tky = <ls_product>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = lv_error_text ) ) TO reported-product.
      ELSE.
        " Если всё ок - обновляем фазу
        MODIFY ENTITIES OF zam_i_product IN LOCAL MODE
          ENTITY Product UPDATE FIELDS ( phase )
          WITH VALUE #( ( %tky = <ls_product>-%tky phase = lv_next_phase ) ).
      ENDIF.
    ENDLOOP.

    " Обновляем UI результатом
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Product ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated).
    result = VALUE #( FOR p IN lt_updated ( %tky = p-%tky %param = p ) ).
  ENDMETHOD.

  METHOD validate_data.
    " Читаем данные продукта
    READ ENTITIES OF zam_i_product IN LOCAL MODE
      ENTITY Product
        FIELDS ( phase price height width depth sizam_uom ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products).

    LOOP AT lt_products INTO DATA(ls_product).
      " Проверки выполняются для фаз DEV, PROD и OUT
      IF ls_product-phase = 'DEV' OR ls_product-phase = 'PROD' OR ls_product-phase = 'OUT'.

        " 1. Проверка Цены
        IF ls_product-price <= 0.
          APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.
          APPEND VALUE #( %tky = ls_product-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = 'Price must be greater than 0 in DEV phase' )
                          %element-price = if_abap_behv=>mk-on ) TO reported-product.
        ENDIF.

        " 2. Групповая проверка размеров (Height, Width, Depth)
        IF ls_product-height <= 0 OR ls_product-width <= 0 OR ls_product-depth <= 0.
          APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.

          " Мы привязываем ошибку к тому полю, которое пустое
          DATA(lv_msg) = 'Dimensions (Height, Width, Depth) must be greater than 0'.

          APPEND VALUE #( %tky = ls_product-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = lv_msg )
                          " Подсвечиваем все три поля, если хотя бы одно не заполнено
                          %element-height = if_abap_behv=>mk-on
                          %element-width  = if_abap_behv=>mk-on
                          %element-depth  = if_abap_behv=>mk-on ) TO reported-product.
        ENDIF.

        " 3. Проверка единицы измерения (Unit of Measure)
        IF ls_product-sizam_uom IS INITIAL.
          APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.
          APPEND VALUE #( %tky = ls_product-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = 'Unit of measure is mandatory' )
                          %element-sizam_uom = if_abap_behv=>mk-on ) TO reported-product.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
