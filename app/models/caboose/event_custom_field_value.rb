class Caboose::EventCustomFieldValue < ActiveRecord::Base
  self.table_name = "event_custom_field_values"
      
  belongs_to :calendar_event
  belongs_to :event_custom_field  
  attr_accessible :id     ,
    :calendar_event_id              ,
    :event_custom_field_id ,    
    :key                  ,    
    :value                ,
    :sort_order

end