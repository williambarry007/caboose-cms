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
    
    def calculate_amount                                
      gc = self.gift_card      
      self.amount = case self.gift_card.card_type
        when GiftCard::CARD_TYPE_AMOUNT      then (self.invoice.total >= gc.balance ? gc.balance : self.invoice.total)
        when GiftCard::CARD_TYPE_PERCENTAGE  then self.invoice.subtotal * gc.total
        when GiftCard::CARD_TYPE_NO_SHIPPING then self.invoice.shipping
        when GiftCard::CARD_TYPE_NO_TAX      then self.invoice.tax
      end
      self.save
    end
      
  end
end
