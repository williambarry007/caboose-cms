require 'tax_cloud'

module Caboose
  class TaxCalculator
    
    def self.custom_tax(store_config, invoice)          
      return store_config.custom_tax_function && store_config.custom_tax_function.strip.length > 0 ? eval(store_config.custom_tax_function) : 0.00    
    end
    
    def self.tax(invoice)
      sc = invoice.site.store_config                                                      
      return self.custom_tax(sc, invoice) if !sc.auto_calculate_tax   

      return 0.00 if !invoice.shipping_address
      return 0.00 if !invoice.has_taxable_items?
      return 0.00 if !invoice.has_shippable_items?

      return invoice.subtotal * invoice.tax_rate if invoice.tax_rate # See if the tax rate has already been calculated

      t = self.transaction(invoice)
      Caboose.log(t.inspect)
      lookup = t.lookup
      tax = lookup.tax_amount
      
      # Save the tax rate      
      invoice.tax_rate = tax/invoice.subtotal
      invoice.save
      
      # Return the tax amount
      return tax                                             
    end
    
    def self.authorized(invoice)
      t = self.transaction(invoice)
      return if t.nil? || t.cart_items.nil? || t.cart_items.count == 0        
      t.invoice_id = invoice.id
      t.authorized            
    end
    
    def self.captured(invoice)
      t = self.transaction(invoice)      
      return if t.nil? || t.cart_items.nil? || t.cart_items.count == 0
      t.invoice_id = invoice.id
      t.captured            
    end
    
    def self.transaction(invoice)            
      sc = invoice.site.store_config 
      return nil if sc.nil? || !sc.auto_calculate_tax
      
      sa = invoice.shipping_address
      if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?        
        sa = invoice.billing_address
      end
      return nil if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?
      
      TaxCloud.configure do |config|
        config.api_login_id  = sc.taxcloud_api_id
        config.api_key       = sc.taxcloud_api_key
        config.usps_username = sc.usps_username
      end
      
      origin      = TaxCloud::Address.new(:address1 => sc.origin_address1 , :address2 => sc.origin_address2 , :city => sc.origin_city , :state => sc.origin_state , :zip5 => sc.origin_zip )      
      destination = TaxCloud::Address.new(:address1 => sa.address1        , :address2 => sa.address2        , :city => sa.city        , :state => sa.state        , :zip5 => sa.zip        )      
      transaction = TaxCloud::Transaction.new(:customer_id => invoice.customer_id, :cart_id => invoice.id, :origin => origin, :destination => destination)
      invoice.line_items.each_with_index do |li, i|
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

    #def self.tax(invoice)
    #  return 0.00 if !invoice.shipping_address
    #
    #  sc = invoice.site.store_config                        
    #  if !sc.auto_calculate_tax                        
    #    tax = self.custom_tax(sc, invoice)
    #    return tax
    #  end
    #  
    #  # See if the tax rate has already been calculated
    #  # If so, use that instead of doing another web service call
    #  if invoice.tax_rate
    #    return invoice.subtotal * invoice.tax_rate
    #  end
    #  
    #  sa = invoice.shipping_address
    #  if sa.nil? || sa.address1.nil? || sa.city.nil? || sa.state.nil? || sa.zip.nil?        
    #    sa = invoice.billing_address
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
    #    :customer_id => invoice.customer_id,
    #    :cart_id     => invoice.id,
    #    :origin      => origin,
    #    :destination => destination
    #  )
    #  invoice.line_items.each_with_index do |li, i|
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
    #  invoice.tax_rate = tax/invoice.subtotal
    #  invoice.save
    #  
    #  # Return the tax amount
    #  return tax                                             
    #end
    
  end
end
