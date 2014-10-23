module Caboose
  class StackableGroup < ActiveRecord::Base
    self.table_name = 'store_stackable_groups'
    
    has_many :products
    attr_accessible :id, 
      :name, 
      :extra_length,
      :extra_width,
      :extra_height,
      :max_length,
      :max_width, 
      :max_height
        
  end
end
                  