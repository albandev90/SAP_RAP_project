@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Projection View'
@Metadata.allowExtensions: true  -- Разрешаем использование MDE
@Search.searchable: true

define root view entity ZAM_C_PRODUCT
  provider contract transactional_query
  as projection on ZAM_I_PRODUCT
{
    key prod_uuid,
    
    @Search.defaultSearchElement: true
    prodid,
    
    @Search.defaultSearchElement: true
    pgname,
    
    height,
    depth,
    width,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_UOM', element: 'msehi' } }]
    sizam_uom,
    
    price,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_CURRENCY', element: 'Currency' } }]
    price_currency,
    
    taxrate,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZAM_I_PHASE', element: 'phaseid' } }]
    phase,
    
    -- Это поле нужно оставить здесь, так как это логика данных
    @UI.hidden: true 
    PhaseCriticality,
    
    -- Системные поля
    created_by,
    creation_time,
    changed_by,
    change_time,
    
    -- Алиас для картинки
    _ProductGroup.imageurl as ProductGroupImage,
    
    -- Редирект ассоциаций
    _Market : redirected to composition child ZAM_C_MARKET
}
