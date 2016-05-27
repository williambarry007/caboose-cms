module Caboose
  class Discount < ActiveRecord::Base
    self.table_name  = 'store_invoice_discounts'
    self.primary_key = 'id'
            
    belongs_to :gift_card
    belongs_to :invoice
    attr_accessible :id,
      :gift_card_id,
      :invoice_id,
      :amount

    after_find do |d|
      d.amount = 0.00 if d.amount.nil?                        
    end
      
  end
end
