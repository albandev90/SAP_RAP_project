@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Group Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_PG
  as select from zam_d_prod_group
{
  key pgid,
      pgname,
      imageurl
}
