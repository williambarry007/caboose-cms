
module Caboose
  class WishList < ActiveRecord::Base
    self.table_name = "wish_lists"
       
    belongs_to :user, :class_name => 'Caboose::User'
    has_many :wish_list_line_items, :class_name => 'Caboose::WishListLineItem'            
    attr_accessible :id, 
      :user_id,
      :name,
      :date_created            
    
  end      
end
