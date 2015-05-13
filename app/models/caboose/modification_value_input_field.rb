
module Caboose        
  class ModificationValueInputField < ActiveRecord::Base
    self.table_name  = 'store_modification_value_input_fields'
    self.primary_key = 'id'

    belongs_to :modification_value, :class_name => 'Caboose::ModificationValue'
    attr_accessible :id,
      :modification_value_id,
      :sort_order,
      :name,
      :description,
      :field_type,      
      :default_value,                        
      :width,
      :height,        
      :options,        
      :options_url     
                  
  end
end
