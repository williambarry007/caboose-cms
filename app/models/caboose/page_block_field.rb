
class Caboose::PageBlockField < ActiveRecord::Base
  self.table_name = "page_block_fields"

  belongs_to :page_block_type
  has_many :page_block_field_values, :dependent => :destroy
  attr_accessible :id, :page_block_type_id, :name, :field_type, :nice_name, :default, :width, :height, :fixed_placeholder, :options, :options_url 
  
end
