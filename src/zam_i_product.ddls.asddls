@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Root Entity'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define root view entity ZAM_I_PRODUCT as select from zam_d_product
association [0..1] to ZAM_I_PG as _ProductGroup on $projection.pgname = _ProductGroup.pgname
association [0..1] to ZAM_I_PHASE as _Phase on $projection.phase = _Phase.phaseid
association [0..1] to ZAM_I_UOM as _UOM on $projection.sizam_uom = _UOM.msehi
composition [0..*] of ZAM_I_PRODUCTMARKET as _Market
association [0..1] to ZAM_C_PRODUCT_ANALYZE as _ProductAnalyze 
    on $projection.prodid = _ProductAnalyze.ProdId
association [0..1] to ZAM_I_CONTACT as _CreatedByContact 
    on $projection.created_by = _CreatedByContact.UserID
    
  association [0..1] to ZAM_I_CONTACT as _ChangedByContact 
    on $projection.changed_by = _ChangedByContact.UserID
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

case cast( phase as abap.int4 )
      when 1 then 1 
      when 2 then 2 
      when 3 then 3 
      when 4 then 0
      else 9       
    end as PhaseCriticality,
 
    case cast( phase as abap.int4 )
      when 1 then 20
      when 2 then 60
      when 3 then 95
      when 4 then 100
      else 0 
    end as IncomePercentage,

    case cast( phase as abap.int4 )
      when 1 then 1 
      when 2 then 2 
      when 3 then 3 
      else 0 
    end as IncomePercentageCriticality,
    @Semantics.user.createdBy: true
    created_by,
    @Semantics.systemDateTime.createdAt: true
    creation_time,
    @Semantics.user.lastChangedBy: true
    changed_by,
    @Semantics.systemDateTime.lastChangedAt: true
    change_time,  
  cast( '' as abap.char(30) ) as Measures,
  _ProductGroup,
  _Phase,
  _UOM,
  _Market,
  _ProductAnalyze,
  _CreatedByContact,
  _ChangedByContact
}
