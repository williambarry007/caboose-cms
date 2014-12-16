module Caboose
  class ShippingMethod < ActiveRecord::Base
    self.table_name = 'store_shipping_methods'
        
    attr_accessible :id,
      :carrier, 
      :service_code, 
      :service_name 
        
  end
end
