
module Caboose
  class PagesController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')      
    end
    
    # @route GET /pages/:id/redirect
    def redirect
      @page = Page.find(params[:id])
      redirect_to "/#{@page.uri}"
    end

    # @route GET /pages/:id
    def show
      
      # Find the page with an exact URI match 
      page = Page.page_with_uri(request.host_with_port, request.fullpath, false)
      
      # Make sure we're not under construction or on a forwarded domain
      d = Caboose::Domain.where(:domain => request.host_with_port).first
      if d.nil?
        Caboose.log("Could not find domain for #{request.host_with_port}\nAdd this domain to the caboose site.")
      elsif d.under_construction == true
        if d.site.under_construction_html && d.site.under_construction_html.strip.length > 0 
          render :text => d.site.under_construction_html
        else 
          render :file => 'caboose/application/under_construction', :layout => false
        end
        return
      # See if we're on a forwarding domain
      elsif d.primary == false && d.forward_to_primary == true
        pd = d.site.primary_domain
        if pd && pd.domain != request.host
          url = "#{request.protocol}#{pd.domain}"
          if d.forward_to_uri && d.forward_to_uri.strip.length > 0
            url << d.forward_to_uri
          elsif request.fullpath && request.fullpath.strip.length > 0 && request.fullpath.strip != '/'
            url << request.fullpath
          end
          redirect_to url
          return
        end
      elsif d.primary == false && !d.forward_to_uri.blank? && request.fullpath == '/'
        url = "#{request.protocol}#{d.domain}#{d.forward_to_uri}"
        redirect_to url
        return
      end
      
      if !page
        asset
        return
      end

      user = logged_in_user      
      if !user.is_allowed(page, 'view')                
        if user.id == User.logged_out_user_id(@site.id)
          redirect_to "/modal/login?return_url=" + URI.encode(request.fullpath)		  		
          return
        else
          # go to 404 page
          render :file => "caboose/extras/error404", :layout => "caboose/application", :formats => [:html]
        end
      end

      if session['use_redirect_urls'] && !page.redirect_url.nil? && page.redirect_url.strip.length > 0
        redirect_to page.redirect_url
        return
      end

      page = Caboose.plugin_hook('page_content', page)      
      @page = page
      @user = user
      @editmode = !params['edit'].nil? && user.is_allowed('pages', 'edit') ? true : false
      @crumb_trail = Caboose::Page.crumb_trail(@page)
      @subnav = Caboose::Page.subnav(@page, session['use_redirect_urls'], @user)

      #@subnav.links = @tasks.collect {|href, task| {'href' => href, 'text' => task, 'is_current' => uri == href}}
  
    end
    
    def asset   
      uri = uri.to_s.gsub(/^(.*?)\?.*?$/, '\1')
      uri.chop! if uri.end_with?('/')
      uri[0] = '' if uri.starts_with?('/')

      page = Page.page_with_uri(request.host_with_port, File.dirname(uri), false)      
      if page.nil? || !page
        
        # Check for a 301 redirect
        site_id = Site.id_for_domain(request.host_with_port)        
        new_url = PermanentRedirect.match(site_id, request.fullpath)        
        if new_url          
          redirect_to new_url, :status => 301
          return
        end
        
        respond_to do |format|          
          format.all { render :file => "caboose/extras/error404", :layout => "caboose/application", :formats => [:html] }
        end         
        return
      end
        
      asset = Asset.where(:page_id => page.id, :filename => File.basename(uri)).first
      if (asset.nil?)
        respond_to do |format|          
          format.all { render :file => "caboose/extras/error404", :layout => "caboose/application", :formats => [:html] }
        end
        return
      end

      user = logged_in_user
      if (!Page.is_allowed(user, asset.page_id, 'view'))
        render "caboose/pages/asset_no_permission"
        return
      end

      #Caboose.log(Caboose::assets_path, 'Caboose::assets_path')
      path = Caboose::assets_path.join("#{asset.id}.#{asset.extension}")
      #Caboose.log("Sending asset #{path}")
      #send_file(path)
      #send_file(path, :filename => "your_document.pdf", :type => "application/pdf")

      #
      #$path = ASSETS_PATH ."/". $asset->id .".". $asset->extension
      #		
      #$finfo = finfo_open(FILEINFO_MIME_TYPE) // return mime type ala mimetype extension
      #$mime = finfo_file($finfo, $path)
      #finfo_close($finfo)
      #
      #header("X-Sendfile: $path")
      #header("Content-Type: $mime")
      #header("Content-Disposition: inline filename=\"$asset->filename\"")

    end
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # @route GET /admin/pages
    def admin_index
      return if !user_is_allowed('pages', 'view')            
      @user = @logged_in_user
      @domain = Domain.where(:domain => request.host_with_port).first
      @home_page = @domain ? Page.index_page(@domain.site_id) : nil
      if @domain && @home_page.nil?
        @home_page = Caboose::Page.create(:site_id => @domain.site_id, :parent_id => -1, :title => 'Home')
      end
      render :layout => 'caboose/admin'      
    end

    # @route GET /admin/pages/new
    def admin_new
      return unless user_is_allowed('pages', 'add')
      @parent_id = params[:parent_id] ? params[:parent_id] : Page.where(:site_id => @site.id, :parent_id => -1).first.id
      @parent = Page.find(@parent_id)
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/pages/:id/custom-fields
    def admin_edit_custom_fields
      return if !user_is_allowed('pages', 'edit')    
      @page = Page.find(params[:id])
      @page.verify_custom_field_values_exist
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/pages/:id/permissions
    def admin_edit_permissions
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route PUT /admin/pages/:id/update-child-permissions
    def admin_update_child_permissions
      return unless user_is_allowed('pages', 'edit')      
      page = Page.find(params[:id])
      if page
        Page.update_child_perms(page.id)
      end 
      render :json => { :success => true }
    end
               
    # @route GET /admin/pages/:id/content
    def admin_edit_content
      @page = Page.find(params[:id])
      redirect_to "/login?return_url=/admin/pages/#{@page.id}/content" and return if @logged_in_user.nil?
      condition = @logged_in_user && (@logged_in_user.is_super_admin? || (@logged_in_user.site_id == @page.site_id && ( @logged_in_user.is_allowed('all','all') || @logged_in_user.is_allowed('pages','edit') && Page.permissible_actions(@logged_in_user, @page.id).include?('edit'))))
      redirect_to "/admin/pages" and return unless condition
      if @page.block.nil?
        redirect_to "/admin/pages/#{@page.id}/layout"
        return
      end
      @editing = true
    end
    
    # @route GET /admin/pages/:id/layout
    def admin_edit_layout
      return unless user_is_allowed('pages', 'edit')      
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end

    # @route PUT /admin/pages/:id/show
    def admin_show_page
      return unless user_is_allowed('pages', 'edit')  
      resp = StdClass.new({'attributes' => {}})    
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        @page.hide = false
        @page.save
        resp.success = true
      end
      render :json => resp
    end

    # @route PUT /admin/pages/:id/hide
    def admin_hide_page
      return unless user_is_allowed('pages', 'edit')  
      resp = StdClass.new({'attributes' => {}})    
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        @page.hide = true
        @page.save
        resp.success = true
      end
      render :json => resp
    end
    
    # @route PUT /admin/pages/:id/layout
    def admin_update_layout
      return unless user_is_allowed('pages', 'edit')      
      bt = BlockType.find(params[:block_type_id])
      old_block = Block.where(:page_id => params[:id], :parent_id => nil).first
      old_block_ids = Block.where(:page_id => params[:id]).pluq(:id)
      new_block = Block.create(:page_id => params[:id], :block_type_id => params[:block_type_id], :name => bt.name)
      new_block.create_children
      saved_blocks = []
      if new_block && old_block && new_block.child('content') && old_block.child('content')
        old_content = old_block.child('content')
        new_content = new_block.child('content')
        old_content.children.each do |child|
          child.parent_id = new_content.id
          child.save
          saved_blocks << child.id
          child.children.each do |c1|
            saved_blocks << c1.id
            c1.children.each do |c2|
              saved_blocks << c2.id
              c2.children.each do |c3|
                saved_blocks << c3.id
              end
            end
          end
        end
      end
      where1 = saved_blocks.count > 0 ? "id NOT IN (#{saved_blocks.to_s.gsub('[','').gsub(']','')})" : ''
      Block.where(:id => old_block_ids).where(where1).destroy_all
      resp = Caboose::StdClass.new({
        'redirect' => "/admin/pages/#{params[:id]}/content"
      })
      render :json => resp
    end
    
    # @route GET /admin/pages/:id/block-order
    def admin_edit_block_order
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route PUT /admin/pages/:id/block-order
    def admin_update_block_order
      return unless user_is_allowed('pages', 'edit')
      block_ids = params[:block_ids]      
      i = 0
      block_ids.each do |block_id|
        Block.find(block_id).update_attribute(:sort_order, i)        
        i = i + 1
      end      
      render :json => true
    end
    
    # @route GET /admin/pages/:id/new-blocks
    def admin_new_blocks
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end        
    
    # @route GET /admin/pages/:id/css
    def admin_edit_css
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route GET /admin/pages/:id/js
    def admin_edit_js
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route GET /admin/pages/:id/seo
    def admin_edit_seo
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route GET /admin/pages/:id/child-order
    def admin_edit_child_sort_order
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route PUT /admin/pages/:id/child-order
    def admin_update_child_sort_order
      return unless user_is_allowed('pages', 'edit')      
      @page = Page.find(params[:id])
      page_ids = params[:page_ids]
      i = 0
      page_ids.each do |pid|
        p = Page.find(pid)
        p.sort_order = i
        p.save
        i = i + 1
      end
      render :json => true
    end
    
    # @route GET /admin/pages/:id/duplicate
    def admin_duplicate_form
      return unless user_is_allowed('pages', 'add')
      @page = Page.find(params[:id])      
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end   
    end
    
    # @route POST /admin/pages/:id/duplicate
    def admin_duplicate
      return unless user_is_allowed('pages', 'add')
      
      resp = Caboose::StdClass.new
      
      p = Page.where(:id => params[:id]).first      
      site_id              = params[:site_id]
      parent_id            = params[:parent_id]
      block_type_id        = params[:block_type_id]
      child_block_type_id  = params[:child_block_type_id]
      duplicate_children   = params[:duplicate_children] == 'true' ? true : false
      
      if p.nil?            then resp.error = "Invalid page"
      elsif site_id.nil?   then resp.error = "Invalid site"
      elsif parent_id.nil? then resp.error = "Invalid parent"
      else
        resp.new_id = p.delay(:priority => 20).duplicate(site_id, parent_id, duplicate_children, block_type_id, child_block_type_id)
        resp.success = true
      end
      
      render :json => resp
    end
      
    # @route GET /admin/pages/:id/delete
    def admin_delete_form
      return unless user_is_allowed('pages', 'delete')
      @page = Page.find(params[:id])      
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end   
    end
    
    # @route GET /admin/pages/:id/uri
    def admin_page_uri
      return unless user_is_allowed('pages', 'view')
      p = Page.find(params[:id])
      render :json => { 'uri' => p.uri }
		end
    
    # @route GET /admin/pages/:id/sitemap
    def admin_sitemap
      return unless user_is_allowed('pages', 'delete')
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end

    # @route GET /admin/pages/:id
    def admin_edit_general
      return if !user_is_allowed('pages', 'edit')
      #return if !Page.is_allowed(logged_in_user, params[:id], 'edit')            
      @page = Page.find(params[:id])
      if @page.site_id != @logged_in_user.site_id && !@logged_in_user.is_super_admin?
        redirect_to '/admin/pages'
      else
        render :layout => 'caboose/admin'
      end
    end
    
    # @route POST /admin/pages
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
            
      parent_id = params[:parent_id]
      title = params[:title]      

      if (title.strip.length == 0)
        resp.error = "A page title is required."
      elsif (!logged_in_user.is_allowed('all', 'all') && 
        !Page.page_ids_with_permission(logged_in_user, 'edit'   ).include?(parent_id) &&
        !Page.page_ids_with_permission(logged_in_user, 'approve').include?(parent_id))
        resp.error = "You don't have permission to add a page there."
      end
      if (!resp.error.nil?)
        render :json => resp
        return
      end
      	
      parent = Caboose::Page.find(parent_id)                  		
      page = Caboose::Page.new      
      
      if parent.nil?
        d = Domain.where(:domain => request.host_with_port).first.site_id
        page.site_id = d.site_id
      else      
        page.site_id = parent.site_id
      end
      
      page.title = title
      page.parent_id = parent_id      
      page.hide = true
      page.content_format = Caboose::Page::CONTENT_FORMAT_HTML
      page.save

      i = 0
      begin 
        page.slug = Page.slug(page.title + (i > 0 ? " #{i}" : ""))
        page.uri = parent.parent_id == -1 ? page.slug : "#{parent.uri}/#{page.slug}"
        i = i+1
      end while (Page.where(:uri => page.uri, :site_id => page.site_id).count > 0 && i < 10)

      page.save
      
      # Create the top level block for the page
      bt = BlockType.find(params[:block_type_id])
      Block.create(:page_id => page.id, :block_type_id => params[:block_type_id], :name => bt.name)
      
      # Set the new page's permissions		  
      viewers = Caboose::PagePermission.where({ :page_id => parent.id, :action => 'view' }).pluck(:role_id)
      editors = Caboose::PagePermission.where({ :page_id => parent.id, :action => 'edit' }).pluck(:role_id)
      Caboose::Page.update_authorized_for_action(page.id, 'view', viewers)
      Caboose::Page.update_authorized_for_action(page.id, 'edit', editors)

      # Send back the response
      resp.redirect = "/admin/pages/#{page.id}"
      render json: resp
    end
    
    # @route PUT /admin/pages/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      page = Page.find(params[:id])
      
      save = true
      user = logged_in_user
      params.each do |name, value|
        case name
        when 'parent_id'
          value = value.to_i
          if page.id == value
            resp.error = "The page's parent cannot be itself."
          elsif Page.is_child(page.id, value)
            resp.error = "You can't set the current page's parent to be one of its child pages."
          elsif value != page.parent_id
            p = Page.find(value)
            if !user.is_allowed(p, 'edit')
              resp.error = "You don't have access to put the current page there."
            end
          end	
          if resp.error
            save = false
          else
            page.parent = Page.find(value)
            page.save
            Page.update_uri(page)
            resp.attributes['parent_id'] = { 'text' => page.parent.title }
          end

        when 'custom_css', 'custom_css_files', 'custom_js', 'custom_js_files'
          value.strip!
          page[name.to_sym] = value

        when 'title', 'menu_title', 'hide', 'layout', 'redirect_url',
          'seo_title', 'meta_keywords', 'meta_description', 'fb_description', 'gp_description', 'canonical_url'
          page[name.to_sym] = value

        when 'linked_resources'
          result = []
          value.each_line do |line|
            line.chomp!
            line.strip!
            next if line.empty?

            if !(line.ends_with('.js') || line.ends_with('.css'))
              resp.error = "Resource '#{line}' has an unsupported file type ('#{comps.last}')."
              save = false
            end

            result << line
          end
          page.linked_resources = result.join("\n")
          
        when 'content_format'
          page.content_format = value
          resp.attributes['content_format'] = { 'text' => value }
          
        when 'meta_robots'
          arr = value.split(',').collect { |v| v.strip }
          if arr.include?('index') && arr.include?('noindex')
            resp.error = "You can't have both index and noindex"
            save = false
          elsif arr.include?('follow') && arr.include?('nofollow')
            resp.error = "You can't have both follow and nofollow"
            save = false
          else            
            page.meta_robots = arr.join(', ')
            resp.attributes['meta_robots'] = { 'text' => page.meta_robots }
          end
          
        when 'content'
          page.content = value.strip.gsub(/<meta.*?>/, '').gsub(/<link.*?>/, '').gsub(/\<\!--[\S\s]*?--\>/, '')
          
        when 'slug' 
          page.slug = Page.slug(value.strip.length > 0 ? value : page.title)
          page.save
          Page.update_uri(page)                      
          resp.attributes['slug'] = { 'value' => page.slug }
          resp.attributes['uri'] = { 'value' => page.uri }
          
        when 'alias'
          page.alias = Page.slug(value.strip)
          page.save
          Page.update_uri(page)
          resp.attributes['slug'] = { 'value' => page.slug }
          resp.attributes['uri'] = { 'value' => page.uri }

        when 'custom_sort_children'
          if (value == 0)
            page.children.each do |p|
              p.sort_order = 1
              p.save
            end
          end
          page.custom_sort_children = value 		  

        when 'viewers'
          Page.update_authorized_for_action(page.id, 'view', value)
        when 'editors'
          Page.update_authorized_for_action(page.id, 'edit', value)
        when 'approvers'
          Page.update_authorized_for_action(page.id, 'approve', value)
        when 'tags'
          current_tags = page.page_tags.collect{ |t| t.tag }
          new_tags = value.split(',').collect{ |v| v.strip.downcase }.reject{ |t| t.nil? || t.strip.length == 0 }          
          
          # Delete the tags not in new_tags
          current_tags.each{ |t| PageTag.where(:page_id => page.id, :tag => t).destroy_all if !new_tags.include?(t) }
          
          # Add any new tags not in current_tags
          new_tags.each{ |t| PageTag.create(:page_id => page.id, :tag => t) if !current_tags.include?(t) }        
        end
        
      end
    
      resp.success = save && page.save
      render json: resp
    end
    
    # @route DELETE /admin/pages/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')
      p = Page.find(params[:id])
      p.destroy
      resp = StdClass.new({
        'redirect' => '/admin/pages'
      })
      render json: resp
    end
        
    # @route_priority 1
    # @route GET /admin/pages/:field-options    
    # @route GET /admin/pages/:id/:field-options    
    def admin_options
      if !user_is_allowed('pages', 'edit')
        render :json => false
        return
      end
      
      case params[:field]
        when nil
        
        when 'sitemap'
          parent_id = params[:parent_id]
          p = nil
          if params[:site_id] && logged_in_user.is_super_admin? 
            p = parent_id ? Page.find(parent_id) : Page.index_page(params[:site_id].to_i)
          else
            p = parent_id ? Page.find(parent_id) : Page.index_page(@site.id)
          end
          options = []
          if p
            sitemap_helper(p, options)
     	    end
     	  when 'robots'
     	    options = [
            { 'value' => 'index'      , 'text' => 'index'     },
            { 'value' => 'noindex'    , 'text' => 'noindex'   },
            { 'value' => 'follow'     , 'text' => 'follow'    },
            { 'value' => 'nofollow'   , 'text' => 'nofollow'  },
            { 'value' => 'nosnippet'  , 'text' => 'nosnippet' },
            { 'value' => 'noodp'      , 'text' => 'noodp'     },
            { 'value' => 'noarchive'  , 'text' => 'noarchive' }
          ]
        when 'format'
          options = [
            { 'value' => 'html', 'text' => 'html' },
            { 'value' => 'text', 'text' => 'text' },
            { 'value' => 'ruby', 'text' => 'ruby' }
          ]
        when 'block'
          options = []
          Block.where("parent_id is null and page_id = ?", params[:id]).reorder(:sort_order).all.each do |b|
            admin_block_options_helper(options, b, "") 
          end
        when 'parentblock'
          options = []
          this_block = Block.find(params[:block_id])
          Block.where("parent_id is null and page_id = ?", params[:id]).reorder(:sort_order).all.each do |b|
            admin_parent_block_options_helper(options, b, "", this_block) 
          end
      end              
      render :json => options 		
    end

    def sitemap_helper(page, options, prefix = '')
      options << { 'value' => page.id, 'text' => prefix + page.title }
      page.children.each do |kid|
        sitemap_helper(kid, options, prefix + ' - ')
      end
    end
      
    def admin_block_options_helper(options, b, prefix)
      options << { 'value' => b.id, 'text' => "#{prefix}#{b.title}" }      
      b.children.each do |b2|
        admin_block_options_helper(options, b2, "#{prefix} - ")        
      end      
    end

    def admin_parent_block_options_helper(options, b, prefix, this_block)
      if b.block_type.allow_child_blocks && (b.block_type.default_child_block_type_id.blank? || b.block_type.default_child_block_type_id == this_block.block_type_id)
        options << { 'value' => b.id, 'text' => "#{prefix}#{b.title}" }
      end      
      b.children.each do |b2|
        admin_parent_block_options_helper(options, b2, "#{prefix} - ", this_block)        
      end
    end
		
  end
end
