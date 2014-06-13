
class Caboose::BlockType < ActiveRecord::Base
  self.table_name = "block_types"

  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType'
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType', :dependent => :destroy    
  attr_accessible :id,
    :parent_id,
    :name, 
    :description, 
    :use_render_function,
    :use_render_function_for_layout,
    :allow_child_blocks,
    :render_function,
    :field_type, 
    :default, 
    :width,
    :height, 
    :fixed_placeholder, 
    :options,
    :options_function,
    :options_url
    
  def render_options(empty_text = nil)    
    return eval(self.options_function)    
  end

end
