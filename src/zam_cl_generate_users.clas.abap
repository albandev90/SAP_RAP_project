CLASS zam_cl_generate_users DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zam_cl_generate_users IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    " 1. Очищаем таблицу перед загрузкой
    DELETE FROM zam_d_user.

    " 2. Вставляем данные Матильды
    " ВАЖНО: Скопируйте свой ID из Fiori Preview (например, CB9980000049)
    " и вставьте его вместо 'ВАШ_ID_ЗДЕСЬ'

    INSERT zam_d_user FROM @( VALUE #(
       user_id    = 'CB9980000049'   " <--- ВСТАВЬТЕ СЮДА ВАШ РЕАЛЬНЫЙ ID
        first_name = 'Mathilde'
        last_name  = 'Mary'
        email      = 'mathilde.benz@sap.com'
        phone      = '+49 123 456 789'
        job_title  = 'Senior SAP Developer' )


    ) .

    out->write( 'Users generated successfully!' ).
  ENDMETHOD.
ENDCLASS.
