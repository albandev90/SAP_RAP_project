@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'secondary interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_UOM as select from zam_d_uom
{
    key msehi,
      dimid,
      isocode
}
