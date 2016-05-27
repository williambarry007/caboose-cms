require 'active_shipping'
#include ActiveShipping

module Caboose
  class ShippingCalculator
        
    def self.custom_rates(store_config, invoice)          
      return eval(store_config.custom_shipping_function)    
    end
    
    def self.rates(invoice)
      
      return [] if invoice.site.nil? || invoice.site.store_config.nil?
      sc = invoice.site.store_config
      if !sc.auto_calculate_shipping        
        rates = self.custom_rates(sc, invoice)
        return rates        
      end

      all_rates = invoice.invoice_packages.all.collect{ |op| { 
        :invoice_package => op, 
        :rates => self.invoice_package_rates(op) 
      }}
      return all_rates
    end
    
    def self.invoice_package_rates(op)
      
      invoice = op.invoice
      sc = invoice.site.store_config
      sa = invoice.shipping_address
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
        Caboose.log("Error: no shipping rates found for invoice package #{op.id}.")
      end
      return rates
    end
    
    def self.calculate_rate(op)
      
      invoice = op.invoice
      sc = invoice.site.store_config
      sa = invoice.shipping_address
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

    def self.rate(invoice)
      return nil if !invoice.shipping_service_code
      self.rates(invoice).each { |rate| return rate if rate[:service_code] == invoice.shipping_service_code }
      return nil
    end

  end
end
