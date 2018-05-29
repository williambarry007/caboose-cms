
class Caboose::Block < ActiveRecord::Base
  self.table_name = "blocks"
  
  #after_find :get_master_value # TODO
  
  belongs_to :post
  belongs_to :page
  belongs_to :media
  belongs_to :block_type
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::Block'   
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::Block', :order => 'sort_order, id' # :dependent => :delete_all
  has_attached_file :file, :path => ':caboose_prefixuploads/:block_file_upload_name.:extension'
  do_not_validate_attachment_file_type :file  
  has_attached_file :image,
    :path => ':caboose_prefixuploads/:block_image_upload_name_:style.:extension',
    :default_url => "http://placehold.it/300x300",
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>',
      :huge  => '1400x1050>'
    }  
  do_not_validate_attachment_file_type :image
      
  attr_accessible :id,
    :post_id,
    :page_id, 
    :parent_id,
    :block_type_id,
    :media_id,
    :sort_order,
    :constrain,
    :full_width,
    :name,
    :value,
    :status,
    :new_parent_id,
    :new_sort_order,
    :new_value,
    :new_media_id
        
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
    if b.block_type.field_type == 'image'
      return b.media.image if b.media
      return b.image
    end
    if b.block_type.field_type == 'file'
      return b.media.file if b.media
      return b.file
    end
    #return b.image if b.block_type.field_type == 'image'
    #return b.file  if b.block_type.field_type == 'file'
    return b.value
  end

  def cv(editing, name)
    editing = defined?(editing) ? editing : false
    b = self.child(name)
    return nil if b.nil?
    if b.block_type.field_type == 'image' && !editing
      return b.media.image if b.media
      return b.image
    end
    if b.block_type.field_type == 'image' && editing
      mid = b.new_media_id.blank? ? b.media_id : b.new_media_id
      return Caboose::Media.find(mid).image if Caboose::Media.where(:id => mid).exists?
      return (mid != 0 ? b.image : nil)
    end
    if b.block_type.field_type == 'file' && !editing
      return b.media.file if b.media
      return b.file
    end
    if b.block_type.field_type == 'file' && editing
      mid = b.new_media_id.blank? ? b.media_id : b.new_media_id
      return Caboose::Media.find(mid).file if Caboose::Media.where(:id => mid).exists?
      return (mid != 0 ? b.file : nil)
    end
    return (editing && !b.new_value.blank?) ? (b.new_value == 'EMPTY' ? nil : b.new_value) : b.value
  end
  
  def rendered_child_value(name, options)
    b = self.child(name)
    return nil if b.nil?
    if b.block_type.field_type == 'image'
      return b.media.image if b.media
      return b.image
    end
    if b.block_type.field_type == 'file'
      return b.media.file if b.media
      return b.file
    end
    return "" if b.value.nil? || b.value.strip.length == 0
    view = options && options[:view] ? options[:view] : ActionView::Base.new(ActionController::Base.view_paths)    
    return view.render(:inline => b.value, :locals => options)                    
  end
  
  def child(name)
    Caboose::Block.where("parent_id = ? and name = ?", self.id, name).first
  end

  def filtered_children(editing, sort_by_id = false)
    blocks = []
    if editing
      sortby = sort_by_id ? 'block_type_id' : 'new_sort_order,id'
      blocks = Caboose::Block.where("status != ?","deleted").where("new_parent_id = ? or (parent_id = ? and new_parent_id is null)", self.id, self.id).order(sortby)
    else
      blocks = Caboose::Block.where(:parent_id => self.id).order('sort_order,id')
    end
    return blocks
  end
  
  def create_children(block_type_override: nil, status: 'published')
    bt = block_type_override ? block_type_override : block_type
    bt.children.each do |bt2|
      bt_id = bt2.id      
      #if bt2.parent_id
      #  new_bt_id = Caboose::BlockType.where(:name => bt2.field_type).first.id 
      #end      
      if self.child(bt2.name).nil?
        b = Caboose::Block.create(
          :post_id => self.post_id,
          :page_id => self.page_id,
          :parent_id => self.id, 
          :block_type_id => bt_id,
          :name => bt2.name,
          :value => bt2.default,
          :status => status
        )
        b.create_children(block_type_override: bt2, status: status)
      end
    end
  end
                                            
  def render(block, options)
    #Caboose.log("block.full_name = #{block.full_name}")
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
              
      #begin str = view.render(:partial => "../../sites/#{site.name}/blocks/#{full_name}", :locals => options2) 
      #rescue ActionView::MissingTemplate => ex        
      #  begin str = view.render(:partial => "../../sites/#{site.name}/blocks/#{block.block_type.name}", :locals => options2) 
      #  rescue ActionView::MissingTemplate => ex          
      #    begin str = view.render(:partial => "../../sites/#{site.name}/blocks/#{block.block_type.field_type}", :locals => options2) 
      #    rescue ActionView::MissingTemplate => ex            
      #      begin str = view.render(:partial => "../../app/views/caboose/blocks/#{full_name}", :locals => options2) 
      #      rescue ActionView::MissingTemplate => ex                                          
      #        begin str = view.render(:partial => "../../app/views/caboose/blocks/#{block.block_type.name}", :locals => options2) 
      #        rescue ActionView::MissingTemplate => ex                
      #          begin str = view.render(:partial => "../../app/views/caboose/blocks/#{block.block_type.field_type}", :locals => options2) 
      #          rescue ActionView::MissingTemplate => ex                  
      #          begin str = view.render(:partial => "caboose/blocks/#{full_name}", :locals => options2)  
      #          rescue ActionView::MissingTemplate => ex                  
      #            begin str = view.render(:partial => "caboose/blocks/#{block.block_type.name}", :locals => options2) 
      #            rescue ActionView::MissingTemplate => ex                    
      #              begin str = view.render(:partial => "caboose/blocks/#{block.block_type.field_type}", :locals => options2) 
      #              rescue Exception => ex 
      #                str = "<p class='note error'>#{self.block_message(block, ex)}</p>" 
      #              end
      #            rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #            end
      #          rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #          end
      #        rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #        end                              
      #      rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #      end
      #    rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #    end
      #  rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #  end
      #rescue Exception => ex { str = "<p class='note error'>#{self.block_message(block, ex)}</p>" } 
      #end
      
      arr = [
        #"../../sites/#{site.name}/blocks/#{full_name}",
        #"../../sites/#{site.name}/blocks/#{block.block_type.name}",
        #"../../sites/#{site.name}/blocks/#{block.block_type.field_type}",
        #"../../app/views/caboose/blocks/#{full_name}",
        #"../../app/views/caboose/blocks/#{block.block_type.name}",
        #"../../app/views/caboose/blocks/#{block.block_type.field_type}",
        #"caboose/blocks/#{full_name}",                
        #"caboose/blocks/#{block.block_type.name}",                
        #"caboose/blocks/#{block.block_type.field_type}"
        
        "../../app/views/caboose/blocks/#{site.name}/#{full_name}",
        "../../app/views/caboose/blocks/#{site.name}/#{block.block_type.name}",
        "../../app/views/caboose/blocks/#{site.name}/#{block.block_type.field_type}",
        "../../app/views/caboose/blocks/#{full_name}",
        "../../app/views/caboose/blocks/#{block.block_type.name}",
        "../../app/views/caboose/blocks/#{block.block_type.field_type}",
        "caboose/blocks/#{full_name}",                
        "caboose/blocks/#{block.block_type.name}",                
        "caboose/blocks/#{block.block_type.field_type}"                
      ]
      
    #  Caboose.log("editing: " + options2[:editing].to_s)

      if options2[:editing] == true
        if !block.new_value.blank? && block.new_value != 'EMPTY'
          block.value = block.new_value 
        elsif block.new_value == 'EMPTY'
          block.value = nil
        end
        block.media_id = block.new_media_id if !block.new_media_id.nil?
       # block.sort_order = block.new_sort_order if !block.new_sort_order.blank?
       # block.parent_id = block.new_parent_id if !block.new_parent_id.blank?
       # Caboose.log("temp setting #{block.id}")
        # block.children.each do |bc|
        #   Caboose.log("temp setting #{bc.id}")
        #   bc.value = bc.new_value if !bc.new_value.blank?
        #   bc.sort_order = bc.new_sort_order if !bc.new_sort_order.blank?
        #   bc.parent_id = bc.new_parent_id if !bc.new_parent_id.blank?
        #   Caboose.log("bc value: #{bc.value}")
        # end

        # if block && block.id == 430363
        #   Caboose.log( block.value )
        # end

        if block.status != 'deleted'  #&& ( block.new_parent_id.blank? || options2[:is_new] )
          str = self.render_helper(view, options2, block, full_name, arr, 0)
        end
     #   str.gsub('child_value','edited_child_value')
      else
        if block.status != 'added'
          str = self.render_helper(view, options2, block, full_name, arr, 0)
        end
      end


    end    
    return str
  end
  
  def render_helper(view, options, block, full_name, arr, i)
    return "<p class='note error'>Could not find block view anywhere.</p>" if i > arr.count
    begin
      str = view.render(:partial => arr[i], :locals => options)
      #Caboose.log("Level #{i+1} for #{full_name}: Found partial #{arr[i]}")
      rescue ActionView::MissingTemplate => ex        
        #Caboose.log("Level #{i+1} for #{full_name}: #{ex.message}")        
        str = render_helper(view, options, block, full_name, arr, i+1)
      rescue Exception => ex 
        #Caboose.log("Level #{i+1} for #{full_name}: #{ex.message}")
        str = "<p class='note error'>#{self.block_message(block, ex)}</p>"
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
    options2[:block] = self
    
    view = options2[:view]     
    view = ActionView::Base.new(ActionController::Base.view_paths) if view.nil?        
    site = options[:site]
    
    begin
      #str = view.render(:partial => "../../sites/#{site.name}/blocks/#{name}", :locals => options2)
      str = view.render(:partial => "../../app/views/caboose/blocks/#{site.name}/#{name}", :locals => options2)
    rescue ActionView::MissingTemplate => ex      
      begin
        str = view.render(:partial => "caboose/blocks/#{name}", :locals => options2)      
      rescue Exception => ex
        Caboose.log("Partial caboose/blocks/#{name} doesn't exist.")
        str = "<p class='note error'>#{self.partial_message(name, ex)}</p>"
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
      'post_id'        => self.post_id,      
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
    
    sql = nil
    if self.page_id
      sql = ["update blocks set value = ? where id in (
          select B.id from blocks B left join pages P on B.page_id = P.id
          where B.id <> ? and B.block_type_id = ? and P.site_id = ?
        )", value, self.id, self.block_type_id, site_id]
    elsif self.post_id      
      sql = ["update blocks set value = ? where id in (
        select B.id from blocks B left join posts P on B.post_id = P.id
        where B.id <> ? and B.block_type_id = ? and P.site_id = ?
      )", value, self.id, self.block_type_id, site_id]
    end
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, sql))            
  end
  
  # Parses the value given for a checkbox multiple block
  def self.parse_checkbox_multiple_value(b, arr)
    current_value = b.new_value.blank? ? (b.value ? b.value.split('|') : []) : (b.new_value ? b.new_value.split('|') : [])
    v = arr[0]
    checked = arr[1].to_i == 1
    if v == 'all'
      if checked && b.block_type && !b.block_type.options.blank?
        Caboose.log(b.block_type.options)
        return b.block_type.options.split("\n").join('|')
      else
        return ''
      end
    else
      if checked && !current_value.include?(v)
        current_value << v      
      elsif !checked && current_value.include?(v)
        current_value.delete(v)
      end
      return current_value.join('|')
    end
  end

  # block siblings (in editing mode)
  def siblings(min_sort_order=0)
    Caboose::Block.where(:name => nil).where('new_sort_order >= ?',min_sort_order).where("(new_parent_id is null and parent_id = ? and status != ?) OR (new_parent_id = ? and status != ?)",(self.new_parent_id.blank? ? self.parent_id : self.new_parent_id),'deleted',(self.new_parent_id.blank? ? self.parent_id : self.new_parent_id),'deleted').order(:new_sort_order, :id).all
  end
  
  # Move a block up
  def move_up    
    sibs = self.siblings
    sibs.each_with_index do |b2, i|      
      b2.new_sort_order = i
      b2.status = 'edited' if b2.status == 'published'
      b2.save
    end
    changed = false
    sibs.each_with_index do |b2, i|      
      if i > 0 && b2.id == self.id                
        sibs[i-1].new_sort_order = i
        sibs[i-1].save        
        b2.new_sort_order = i - 1
        b2.status = 'edited' if b2.status == 'published'
        b2.save
        changed = true
      end      
    end
    return changed            
  end
  
  # Move a block down
  def move_down
    sibs = self.siblings
    sibs.each_with_index do |b2, i|      
      b2.new_sort_order = i
      b2.status = 'edited' if b2.status == 'published'
      b2.save
    end
    changed = false
    sibs.each_with_index do |b2, i|      
      if i < (sibs.count-1) && b2.id == self.id                
        sibs[i+1].new_sort_order = i
        sibs[i+1].save        
        b2.new_sort_order = i + 1
        b2.status = 'edited' if b2.status == 'published'
        b2.save
        changed = true
      end      
    end
    return changed            
  end

  # fix sort orders
  def reorganize
    sibs = self.siblings
    sibs.each_with_index do |b2, i|      
      b2.new_sort_order = i
      b2.status = 'edited' if b2.status == 'published'
      b2.save
    end     
  end
  
  def constrain_all         
    self.children.each do |b|
      return false if b.full_width == true
    end
    return true
  end
  
  def unique_file_upload_name(str)
    base = str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
    str = "#{base}"
    i = 1
    while Caboose::Block.where("id <> ? and file_upload_name = ?", self.id, str).exists? && i < 100 do
      str = "#{base}-#{i}"
      i = i + 1
    end
    return str              
  end
  
  def unique_image_upload_name(str)
    base = str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
    str = "#{base}"
    i = 1
    while Caboose::Block.where("id <> ? and image_upload_name = ?", self.id, str).exists? && i < 100 do
      str = "#{base}-#{i}"
      i = i + 1
    end
    return str              
  end
  
  def self.unique_file_upload_name(str)
    base = str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
    str = "#{base}"
    i = 1
    while Caboose::Block.where("file_upload_name = ?", str).exists? && i < 100 do
      str = "#{base}-#{i}"
      i = i + 1
    end
    return str              
  end
  
  def self.unique_image_upload_name(str)
    base = str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
    str = "#{base}"
    i = 1
    while Caboose::Block.where("image_upload_name = ?", str).exists? && i < 100 do
      str = "#{base}-#{i}"
      i = i + 1
    end
    return str              
  end
  
  def migrate_media
    
    if self.block_type.field_type == 'image' && !self.image_file_name.nil? && self.media_id.nil?
      
      site_id = self.page_id ? self.page.site_id : self.post.site_id
      cat = Caboose::MediaCategory.top_category(site_id)      
      m = self.media
      m = Caboose::Media.create(:media_category_id => cat.id, :original_name => self.image_file_name, :name => Caboose::Media.upload_name(self.image_file_name)) if m.nil?      
      m.image = URI.parse(self.image.url(:original))
      m.processed = true
      m.save
      
      self.media_id = m.id
      self.save
    
    elsif self.block_type.field_type == 'file' && !self.file_file_name.nil? && self.media_id.nil?
      
      site_id = self.page_id ? self.page.site_id : self.post.site_id
      cat = Caboose::MediaCategory.top_category(site_id)
      m = self.media      
      m = Caboose::Media.create(:media_category_id => cat.id, :original_name => self.file_file_name, :name => Caboose::Media.upload_name(self.file_file_name)) if m.nil?        
      m.file = URI.parse(self.file.url)
      m.processed = true
      m.save
      
      self.media_id = m.id
      self.save
      
    end
    
  end
  
  # Assumes that we start the duplicate process at the top level block
  def duplicate_page_block(site_id, page_id, new_block_type_id = nil, new_parent_id = nil)        
    b = Caboose::Block.create(
      :page_id            => page_id,          
      :post_id            => nil,         
      :parent_id          => new_parent_id,
      :media_id           => self.media_id,
      :block_type_id      => new_block_type_id,    
      :sort_order         => self.sort_order,
      :constrain          => self.constrain,
      :full_width         => self.full_width,
      :name               => self.name,
      :value              => self.value
    )    
    self.children.each do |b2|
      if b2.name 
        # The block is part of the block type, so we have to find the corresponding child block in the new block type        
        bt = Caboose::BlockType.where(:parent_id => new_block_type_id, :name => b2.name).first
        if bt
          b2.duplicate_page_block(site_id, page_id, bt.id, b.id)
        else
          # Don't duplicate it because the corresponding child block doesn't exist in the new block type
        end
      else
        # The block is a child block that isn't part of the block type definition
        b2.duplicate_page_block(site_id, page_id, b2.block_type_id, b.id)
      end
    end
  end


  # Assumes that we start the duplicate process at the top level block
  def duplicate_block(site_id, page_id, post_id, new_block_type_id = nil, new_parent_id = nil)      
    b = Caboose::Block.create(
      :page_id            => page_id,          
      :post_id            => post_id,         
      :parent_id          => new_parent_id,
      :media_id           => self.media_id,
      :new_media_id       => self.new_media_id,
      :block_type_id      => self.block_type_id,    
      :sort_order         => (self.new_sort_order.blank? ? (self.sort_order) : (self.new_sort_order)),
      :new_sort_order     => (self.new_sort_order.blank? ? (self.sort_order) : (self.new_sort_order)),
      :constrain          => self.constrain,
      :full_width         => self.full_width,
      :name               => self.name,
      :value              => self.value,
      :new_value          => self.new_value,
      :status             => 'added'
    )

    if b.name.nil?
 #     Caboose.log("moving block #{b.id} down, parent_id is #{b.parent_id}")
      b.reorganize
    end

    self.filtered_children(true).each do |b2|
      if b2.name 
        # The block is part of the block type, so we have to find the corresponding child block in the new block type        
        bt = Caboose::BlockType.where(:parent_id => self.block_type_id, :name => b2.name).first
        if bt
          b2.duplicate_block(site_id, page_id, post_id, bt.id, b.id)
        else
          # Don't duplicate it because the corresponding child block doesn't exist in the new block type
        end
      else
        # The block is a child block that isn't part of the block type definition
        b2.duplicate_block(site_id, page_id, post_id, b2.block_type_id, b.id)
      end
    end
    return b.id
  end
  
  def modal_js_block_names
    arr = []
    arr << self.block_type.name if self.block_type.use_js_for_modal
    self.filtered_children(true).each do |b2|
      self.modal_js_controllers_helper(b2, arr)
    end
    return arr
  end
  
  def modal_js_controllers_helper(b, arr)
    bt = b.block_type
    arr << bt.name if bt.use_js_for_modal
    b.filtered_children(true).each do |b2|
      self.modal_js_controllers_helper(b2, arr)
    end                          
  end

end
