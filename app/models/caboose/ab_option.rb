class Caboose::AbOption < ActiveRecord::Base

  self.table_name = "ab_options"
  belongs_to :ab_variant
  has_many :ab_values, :dependent => :destroy  
  attr_accessible :value, :ab_variant_id

end
