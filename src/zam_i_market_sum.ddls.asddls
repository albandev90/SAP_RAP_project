@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Market Totals'
define view entity ZAM_I_MARKET_SUM
  as select from zam_d_mrkt_order
{
  key mrkt_uuid,
  
  @Aggregation.default: #SUM
  sum(quantity)     as TotalQuantity,
  
  @Aggregation.default: #SUM
  @Semantics.amount.currencyCode: 'amountcurr'
  sum(netamount)    as TotalNetAmount,
  
  @Aggregation.default: #SUM
  @Semantics.amount.currencyCode: 'amountcurr'
  sum(grossamount)  as TotalGrossAmount,
  
  amountcurr 
}
group by
  mrkt_uuid,
  amountcurr
