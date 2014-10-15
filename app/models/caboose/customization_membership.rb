module Caboose
  class CustomizationMembership < ActiveRecord::Base
    self.table_name = 'store_customization_memberships'
    
    belongs_to :product
    belongs_to :customization, :class_name => 'Caboose::Product'
    
    attr_accessible :product_id, :customization_id
  end
end
