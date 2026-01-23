@EndUserText.label: 'Market Order Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZAM_C_MRKT_ORDER
  as projection on ZAM_I_MRKT_ORDER
{
  key order_uuid,
  key prod_uuid,
  key mrkt_uuid,
  
  orderid,
  quantity,
  calendar_year,
  delivery_date,
  @Semantics.amount.currencyCode: 'amountcurr'
  netamount,
  @Semantics.amount.currencyCode: 'amountcurr'
  grossamount,
  amountcurr,

    created_by,
    creation_time,
    changed_by,
    change_time,
  /* Associations */
  _Market  : redirected to parent ZAM_C_MARKET,
  _Product : redirected to ZAM_C_PRODUCT
}
