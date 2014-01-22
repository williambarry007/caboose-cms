class Caboose::AbValue < ActiveRecord::Base

  self.table_name = "ab_values"
  belongs_to :ab_variant
  belongs_to :ab_option
  attr_accessible :session_id, :ab_variant_id, :ab_option_id
  
  def keyval
    return "#{ab_variant.analytics_name}=#{ab_option_id}"
  end
    
end
