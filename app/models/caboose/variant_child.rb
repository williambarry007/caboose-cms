module Caboose
  class VariantChild < ActiveRecord::Base
    self.table_name = 'store_variant_children'
    
    belongs_to :parent, :class_name => 'Caboose::Variant'
    belongs_to :variant, :class_name => 'Caboose::Variant'    
    attr_accessible :id,
      :parent_id,
      :variant_id,
      :quantity

  end
end
