
module Caboose        
  class ModificationValue < ActiveRecord::Base
    self.table_name  = 'store_modification_values'
    self.primary_key = 'id'

    belongs_to :modification, :class_name => 'Caboose::Modification'
    attr_accessible :id,
      :modification_id,
      :sort_order,
      :value,
      :is_default,
      :price,
      :requires_input,
      :input_description
      
  end
end

