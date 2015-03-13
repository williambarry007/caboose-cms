module Caboose
  class ProductCategorySort < ActiveRecord::Base
    self.table_name = 'store_product_category_sorts'
    self.primary_key = 'id'

    belongs_to :product
    belongs_to :category            
    attr_accessible :id,
      :product_id,
      :category_id,
      :sort_order
    
  end
end
