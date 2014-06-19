
class Caboose::Block < ActiveRecord::Base
  self.table_name = "blocks"
  
  belongs_to :page
  belongs_to :block_type
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::Block'   
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::Block', :dependent => :delete_all, :order => 'sort_order'
  has_attached_file :file, :path => '/uploads/:id.:extension'
  do_not_validate_attachment_file_type :file
  has_attached_file :image, 
    :path => 'uploads/:id_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  do_not_validate_attachment_file_type :image
  
  attr_accessible :id, 
    :page_id, 
    :parent_id,
    :block_type_id,
    :sort_order,
    :name,
    :value        
    
  after_initialize do |b|
    # Do whatever we need to do to set the value to be correct for the field type we have.
    # Most field types are fine with the raw value in the database
    if b.block_type.nil?
      bt = Caboose::BlockType.where(:field_type => 'text').first
      b.block_type_id = bt.id
    end
    if b.block_type.field_type.nil?
      b.block_type.field_type = 'text'
      b.save
    end
    case b.block_type.field_type
      when 'checkbox' then b.value = (b.value == 1 || b.value == '1' || b.value == true ? true : false)
    end
  end
  
  before_save :caste_value
  def caste_value  
    case self.block_type.field_type
      when 'checkbox'
        if self.value.nil? then self.value = false
        else self.value = (self.value == 1 || self.value == '1' || self.value == true ? 1 : 0)
        end
    end
  end
  
  def full_name
    return name if parent_id.nil?
    return "#{parent.full_name}_#{name}"
  end
  
  def child_value(name)
    b = child(name)
    return nil if b.nil?
    return b.image if b.block_type.field_type == 'image'
    return b.file  if b.block_type.field_type == 'file'
    return b.value        
  end
  
  def child(name)
    Caboose::Block.where("parent_id = ? and name = ?", self.id, name).first
  end
  
  def create_children(block_type_override = nil)
    bt = block_type_override ? block_type_override : block_type
    bt.children.each do |bt2|
      bt_id = bt2.id      
      #if bt2.parent_id
      #  new_bt_id = Caboose::BlockType.where(:name => bt2.field_type).first.id 
      #end      
      if self.child(bt2.name).nil?
        b = Caboose::Block.create(
          :page_id => self.page_id,
          :parent_id => self.id, 
          :block_type_id => bt_id,
          :name => bt2.name,
          :value => bt2.default
        )
        b.create_children(bt2)
      end
    end
  end
                                            
  def render(block, options)    
    #Caboose.log("block.render\nself.id = #{self.id}\nblock = #{block}\nblock.full_name = #{block.full_name}\noptions.class = #{options.class}\noptions = #{options}")
    
    if block && block.is_a?(String)
      #Caboose.log("Block #{block} is a string, finding block object... self.id = #{self.id}")
      b = self.child(block)        
      if b.nil?
        self.create_children
        b = self.child(block)
        if b.nil?        
          Caboose.log("No block exists with name \"#{block}\".")
          return false
        end
      end
      block = b
    end        
    str = ""

    defaults = { :modal => false, :empty_text => '', :editing => false, :css => nil, :js => nil, :block => block }
    options2 = nil
    if options.is_a?(Hash)
      options2 = defaults.merge(options)
    else
      options2 = { :modal => options.modal, :empty_text => options.empty_text, :editing => options.editing, :css => options.css, :js => options.js }        
    end
    options2[:block] = block

    if block.block_type.use_render_function && block.block_type.render_function            
      str = block.render_from_function(options2)
    else
      view = ActionView::Base.new(ActionController::Base.view_paths)
      begin        
        str = view.render(:partial => "caboose/blocks/#{block.full_name}", :locals => options2)
      rescue ActionView::MissingTemplate
        begin
          str = view.render(:partial => "caboose/blocks/#{block.block_type.name}", :locals => options2)          
        rescue ActionView::MissingTemplate
          begin
            str = view.render(:partial => "caboose/blocks/#{block.block_type.field_type}", :locals => options2)
          rescue Exception => ex
            Caboose.log(ex.message)
          end
        rescue Exception => ex
          Caboose.log(ex.message)
        end
      rescue Exception => ex
        Caboose.log(ex.message)
      end        
    end
    return str
  end

  def render_from_function(options)
    self.create_children    
    #locals = OpenStruct.new(:block => self, :empty_text => empty_text, :editing => editing)
    locals = OpenStruct.new(options)
    erb = ERB.new(block_type.render_function)
    return erb.result(locals.instance_eval { binding })
  end
  
  def partial(name, options)    
    defaults = { :modal => false, :empty_text => '', :editing => false, :css => nil, :js => nil }
    options2 = nil
    if options.is_a?(Hash)
      options2 = defaults.merge(options)
    else
      options2 = { :modal => options.modal, :empty_text => options.empty_text, :editing => options.editing, :css => options.css, :js => options.js }        
    end
    options2[:block] = self
    
    view = ActionView::Base.new(ActionController::Base.view_paths)
    begin
      str = view.render(:partial => "caboose/blocks/#{name}", :locals => options2)
    rescue
      Caboose.log("Partial caboose/blocks/#{name} doesn't exist.")
    end
    return str
  end
        
  def child_block_link        
    return "<div class='new_block' id='new_block_#{self.id}'>New Block</div>"    
  end    
  
  def js_hash
    kids = self.children.collect { |b| b.js_hash }
    bt = self.block_type
    return {
      'id'             => self.id,           
      'page_id'        => self.page_id,      
      'parent_id'      => self.parent_id,    
      'block_type_id'  => self.block_type_id,    
      'sort_order'     => self.sort_order,
      'name'           => self.name,
      'value'          => self.value,
      'children'       => kids,      
      'block_type'     => {      
        'id'                              => bt.id,                            
        'parent_id'                       => bt.parent_id,                     
        'name'                            => bt.name,
        'description'                     => bt.description,
        'render_function'                 => bt.render_function,
        'use_render_function'             => bt.use_render_function,
        'use_render_function_for_layout'  => bt.use_render_function_for_layout,
        'allow_child_blocks'              => bt.allow_child_blocks,
        'field_type'                      => bt.field_type,
        'default'                         => bt.default,
        'width'                           => bt.width,
        'height'                          => bt.height,
        'fixed_placeholder'               => bt.fixed_placeholder,
        'options'                         => bt.options,
        'options_function'                => bt.options_function,
        'options_url'                     => bt.options_url
      },
      'file' => {
        'url' => self.file.url
      },
      'image' => {
        'tiny_url'  => self.image.url(:tiny),
        'thumb_url' => self.image.url(:thumb),
        'large_url' => self.image.url(:large),
      }
    }
  end

end
