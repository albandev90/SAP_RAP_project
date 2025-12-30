@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Projection View'
@Search.searchable: true
@UI.headerInfo: {
    typeName: 'Product',
    typeNamePlural: 'Products',
    title: { type: #STANDARD, value: 'prodid' },
    description: { type: #STANDARD, value: 'pgname' },
    imageUrl: 'ProductGroupImage' 
}
@UI.presentationVariant: [{
    sortOrder: [
        { by: 'prodid', direction: #ASC }, 
        { by: 'pgname', direction: #ASC }  
    ]
}]
define root view entity ZAM_C_PRODUCT
  provider contract transactional_query
  as projection on ZAM_I_PRODUCT
{
@UI.facet: [
{ id: 'HeaderNetPrice',
      purpose: #HEADER,
      type: #FIELDGROUP_REFERENCE,
      targetQualifier: 'HeaderPriceOnly', 
      position: 10 },

    { id: 'HeaderProductID',
      purpose: #HEADER,
      type: #FIELDGROUP_REFERENCE,
      targetQualifier: 'HeaderData', 
      position: 20 },

    { id: 'HeaderTaxRate',
      purpose: #HEADER,
      type: #FIELDGROUP_REFERENCE,
      targetQualifier: 'HeaderPrice', 
      position: 30 },
      
    { id: 'GeneralInfo',
      type: #COLLECTION,
      label: 'General Information',
      position: 10 },

    { id: 'BasicDataFacet',
      parentId: 'GeneralInfo',
      type: #FIELDGROUP_REFERENCE,
      label: 'Basic Data',
      targetQualifier: 'BasicData',
      position: 10 },

  
    { id: 'SizesFacet',
      parentId: 'GeneralInfo',
      type: #FIELDGROUP_REFERENCE,
      label: 'Size Dimensions',
      targetQualifier: 'Sizes',
      position: 20 },

    { id: 'PricesFacet',
      parentId: 'GeneralInfo',
      type: #FIELDGROUP_REFERENCE,
      label: 'Price Details',
      targetQualifier: 'Prices',
      position: 30 },
      
      { id: 'MarketFacet',
      type: #LINEITEM_REFERENCE,
      label: 'Markets',
      position: 40,
      targetElement: '_Market' }
]
    key prod_uuid,
   
    @UI: {
      lineItem:       [ 
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'MAKE_COPY', label: 'Copy' } 
      ],
      selectionField: [ { position: 10 } ],
      
      identification: [ 
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'MAKE_COPY', label: 'Copy' }
      ],
      
      fieldGroup:     [ { qualifier: 'HeaderData', position: 10 },
                        { qualifier: 'BasicData', position: 10 } ]
    }
    @Search.defaultSearchElement: true
    prodid,
    @UI: { lineItem:       [ { position: 20 } ],
           fieldGroup:     [ { qualifier: 'BasicData', position: 20 } ],
           selectionField: [ { position: 20 } ] }
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_PG', element: 'pgname' } }]
    @Search.defaultSearchElement: true
    pgname,
    @UI: { fieldGroup:     [ { qualifier: 'Sizes', position: 10 } ] }
    @EndUserText.label: 'Height'
    height,
    @UI: { fieldGroup:     [ { qualifier: 'Sizes', position: 20 } ] }
    @EndUserText.label: 'Depth'
    depth,
    @UI: { fieldGroup:     [ { qualifier: 'Sizes', position: 30 } ] }
    @EndUserText.label: 'Width'
    width,
    @UI: { lineItem:       [ { position: 30 } ],
           identification: [ { position: 30 } ],
           selectionField: [ { position: 30 } ] }
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_UOM', element: 'msehi' } }]
    sizam_uom,
    @UI: { lineItem:       [ { position: 40 } ],
           fieldGroup:     [ { qualifier: 'Prices', position: 10 },
                                { qualifier: 'HeaderPriceOnly', position: 10 } ] }
    @EndUserText.label: 'Net Price'
    price,
    @UI: { lineItem:       [ { position: 40 } ],
           identification: [ { position: 40 } ],
           selectionField: [ { position: 40 } ] }
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_CURRENCY', element: 'Currency' } }]
    price_currency,
    @UI: { fieldGroup:     [ { qualifier: 'Prices', position: 20 },
                                { qualifier: 'HeaderTaxOnly', position: 20 } ] }
    @EndUserText.label: 'Tax Rate'
    taxrate,
    created_by,
    @UI: { lineItem:       [ { position: 50, criticality: 'PhaseCriticality' } ],
           fieldGroup: [ { qualifier: 'BasicData', position: 50, criticality: 'PhaseCriticality' } ],
           selectionField: [ { position: 50 } ] }
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_PHASE', element: 'phaseid' } }]
    @EndUserText.label: 'Phase'
    phase,
    @UI.hidden: true 
    PhaseCriticality,
    creation_time,
    changed_by,
    change_time,
    _ProductGroup.imageurl as ProductGroupImage,
    _Market : redirected to composition child ZAM_C_MARKET
    
}
