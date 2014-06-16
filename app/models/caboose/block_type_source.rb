require 'httparty'

class Caboose::BlockTypeSource < ActiveRecord::Base
  self.table_name = "block_type_sources"
  
  has_many :block_types, :class_name => 'Caboose::BlockType', :order => 'name'    
  attr_accessible :id,
    :name, 
    :url,
    :token,
    :priority,
    :active    

  def refresh
    resp = nil
    begin
      resp = HTTParty.get("#{self.url}/block-types?token=#{self.token}")
    rescue HTTParty::Error => e
      Caboose.log(e.message)
      return false
    end
    
    block_types = nil
    begin
      block_types = JSON.parse(resp.body)
    rescue
      Caboose.log("Response body isn't valid JSON.")
      return false
    end
    
    #block_types.each do |bt|
    #  Caboose.log(
    #  next if Caboose::BlockType.where(:name => bt.name).exists?
    #  #self.recursive_add(bt)
    #end
    
    return true
  end
  
  def recursive_add(bt, parent_id = nil)
    bt2 = Caboose::BlockType.create(
      :parent_id                       => parent_id,
      :name                            => bt.name,
      :description                     => bt.description,
      :block_type_category_id          => bt.block_type_category_id,
      :render_function                 => bt.render_function,
      :use_render_function             => bt.use_render_function,
      :use_render_function_for_layout  => bt.use_render_function_for_layout,
      :allow_child_blocks              => bt.allow_child_blocks,
      :field_type                      => bt.field_type,
      :default                         => bt.default,
      :width                           => bt.width,
      :height                          => bt.height,
      :fixed_placeholder               => bt.fixed_placeholder,
      :options                         => bt.options,
      :options_function                => bt.options_function,
      :options_url                     => bt.options_url
    )
    bt.children.each do |bt3|
      self.recursive_add(bt3, bt2.id)
    end
  end        

end
