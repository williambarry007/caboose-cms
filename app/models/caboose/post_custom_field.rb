
class Caboose::PostCustomField < ActiveRecord::Base
  self.table_name = "post_custom_fields"
      
  belongs_to :site  
  attr_accessible :id  ,
    :site_id           ,
    :key               ,
    :name              ,
    :field_type        ,
    :default_value     ,
    :options           ,
    :sort_order
    
  FIELD_TYPE_TEXT = 'text'
  FIELD_TYPE_SELECT = 'select'
  FIELD_TYPE_CHECKBOX = 'checkbox'
  FIELD_TYPE_DATE = 'date'
  FIELD_TYPE_DATETIME = 'datetime'

end
