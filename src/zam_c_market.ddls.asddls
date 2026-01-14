@EndUserText.label: 'Market Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZAM_C_MARKET
  as projection on ZAM_I_PRODUCTMARKET
{
    key mrkt_uuid,
    prod_uuid,
    
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    @ObjectModel.text.element: [ 'MarketName' ]
    mrktid,
    MarketName,
    status_confirm,
    StatusCriticality,
    start_date,
    end_date,
    
    imageurl,
    created_by,
    creation_time,
    changed_by,
    change_time,
   
    _Product : redirected to parent ZAM_C_PRODUCT
    
}
