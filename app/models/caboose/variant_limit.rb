module Caboose
  class VariantLimit < ActiveRecord::Base
    self.table_name = 'store_variant_limits'
    
    belongs_to :variant
    belongs_to :user    
    attr_accessible :id   ,
      :variant_id         ,
      :user_id            ,
      :min_quantity_value ,
      :min_quantity_func  ,
      :max_quantity_value ,
      :max_quantity_func  ,
      :current_value
      
    def min_quantity(invoice)
      return self.min_quantity_value if self.min_quantity_func.nil? || self.min_quantity_func.strip.length == 0      
      return eval(self.min_quantity_func)            
    end
    
    def max_quantity(invoice)
      return self.max_quantity_value if self.max_quantity_func.nil? || self.max_quantity_func.strip.length == 0      
      return eval(self.max_quantity_func)            
    end

    def quantity_message(invoice)
      if self.min_quantity(invoice) == 0 && self.max_quantity(invoice) == 0
        return "You are not allowed to purchase this item."
      end
      if self.max_quantity(invoice)
        if self.min_quantity(invoice) && self.min_quantity(invoice) > 0
          return "You are allowed to purchase between #{self.min_quantity(invoice)} and #{self.max_quantity(invoice)} of this item."
        else
          return "You are allowed to purchase up to #{self.max_quantity(invoice)} of this item."
        end
      end
      if self.min_quantity(invoice) && self.min_quantity(invoice) > 0
        return "You must purchase at least #{self.min_quantity(invoice)} of this item." 
      end
      return nil
    end
    
    def no_purchases_allowed(invoice)
      return self.min_quantity(invoice) == 0 && self.max_quantity(invoice) == 0
    end
    
    def qty_within_range(qty, invoice)
      return false if self.min_quantity(invoice) && qty < self.min_quantity(invoice)
      return false if self.max_quantity(invoice) && qty > self.max_quantity(invoice)
      return true
    end
    
    def qty_too_low(qty, invoice)
      return self.min_quantity(invoice) && qty < self.min_quantity(invoice)
    end
    
    def qty_too_high(qty, invoice)
      return self.max_quantity(invoice) && qty > self.max_quantity(invoice)
    end
          
  end
end

