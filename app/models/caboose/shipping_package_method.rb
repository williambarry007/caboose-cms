module Caboose
  class ShippingPackageMethod < ActiveRecord::Base
    self.table_name = 'store_shipping_package_methods'
    
    belongs_to :shipping_package
    belongs_to :shipping_method
    attr_accessible :id,
      :shipping_package_id,
      :shipping_method_id

  end
end
