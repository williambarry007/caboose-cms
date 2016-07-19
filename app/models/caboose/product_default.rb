#
# ProductDefault
#
# :: Class Methods
# :: Instance Methods

module Caboose
  class ProductDefault < ActiveRecord::Base
    self.table_name = 'store_product_defaults'
            
    belongs_to :site
    belongs_to :vendor
    attr_accessible :id ,
      :site_id          ,
      :vendor_id        ,
      :option1          ,
      :option2          ,
      :option3          ,
      :status           ,
      :on_sale          ,
      :allow_gift_wrap  ,
      :gift_wrap_price
      
  end     
end
