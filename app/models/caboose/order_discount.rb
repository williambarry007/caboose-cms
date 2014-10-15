module Caboose        
  class OrderDiscount < ActiveRecord::Base
    self.table_name = 'store_order_discounts'
    
    belongs_to :order
    belongs_to :discount
    
    attr_accessible :order_id, :discount_id
  end
end
