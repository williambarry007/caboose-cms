
module Caboose
  class PageCacher
    
    def self.cache_all
      Page.reorder(:id).all.each do |p|
        puts "Caching #{p.title}..."
        self.cache(p)
      end      
    end
      
    def self.cache(page_id)    
      p = (page_id.is_a?(Integer) ? Page.where(:id => page_id).first : page_id)
      return if p.nil?
      return if p.site_id.nil?
      return if p.block.nil?
            
      @render_functions = {} if @render_functions.nil?
      @page_render_functions = {} if @page_render_functions.nil?      
      @page_render_functions[p.id] = []
      @dups = {}
                  
      self.cache_helper(p.site, p, p.block)

      arr = @page_render_functions[p.id].collect do |bt_id|                        
        "<% def render_block_type_#{bt_id}(block, page, view, controller_view_content, modal, empty_text, editing, css, js, csrf_meta_tags, csrf_meta_tags2, logged_in_user, site) %>#{@render_functions[bt_id]}<% end %>"         
      end                  
      
      dups = []
      @dups.each{ |bt_id, arr| dups << "#{bt_id} => [#{arr.join(',')}]" }
      dups = dups.join(', ')
        
      str = arr.join("\n\n")      
      str << "<%\n"      
      str << "def dup_id(bt_id)\n"
      str << "  dups = {#{dups}}\n"
      str << "  dups.each do |bt_id2, arr|\n"
      str << "    return bt_id2 if arr.include?(bt_id)\n"
      str << "  end\n"
      str << "  return bt_id\n"
      str << "end\n"            
      str << "def render_block_type(block, child_block, page, view, controller_view_content, modal, empty_text, editing, css, js, csrf_meta_tags, csrf_meta_tags2, logged_in_user, site)\n"
      str << "  b = child_block && child_block.is_a?(String) ? block.child(child_block) : child_block\n"      
      str << "  send(\"render_block_type_\#\{dup_id(b.block_type_id)\}\", b, page, view, controller_view_content, modal, empty_text, editing, css, js, csrf_meta_tags, csrf_meta_tags2, logged_in_user, site)\n"
      str << "end\n\n"            
      str << "render_block_type_#{p.block.block_type_id}(@block, @page, @view, @controller_view_content, @modal, @empty_text, @editing, @css, @js, @csrf_meta_tags, @csrf_meta_tags2, @logged_in_user, @site)\n"      
      str << "%>\n"      
            
      pc = PageCache.where(:page_id => p.id).first
      pc = PageCache.new(:page_id => p.id) if pc.nil?
      pc.render_function = str
      pc.block = Marshal.dump(BlockCache.new(p.block))
      pc.save              
    end
    
    def self.cache_helper(site, p, block)
      return if block.nil?
      self.cache_helper2(site, p, block.block_type)            
      block.children.each{ |b2| self.cache_helper(site, p, b2) }
    end
    
    def self.cache_helper2(site, p, bt)      
      self.add_block_type(site, p, bt)
      bt.children.each{ |bt2| self.cache_helper2(site, p, bt2) }
    end
            
    def self.add_block_type(site, p, bt)
      if !@render_functions.has_key?(bt.id)
        f = ''        
        if bt.use_render_function && bt.render_function
          f = bt.render_function          
        else
          full_name = bt.full_name
          full_name = "lksdjflskfjslkfjlskdfjlkjsdf" if full_name.nil? || full_name.length == 0
          if    File.file?(Rails.root.join("sites/#{site.name}/blocks/_#{full_name}.html.erb"     )) then f = Rails.root.join("sites/#{site.name}/blocks/_#{full_name}.html.erb")
          elsif File.file?(Rails.root.join("sites/#{site.name}/blocks/_#{bt.name}.html.erb"       )) then f = Rails.root.join("sites/#{site.name}/blocks/_#{bt.name}.html.erb")
          elsif File.file?(Rails.root.join("sites/#{site.name}/blocks/_#{bt.field_type}.html.erb" )) then f = Rails.root.join("sites/#{site.name}/blocks/_#{bt.field_type}.html.erb")
          elsif File.file?(Rails.root.join("app/views/caboose/blocks/_#{full_name}.html.erb"      )) then f = Rails.root.join("app/views/caboose/blocks/_#{full_name}.html.erb")
          elsif File.file?(Rails.root.join("app/views/caboose/blocks/_#{bt.name}.html.erb"        )) then f = Rails.root.join("app/views/caboose/blocks/_#{bt.name}.html.erb")
          elsif File.file?(Rails.root.join("app/views/caboose/blocks/_#{bt.field_type}.html.erb"  )) then f = Rails.root.join("app/views/caboose/blocks/_#{bt.field_type}.html.erb")
          elsif File.file?("#{Caboose.root}/app/views/caboose/blocks/_#{full_name}.html.erb"       ) then f = "#{Caboose.root}/app/views/caboose/blocks/_#{full_name}.html.erb"
          elsif File.file?("#{Caboose.root}/app/views/caboose/blocks/_#{bt.name}.html.erb"         ) then f = "#{Caboose.root}/app/views/caboose/blocks/_#{bt.name}.html.erb"
          elsif File.file?("#{Caboose.root}/app/views/caboose/blocks/_#{bt.field_type}.html.erb"   ) then f = "#{Caboose.root}/app/views/caboose/blocks/_#{bt.field_type}.html.erb"
          end
          f = File.read(f)
        end
        f.gsub!(/block\.partial\((.*?),(.*?)\)/ , 'render :partial => \1')
        f.gsub!(/block\.render\((.*?),(.*?)\)/  , 'render_block_type(block, \1, page, view, controller_view_content, modal, empty_text, editing, css, js, csrf_meta_tags, csrf_meta_tags2, logged_in_user, site)')        
        f.gsub!(/\=\s*render_block_type\(/      , 'render_block_type(')
        f.gsub!(/\=\s*raw render_block_type\(/  , 'render_block_type(')        
                
        #@render_functions[bt.id] = "<% def render_block_type_#{bt.id}(block, page, view, controller_view_content, modal, empty_text, editing, css, js, csrf_meta_tags, csrf_meta_tags2, logged_in_user, site) %>#{f}<% end %>"
          
        @render_functions[bt.id] = f
      end
      
      is_dup = false
      f = @render_functions[bt.id]
      @render_functions.each do |bt_id, f2|
        if f == f2 && @page_render_functions[p.id].include?(bt_id)
          @dups[bt_id] = [] if !@dups.has_key?(bt_id)
          @dups[bt_id] << bt.id if !@dups[bt_id].include?(bt.id)
          is_dup = true
          break
        end
      end
      
      if !is_dup        
        @page_render_functions[p.id] = [] if !@page_render_functions.has_key?(p.id)
        @page_render_functions[p.id] << bt.id if !@page_render_functions[p.id].include?(bt.id)
      end
    end
    
  end
end
