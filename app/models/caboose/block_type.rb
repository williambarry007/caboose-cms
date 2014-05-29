
class Caboose::BlockType < ActiveRecord::Base
  self.table_name = "block_types"

  has_many :field_types, :dependent => :destroy  
  attr_accessible :id, :name, :description, :use_render_function, :render_function  

end
