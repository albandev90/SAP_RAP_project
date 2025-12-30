@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: ' secondary interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZAM_I_PHASE as select from zam_d_phase
{
    key cast( phaseid as abap.char( 20 ) ) as phaseid,
      phase
}
