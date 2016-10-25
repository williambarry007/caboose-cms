module Caboose
  class VariantChild < ActiveRecord::Base
    self.table_name = 'store_variant_children'
    
    belongs_to :parent  , :class_name => 'Caboose::Variant', :foreign_key => 'parent_id'
    belongs_to :variant , :class_name => 'Caboose::Variant', :foreign_key => 'variant_id'
    attr_accessible :id,
      :parent_id,
      :variant_id,
      :quantity

  end
end
