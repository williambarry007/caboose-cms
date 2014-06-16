
class Caboose::BlockType < ActiveRecord::Base
  self.table_name = "block_types"

  belongs_to :block_type_category
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType'
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType', :dependent => :destroy    
  attr_accessible :id,
    :parent_id,
    :name, 
    :description,
    :block_type_category_id,
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
  
  def api_hash
    return {
      :name                            => self.name,
      :description                     => self.description,
      :block_type_category_id          => self.block_type_category_id,
      :render_function                 => self.render_function,
      :use_render_function             => self.use_render_function,
      :use_render_function_for_layout  => self.use_render_function_for_layout,
      :allow_child_blocks              => self.allow_child_blocks,
      :field_type                      => self.field_type,
      :default                         => self.default,
      :width                           => self.width,
      :height                          => self.height,
      :fixed_placeholder               => self.fixed_placeholder,
      :options                         => self.options,
      :options_function                => self.options_function,
      :options_url                     => self.options_url,
      :children                        => self.api_hash_children
    }
  end
  
  def api_hash_children
    return nil if self.children.nil? || self.children.count == 0    
    return self.children.collect { |bt| bt.api_hash }
  end

end
