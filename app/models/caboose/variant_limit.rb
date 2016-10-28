module Caboose
  class VariantLimit < ActiveRecord::Base
    self.table_name = 'store_variant_limits'
    
    belongs_to :variant
    belongs_to :user    
    attr_accessible :id ,
      :variant_id       ,
      :user_id          ,
      :min_quantity     ,
      :max_quantity     ,
      :current_value

  end
end
