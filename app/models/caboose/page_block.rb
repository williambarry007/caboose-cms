
class Caboose::PageBlock < ActiveRecord::Base
  self.table_name = "page_blocks"
  
  belongs_to :page
  belongs_to :page_block_type  
  has_many :page_block_field_values
  attr_accessible :id, :page_id, :page_block_type_id, :sort_order
    
  def fields
    return page_block_type.fields
  end
  
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
  
  def field_value_object(name)    
    page_block_field_values.each do |fv|
      #Caboose.log("fv = #{fv}")
      return fv if fv.page_block_field.name == name      
    end
    return nil
  end
  
  def self.create_field_values(block_id)
    block = self.find(block_id)
    block.page_block_type.fields.each do |f| 
      if block.field_value_object(f.name).nil?
        Caboose::PageBlockFieldValue.create(:page_block_id => block.id, :page_block_field_id => f.id, :value => f.default)
      end
    end
  end
  
  def render_from_function(empty_text = nil, editing = false)
    Caboose.log("editing = #{editing}")
    locals = OpenStruct.new(:block => self, :empty_text => empty_text, :editing => editing)
    erb = ERB.new(page_block_type.render_function)
    return erb.result(locals.instance_eval { binding })
  end

end
