
class Caboose::PostCustomFieldValue < ActiveRecord::Base
  self.table_name = "post_custom_field_values"
      
  belongs_to :post
  belongs_to :post_custom_field  
  attr_accessible :id     ,
    :post_id              ,
    :post_custom_field_id ,    
    :key                  ,    
    :value                ,
    :sort_order

end
