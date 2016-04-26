module Caboose
  class Product < ActiveRecord::Base
    self.table_name = 'store_products'
    self.primary_key = 'id'

    belongs_to :site    
    belongs_to :media_category    
    belongs_to :stackable_group, :class_name => 'Caboose::StackableGroup'
    belongs_to :vendor, :class_name => 'Caboose::Vendor'
    has_many :customizations, :class_name => 'Caboose::Product', :through => :customization_memberships
    has_many :customization_memberships, :class_name => 'Caboose::CustomizationMembership'
    has_many :categories, :class_name => 'Caboose::Category', :through => :category_memberships
    has_many :category_memberships, :class_name => 'Caboose::CategoryMembership'
    has_many :variants, :class_name => 'Caboose::Variant', :order => 'option1_sort_order, option2_sort_order, option3_sort_order'
    has_many :product_images, :class_name => 'Caboose::ProductImage'
    has_many :product_inputs, :class_name => 'Caboose::ProductInput'
    has_many :modifications, :class_name => 'Caboose::Modification', :order => 'sort_order'
    has_many :reviews, :class_name => 'Caboose::Review'
    has_many :product_category_sorts, :class_name => 'Caboose::ProductCategorySort'
    
    #default_scope order('store_products.sort_order')
    
    attr_accessible :id      ,
      :site_id               ,
      :alternate_id          ,
      :title                 ,
      :caption               ,
      :description           ,
      :handle                ,
      :status                ,
      :vendor_id             ,
      :category_id           ,      
      :option1               ,
      :option2               ,
      :option3               ,
      :option1_media         ,
      :option2_media         ,
      :option3_media         ,      
      :default1              ,
      :default2              ,
      :default3              ,
      :seo_title             ,
      :seo_description       ,
      :alternate_id          ,
      :date_available        ,
      :custom_input          ,
      :sort_order            ,
      :featured              ,
      :stackable_group_id    ,
      :on_sale               ,
      :allow_gift_wrap       ,
      :gift_wrap_price       ,
      :media_category_id

    STATUS_ACTIVE = 'Active'
    STATUS_INACTIVE = 'Inactive'
    
    #
    # Scopes
    #
    
    scope :featured, -> { where(:featured => true) }
      
    #
    # Class Methods
    #
    
    def self.with_images
      joins(:product_images)
    end
    
    def self.active
      where(:status => 'Active')
    end
    
    def self.by_title
      order('title')
    end
    
    #
    # Instance Methods
    #
    
    def as_json(options={})
      self.attributes.merge({
        :vendor => self.vendor,
        :categories => self.categories,
        :variants => self.variants,
        :images => self.product_images        
      })
    end
    
    def options
      options = []
      
      options << self.option1 if !self.option1.nil? && self.option1.strip.length > 0
      options << self.option2 if !self.option2.nil? && self.option2.strip.length > 0
      options << self.option3 if !self.option3.nil? && self.option3.strip.length > 0
      
      return options
    end
    
    def most_popular_variant
      self.variants.where('price > ? AND status != ?', 0, 'Deleted').order('price ASC').first
    end
    
    def first_tiny_image_url
    	return '' if self.product_images.count == 0
    	return self.product_images.first.image.url(:tiny)
    end
    
    def featured_image
    	self.product_images.reject{|p| p.nil?}.first
    end
    
    def price_varies
      arr = variants.collect{ |v| v.price }.uniq
      return arr.count > 0
    end
    
    def price_range
      min = 100000
      max = 0
      
      self.variants.each do |variant|        
        next if variant.nil? || variant.price.nil? || variant.price <= 0
        price = variant.on_sale? ? variant.sale_price : variant.price
        min = price if price < min
        max = price if price > max
      end
      
      return [min, max]
    end
    
    def url
      "/products/#{self.id}"
    end
    
    def related_items
      Array.new # TODO should be obvious
    end
    
    def in_stock
      Variant.where(:product_id => self.id).where('quantity_in_stock > 0').count > 0
    end
    
    def input_required?
      !self.custom_input.nil?
    end
    
    def active_customizations
      self.customizations.where(:status => 'Active')
    end
    
    def live_variants
      
      # Return variants that haven't been "deleted"
      self.variants.where(:status => ['Active', 'Inactive'])
    end
    
    def option1_values      
      self.variants.where(:status => 'Active').reorder(:option1_sort_order).pluck(:option1).uniq.reject { |x| x.nil? || x.empty? }
    end
    
    def option1_values_with_media(url_only = false)
      h = {}
      self.variants.where("status = ? and option1 is not null", 'Active').reorder(:option1_sort_order).each{ |v| h[v.option1] = url_only ? (v.option1_media && v.option1_media.image ? v.option1_media.image.url(:thumb) : false) : v.option1_media }      
      return h      
    end
    
    def option2_values
      self.variants.where(:status => 'Active').reorder(:option2_sort_order).pluck(:option2).uniq.reject { |x| x.nil? || x.empty? }
    end
    
    def option2_values_with_media(url_only = false)
      h = {}
      self.variants.where("status = ? and option2 is not null", 'Active').reorder(:option2_sort_order).each{ |v| h[v.option2] = url_only ? (v.option2_media && v.option2_media.image ? v.option2_media.image.url(:thumb) : false) : v.option2_media }      
      return h      
    end
    
    def option3_values
      self.variants.where(:status => 'Active').reorder(:option3_sort_order).pluck(:option3).uniq.reject { |x| x.nil? || x.empty? }
    end
    
    def option3_values_with_media(url_only = false)
      h = {}
      self.variants.where("status = ? and option3 is not null", 'Active').reorder(:option3_sort_order).each{ |v| h[v.option3] = url_only ? (v.option3_media && v.option3_media.image ? v.option3_media.image.url(:thumb) : false) : v.option3_media }      
      return h      
    end
    
    def toggle_category(cat_id, value)            
      if value.to_i > 0 # Add to category                   
        if cat_id == 'all'
          CategoryMembership.where(:product_id => self.id).destroy_all      
          Category.where(:site_id => self.site_id).reorder(:name).all.each{ |cat| CategoryMembership.create(:product_id => self.id, :category_id => cat.id) }                          
        else
          if !CategoryMembership.where(:product_id => self.id, :category_id => cat_id.to_i).exists?
            CategoryMembership.create(:product_id => self.id, :category_id => cat_id.to_i)
          end      
        end
      else # Remove from category    
        if cat_id == 'all'
          CategoryMembership.where(:product_id => self.id).destroy_all                          
        else
          CategoryMembership.where(:product_id => self.id, :category_id => cat_id.to_i).destroy_all      
        end
      end
    end
    
    def update_on_sale      
      is_on_sale = false
      self.variants.each do |v|
        is_on_sale = true if v.on_sale?
      end
      if (is_on_sale && !self.on_sale) || (!is_on_sale && self.on_sale)
        self.on_sale = is_on_sale
        self.save
      end
    end            
    
    def Product.update_on_sale            
      Product.reorder(:id).all.each do |p|
        p.delay.update_on_sale 
      end
    end

  end
end
