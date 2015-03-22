require 'tax_cloud'

module Caboose
  class TaxCalculator
    
    def self.custom_tax(store_config, order)          
      return eval(store_config.custom_tax_function)    
    end
    
    def self.tax(order)
      return 0.00 if !order.shipping_address

      sc = order.site.store_config                        
      if !sc.auto_calculate_tax                        
        tax = self.custom_tax(sc, order)
        return tax
      end
      
      # See if the tax rate has already been calculated
      # If so, use that instead of doing another web service call
      if order.tax_rate
        return order.subtotal * order.tax_rate
      end
      
      sa = order.shipping_address
      if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?        
        sa = order.billing_address
      end      
      return 0.00 if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?
      
      TaxCloud.configure do |config|
        config.api_login_id  = sc.taxcloud_api_id
        config.api_key       = sc.taxcloud_api_key
        config.usps_username = sc.usps_username
      end
      
      origin = TaxCloud::Address.new(
        :address1 => sc.origin_address1,
        :address2 => sc.origin_address2,
        :city     => sc.origin_city,
        :state    => sc.origin_state,
        :zip5     => sc.origin_zip
      )      
      destination = TaxCloud::Address.new(
        :address1 => sa.address1,
        :address2 => sa.address2,
        :city     => sa.city,
        :state    => sa.state,
        :zip5     => sa.zip
      )      
      transaction = TaxCloud::Transaction.new(
        :customer_id => order.customer_id,
        :cart_id     => order.id,
        :origin      => origin,
        :destination => destination
      )
      order.line_items.each_with_index do |li, i|        
        transaction.cart_items << TaxCloud::CartItem.new(
          :index    => i,
          :item_id  => li.variant.id,
          :tic      => TaxCloud::TaxCodes::GENERAL,
          :price    => li.unit_price,
          :quantity => li.quantity
        )
      end
      lookup = transaction.lookup
      tax = lookup.tax_amount
      
      # Save the tax rate      
      order.tax_rate = tax/order.subtotal
      order.save
      
      # Return the tax amount
      return tax
                          
      #return 0.00 if address.nil? || address.city.nil? || address.state.nil?       
      #return 0 if address.state.downcase != 'al'
      #return 0.09
      
      #rate = 0.00      
      #city = address.city.downcase            
      #rate = rate + 0.05 if city == 'brookwood'  
      #rate = rate + 0.05 if city == 'coaling'    
      #rate = rate + 0.05 if city == 'coker'      
      #rate = rate + 0.05 if city == 'holt'       
      #rate = rate + 0.05 if city == 'holt CDP'   
      #rate = rate + 0.05 if city == 'lake View'  
      #rate = rate + 0.05 if city == 'moundville' 
      #rate = rate + 0.05 if city == 'northport'  
      #rate = rate + 0.05 if city == 'tuscaloosa' 
      #rate = rate + 0.05 if city == 'vance'      
      #rate = rate + 0.05 if city == 'woodstock'      
      #rate = rate + 0.04 if address.state.downcase == 'al' || address.state.downcase == 'alabama'              
      #return rate.round(2)             
    end
  end
end
