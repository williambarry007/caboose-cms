
class Caboose::Block < ActiveRecord::Base
  self.table_name = "blocks"
  
  belongs_to :block_type
  belongs_to :page
  belongs_to :parent    
  has_many :fields
  attr_accessible :id, :page_id, :parent_id, :block_type_id, :sort_order

  def field_value(name)    
    page_block_field_values.each do |fv|
      if fv.page_block_field.name == name
        if    fv.page_block_field.field_type == 'image' then return fv.image
        elsif fv.page_block_field.field_type == 'file'  then return fv.file
        else return fv.value
        end
      end
    end
    return nil
  end
  
  
  
  def render_from_function(empty_text = nil, editing = false)    
    locals = OpenStruct.new(:block => self, :empty_text => empty_text, :editing => editing)
    erb = ERB.new(page_block_type.render_function)
    return erb.result(locals.instance_eval { binding })
  end

end
