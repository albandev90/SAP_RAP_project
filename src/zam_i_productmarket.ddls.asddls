@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child Product Market Interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_PRODUCTMARKET as select from zam_d_mrkt_trl
association [0..1] to ZAM_I_MARKET as _MarketInfo on $projection.mrktid = _MarketInfo.mrktid
association to parent ZAM_I_PRODUCT as _Product on $projection.prod_uuid = _Product.prod_uuid
{
  key mrkt_uuid,
  prod_uuid,
  @ObjectModel.text.element: [ 'MarketName' ]
  mrktid,
  _MarketInfo.mrktname as MarketName,
  status_confirm,
  @EndUserText.label: 'Status Criticality'
  case status_confirm
    when 'X' then 3 // Если подтверждено (Yes) -> Зеленый
    else 1          // Если нет (No) -> Красный
  end as StatusCriticality,
  start_date,
  end_date,
  
  @Semantics.user.createdBy: true
  created_by,
  @Semantics.systemDateTime.createdAt: true
  creation_time,
  @Semantics.user.lastChangedBy: true
  changed_by,
  @Semantics.systemDateTime.lastChangedAt: true
  change_time,
  _MarketInfo.imageurl as imageurl,
  _Product,
  _MarketInfo
}
