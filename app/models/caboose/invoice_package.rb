module Caboose
  class InvoicePackage < ActiveRecord::Base
    self.table_name = 'store_invoice_packages'

    belongs_to :invoice
    belongs_to :shipping_package
    belongs_to :shipping_method
    has_many :line_items    
    attr_accessible :id, 
      :invoice_id,
      :shipping_method_id,
      :shipping_package_id,
      :status,
      :tracking_number,
      :total,
      :instore_pickup
      
    STATUS_PENDING       = 'Pending'
    STATUS_READY_TO_SHIP = 'Ready to Ship'
    STATUS_SHIPPED       = 'Shipped'
    
    after_initialize :check_nil_fields
    
    def check_nil_fields      
      self.total = 0.00 if self.total.nil?
    end
    
    def self.custom_invoice_packages(store_config, invoice)          
      eval(store_config.custom_packages_function)    
    end
    
    # Calculates the shipping packages required for all the items in the invoice
    def calculate_shipping_package
      
      store_config = invoice.site.store_config            
      if !store_config.auto_calculate_packages                        
        return self.custom_shipping_package(store_config, self)        
      end
      
      variants = self.line_items.sort_by{ |li| li.quantity * (li.variant.volume ? li.variant.volume : 0.00) * -1 }.collect{ |li| li.variant.downloadable ? nil : li.variant }.reject{ |v| v.nil? }      
      ShippingPackage.where(:site_id => self.invoice.site_id).reorder(:flat_rate_price).all.each do |sp|
        if sp.fits(variants)
          self.shipping_package_id = sp.id
          self.save
          return true          
        end 
      end                    
      Caboose.log("Error: line item #{li.id} (#{li.variant.product.title}) does not fit into any package.")
      return false
    end
    
    def fits(line_item = nil)
      variants = self.line_items.collect{ |li| li.variant }
      variants << line_item.variant if line_item
      return self.shipping_package.fits(variants)
    end
    
    # Gets the activemerchant package based on the shipping package
    def activemerchant_package
      sc = self.invoice.site.store_config
      
      weight = 0.0
      self.line_items.each{ |li| weight = weight + (li.variant.weight * li.quantity) }      
      weight = weight * 0.035274 if sc.weight_unit == StoreConfig::WEIGHT_UNIT_METRIC # grams to ounces
                  
      sp = self.shipping_package
      dimensions = [sp.outside_length, sp.outside_width, sp.outside_height]
      if sc.length_unit == StoreConfig::LENGTH_UNIT_METRIC # cm to inches
        dimensions[0] = dimensions[0] / 2.54
        dimensions[1] = dimensions[0] / 2.54
        dimensions[2] = dimensions[0] / 2.54
      end
      
      return ActiveShipping::Package.new(weight, dimensions, :units => :imperial, :container => :variable)
    end

  end
end
