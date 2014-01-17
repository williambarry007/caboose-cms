
class Caboose::PageBlockType < ActiveRecord::Base
  self.table_name = "page_block_types"

  has_many :page_block_fields, :dependent => :destroy  
  attr_accessible :id, :name, :description, :use_render_function, :render_function  

  def fields
    return page_block_fields
  end
  
end
