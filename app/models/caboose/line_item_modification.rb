
module Caboose        
  class LineItemModification < ActiveRecord::Base
    self.table_name  = 'store_line_item_modifications'
    self.primary_key = 'id'

    belongs_to :line_item, :class_name => 'Caboose::LineItem'
    belongs_to :modification, :class_name => 'Caboose::Modification'
    belongs_to :modification_value, :class_name => 'Caboose::ModificationValue'        
    attr_accessible :id,
      :line_item_id,
      :modification_id,
      :modification_value_id,
      :input            

  end
end

