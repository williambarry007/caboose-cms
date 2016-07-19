#
# VariantDefault
#
# :: Class Methods
# :: Instance Methods

module Caboose
  class VariantDefault < ActiveRecord::Base
    self.table_name = 'store_variant_defaults'

    belongs_to :site
    attr_accessible :id              ,    
      :site_id                       ,
      :cost                          ,
      :price                         ,       
      :available                     ,
      :quantity_in_stock             ,
      :ignore_quantity               ,
      :allow_backorder               ,
      :weight                        ,
      :length                        ,
      :width                         ,
      :height                        ,
      :volume                        ,
      :cylinder                      ,
      :requires_shipping             ,
      :taxable                       ,
      :shipping_unit_value           ,
      :flat_rate_shipping            ,
      :flat_rate_shipping_package_id ,
      :flat_rate_shipping_method_id  ,
      :flat_rate_shipping_single     ,
      :flat_rate_shipping_combined   ,    
      :status                        ,
      :downloadable                  ,
      :is_bundle                     
     
  end
end
