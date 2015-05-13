require 'active_shipping'
#include ActiveMerchant::Shipping

module Caboose
  class ShippingCalculator
        
    def self.custom_rates(store_config, order)          
      return eval(store_config.custom_shipping_function)    
    end
    
    #def self.rates(order)
    #  
    #  return [] if order.site.nil? || order.site.store_config.nil?
    #  sc = order.site.store_config
    #  if !sc.auto_calculate_shipping        
    #    rates = self.custom_rates(sc, order)
    #    return rates        
    #  end
    #
    #  origin = Location.new(
    #    :country => sc.origin_country,
    #    :state   => sc.origin_state,
    #    :city    => sc.origin_city,
    #    :zip     => sc.origin_zip
    #  )      
    #  destination = Location.new(
    #    :country     => sc.origin_country,
    #    :state       => order.shipping_address.state,
    #    :city        => order.shipping_address.city,
    #    :postal_code => order.shipping_address.zip
    #  )
    #  carriers = {}      
    #  carriers['UPS']   = UPS.new(  :login => sc.ups_username, :password => sc.ups_password, :key => sc.ups_key, :origin_account => sc.ups_origin_account)  if sc.ups_username   && sc.ups_username.strip.length   > 0 
    #  carriers['USPS']  = USPS.new( :login => sc.usps_username)                                                                                             if sc.usps_username  && sc.usps_username.strip.length  > 0
    #  carriers['FedEx'] = FedEx.new(:login => sc.fedex_username, :password => sc.fedex_password, :key => sc.fedex_key, :account => sc.fedex_account)        if sc.fedex_username && sc.fedex_username.strip.length > 0
    #  
    #  all_rates = []            
    #  order.order_packages.all.each do |op|                
    #    sp = op.shipping_package                            
    #    package = op.activemerchant_package
    #    rates = []
    #    carriers.each do |name, carrier|          
    #      if sp.uses_carrier(name)                        
    #        resp = carrier.find_rates(origin, destination, package)                        
    #        resp.rates.sort_by(&:price).each do |rate|                            
    #          sm = ShippingMethod.where( :carrier => name, :service_code => rate.service_code, :service_name => rate.service_name).first
    #          sm = ShippingMethod.create(:carrier => name, :service_code => rate.service_code, :service_name => rate.service_name) if sm.nil?
    #          next if !sp.uses_shipping_method(sm)
    #          price = rate.total_price
    #          price = rate.package_rates[0].rate if price.nil? && rate.package_rates && rate.package_rates.count > 0              
    #          rates << { :shipping_method => sm, :total_price => (price.to_d/100) }
    #        end
    #      end
    #    end        
    #    if rates.count == 0
    #      Caboose.log("Error: no shipping rates found for order package #{op.id}.")
    #    end
    #    all_rates << { :order_package => op, :rates => rates }        
    #  end            
    #  return all_rates
    #end
    
    def self.rates(order)
      
      return [] if order.site.nil? || order.site.store_config.nil?
      sc = order.site.store_config
      if !sc.auto_calculate_shipping        
        rates = self.custom_rates(sc, order)
        return rates        
      end

      all_rates = order.order_packages.all.collect{ |op| { 
        :order_package => op, 
        :rates => self.order_package_rates(op) 
      }}
      return all_rates
    end
    
    def self.order_package_rates(op)
      
      order = op.order
      sc = order.site.store_config
      sa = order.shipping_address
      origin      = ActiveShipping::Location.new(:country => sc.origin_country, :state => sc.origin_state, :city => sc.origin_city, :zip => sc.origin_zip)
      destination = ActiveShipping::Location.new(:country => sc.origin_country, :state => sa.state, :city => sa.city, :postal_code => sa.zip)
      carriers = {}      
      carriers['UPS']   = ActiveShipping::UPS.new(  :login => sc.ups_username, :password => sc.ups_password, :key => sc.ups_key, :origin_account => sc.ups_origin_account)  if sc.ups_username   && sc.ups_username.strip.length   > 0 
      carriers['USPS']  = ActiveShipping::USPS.new( :login => sc.usps_username)                                                                                             if sc.usps_username  && sc.usps_username.strip.length  > 0
      carriers['FedEx'] = ActiveShipping::FedEx.new(:login => sc.fedex_username, :password => sc.fedex_password, :key => sc.fedex_key, :account => sc.fedex_account)        if sc.fedex_username && sc.fedex_username.strip.length > 0
      
      sp = op.shipping_package                            
      package = op.activemerchant_package
      rates = []
      carriers.each do |name, carrier|          
        if sp.uses_carrier(name)                        
          resp = carrier.find_rates(origin, destination, package)                        
          resp.rates.sort_by(&:price).each do |rate|                            
            sm = ShippingMethod.where( :carrier => name, :service_code => rate.service_code, :service_name => rate.service_name).first
            sm = ShippingMethod.create(:carrier => name, :service_code => rate.service_code, :service_name => rate.service_name) if sm.nil?
            next if !sp.uses_shipping_method(sm)
            price = rate.total_price
            price = rate.package_rates[0].rate if price.nil? && rate.package_rates && rate.package_rates.count > 0              
            rates << { :shipping_method => sm, :total_price => (price.to_d/100) }
          end
        end
      end        
      if rates.count == 0
        Caboose.log("Error: no shipping rates found for order package #{op.id}.")
      end
      return rates
    end
    
    def self.calculate_rate(op)
      
      order = op.order
      sc = order.site.store_config
      sa = order.shipping_address
      origin      = ActiveShipping::Location.new(:country => sc.origin_country, :state => sc.origin_state, :city => sc.origin_city, :zip => sc.origin_zip)
      destination = ActiveShipping::Location.new(:country => sc.origin_country, :state => sa.state, :city => sa.city, :postal_code => sa.zip)

      carrier = case op.shipping_method.carrier                    
        when 'UPS'   then ActiveShipping::UPS.new(  :login => sc.ups_username, :password => sc.ups_password, :key => sc.ups_key, :origin_account => sc.ups_origin_account) 
        when 'USPS'  then ActiveShipping::USPS.new( :login => sc.usps_username)
        when 'FedEx' then ActiveShipping::FedEx.new(:login => sc.fedex_username, :password => sc.fedex_password, :key => sc.fedex_key, :account => sc.fedex_account)
        end
        
      #Caboose.log(op.shipping_method.inspect)

      sm = op.shipping_method
      package = op.activemerchant_package                                        
      resp = carrier.find_rates(origin, destination, package)                        
      resp.rates.sort_by(&:price).each do |rate|
        #Caboose.log("rate.service_code = #{rate.service_code}, rate.service_name = #{rate.service_name}")
        sm2 = ShippingMethod.where( :carrier => sm.carrier, :service_code => rate.service_code, :service_name => rate.service_name).first
        sm2 = ShippingMethod.create(:carrier => sm.carrier, :service_code => rate.service_code, :service_name => rate.service_name) if sm2.nil?
        if sm2.id == sm.id                    
          price = rate.total_price
          price = rate.package_rates[0].rate if price.nil? && rate.package_rates && rate.package_rates.count > 0              
          return price.to_d/100
        end        
      end
      return nil

    end

    def self.rate(order)
      return nil if !order.shipping_service_code
      self.rates(order).each { |rate| return rate if rate[:service_code] == order.shipping_service_code }
      return nil
    end
                
    # Calculates the packages required for all the items in the order
    #def self.packages_for_order(order)
    #
    #  # Make sure all the items in the order have attributes set
    #  order.line_items.each do |li|              
    #    v = li.variant
    #    Caboose.log("Error: variant #{v.id} has a zero weight") and return false if v.weight.nil? || v.weight == 0
    #    next if v.volume && v.volume > 0
    #    Caboose.log("Error: variant #{v.id} has a zero length") and return false if v.length.nil? || v.length == 0
    #    Caboose.log("Error: variant #{v.id} has a zero width" ) and return false if v.width.nil?  || v.width  == 0
    #    Caboose.log("Error: variant #{v.id} has a zero height") and return false if v.height.nil? || v.height == 0        
    #    v.volume = v.length * v.width * v.height
    #    v.save
    #  end
    #        
    #  # Reorder the items in the order by volume            
    #  h = {}
    #  order.line_items.each do |li|
    #    (1..li.quantity).each do |i|        
    #      v = li.variant          
    #      h[v.volume] = v          
    #    end
    #  end      
    #  variants = h.sort_by{ |k,v| k }.collect{ |x| x[1] }
    #  
    #  all_packages = ShippingPackage.reorder(:price).all
    #  packages = []
    #  
    #  # Now go through each variant and fit it in a new or existing package
    #  variants.each do |v|
    #    
    #    # See if the item will fit in any of the existing packages
    #    it_fits = false
    #    packages.each do |h|
    #      it_fits = h.shipping_package.fits(h.variants, v)
    #      if it_fits
    #        h.variants << v
    #        break
    #      end
    #    end        
    #    next if it_fits
    #    
    #    # Otherwise find the cheapest package the item will fit into
    #    all_packages.each do |p|          
    #      if p.fits(v)
    #        packages << StdClass.new('shipping_package' => p, 'variants' => [v])
    #        break
    #      end
    #    end
    #           
    #  end
    #  
    #  return packages
    #  
    #  #arr = []
    #  #packages.each do |h|
    #  #  p = h.package
    #  #  weight = 0.0
    #  #  h.variants.each{ |v| weight = weight + v.weight }
    #  #  weight = weight * 0.035274        
    #  #  arr << Package.new(weight, [p.length, p.width, p.height], :units => :imperial)      
    #  #end      
    #  #return arr
    #                  
    #end
  end
end
