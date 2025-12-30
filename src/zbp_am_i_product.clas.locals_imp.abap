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

ENDCLASS.
