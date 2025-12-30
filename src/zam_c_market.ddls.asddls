@EndUserText.label: 'Market Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZAM_C_MARKET
  as projection on ZAM_I_PRODUCTMARKET
{
    key mrkt_uuid,
    prod_uuid,
    
    
    mrktid,
    status_confirm,
    start_date,
    end_date,
    
    
    _Product : redirected to parent ZAM_C_PRODUCT
}
