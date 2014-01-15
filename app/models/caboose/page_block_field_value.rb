
class Caboose::PageBlockFieldValue < ActiveRecord::Base
  self.table_name = "page_block_field_values"

  belongs_to :page_block
  belongs_to :page_block_field
  attr_accessible :id, :page_block_id, :page_block_field_id, :value
    
end
