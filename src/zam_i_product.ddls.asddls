@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Root Entity'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define root view entity ZAM_I_PRODUCT as select from zam_d_product
association [0..1] to ZAM_I_PG as _ProductGroup on $projection.pgname = _ProductGroup.pgname
association [0..1] to ZAM_I_PHASE as _Phase on $projection.phase = _Phase.phaseid
association [0..1] to ZAM_I_UOM as _UOM on $projection.sizam_uom = _UOM.msehi
composition [0..*] of ZAM_I_PRODUCTMARKET as _Market
{
 key prod_uuid,
 @Search.defaultSearchElement: true 
    @Search.fuzzinessThreshold: 0.8
    prodid,
    @Search.defaultSearchElement: true
    pgname,
    @Semantics.quantity.unitOfMeasure: 'sizam_uom'
    height,
    @Semantics.quantity.unitOfMeasure: 'sizam_uom'
    depth,
    @Semantics.quantity.unitOfMeasure: 'sizam_uom'
    width,
    sizam_uom,
    @Semantics.amount.currencyCode: 'price_currency'
    price,
    price_currency,
    taxrate,
    phase,
    case phase
      when 'PLAN' then 1 
      when 'DEV'  then 2 
      when 'PROD' then 3 
      else 0 
    end as PhaseCriticality,
    @Semantics.user.createdBy: true
    created_by,
    @Semantics.systemDateTime.createdAt: true
    creation_time,
    @Semantics.user.lastChangedBy: true
    changed_by,
    @Semantics.systemDateTime.lastChangedAt: true
    change_time,   
  _ProductGroup,
  _Phase,
  _UOM,
  _Market
}
