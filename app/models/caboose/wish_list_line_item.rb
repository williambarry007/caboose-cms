
module Caboose
  class WishListLineItem < ActiveRecord::Base
    self.table_name = "wish_list_line_item"
       
    belongs_to :wish_list, :class_name => 'Caboose::WishList'
    belongs_to :variant, :class_name => 'Caboose::Variant'                    
    attr_accessible :id, 
      :variant_id,
      :quantity

  end      
end
