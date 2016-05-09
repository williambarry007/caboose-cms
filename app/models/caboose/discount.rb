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

    after_find do |d|
      d.amount = 0.00 if d.amount.nil?                        
    end
    
    def calculate_amount                                
      gc = self.gift_card      
      self.amount = case self.gift_card.card_type
        when GiftCard::CARD_TYPE_AMOUNT      then (self.order.total >= gc.balance ? gc.balance : self.order.total)
        when GiftCard::CARD_TYPE_PERCENTAGE  then self.order.subtotal * gc.total
        when GiftCard::CARD_TYPE_NO_SHIPPING then self.order.shipping
        when GiftCard::CARD_TYPE_NO_TAX      then self.order.tax
      end
      self.save
    end
      
  end
end
