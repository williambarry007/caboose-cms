require 'box_packer'

module Caboose
  class ShippingPackage < ActiveRecord::Base
    self.table_name = 'store_shipping_packages'
    
    has_many :shipping_package_methods
    has_many :shipping_methods, :through => :shipping_package_methods
    attr_accessible :id,
      :site_id,
      :name,
      :inside_length, 
      :inside_width, 
      :inside_height,
      :outside_length, 
      :outside_width, 
      :outside_height,
      :volume,
      :empty_weight,
      :cylinder,
      :priority,
      :flat_rate_price            
          
    def fits(variants)  
      
      arr = variants.is_a?(Array) ? variants : [variants]            
      rigid = []
      floppy = []
      arr.each do |v|
        if v.length && v.length > 0 && v.width && v.width > 0 && v.height && v.height > 0
          rigid << v
        else
          floppy << v
        end
      end
      rigid_volume = 0.0
      floppy_volume = 0.0
      rigid.each { |v| rigid_volume  = rigid_volume  + v.volume }      
      floppy.each{ |v| floppy_volume = floppy_volume + v.volume }
      return false if (rigid_volume + floppy_volume) > self.volume
      rigid_boxes = self.boxes(rigid)
      
      it_fits = false      
      BoxPacker.container [self.inside_length, self.inside_width, self.inside_height] do        
        rigid_boxes.each{ |arr| add_item arr }    
        count = pack!
        it_fits = true if count == rigid_boxes.count                                      
      end
      return it_fits         

    end
    
    # Gets the 3d dimensions of the variants after they're stacked
    def boxes(rigid_variants)
      stackable = {}
      nonstackable = []      
      rigid_variants.each do |v|
        sgid = v.product.stackable_group_id        
        if sgid          
          stackable[sgid] = [] if stackable[sgid].nil?
          stackable[sgid] << v
        else
          nonstackable << [v.length, v.width, v.height]
        end
      end
            
      stackable.each do |sgid, arr|                
        sg = arr[0].product.stackable_group        
        l = 0.0
        w = 0.0
        h = 0.0        
        arr.each do |v|
          if l+sg.extra_length >= sg.max_length || w+sg.extra_width >= sg.max_width || h+sg.extra_height >= sg.max_height
            nonstackable << [l, w, h]
            l = 0.0
            w = 0.0
            h = 0.0
          end
          if l == 0.0
            l = v.length
            w = v.width
            h = v.height            
          else
            l = l + sg.extra_length
            w = w + sg.extra_width
            h = h + sg.extra_height            
          end
        end        
        nonstackable << [l, w, h] if l > 0
      end
      
      return nonstackable
    end
    
    def toggle_shipping_method(shipping_method_id, value)      
      if value.to_i > 0 # Add        
        if shipping_method_id == 'all'
          ShippingPackageMethod.where(:shipping_package_id => self.id).destroy_all      
          ShippingMethod.reorder(:service_name).all.each do |sm|
            ShippingPackageMethod.create(:shipping_package_id => self.id, :shipping_method_id => sm.id)
          end                          
        else
          if !ShippingPackageMethod.where(:shipping_package_id => self.id, :shipping_method_id => shipping_method_id.to_i).exists?
            ShippingPackageMethod.create(:shipping_package_id => self.id, :shipping_method_id => shipping_method_id.to_i)
          end      
        end              
      else # Remove
        if shipping_method_id == 'all'
          ShippingPackageMethod.where(:shipping_package_id => self.id).destroy_all                          
        else
          ShippingPackageMethod.where(:shipping_package_id => self.id, :shipping_method_id => shipping_method_id.to_i).destroy_all      
        end
      end
    end
    
    def uses_carrier(carrier)
      self.shipping_methods.each do |sm|
        return true if sm.carrier == carrier
      end
      return false
    end
    
    def uses_service_code(carrier, service_code)
      self.shipping_methods.each do |sm|
        return true if sm.carrier == carrier && sm.service_code == service_code
      end
      return false
    end
    
    def uses_shipping_method(sm)
      self.shipping_methods.each do |sm2|
        return true if sm.id == sm2.id
      end
      return false
    end
        
  end
end
