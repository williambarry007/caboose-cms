module Caboose
  class OrderPackage < ActiveRecord::Base
    self.table_name = 'store_order_packages'

    belongs_to :order
    belongs_to :shipping_package
    belongs_to :shipping_method
    has_many :line_items    
    attr_accessible :id, 
      :order_id,
      :shipping_method_id,
      :shipping_package_id,
      :status,
      :tracking_number,
      :total
      
    STATUS_PENDING = 'Pending'
    STATUS_SHIPPED = 'Shipped'
    
    after_initialize :check_nil_fields
    
    def check_nil_fields      
      self.total = 0.00 if self.total.nil?
    end
    
    def self.custom_order_packages(store_config, order)          
      eval(store_config.custom_packages_function)    
    end
    
    # Calculates the shipping packages required for all the items in the order
    def self.create_for_order(order)
      
      store_config = order.site.store_config            
      if !store_config.auto_calculate_packages                        
        self.custom_order_packages(store_config, order)
        return
      end
                  
      # Make sure all the line items in the order have a quantity of 1
      extra_line_items = []
      order.line_items.each do |li|        
        if li.quantity > 1          
          (1..li.quantity).each{ |i|            
            extra_line_items << li.copy 
          }
          li.quantity = 1
          li.save
        end        
      end
      extra_line_items.each do |li|         
        li.quantity = 1                        
        li.save 
      end 
      
      # Make sure all the items in the order have attributes set
      order.line_items.each do |li|              
        v = li.variant
        next if v.downloadable
        Caboose.log("Error: variant #{v.id} has a zero weight") and return false if v.weight.nil? || v.weight == 0
        next if v.volume && v.volume > 0
        Caboose.log("Error: variant #{v.id} has a zero length") and return false if v.length.nil? || v.length == 0
        Caboose.log("Error: variant #{v.id} has a zero width" ) and return false if v.width.nil?  || v.width  == 0
        Caboose.log("Error: variant #{v.id} has a zero height") and return false if v.height.nil? || v.height == 0        
        v.volume = v.length * v.width * v.height
        v.save
      end
            
      # Reorder the items in the order by volume
      line_items = order.line_items.sort_by{ |li| li.quantity * (li.variant.volume ? li.variant.volume : 0.00) * -1 }
                      
      # Get all the packages we're going to use      
      all_packages = ShippingPackage.where(:site_id => order.site_id).reorder(:flat_rate_price).all      
      
      # Now go through each variant and fit it in a new or existing package            
      line_items.each do |li|        
        next if li.variant.downloadable
        
        # See if the item will fit in any of the existing packages
        it_fits = false
        order.order_packages.all.each do |op|
          it_fits = op.fits(li)
          if it_fits            
            li.order_package_id = op.id
            li.save            
            break
          end
        end        
        next if it_fits
        
        # Otherwise find the cheapest package the item will fit into
        it_fits = false
        all_packages.each do |sp|
          it_fits = sp.fits(li.variant)          
          if it_fits            
            op = OrderPackage.create(:order_id => order.id, :shipping_package_id => sp.id)
            li.order_package_id = op.id
            li.save                          
            break
          end
        end
        next if it_fits
        
        Caboose.log("Error: line item #{li.id} (#{li.variant.product.title}) does not fit into any package.")               
      end      
    end
    
    def fits(line_item = nil)
      variants = self.line_items.collect{ |li| li.variant }
      variants << line_item.variant if line_item
      return self.shipping_package.fits(variants)
    end
    
    # Gets the activemerchant package based on the shipping package
    def activemerchant_package
      sc = self.order.site.store_config
      
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
