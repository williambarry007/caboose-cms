class Caboose::AbOption < ActiveRecord::Base

  self.table_name = "ab_options"
  belongs_to :ab_variant
  attr_accessible :text, :ab_variant_id

end
