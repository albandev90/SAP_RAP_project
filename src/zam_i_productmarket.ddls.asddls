@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child Product Market Interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_PRODUCTMARKET as select from zam_d_mrkt_trl
association to parent ZAM_I_PRODUCT as _Product on $projection.prod_uuid = _Product.prod_uuid
{
  key mrkt_uuid,
  prod_uuid,
  mrktid,
  status_confirm,
  start_date,
  end_date,
  

  _Product
}
