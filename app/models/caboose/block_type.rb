
class Caboose::BlockType < ActiveRecord::Base
  self.table_name = "block_types"
  
  belongs_to :default_child_block_type, :foreign_key => 'default_child_block_type_id', :class_name => 'Caboose::BlockType'
  belongs_to :block_type_category
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType'
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockType', :dependent => :destroy
  has_many :sites, :through => :block_type_site_memberships
  has_many :block_type_site_memberships
  attr_accessible :id,    
    :parent_id,
    :name, 
    :description,
    :is_global,
    :block_type_category_id,
    :use_render_function,
    :use_render_function_for_layout,
    :allow_child_blocks,
    :default_child_block_type_id,
    :render_function,    
    :field_type, 
    :default, 
    :width,
    :height, 
    :fixed_placeholder, 
    :options,
    :options_function,
    :options_url,
    :icon,
    :default_constrain,
    :default_included,
    :custom_sass,
    :latest_error,
    :share,      # Whether or not to share the block type in the existing block store.
    :downloaded  # Whether the full block type has been download or just the name and description.
    
  def full_name    
    return name if parent_id.nil?
    return "#{parent.full_name}_#{name}"
  end
  
  def render_options(site_id)    
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
    Caboose.log(h)
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
    self.icon                            = h['icon']
    self.save
    
    # Remove any named children that don't exist in the given hash
    if h['children'].nil?
      Caboose::BlockType.where("parent_id = ? and name is not null", self.id).destroy_all
    else
      new_child_names = h['children'].collect { |h2| h2['name'] }      
      Caboose::BlockType.where("parent_id = ? and name is not null and name not in (?)", self.id, new_child_names).destroy_all
    end
    
    # Now add/update all the children
    if h['children']
      h['children'].each do |h2|
        bt = self.child(h2['name'])
        bt = Caboose::BlockType.create(:parent_id => self.id) if bt.nil?
        bt.parse_api_hash(h2)
      end
    end
    
  end
    
  def toggle_site(site_id, value)          
    if value.to_i > 0
      return self.add_to_site(site_id)
    else
      return self.remove_from_site(site_id)
    end
  end
    
  def add_to_site(site_id)          
    if site_id == 'all'
      Caboose::BlockTypeSiteMembership.where(:block_type_id => self.id).destroy_all      
      Caboose::Site.reorder(:name).all.each do |site|
        Caboose::BlockTypeSiteMembership.create(:block_type_id => self.id, :site_id => site.id)
      end                          
    else
      if !Caboose::BlockTypeSiteMembership.where(:block_type_id => self.id, :site_id => site_id.to_i).exists?
        btsm = Caboose::BlockTypeSiteMembership.new 
        btsm.block_type_id = self.id
        btsm.site_id = site_id.to_i
        btsm.save
        return btsm.id
      end      
    end
  end
  
  def remove_from_site(site_id)
    if site_id == 'all'
      Caboose::BlockTypeSiteMembership.where(:block_type_id => self.id).destroy_all                          
    else
      Caboose::BlockTypeSiteMembership.where(:block_type_id => self.id, :site_id => site_id.to_i).destroy_all      
    end
  end
end
