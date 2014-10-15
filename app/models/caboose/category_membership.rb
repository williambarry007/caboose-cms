module Caboose
  class CategoryMembership < ActiveRecord::Base
    self.table_name = 'store_category_memberships'
    
    belongs_to :category
    belongs_to :product
    
    attr_accessible :category_id, :product_id
  end
end
