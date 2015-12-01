class Caboose::FontFamily < ActiveRecord::Base
  self.table_name = "font_families"
  has_many :font_variants, :class_name => 'Caboose::FontVariant', :dependent => :delete_all
  attr_accessible :id, :name
end