module Caboose
  class GiftCard < ActiveRecord::Base
    self.table_name  = 'store_gift_cards'
    self.primary_key = 'id'
        
    belongs_to :site    
    has_many :discounts
    has_many :orders, :through => :discounts    
    attr_accessible :id,
      :site_id,      
      :name,  # The name of this discount            
      :code,  # The code the customer has to input to apply for this discount
      :card_type,
      :total,
      :balance,
      :min_order_total, # The minimum order total required to be able to use the card
      :date_available,
      :date_expires,
      :status            
            
    STATUS_INACTIVE = 'Inactive'
    STATUS_ACTIVE   = 'Active'
    STATUS_EXPIRED  = 'Expired'
    
    CARD_TYPE_AMOUNT      = 'Amount'
    CARD_TYPE_PERCENTAGE  = 'Percentage'
    CARD_TYPE_NO_SHIPPING = 'No Shipping'
    CARD_TYPE_NO_TAX      = 'No Tax'
    
    after_initialize :check_nil_fields
    
    def check_nil_fields
      self.total           = 0.00 if self.total.nil?
      self.balance         = 0.00 if self.balance.nil?          
      self.min_order_total = 0.00 if self.min_order_total.nil?  
    end

    def valid_for_order?(order)
      return false if self.status != GiftCard::STATUS_ACTIVE
      return false if self.date_available && DateTime.now.utc < self.date_available
      return false if self.date_expires && DateTime.now.utc > self.date_expires
      return false if self.card_type == GiftCard::CARD_TYPE_AMOUNT && self.balance <= 0      
      return false if self.min_order_total && order.total < self.min_order_total
      return true
    end
    
  end
end

# Flat amount - $10 off
# Flat amount off if you spend over a certain amount
# Percentage off
# Percentage amount off if you spend over a certain amount
# Free shipping
# Free shipping if you spend over a certain amount
# No Tax
# No tax if you spend over a certain amount
