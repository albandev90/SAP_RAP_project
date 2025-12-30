@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'secondary interface CDS view'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_MARKET as select from zam_d_market
{
    key mrktid,
      mrktname,
      code,
      imageurl
}
