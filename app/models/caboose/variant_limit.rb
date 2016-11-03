module Caboose
  class VariantLimit < ActiveRecord::Base
    self.table_name = 'store_variant_limits'
    
    belongs_to :variant
    belongs_to :user    
    attr_accessible :id ,
      :variant_id       ,
      :user_id          ,
      :min_quantity     ,
      :max_quantity     ,
      :current_value
      
    def quantity_message      
      if self.min_quantity == 0 && self.max_quantity == 0
        return "You are not allowed to purchase this item."
      end
      if self.max_quantity
        if self.min_quantity && self.min_quantity > 0
          return "You are allowed to purchase between #{self.min_quantity} and #{self.max_quantity} of this item".
        else
          return "You are allowed to purchase up to #{self.max_quantity} of this item."
        end
      end            
      return "You must purchase at least #{self.min_quantity} of this item." 
    end
    
    def no_purchases_allowed
      return self.min_quantity == 0 && self.max_quantity == 0
    end
    
    def qty_within_range(qty)
      return false if self.min_quantity && qty < self.min_quantity
      return false if self.max_quantity && qty > self.max_quantity
      return true
    end
    
    def qty_too_low(qty)
      return self.min_quantity && qty < self.min_quantity
    end
    
    def qty_too_high(qty)
      return self.max_quantity && qty > self.max_quantity
    end
          
  end
end
