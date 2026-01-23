@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface view order'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_MRKT_ORDER as select from zam_d_mrkt_order
association to parent ZAM_I_PRODUCTMARKET as _Market  on $projection.mrkt_uuid = _Market.mrkt_uuid
  association [1..1] to ZAM_I_PRODUCT       as _Product on $projection.prod_uuid = _Product.prod_uuid
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
      
cast( 'USD' as abap.cuky ) as amountcurr,
      
      /* Adimin data */
      @Semantics.user.createdBy: true
      created_by,
      @Semantics.systemDateTime.createdAt: true
      creation_time,
      @Semantics.user.lastChangedBy: true
      changed_by,
      @Semantics.systemDateTime.lastChangedAt: true
      change_time,

      /* Associations */
      _Market,
      _Product
}
