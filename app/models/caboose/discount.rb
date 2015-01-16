module Caboose
  class Discount < ActiveRecord::Base
    self.table_name  = 'store_order_discounts'
    self.primary_key = 'id'
            
    belongs_to :gift_card
    belongs_to :order
    attr_accessible :id,
      :gift_card_id,
      :order_id,
      :amount      
      
  end
end
