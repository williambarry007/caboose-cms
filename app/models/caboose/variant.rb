#
# Variant
#
# :: Class Methods
# :: Instance Methods

module Caboose
  class Variant < ActiveRecord::Base
    self.table_name = 'store_variants'
    
    belongs_to :product
    has_many :product_image_variants
    has_many :product_images, :through => :product_image_variants
    belongs_to :flat_rate_shipping_method, :class_name => 'Caboose::ShippingMethod'
    belongs_to :flat_rate_shipping_package, :class_name => 'Caboose::ShippingPackage'
    belongs_to :option1_media, :class_name => 'Caboose::Media'
    belongs_to :option2_media, :class_name => 'Caboose::Media'
    belongs_to :option3_media, :class_name => 'Caboose::Media'
    has_many :variant_children, :class_name => 'Caboose::VariantChild', :foreign_key => 'parent_id'
    
    attr_accessible :id,
      :alternate_id,
      :product_id,
      :sku,
      :barcode,            # Returns the barcode value of the variant.
      :cost,               # Cost of goods (don't show to customer)
      :price,              # Variant’s price.
      :sale_price,
      :date_sale_starts,
      :date_sale_end,
      :clearance,
      :clearance_price,
      :ignore_quantity,
      :quantity,
      :quantity_in_stock,
      :allow_backorder,    # Whether to allow items with no inventory to be added to the cart    
      :status,             # Current status: active, inactive, deleted
      :weight,             # The weight of the variant. This will always be in metric grams.
      :length,             # Length of variant in inches
      :width,              # Width of variant in inches
      :height,             # Height of variant in inches
      :volume,
      :option1,            # Returns the value of option1 for given variant
      :option2,            # If a product has a second option defined, then returns the value of this variant's option2.
      :option3,            # If a product has a third option defined, then returns the value of this variant's option3.
      :option1_color,      
      :option2_color,      
      :option3_color,
      :option1_media_id,      
      :option2_media_id,      
      :option3_media_id,
      :option1_sort_order,
      :option2_sort_order,
      :option3_sort_order,
      :requires_shipping,  # Returns true if the variant is shippable or false if it is a service or a digital good.    
      :taxable,            # Returns true if the variant is taxable or false if it is not.      
      :available,
      :cylinder,
      :shipping_unit_value,
      :flat_rate_shipping,
      :flat_rate_shipping_single,
      :flat_rate_shipping_combined,
      :flat_rate_shipping_method_id,
      :flat_rate_shipping_package_id,
      :sort_order,      
      :downloadable,
      :download_path,      
      :is_bundle,
      :is_subscription,
      :subscription_interval            ,
      :subscription_prorate             ,
      :subscription_prorate_method      ,
      :subscription_prorate_flat_amount ,
      :subscription_prorate_function    ,
      :subscription_start_on_day        ,
      :subscription_start_day           ,
      :subscription_start_month
    
    STATUS_ACTIVE   = 'active'
    STATUS_INACTIVE = 'inactive'
    STATUS_DELETED  = 'deleted'      
        
    SUBSCRIPTION_INTERVAL_MONTHLY = 'monthly'
    SUBSCRIPTION_INTERVAL_YEARLY  = 'yearly'
    
    SUBSCRIPTION_PRORATE_METHOD_FLAT       = 'flat'
    SUBSCRIPTION_PRORATE_METHOD_PERCENTAGE = 'percentage'
    SUBSCRIPTION_PRORATE_METHOD_CUSTOM     = 'custom'
    
    after_initialize do |v|
      v.price       = 0.00 if v.price.nil?
      v.sale_price  = 0.00 if v.sale_price.nil?                  
    end
    
    #
    # Class Methods
    #
    
    def self.find_by_options(product_id, option1=nil, option2=nil, option3=nil)
      
      # Create the vars that will become the full conditions statement
      where  = ['product_id=?']
      values = [product_id.to_i]
      
      # Append option values if they exist
      
      if option1
        where  << 'option1=?'
        values << option1
      end
      
      if option2
        where  << 'option2=?'
        values << option2
      end
      
      if option3
        where  << 'option3=?'
        values << option3
      end
      
      # Combine all the options into a single conditions statement
      conditions = [ where.join(' AND ') ].concat(values)
      
      # Return whatever is found
      return Variant.where(conditions).first
    end
    
    #
    # Instance Methods
    #
    
    def as_json(options={})
      self.attributes.merge({
        :images => self.product_images.any? ? self.product_images : [self.product.product_images.first],
        :title => "#{self.product.title} (#{self.options.join(', ')})",
        :flat_rate_shipping_package => self.flat_rate_shipping_package,
        :flat_rate_shipping_method => self.flat_rate_shipping_method                
      })
    end
    
    def title
      return self.options.join(' / ')
    end
    
    def full_title
      return self.product.title if self.options.count == 0
      return "#{self.product.title} - #{self.title}"
    end
    
    def options
      arr = []
      arr << self.option1 if self.option1 && self.option1.strip.length > 0
      arr << self.option2 if self.option2 && self.option2.strip.length > 0
      arr << self.option3 if self.option3 && self.option3.strip.length > 0
      return arr
    end
    
    def product_image
      return self.product_images.first if self.product_images
      return self.product.product_images.first if self.product.product_images
      return nil
    end
    
    def on_sale?
      return false if self.sale_price.nil? || self.sale_price == 0.0
      d = DateTime.now.utc
      return false if self.date_sale_starts && d < self.date_sale_starts
      return false if self.date_sale_ends   && d > self.date_sale_ends
      return true
    end

  end
end
