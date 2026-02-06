@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Analyze Quick View'
@Metadata.allowExtensions: true

/* Это имя понадобится нам позже для настройки ссылки без Launchpad */
@Consumption.semanticObject: 'ProductAnalyze' 

define view entity ZAM_C_PRODUCT_ANALYZE 
  as select from ZAM_I_PRODUCT as Product
{
  
  key prodid as ProdId,
  pgname as ProductName,
  
  /* Добавим цену и валюту для красоты */
  @Semantics.amount.currencyCode: 'Currency'
  price  as Price,
  price_currency as Currency,

  /* Технические поля для связи */
  phase  as PhaseId
}
