
module Caboose
  class Vendor < ActiveRecord::Base
    self.table_name = 'store_vendors'
    
    has_many :products
    attr_accessible :id, :name, :status, :sort_order
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
