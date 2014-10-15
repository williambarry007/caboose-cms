module Caboose
  class ProductImageVariant < ActiveRecord::Base
    self.table_name = 'store_product_image_variants'
    
    belongs_to :product_image
    belongs_to :variant
    
    attr_accessible :product_image_id, :variant_id
  end
end
