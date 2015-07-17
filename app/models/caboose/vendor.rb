
module Caboose
  class Vendor < ActiveRecord::Base
    self.table_name = 'store_vendors'

    belongs_to :site    
    has_many :products
    has_attached_file :image, 
      :path => ':caboose_prefixvendors/:id_:style.:extension',    
      :default_url => 'http://placehold.it/300x300',    
      :styles => {
        :tiny  => '150x200>',
        :thumb => '300x400>',
        :large => '600x800>'
      }
    do_not_validate_attachment_file_type :image
    attr_accessible :id,    
      :site_id,
      :alternate_id,
      :name, 
      :status,
      :sort_order
    after_save :clear_filters

    def self.active
      where(:status => 'Active')
    end
    
    def update_products
      self.products.each { |product| product.update_attribute(:vendor_status, self.status) }
    end
    
    def clear_filters
      SearchFilter.delete_all
    end
  end
end
