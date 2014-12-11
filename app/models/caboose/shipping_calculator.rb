require 'active_shipping'
include ActiveMerchant::Shipping

module Caboose
  class ShippingCalculator
    
    def self.custom_rates(store_config, order)          
      return eval(store_config.shipping_rates_function)    
    end
    
    def self.rates(order)
      return [] if Caboose::store_shipping.nil?
            
      store_config = order.site.store_config
      if store_config        
        rates = self.custom_rates(store_config, order)
        return rates        
      end
            
      ss = Caboose::store_shipping
      origin = Location.new(
        :country => ss[:origin][:country],
        :state   => ss[:origin][:state],
        :city    => ss[:origin][:city],
        :zip     => ss[:origin][:zip]
      )      
      destination = Location.new(
        :country     => ss[:origin][:country],
        :state       => order.shipping_address.state,
        :city        => order.shipping_address.city,
        :postal_code => order.shipping_address.zip
      )      
      ups = ss[:ups] ? UPS.new(:key => ss[:ups][:key], :login => ss[:ups][:username], :password => ss[:ups][:password], :origin_account => ss[:ups][:origin_account]) : nil        
      usps = ss[:usps] ? USPS.new(:login => ss[:usps][:username]) : nil                        
                  
      all_rates = []
      order.packages.each do |op|              
        sp = op.shipping_package
        package = op.activemerchant_package
        rates = []
        if ups                  
          resp = ups.find_rates(origin, destination, package)      
          resp.rates.sort_by(&:price).each do |rate|
            next if rate.service_code != sp.service_code            
            rates << { :carrier => 'UPS', :service_code => rate.service_code, :service_name => rate.service_name, :price => rate.total_price.to_d / 100 }
          end
        end
        if usps
          resp = usps.find_rates(origin, destination, package)
          resp.rates.sort_by(&:price).each do |rate|
            next if rate.service_code != sp.service_code            
            rates << { :carrier => 'USPS', :service_code => rate.service_code, :service_name => rate.service_name, :total_price  => rate.total_price.to_d / 100 }
          end
        end
        all_rates << { :order_package => op, :rates => rates }
      end            
      return all_rates
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
