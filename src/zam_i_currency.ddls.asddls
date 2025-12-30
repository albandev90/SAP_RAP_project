@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'secondary interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_CURRENCY as select from I_Currency
{
 key Currency,
      CurrencyISOCode  
}
