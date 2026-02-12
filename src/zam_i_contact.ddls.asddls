@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Contact Card Information'

/* Теперь читаем из реальной таблицы пользователей */
define view entity ZAM_I_CONTACT 
  as select from zam_d_user
{
  key user_id as UserID,

  /* Склеиваем Имя + Фамилия */
  @Semantics.text: true
  @Semantics.name.fullName: true
  concat_with_space(first_name, last_name, 1) as FullName,

  job_title as JobTitle,

  @Semantics.eMail.address: true
  @Semantics.eMail.type: [#WORK]
  email as Email,

  @Semantics.telephone.type: [#WORK]
  phone as Phone
}
/* Group By больше не нужен, так как в этой таблице ID уникальны */
