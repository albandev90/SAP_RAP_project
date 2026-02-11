@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Contact Card Information'

define view entity ZAM_I_CONTACT 
  as select from zam_d_product
{
  key created_by as UserID,

  /* Используем MAX(), чтобы схлопнуть дубликаты и успокоить систему */
  @Semantics.text: true
  @Semantics.name.fullName: true
  max( concat('User ', created_by) ) as FullName,

  'SAP Developer' as JobTitle,

  @Semantics.eMail.address: true
  @Semantics.eMail.type: [#WORK]
  max( concat(created_by, '@sap.com') ) as Email,

  @Semantics.telephone.type: [#WORK]
  '+49 123 456 789' as Phone
} 
group by created_by  // <--- ГЛАВНОЕ ИСПРАВЛЕНИЕ
