
module Caboose        
  class Modification < ActiveRecord::Base
    self.table_name  = 'store_modifications'
    self.primary_key = 'id'

    belongs_to :product, :class_name => 'Caboose::Product'    
    has_many :modification_values, -> { order(:sort_order) }, :class_name => 'Caboose::ModificationValue'
    attr_accessible :id,
      :product_id,
      :sort_order,
      :name      
      
    def values
      return self.modification_values
    end

  end
end

