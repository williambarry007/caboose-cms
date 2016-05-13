require 'active_shipping'
#include ActiveMerchant::Shipping

module Caboose
  class InvoicePackageCalculator
    
    def self.custom_invoice_packages(store_config, invoice)          
      return eval(store_config.custom_packages_function)    
    end
    
    def self.invoice_packages(invoice)
      return [] if Caboose::store_shipping.nil?
            
      sc = invoice.site.store_config
      if !sc.auto_calculate_packages        
        invoice_packages = self.custom_invoice_packages(sc, invoice)
        return invoice_packages        
      end
      
      # Remove any invoice packages      
      LineItem.where(:invoice_id => invoice.id).update_all(:invoice_package_id => nil)
      InvoicePackage.where(:invoice_id => invoice.id).destroy_all      
        
      # Calculate what shipping packages we'll need            
      InvoicePackage.create_for_invoice(invoice)
              
      return all_rates
    end
    
    def self.rate(invoice)
      return nil if !invoice.shipping_service_code
      self.rates(invoice).each { |rate| return rate if rate[:service_code] == invoice.shipping_service_code }
      return nil
    end
                
    # Calculates the packages required for all the items in the invoice
    #def self.packages_for_invoice(invoice)
    #
    #  # Make sure all the items in the invoice have attributes set
    #  invoice.line_items.each do |li|              
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
    #  # Reinvoice the items in the order by volume            
    #  h = {}
    #  invoice.line_items.each do |li|
    #    (1..li.quantity).each do |i|        
    #      v = li.variant          
    #      h[v.volume] = v          
    #    end
    #  end      
    #  variants = h.sort_by{ |k,v| k }.collect{ |x| x[1] }
    #  
    #  all_packages = ShippingPackage.reinvoice(:price).all
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
