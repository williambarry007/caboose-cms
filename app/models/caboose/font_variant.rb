class Caboose::FontVariant < ActiveRecord::Base
  self.table_name = "font_variants"
  belongs_to :font_family, :class_name => 'Caboose::FontFamily'
  attr_accessible :id, :ttf_url, :font_family_id, :variant, :weight, :style
end