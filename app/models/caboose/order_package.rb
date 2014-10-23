module Caboose
  class OrderPackage < ActiveRecord::Base
    self.table_name = 'store_order_packages'

    belongs_to :order
    belongs_to :shipping_package
    has_many :line_items    
    attr_accessible :id, 
      :order_id,
      :shipping_package_id,
      :status,
      :tracking_number
      
    STATUS_PENDING = 'Pending'
    STATUS_SHIPPED = 'Shipped'
    
    # Calculates the shipping packages required for all the items in the order
    def self.create_for_order(order)

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
        Caboose.log("Error: variant #{v.id} has a zero weight") and return false if v.weight.nil? || v.weight == 0
        next if v.volume && v.volume > 0
        Caboose.log("Error: variant #{v.id} has a zero length") and return false if v.length.nil? || v.length == 0
        Caboose.log("Error: variant #{v.id} has a zero width" ) and return false if v.width.nil?  || v.width  == 0
        Caboose.log("Error: variant #{v.id} has a zero height") and return false if v.height.nil? || v.height == 0        
        v.volume = v.length * v.width * v.height
        v.save
      end
            
      # Reorder the items in the order by volume            
      h = {}
      order.line_items.each do |li|
        (1..li.quantity).each do |i|        
          v = li.variant          
          h[v.volume] = li          
        end
      end      
      line_items = h.sort_by{ |k,v| k }.collect{ |x| x[1] }      
      all_packages = ShippingPackage.reorder(:price).all      
      
      # Now go through each variant and fit it in a new or existing package
      line_items.each do |li|
        
        # See if the item will fit in any of the existing packages
        it_fits = false
        order.packages.each do |op|
          it_fits = op.fits(li)
          if it_fits
            li.order_package_id = op.id
            li.save            
            break
          end
        end        
        next if it_fits
        
        # Otherwise find the cheapest package the item will fit into
        all_packages.each do |sp|          
          if sp.fits(li.variant)
            op = OrderPackage.create(:order_id => order.id, :shipping_package_id => sp.id)
            li.order_package_id = op.id
            li.save                          
            break
          end
        end
               
      end                      
    end
    
    def fits(line_item = nil)
      variants = self.line_items.collect{ |li| li.variant }
      variants << line_item.variant if line_item
      return self.shipping_package.fits(variants)
    end
    
    # Gets the activemerchant package based on the shipping package
    def activemerchant_package      
      weight = 0.0
      self.line_items.each{ |li| weight = weight + li.variant.weight }
      weight = weight * 0.035274 # Convert from grams to ounces
      sp = self.shipping_package
      return Package.new(weight, [sp.length, sp.width, sp.height], :units => :imperial)
    end

  end
end
