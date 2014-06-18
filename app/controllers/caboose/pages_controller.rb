
module Caboose
  class PagesController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri('/admin')
    end    

    # GET /pages/:id
    def show
      
      # Find the page with an exact URI match 
      page = Page.page_with_uri(request.fullpath, false)

      if (!page)
        asset
        return
      end

      user = logged_in_user            
      if !user.is_allowed(page, 'view')        
        if user.id == User::LOGGED_OUT_USER_ID	
          redirect_to "/modal/login?return_url=" + URI.encode(request.fullpath)		  		
          return
        else
          page.title = 'Access Denied'
          #page.content = "<p class='note error'>You do not have access to view this page.</p>"
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

      page = Page.page_with_uri(File.dirname(uri), false)
      if (page.nil? || !page)
        render :file => "caboose/extras/error404", :layout => "caboose/error404" 
        return
      end
        
      asset = Asset.where(:page_id => page.id, :filename => File.basename(uri)).first
      if (asset.nil?)
        render :file => "caboose/extras/error404", :layout => "caboose/error404"
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
    
    # GET /pages/1/redirect
    def redirect
      @page = Page.find(params[:id])
      redirect_to "/#{@page.uri}"
    end
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/pages
    def admin_index
      return if !user_is_allowed('pages', 'view')
      @home_page = Page.find(1)
      render :layout => 'caboose/admin'      
    end

    # GET /admin/pages/new
    def admin_new
      return unless user_is_allowed('pages', 'add')
      @parent_id = params[:parent_id] ? params[:parent_id] : 1
      @parent = Page.find(@parent_id)
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:id/edit
    def admin_edit_general
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:id/permissions
    def admin_edit_permissions
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
     
    # GET /admin/pages/:id/content
    def admin_edit_content
      return unless user_is_allowed('pages', 'edit')      
      @page = Page.find(params[:id])
      #if @page.top_level_blocks.nil? || @page.top_level_blocks.count == 0      
      #  redirect_to '/admin/page/:id/layout'
      #  return
      #end
      @editing = true
    end
    
    # GET /admin/pages/:id/layout
    def admin_edit_layout
      return unless user_is_allowed('pages', 'edit')      
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/pages/:id/layout
    def admin_update_layout
      return unless user_is_allowed('pages', 'edit')      
      bt = BlockType.find(params[:block_type_id])
      Block.create(:page_id => params[:id], :block_type_id => params[:block_type_id], :name => bt.name)
      resp = Caboose::StdClass.new({
        'redirect' => "/admin/pages/#{params[:id]}/content"
      })
      render :json => resp
    end
    
    # GET /admin/pages/:id/block-order
    def admin_edit_block_order
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/pages/:id/block-order
    def admin_update_block_order
      return unless user_is_allowed('pages', 'edit')
      block_ids = params[:block_ids]
      i = 0
      block_ids.each do |block_id|
        b = Block.find(block_id)
        b.sort_order = i
        b.save
        i = i + 1
      end      
      render :json => true
    end
    
    # GET /admin/pages/:id/new-blocks
    def admin_new_blocks
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end        
    
    # GET /admin/pages/:id/css
    def admin_edit_css
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:id/js
    def admin_edit_js
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:id/seo
    def admin_edit_seo
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:id/child-order
    def admin_edit_child_sort_order
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/pages/:id/child-order
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
    
    # POST /admin/pages
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
        render json: resp
        return
      end
      	
      parent = Caboose::Page.find(parent_id)
      		
      page = Caboose::Page.new
      page.title = title
      page.parent_id = parent_id      
      page.hide = true
      page.content_format = Caboose::Page::CONTENT_FORMAT_HTML

      i = 0
      begin 
        page.slug = Page.slug(page.title + (i > 0 ? " #{i}" : ""))
        page.uri = parent.parent_id == -1 ? page.slug : "#{parent.uri}/#{page.slug}"
        i = i+1
      end while (Page.where(:uri => page.uri).count > 0 && i < 10)

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
      resp.redirect = "/admin/pages/#{page.id}/edit"
      render json: resp
    end
    
    # PUT /admin/pages/:id
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

        when 'custom_css', 'custom_js'
          value.strip!
          page[name.to_sym] = value

        when 'title', 'menu_title', 'hide', 'layout', 'redirect_url',
          'seo_title', 'meta_description', 'fb_description', 'gp_description', 'canonical_url'
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
          if (value.include?('index') && value.include?('noindex'))
            resp.error = "You can't have both index and noindex"
            save = false
          elsif (value.include?('follow') && value.include?('nofollow'))
            resp.error = "You can't have both follow and nofollow"
            save = false
          else
            page.meta_robots = value.join(', ')
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
        end
      end
    
      resp.success = save && page.save
      render json: resp
    end
      
    # GET /admin/pages/:page_id/delete
    def admin_delete_form
      return unless user_is_allowed('pages', 'delete')
      @page = Page.find(params[:id])      
      render :layout => 'caboose/admin'      
    end
    
    # DELETE /admin/pages/1
    def admin_delete
      return unless user_is_allowed('pages', 'delete')
      p = Page.find(params[:id])
      p.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/pages'
      })
      render json: resp
    end
    
    # GET /admin/pages/:page_id/sitemap
    def admin_sitemap
      return unless user_is_allowed('pages', 'delete')
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # GET /admin/pages/sitemap-options
    def admin_sitemap_options
      parent_id = params[:parent_id]
      top_page = Page.index_page
      p = !parent_id.nil? ? Page.find(parent_id) : top_page
      options = []
      sitemap_helper(top_page, options)
     	  
      render json: options 		
    end

    def sitemap_helper(page, options, prefix = '')
      options << { 'value' => page.id, 'text' => prefix + page.title }
      page.children.each do |kid|
        sitemap_helper(kid, options, prefix + ' - ')
      end
    end

    # GET /admin/pages/robots-options
    def admin_robots_options
      options = [
        { 'value' => 'index'      , 'text' => 'index'     },
        { 'value' => 'noindex'    , 'text' => 'noindex'   },
        { 'value' => 'follow'     , 'text' => 'follow'    },
        { 'value' => 'nofollow'   , 'text' => 'nofollow'  },
        { 'value' => 'nosnippet'  , 'text' => 'nosnippet' },
        { 'value' => 'noodp'      , 'text' => 'noodp'     },
        { 'value' => 'noarchive'  , 'text' => 'noarchive' }
      ]
      render json: options 		
    end

    # GET /admin/pages/format-options
    def admin_content_format_options
      options = [
        { 'value' => 'html', 'text' => 'html' },
        { 'value' => 'text', 'text' => 'text' },
        { 'value' => 'ruby', 'text' => 'ruby' }
      ]
      render json: options 		
    end
    
    # GET /admin/pages/:id/uri
    def admin_page_uri
      return unless user_is_allowed('pages', 'view')
      p = Page.find(params[:id])
      render :json => { 'uri' => p.uri }
		end
		
  end
end
