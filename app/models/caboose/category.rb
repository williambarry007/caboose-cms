#
# Category
#
# :: Class Methods
# :: Instance Methods

module Caboose
  class Category < ActiveRecord::Base
    self.table_name = 'store_categories'

    belongs_to :site    
    belongs_to :parent, :class_name => 'Category', :foreign_key => 'parent_id'
    has_many :children, -> { order(:name) }, :class_name => 'Category', :foreign_key => 'parent_id'
    has_many :products, -> { order(:title) }, :through => :category_memberships
    has_many :category_memberships
    
    has_attached_file :image,    
      :path => ':caboose_prefixcategories/:id_:style.:extension',      
      :default_url => 'http://placehold.it/300x300',
      :s3_protocol => :https,
      :styles => {
        :tiny   => '100x100>',
        :thumb  => '250x250>',
        :medium => '400x400>',
        :large  => '800x800>',
        :huge   => '1200x1200>'
      }
    validates_attachment_content_type :image, :content_type => %w(image/jpeg image/jpg image/png)
    
    attr_accessible :id,
      :site_id,
      :parent_id,
      :alternate_id,
      :name,
      :url,
      :slug,
      :sort_order,
      :status,
      :image_file_name,
      :image_content_type,
      :image_file_size,
      :image_updated_at,
      :square_offset_x,
      :square_offset_y,
      :square_scale_factor
      
    STATUS_ACTIVE = 'Active'
    STATUS_INACTIVE = 'Inactive'
    
    #
    # Class Methods
    #
    
    def self.root
      self.find_by_url('/products')
    end
    
    def self.top_level
      self.root.children
    end
    
    def self.sample(number)
      Caboose::Category.top_level.collect { |category| category if category.active_products.any? }.compact.sample(number)
    end
    
    #
    # Instance Methods
    #
    
    def generate_slug
      self.name.gsub(' ', '-').downcase
    end
    
    def update_child_slugs
      return if self.children.nil? or self.children.empty?
      
      self.children.each do |child|
        child.update_attribute(:url, "#{self.url}/#{child.slug}")
        child.update_child_slugs
      end
    end
    
    def active_products
      self.products.where(:status => 'Active')      
    end
    
    def ancestry
      return [self] if self.parent.nil?
      ancestors = self.parent.ancestry
      ancestors << self
      return ancestors 
    end
        
    def self.options(site_id)            
      cat = Category.where("site_id = ? and parent_id is null", site_id).first      
      if cat.nil?
        cat = Category.create(:site_id => site_id, :name => 'All Products', :url => '/')
      end
      arr = self.options_helper(cat, '')
      return arr
    end
        
    def self.options_helper(cat, prefix)
      return [] if cat.nil?
      arr = [{ :value => cat.id, :text => "#{prefix}#{cat.name}" }]      
      cat.children.each do |c|
        arr = arr + self.options_helper(c, "#{prefix} - ")        
      end
      return arr
    end
  end
end
