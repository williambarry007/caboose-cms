
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
    :options_url,
    :share,      # Whether or not to share the block type in the existing block store.
    :downloaded  # Whether the full block type has been download or just the name and description.
    
  def render_options(empty_text = nil)    
    return eval(self.options_function)    
  end
  
  def child(name)
    Caboose::BlockType.where("parent_id = ? and name = ?", self.id, name).first
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
  
  def parse_api_hash(h)    
    self.name                            = h['name']
    self.description                     = h['description']
    self.block_type_category_id          = h['block_type_category_id']
    self.render_function                 = h['render_function']
    self.use_render_function             = h['use_render_function']
    self.use_render_function_for_layout  = h['use_render_function_for_layout']
    self.allow_child_blocks              = h['allow_child_blocks']
    self.field_type                      = h['field_type']
    self.default                         = h['default']
    self.width                           = h['width']
    self.height                          = h['height']
    self.fixed_placeholder               = h['fixed_placeholder']
    self.options                         = h['options']
    self.options_function                = h['options_function']
    self.options_url                     = h['options_url']
    self.save
    
    # Remove any named children that don't exist in the given hash
    new_child_names = h['children'].collect { |h2| h2['name'] }
    Caboose::BlockType.where(:parent_id => self.id).all.each do |bt|
      bt.destroy if bt.name && bt.name.strip.length > 0 && !new_child_names.include?(bt.name)
    end
    
    # Now add/update all the children
    h['children'].each do |h2|
      bt = self.child(h2['name'])
      bt = Caboose::BlockType.create(:parent_id => self.id) if bt.nil?
      bt.parse_api_hash(h)
    end
    
  end
end
