class Caboose::AbOption < ActiveRecord::Base

  self.table_name = "ab_options"

  belongs_to :ab_variant, dependent: :destroy

  attr_accessible :text

end
