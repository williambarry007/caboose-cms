
class Caboose::Block < ActiveRecord::Base
  self.table_name = "blocks"
  
  #after_find :get_master_value # TODO
  
  belongs_to :page
  belongs_to :block_type
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::Block'   
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::Block', :dependent => :delete_all, :order => 'sort_order'
  has_attached_file :file, :path => ':path_prefixuploads/:id.:extension'
  do_not_validate_attachment_file_type :file
  has_attached_file :image,
    :path => ':path_prefixuploads/:id_:style.:extension',
    :default_url => "http://placehold.it/300x300",
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>',
      :huge  => '1400x1050>'
    }
  do_not_validate_attachment_file_type :image
  
  attr_accessible :id, 
    :page_id, 
    :parent_id,
    :block_type_id,
    :sort_order,
    :constrain,
    :name,
    :value        
    
  after_initialize :caste_value
  before_save :caste_value
  
  def caste_value
    if self.block_type_id.nil?
      bt = Caboose::BlockType.where(:field_type => 'text').first
      if bt.nil?
        bt = Caboose::BlockType.create(:name => 'text', :description => 'Text', :field_type => 'text', :default => '', :width => 800, :height => 400, :fixed_placeholder => false)
      end      
      self.block_type_id = bt.id
    end
    #if self.block_type_id.field_type.nil?
    #  self.block_type.field_type = 'text'      
    #end        
    #if self.block_type.field_type == 'checkbox'
    #  v = self.value
    #  self.value = v ? (v == 1 || v == '1' || v == true ? 1 : 0) : 0        
    #end
  end
  
  def full_name
    return self.name if parent_id.nil?
    return "#{parent.full_name}_#{self.name}"
  end
  
  def child_value(name)
    b = self.child(name)
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

    defaults = {
      :view => nil,
      :controller_view_content => nil,
      :modal => false,
      :empty_text => '',
      :editing => false,
      :css => nil,
      :js => nil,
      :csrf_meta_tags => nil,
      :csrf_meta_tags2 => nil,    
      :logged_in_user => nil
    }    
    #defaults = { :modal => false, :empty_text => '', :editing => false, :css => nil, :js => nil, :block => block }
    options2 = nil
    if options.is_a?(Hash)
      options2 = defaults.merge(options)
    else
      #options2 = { :modal => options.modal, :empty_text => options.empty_text, :editing => options.editing, :css => options.css, :js => options.js }
      options2 = {
        :view                    => options.view                    ? options.view                    : nil,
        :controller_view_content => options.controller_view_content ? options.controller_view_content : nil,
        :modal                   => options.modal                   ? options.modal                   : nil,
        :empty_text              => options.empty_text              ? options.empty_text              : nil,
        :editing                 => options.editing                 ? options.editing                 : nil,
        :css                     => options.css                     ? options.css                     : nil,
        :js                      => options.js                      ? options.js                      : nil,
        :csrf_meta_tags          => options.csrf_meta_tags          ? options.csrf_meta_tags          : nil,
        :csrf_meta_tags2         => options.csrf_meta_tags2         ? options.csrf_meta_tags2         : nil,
        :logged_in_user          => options.logged_in_user          ? options.logged_in_user          : nil
      }
    end
    options2[:block] = block

    view = options2[:view]     
    view = ActionView::Base.new(ActionController::Base.view_paths) if view.nil?
      
    if block.block_type.use_render_function && block.block_type.render_function
      begin
        str = view.render(:partial => "caboose/blocks/render_function", :locals => options2)
      rescue Exception => ex
        msg = block ? (block.block_type ? "Error with #{block.block_type.name} block (block_type_id #{block.block_type.id}, block_id #{block.id})\n" : "Error with block (block_id #{block.id})\n") : ''             
        Caboose.log("#{msg}#{ex.message}\n#{ex.backtrace.join("\n")}")
        str = "<p class='note error'>#{msg}</p>"
      end            
    else
      
      full_name = block.block_type.full_name
      full_name = "lksdjflskfjslkfjlskdfjlkjsdf" if full_name.nil? || full_name.length == 0
      
      # Check the local site first      
      site = options2[:site]
      if site.nil?
        self.block_message(block, "Error: site variable is nil.")
      end
        
      begin                        
        str = view.render(:partial => "../../sites/#{site.name}/blocks/#{full_name}", :locals => options2)        
      rescue ActionView::MissingTemplate => ex
        #Caboose.log("Can't find partial: ../../sites/#{site.name}/blocks/#{full_name}")
        begin
          str = view.render(:partial => "../../sites/#{site.name}/blocks/#{block.block_type.name}", :locals => options2)                    
        rescue ActionView::MissingTemplate => ex
          #Caboose.log("Can't find partial: ../../sites/#{site.name}/blocks/#{block.block_type.name}")
          begin                        
            str = view.render(:partial => "../../sites/#{site.name}/blocks/#{block.block_type.field_type}", :locals => options2)            
          rescue ActionView::MissingTemplate
            #Caboose.log("Can't find partial: ../../sites/#{site.name}/blocks/#{block.block_type.field_type}")
            begin
              str = view.render(:partial => "caboose/blocks/#{full_name}", :locals => options2)        
            rescue ActionView::MissingTemplate
              #Caboose.log("Can't find partial: caboose/blocks/#{full_name}")
              begin          
                str = view.render(:partial => "caboose/blocks/#{block.block_type.name}", :locals => options2)                    
              rescue ActionView::MissingTemplate
                #Caboose.log("Can't find partial: caboose/blocks/#{block.block_type.name}")
                begin                        
                  str = view.render(:partial => "caboose/blocks/#{block.block_type.field_type}", :locals => options2)            
                rescue Exception => ex                  
                  #Caboose.log("Can't find partial: caboose/blocks/#{block.block_type.field_type}")
                  str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
                end
              rescue Exception => ex                          
                str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
              end
            rescue Exception => ex              
              str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
            end
          rescue Exception => ex                  
            str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
          end                              
        rescue Exception => ex                                                     
          str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
        end        
      rescue Exception => ex        
        str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
      end                    
    end    
    return str
  end
  
  def block_message(block, ex)    
    msg = block ? (block.block_type ? "Error with #{block.block_type.name} block (block_type_id #{block.block_type.id}, block_id #{block.id})\n" : "Error with block (block_id #{block.id})\n") : ''
    if ex.is_a?(String)
      Caboose.log("#{msg}#{ex}")
    else
      Caboose.log("#{msg}#{ex.message}\n#{ex.backtrace.join("\n")}")
    end
    return msg
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
    site = options[:site]
    
    begin
      str = view.render(:partial => "../../sites/#{site.name}/blocks/#{name}", :locals => options2)
    rescue ActionView::MissingTemplate => ex      
      begin
        str = view.render(:partial => "caboose/blocks/#{name}", :locals => options2)
      rescue
        Caboose.log("Partial caboose/blocks/#{name} doesn't exist.")
        str = "<p class='note error'>#{self.partial_message(block, ex)}</p>"
      end      
    end
      
    return str
  end
        
  def partial_message(name, ex)    
    msg = "Error with partial #{name}:\n"
    if ex.is_a?(String)
      Caboose.log("#{msg}#{ex}")
    else
      Caboose.log("#{msg}#{ex.message}\n#{ex.backtrace.join("\n")}")
    end
    return msg
  end
  
  #def child_block_link        
  #  return "<div class='new_block' id='new_block_#{self.id}'>New Block</div>"    
  #end  
  #def new_block_before_link        
  #  return "<div class='new_block_before' id='new_block_before_#{self.id}'>New Block</div>"    
  #end  
  #def new_block_after_link        
  #  return "<div class='new_block_after' id='new_block_after_#{self.id}'>New Block</div>"    
  #end
  
  def title    
    str = "#{self.block_type.name}"
    if self.name && self.name.strip.length > 0
      str << " (#{self.name})"
    end
    return str
  end
  
  def js_hash
    kids = self.children.collect { |b| b.js_hash }
    bt = self.block_type    
    return {
      'id'             => self.id,           
      'page_id'        => self.page_id,      
      'parent_id'      => self.parent_id,
      'parent_title'   => self.parent ? self.parent.title : '',
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
  
  def log_helper(prefix = '')
    puts "#{prefix}#{self.id}"
    self.children.each do |b|
      b.log_helper("#{prefix}-")
    end
  end
      
  # Returns the master block for this global block 
  def get_global_value(site_id)
    return if !self.block_type.is_global    
    return if !Caboose::Block.includes(:page).where("blocks.id <> ? and block_type_id = ? and pages.site_id = ?", self.id, self.block_type_id, site_id).exists?        
    b = Caboose::Block.includes(:page).where("blocks.id <> ? and block_type_id = ? and pages.site_id = ?", self.id, self.block_type_id, site_id).reorder("blocks.id").first    
    self.value = b.value
    self.save
    
    self.children.each do |b2|
      b2.get_global_value(site_id) if b2.block_type.is_global
    end    
  end
  
  # Updates all the global blocks for the given site
  def update_global_value(value, site_id)
    return if !self.block_type.is_global    
    return if !Caboose::Block.includes(:page).where("blocks.id <> ? and block_type_id = ? and pages.site_id = ?", self.id, self.block_type_id, site_id).exists?        
    
    sql = ["update blocks set value = ? where id in (
        select B.id from blocks B left join pages P on B.page_id = P.id
        where B.id <> ? and B.block_type_id = ? and P.site_id = ?
      )", value, self.id, self.block_type_id, site_id]       
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, sql))            
  end
  
  # Parses the value given for a checkbox multiple block
  def self.parse_checkbox_multiple_value(b, arr)
    current_value = b.value ? b.value.split('|') : []
    v = arr[0]
    checked = arr[1].to_i == 1
    if checked && !current_value.include?(v)
      current_value << v      
    elsif !checked && current_value.include?(v)
      current_value.delete(v)
    end
    return current_value.join('|')
  end
  
  # Move a block up
  def move_up    
    siblings = Caboose::Block.where(:parent_id => self.parent_id).reorder(:sort_order).all        
    siblings.each_with_index do |b2, i|      
      b2.sort_order = i
      b2.save
    end
    changed = false
    siblings.each_with_index do |b2, i|      
      if i > 0 && b2.id == self.id                
        siblings[i-1].sort_order = i
        siblings[i-1].save        
        b2.sort_order = i - 1
        b2.save
        changed = true
      end      
    end
    return changed            
  end
  
  # Move a block down
  def move_down
    siblings = Caboose::Block.where(:parent_id => self.parent_id).reorder(:sort_order).all        
    siblings.each_with_index do |b2, i|      
      b2.sort_order = i
      b2.save
    end
    changed = false
    siblings.each_with_index do |b2, i|      
      if i < (siblings.count-1) && b2.id == self.id                
        siblings[i+1].sort_order = i
        siblings[i+1].save        
        b2.sort_order = i + 1
        b2.save
        changed = true
      end      
    end
    return changed            
  end

end
