require 'tax_cloud'

module Caboose
  class TaxCalculator
    
    def self.custom_tax(store_config, order)          
      return eval(store_config.custom_tax_function)    
    end
    
    def self.tax(order)
      return 0.00 if !order.shipping_address
      return 0.00 if !order.has_taxable_items?

      sc = order.site.store_config                                                      
      return self.custom_tax(sc, order) if !sc.auto_calculate_tax      
      return order.subtotal * order.tax_rate if order.tax_rate # See if the tax rate has already been calculated

      t = self.transaction(order)
      Caboose.log(t.inspect)
      lookup = t.lookup
      tax = lookup.tax_amount
      
      # Save the tax rate      
      order.tax_rate = tax/order.subtotal
      order.save
      
      # Return the tax amount
      return tax                                             
    end
    
    def self.authorized(order)
      t = self.transaction(order)
      return if t.nil? || t.cart_items.nil? || t.cart_items.count == 0        
      t.order_id = order.id
      t.authorized            
    end
    
    def self.captured(order)
      t = self.transaction(order)      
      return if t.nil? || t.cart_items.nil? || t.cart_items.count == 0
      t.order_id = order.id
      t.captured            
    end
    
    def self.transaction(order)            
      sc = order.site.store_config 
      return nil if sc.nil? || !sc.auto_calculate_tax
      
      sa = order.shipping_address
      if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?        
        sa = order.billing_address
      end
      return nil if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?
      
      TaxCloud.configure do |config|
        config.api_login_id  = sc.taxcloud_api_id
        config.api_key       = sc.taxcloud_api_key
        config.usps_username = sc.usps_username
      end
      
      origin      = TaxCloud::Address.new(:address1 => sc.origin_address1 , :address2 => sc.origin_address2 , :city => sc.origin_city , :state => sc.origin_state , :zip5 => sc.origin_zip )      
      destination = TaxCloud::Address.new(:address1 => sa.address1        , :address2 => sa.address2        , :city => sa.city        , :state => sa.state        , :zip5 => sa.zip        )      
      transaction = TaxCloud::Transaction.new(:customer_id => order.customer_id, :cart_id => order.id, :origin => origin, :destination => destination)
      order.line_items.each_with_index do |li, i|
        next if !li.variant.taxable # Skip any non-taxable items        
        transaction.cart_items << TaxCloud::CartItem.new(
          :index    => i,
          :item_id  => li.variant.id,
          :tic      => TaxCloud::TaxCodes::GENERAL,
          :price    => li.unit_price,
          :quantity => li.quantity
        )
      end
      return transaction
    end

    #def self.tax(order)
    #  return 0.00 if !order.shipping_address
    #
    #  sc = order.site.store_config                        
    #  if !sc.auto_calculate_tax                        
    #    tax = self.custom_tax(sc, order)
    #    return tax
    #  end
    #  
    #  # See if the tax rate has already been calculated
    #  # If so, use that instead of doing another web service call
    #  if order.tax_rate
    #    return order.subtotal * order.tax_rate
    #  end
    #  
    #  sa = order.shipping_address
    #  if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?        
    #    sa = order.billing_address
    #  end
    #  return 0.00 if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?
    #  
    #  TaxCloud.configure do |config|
    #    config.api_login_id  = sc.taxcloud_api_id
    #    config.api_key       = sc.taxcloud_api_key
    #    config.usps_username = sc.usps_username
    #  end
    #  
    #  origin = TaxCloud::Address.new(
    #    :address1 => sc.origin_address1,
    #    :address2 => sc.origin_address2,
    #    :city     => sc.origin_city,
    #    :state    => sc.origin_state,
    #    :zip5     => sc.origin_zip
    #  )      
    #  destination = TaxCloud::Address.new(
    #    :address1 => sa.address1,
    #    :address2 => sa.address2,
    #    :city     => sa.city,
    #    :state    => sa.state,
    #    :zip5     => sa.zip
    #  )      
    #  transaction = TaxCloud::Transaction.new(
    #    :customer_id => order.customer_id,
    #    :cart_id     => order.id,
    #    :origin      => origin,
    #    :destination => destination
    #  )
    #  order.line_items.each_with_index do |li, i|
    #    next if !li.variant.taxable # Skip any non-taxable items        
    #    transaction.cart_items << TaxCloud::CartItem.new(
    #      :index    => i,
    #      :item_id  => li.variant.id,
    #      :tic      => TaxCloud::TaxCodes::GENERAL,
    #      :price    => li.unit_price,
    #      :quantity => li.quantity
    #    )
    #  end
    #  lookup = transaction.lookup
    #  tax = lookup.tax_amount
    #  
    #  # Save the tax rate      
    #  order.tax_rate = tax/order.subtotal
    #  order.save
    #  
    #  # Return the tax amount
    #  return tax                                             
    #end
    
  end
end
