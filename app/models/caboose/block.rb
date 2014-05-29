
class Caboose::Block < ActiveRecord::Base
  self.table_name = "blocks"
  
  belongs_to :page
  belongs_to :block_type
  belongs_to :field   
  has_many :fields
  attr_accessible :id, :page_id, :field_id, :block_type_id, :sort_order
  
  def field_value(name)      
    fields.each do |f|
      if f.field_type.name == name
        if    f.field_type.field_type == 'image' then return f.image
        elsif f.field_type.field_type == 'file'  then return f.file
        else return f.value
        end
      end
    end
    return nil
  end
  
  def field_block(name)
    f = self.field_for(name)
    return nil if f.nil? || f.child_block.nil?
    return f.child_block    
  end
  
  def field_for(name)    
    fields.each do |f|
      return f if f.field_type.name == name      
    end
    return nil
  end
  
  #def self.create_fields(block_id)
  #  block = self.find(block_id)
  #  block.block_type.field_types.each do |ft| 
  #    if block.field_for(f.name).nil?
  #      Caboose::PageBlockFieldValue.create(:page_block_id => block.id, :page_block_field_id => f.id, :value => f.default)
  #    end
  #  end
  #end
  
  def create_fields
    block_type.field_types.each do |ft| 
      if self.field_for(ft.name).nil?
        f = Caboose::Field.create(:block_id => self.id, :field_type_id => ft.id, :value => ft.default)
        if ft.field_type.starts_with?('block')
          b = Caboose::Block.create(:page_id => self.page_id, :field_id => f.id, :block_type_id => 2)
          b.create_fields
        end
      end
    end
  end
  
  def render(empty_text = nil, editing = false)
    if block_type.use_render_function && block_type.render_function
      return render_from_function(empty_text, editing)        
    else       
      view = ActionView::Base.new(ActionController::Base.view_paths)      
      return view.render(:partial => "caboose/blocks/#{block_type.name}", :locals => { :block => self, :empty_text => empty_text, :editing => editing })
    end
  end

  def render_from_function(empty_text = nil, editing = false)    
    locals = OpenStruct.new(:block => self, :empty_text => empty_text, :editing => editing)
    Caboose.log(block_type.id)
    erb = ERB.new(block_type.render_function)
    return erb.result(locals.instance_eval { binding })
  end
  
end
