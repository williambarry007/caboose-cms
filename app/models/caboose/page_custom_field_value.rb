
class Caboose::PageCustomFieldValue < ActiveRecord::Base
  self.table_name = "page_custom_field_values"
      
  belongs_to :page
  belongs_to :page_custom_field  
  attr_accessible :id     ,
    :page_id              ,
    :page_custom_field_id ,    
    :key                  ,    
    :value                ,
    :sort_order

end
