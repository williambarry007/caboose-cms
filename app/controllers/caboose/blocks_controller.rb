require 'nokogiri'

module Caboose
  class BlocksController < ApplicationController
    
    helper :application
    before_filter :before_blocks_action
    
    def before_blocks_action
      @p = params[:page_id] ? Page.find(params[:page_id]) : Post.find(params[:post_id])
    end
    
    def page_or_post
      return params[:page_id] ? 'page' : 'post'
    end
          
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # @route GET /admin/pages/:page_id/blocks
    # @route GET /admin/posts/:post_id/blocks
    def admin_index
      return if !user_is_allowed("#{page_or_post}s", 'view')
      #h = params[:post_id] ? { :post_id => params[:post_id] } : { :page_id => params[:page_id] }
      #blocks = Block.where(h).reorder(:sort_order)
      #render :json => blocks
      render :json => @p.block      
    end

    # @route GET /admin/pages/:page_id/blocks/:id/new
    # @route GET /admin/pages/:page_id/blocks/new
    # @route GET /admin/posts/:post_id/blocks/:id/new
    # @route GET /admin/posts/:post_id/blocks/new
    def admin_new
      return unless user_is_allowed("#{page_or_post}s", 'add')

      if params[:id]
        block_type_id = params[:block_type_id]
        block_type_id = Block.find(params[:id]).block_type.default_child_block_type_id if block_type_id.nil?                 
        if block_type_id                                  
          b = Block.new
          if params[:page_id]
            b.page_id = params[:page_id].to_i
          else
            b.post_id = params[:post_id].to_i
          end
          b.parent_id = params[:id]
          b.block_type_id = block_type_id
          b.status = 'added'
          b.sort_order = Block.where(:parent_id => params[:id]).count              
          b.save
          b.create_children(status: 'added')
          if params[:page_id]
            redirect_to "/admin/pages/#{b.page_id}/blocks/#{b.id}/edit"
          else
            redirect_to "/admin/posts/#{b.post_id}/blocks/#{b.id}/edit"
          end
          return
        end
      end
    
      @page = Page.find(params[:page_id]) if params[:page_id]
      if @page
        @page.status = 'edited'
        @page.save
      end
      @post = Post.find(params[:post_id]) if params[:post_id] 
      if @post
        @post.status = 'edited'
        @post.save
      end     
      @block = params[:id] ? Block.find(params[:id]) : (params[:page_id] ? Block.new(:page_id => params[:page_id]) : Block.new(:post_id => params[:post_id]))
      @after_id = params[:after_id] ? params[:after_id] : nil
      @before_id = params[:before_id] ? params[:before_id] : nil
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/pages/:page_id/blocks/tree
    # @route GET /admin/pages/:page_id/blocks/:id/tree
    # @route GET /admin/posts/:post_id/blocks/tree
    # @route GET /admin/posts/:post_id/blocks/:id/tree    
    def admin_tree
      return unless user_is_allowed("#{page_or_post}s", 'edit')      
      blocks = []
      if params[:id]
        b = Block.find(params[:id])
        b.create_children(status: 'added') # if Caboose::Block.where(:parent_id => b.id).count == 0
        bt = b.block_type
        blocks << { 
          'id'                 => b.id,
          'parent_id'          => (b.new_parent_id.blank? ? b.parent_id : b.new_parent_id),
          'page_id'            => b.page_id,          
          'post_id'            => b.post_id,          
          'name'               => b.name,
          'value'              => (b.new_value.blank? ? b.value : (b.new_value == 'EMPTY' ? nil : b.new_value)),
          'constrain'          => b.constrain,
          'full_width'         => b.full_width,
          'block_type'         => bt,
          'children'           => admin_tree_helper(b,1),
          'crumbtrail'         => self.crumbtrail(b)          
          #'block_type_id'      => bt.id,           
          #'field_type'         => bt.field_type,
          #'allow_child_blocks' => bt.allow_child_blocks,
          #'use_js_for_modal'   => bt.use_js_for_modal,                              
        }
      else
        q = !params[:page_id].blank? ? ["parent_id is null and page_id = ?", params[:page_id]] : ["parent_id is null and post_id = ?", params[:post_id]] 
        Block.where(q).reorder(:new_sort_order).all.each do |b|
          bt = b.block_type
          blocks << { 
            'id'                 => b.id,
            'parent_id'          => (b.new_parent_id.blank? ? b.parent_id : b.new_parent_id),
            'page_id'            => b.page_id,            
            'post_id'            => b.post_id,                        
            'name'               => b.name, 
            'value'              => (b.new_value.blank? ? b.value : (b.new_value == 'EMPTY' ? nil : b.new_value)),
            'constrain'          => b.constrain,
            'full_width'         => b.full_width,
            'block_type'         => bt,
            'children'           => admin_tree_helper(b,1)            
            #'block_type_id'      => bt.id,
            #'field_type'         => bt.field_type,
            #'allow_child_blocks' => bt.allow_child_blocks,
            #'use_js_for_modal'   => bt.use_js_for_modal,                                    
          }
        end        
      end
      render :json => blocks
    end
    
    def crumbtrail(block)
      crumbs = []      
      b = block
      while b
        bt = b.block_type
        crumbs << {
          :block_id => b.id,
          :text => bt.description
        }        
        b = (b.new_parent_id.blank? ? b.parent : Caboose::Block.find(b.new_parent_id))
      end
      return crumbs.reverse
    end
      
    def admin_tree_helper(b,level)
      arr = []
      if level < 3
        sort_by_id = b.block_type.default_child_block_type_id.nil? ? true : false
        b.filtered_children(true,sort_by_id).each do |b2|
          bt = b2.block_type
          arr << {
            'id'                 => b2.id,
            'parent_id'          => (b2.new_parent_id.blank? ? b2.parent_id : b2.new_parent_id),
            'page_id'            => b2.page_id,
            'post_id'            => b2.post_id,
            'name'               => b2.name,
            'value'              => (b2.new_value.blank? ? b2.value : (b2.new_value == 'EMPTY' ? nil : b2.new_value)),
            'constrain'          => b2.constrain,
            'full_width'         => b2.full_width,
            'block_type'         => bt,
            'children'           => admin_tree_helper(b2,level+1)          
            #'block_type_id'      => bt.id,          
            #'field_type'         => bt.field_type,
            #'allow_child_blocks' => bt.allow_child_blocks,
            #'use_js_for_modal'   => bt.use_js_for_modal,          
          }
        end
      end
      return arr
    end     

    # @route PUT /admin/pages/:page_id/blocks/:id/remove-media
    # @route PUT /admin/posts/:post_id/blocks/:id/remove-media
    def admin_remove_media
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      resp = Caboose::StdClass.new   
      b = Block.find(params[:id])      
      b.new_media_id = 0
      b.image_file_name = nil
      b.image_file_size = nil
      b.image_content_type = nil
      b.image_updated_at = nil
      b.status = 'edited' if b.status == 'published'
      resp.success = b.save
      render :json => resp      
    end 
      
    # @route GET /admin/pages/:page_id/blocks/:id/render
    # @route GET /admin/posts/:post_id/blocks/:id/render
    def admin_render
      return unless user_is_allowed("#{page_or_post}s", 'edit')      
      b = Block.find(params[:id])      
      bt = b.block_type
      if bt.nil?
        bt = BlockType.where(:name => 'richtext').first 
        b.block_type_id = bt.id
        b.save
      end      
      html = b.render(b, {                
        :view => nil,
        :controller_view_content => nil,
        :modal => false,
        :editing => true,
        :empty_text => params[:empty_text],            
        :css => '|CABOOSE_CSS|',                     
        :js => '|CABOOSE_JAVASCRIPT|',
        :csrf_meta_tags => '|CABOOSE_CSRF|',
        :csrf_meta_tags2 => '|CABOOSE_CSRF|',    
        :logged_in_user => @logged_in_user,
        :site => @site,
        :page => params[:page_id] ? @p : nil,
        :post => params[:post_id] ? @p : nil,            
        :request => request,
        :is_new => (params[:is_new].blank? ? false : true)
      })
      render :inline => html
    end
          
    # @route GET /admin/pages/:page_id/blocks/render
    # @route GET /admin/posts/:post_id/blocks/render
    def admin_render_all
      return unless user_is_allowed("#{page_or_post}s", 'edit')            
      blocks = Block.where("#{page_or_post}_id = ? and parent_id is null", @p.id).reorder(:sort_order).collect do |b|        
        {
          :id => b.id,
          :block_type_id => b.block_type.id,
          :sort_order => b.sort_order,
          :html => b.render(b, {
            :view => nil,
            :controller_view_content => nil,
            :modal => false,
            :editing => true,
            :empty_text => params[:empty_text],            
            :css => '|CABOOSE_CSS|',                     
            :js => '|CABOOSE_JAVASCRIPT|',
            :csrf_meta_tags => '|CABOOSE_CSRF|',
            :csrf_meta_tags2 => '|CABOOSE_CSRF|',    
            :logged_in_user => @logged_in_user,
            :site => @site,
            :page => params[:page_id] ? @p : nil,
            :post => params[:post_id] ? @p : nil,            
            :request => request
          })        
        }
      end
      render :json => blocks
    end
    
    # @route GET /admin/pages/:page_id/blocks/render-second-level
    # @route GET /admin/posts/:post_id/blocks/render-second-level
    def admin_render_second_level
      return unless user_is_allowed("#{page_or_post}s", 'edit')      
      view = ActionView::Base.new(ActionController::Base.view_paths)      
      blocks = @p.block.filtered_children(true,true).collect do |b|
        {           
          :id => b.id,
          :block_type_id => b.block_type.id,
          :sort_order => b.sort_order,
          :html => b.render(b, {
            :view => nil,
            :controller_view_content => nil,
            :modal => false,
            :editing => true,
            :empty_text => params[:empty_text] ? params[:empy_text] : '[Empty, click to edit]',            
            :css => '|CABOOSE_CSS|',                     
            :js => '|CABOOSE_JAVASCRIPT|',
            :csrf_meta_tags => '|CABOOSE_CSRF|',
            :csrf_meta_tags2 => '|CABOOSE_CSRF|',    
            :logged_in_user => @logged_in_user,
            :site => @site,
            :page => params[:page_id] ? @p : nil,
            :post => params[:post_id] ? @p : nil,            
            :request => request,
            :params => params
          })
        }
      end
      render :json => blocks      
    end
    
    # @route GET /admin/pages/:page_id/blocks/:id/edit
    # @route GET /admin/posts/:post_id/blocks/:id/edit
    def admin_edit
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      @page = Page.find(params[:page_id]) if params[:page_id]
      @post = Post.find(params[:post_id]) if params[:post_id]
      @block = Block.find(params[:id])
      @block.create_children
      @modal = true

      @document_domain = request.host
      @document_domain.gsub('http://', '')
      @document_domain.gsub('https://', '')
            
      full_name = @block.block_type.full_name
      begin
        if full_name != 'image'  
          render "caboose/blocks/admin_edit_#{@block.block_type.full_name}", :layout => 'caboose/modal'
        else
          render :layout => 'caboose/modal'
        end
      rescue ActionView::MissingTemplate => ex        
        begin        
          render "caboose/blocks/admin_edit_#{@block.block_type.field_type}", :layout => 'caboose/modal'
        rescue ActionView::MissingTemplate => ex        
          render :layout => 'caboose/modal'          
        end
      end
    end
    
    # @route GET /admin/pages/:page_id/blocks/:id/advanced
    # @route GET /admin/posts/:post_id/blocks/:id/advanced
    def admin_edit_advanced
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      @page = Page.find(params[:page_id]) if params[:page_id]
      @post = Post.find(params[:post_id]) if params[:post_id]
      @block = Block.find(params[:id])
      @block.create_children      
      render :layout => 'caboose/modal'      
    end
    
    # @route GET /admin/pages/:page_id/blocks/:id
    # @route GET /admin/posts/:post_id/blocks/:id
    def admin_show
      return unless user_is_allowed("#{page_or_post}s", 'edit')      
      block = Block.find(params[:id])
      render :json => block      
    end
    
    # @route POST /admin/pages/:page_id/blocks
    # @route POST /admin/pages/:page_id/blocks/:id
    # @route POST /admin/posts/:post_id/blocks
    # @route POST /admin/posts/:post_id/blocks/:id
    def admin_create
      return unless user_is_allowed("#{page_or_post}s", 'edit')

      resp = Caboose::StdClass.new

      b = Block.new
      b.status = 'added'    
      if params[:page_id]
        b.page_id = params[:page_id].to_i
      else
        b.post_id = params[:post_id].to_i
      end
      b.parent_id = params[:id] ? params[:id] : nil
      b.block_type_id = params[:block_type_id]
                      
      if !params[:index].nil?      
        b.new_sort_order = params[:index].to_i
        
        i = 1
        b.parent.filtered_children(true).where('new_sort_order >= ?', b.new_sort_order).order('new_sort_order,id').all.each do |b3|
          b3.new_sort_order = b.new_sort_order + i
          b3.status = 'edited' if b3.status == 'published'
          b3.save
          i = i + 1                  
        end
        
      elsif params[:before_id] && !params[:before_id].blank?
        b2 = Block.find(params[:before_id].to_i)
        b.new_sort_order = b2.new_sort_order
        
        i = 1
        b2.parent.filtered_children(true).where('new_sort_order >= ?', b.new_sort_order).order('new_sort_order,id').all.each do |b3|
          b3.new_sort_order = b.new_sort_order + i
          b3.status = 'edited' if b3.status == 'published'
          b3.save
          i = i + 1                  
        end
      
      elsif params[:after_id] && !params[:after_id].blank?
        b2 = Block.find(params[:after_id].to_i)
        b.new_sort_order = b2.new_sort_order + 1

        i = 1
        b2.parent.filtered_children(true).where('new_sort_order >= ?', b.new_sort_order).order('new_sort_order,id').all.each do |b3|
          b3.new_sort_order = b.new_sort_order + i
          b3.status = 'edited' if b3.status == 'published'
          b3.save
          i = i + 1                  
        end
        
      elsif params[:id]
        b.new_sort_order = Block.where(:name => nil).where("(new_parent_id is null and parent_id = ? and status != ?) OR (new_parent_id = ? and status != ?)",params[:id],'deleted',params[:id],'deleted').count        
      end                  
      
      # Save the block
      b.save

      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end

      if !b.block_type.default.blank?
        b.value = b.block_type.default
        b.save
      end
      
      # Ensure that all the children are created for the block
      b.create_children(status: 'added')

      # Default child block count
      if !params[:child_count].blank? && params[:child_count].to_i > 0
        (1..params[:child_count].to_i).each_with_index do |cc, ind|
          b1 = Block.new
          if params[:page_id]
            b1.page_id = params[:page_id].to_i
          else
            b1.post_id = params[:post_id].to_i
          end
          b1.parent_id = b.id
          b1.sort_order = ind
          b1.new_sort_order = ind
     #     b1.new_parent_id = b.id
          b1.status = 'added'
          b1.block_type_id = b.block_type.default_child_block_type_id
          b1.save
          b1.create_children(status: 'added')
          bw = b1.child('width')
          if bw
            bw.value = 'auto' # (100.0 / params[:child_count].to_f).to_i.to_s + '%'
            bw.save
          end
        end
      end

      # Set the global values if necessary
      if b.block_type.is_global        
        b.get_global_value(@site.id)
      end

      # Send back the response
      #resp.block = b
      resp.success = true
      resp.new_id = b.id
      resp.parent_id = b.parent_id
      resp.redirect = params[:page_id] ? "/admin/pages/#{b.page_id}/blocks/#{b.id}" : "/admin/posts/#{b.post_id}/blocks/#{b.id}"              
      render :json => resp
    end
    
    # @route PUT /admin/pages/:page_id/blocks/:id
    # @route PUT /admin/posts/:post_id/blocks/:id
    def admin_update
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      b = Block.find(params[:id])

      save = true
      params.each do |k,v|
        case k
          #when 'page_id'       then b.page_id       = v
          when 'parent_id'     then 
            b.parent_id  = v
            b.new_sort_order = Block.where("(parent_id = ? and status = ?) or (new_parent_id = ? and (status = ? or status = ?))",v,'published',v,'edited','added').count
            b.status = 'edited' if b.status == 'published'
          when 'block_type_id' then b.block_type_id = v
          when 'sort_order'    then 
            b.new_sort_order    = v
            b.status = 'edited' if b.status == 'published'
          when 'constrain'     then b.constrain     = v
          when 'full_width'    then b.full_width    = v
          when 'media_id'      then 
            b.new_media_id      = v
            b.status = 'edited' if b.status == 'published'
          when 'name'          then b.name          = v
          when 'value'         then
            
            if b.block_type.is_global
              if b.block_type.field_type == 'checkbox_multiple'
                b.value = Block.parse_checkbox_multiple_value(b, v)
              else                    
                b.value = v
              end                
              b.update_global_value(b.value, @site.id)              
            else              
              if Caboose::parse_richtext_blocks == true && b.block_type.field_type == 'richtext' && (b.name.nil? || b.name.strip.length == 0) && (b.block_type.name != 'richtext2')                
                b = RichTextBlockParser.parse(b, v, request.host_with_port)
              else
                if b.block_type.field_type == 'checkbox_multiple'
                  pv = Block.parse_checkbox_multiple_value(b, v)
                  b.new_value = (pv.blank? ? 'EMPTY' : pv)
                  b.status = 'edited' if b.status == 'published'
                else                    
                  b.new_value = (v.blank? ? 'EMPTY' : v)
                  b.status = 'edited' if b.status == 'published'
                end
              end
            end
        end
      end

      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end
                
      resp.success = save && b.save
      b.create_children(status: 'added')
      render :json => resp      
    end

    # @route PUT /admin/pages/:page_id/blocks/:id/value
    # @route PUT /admin/posts/:post_id/blocks/:id/value
    def admin_update_value
      return unless user_is_allowed('pages', 'edit')
      resp = StdClass.new({'attributes' => {}})
      b = Block.find(params[:id])
      # if b.block_type_id == 309 # Richtext
      b.new_value = params[:value]
      b.status = 'edited' if b.status == 'published'
      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end

      # elsif b.block_type_id == 1 # Heading
      #   b1 = b.child('heading_text')
      #   b1.value = params[:value]
      #   b1.save
      # end
      resp.success = b.save
      render :json => resp
    end
    
    # @route POST /admin/pages/:page_id/blocks/:id/image
    # @route POST /admin/posts/:post_id/blocks/:id/image
    def admin_update_image
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      b = Block.find(params[:id])
      b.image = params[:value]
      
      str = params[:value].original_filename
      arr = str.split('.')
      arr.pop
      str = arr.join('.')      
      b.image_upload_name = b.unique_image_upload_name(str)      
      
      b.save
      resp.success = true 
      resp.attributes = { 'value' => { 'value' => b.image.url(:tiny) }}
      
      render :json => resp
    end
    
    # @route POST /admin/pages/:page_id/blocks/:id/file
    # @route POST /admin/posts/:post_id/blocks/:id/file
    def admin_update_file
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      b = Block.find(params[:id])
      b.file = params[:value]
      
      str = params[:value].original_filename
      arr = str.split('.')
      arr.pop
      str = arr.join('.')      
      b.file_upload_name = b.unique_file_upload_name(str)
      
      b.save
      resp.success = true      
      resp.attributes = { 'value' => { 'value' => b.file.url }}
      
      render :json => resp
    end
    
    # @route DELETE /admin/pages/:page_id/blocks/:id
    # @route DELETE /admin/posts/:post_id/blocks/:id
    def admin_delete
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new
      b = Block.find(params[:id])
    #  sibs = b.siblings
      parent_id = b.new_parent_id.blank? ? b.parent_id : b.new_parent_id
      if b.parent_id
        if params[:page_id]
          resp.redirect = "/admin/pages/#{b.page_id}/blocks/#{b.parent_id}/edit"
        else
          resp.redirect = "/admin/posts/#{b.post_id}/blocks/#{b.parent_id}/edit"
        end        
      else
        resp.close = true
      end

      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end


      child_ids = b.filtered_children(true).pluck(:id)
      cids = child_ids.blank? ? 0 : child_ids

      
      bid1 = Block.where("id = ? or id in (?)",b.id,cids).where('status = ? or status = ?','edited','published')
      # Caboose.log("marking as deleted: #{bid1.pluck(:id)}")
      bid1.update_all(:status => 'deleted')
      bid2 = Block.where("id = ? or id in (?)",b.id,cids).where(:status => 'added')
      bid2.destroy_all
      # Caboose.log("destroying: #{bid2.pluck(:id)}")

      
      if parent_id
        # Caboose.log("reorganizing blocks under #{parent_id}")
        # i = 0
        # Block.where(:parent_id => parent_id).where('status != ?', 'deleted').order(:new_sort_order).all.each do |b2|
        #   b2.new_sort_order = i
        #   b2.status = 'edited' if b2.status == 'published'
        #   b2.save
        #   i = i + 1
        # end
        sibs = Caboose::Block.where(:name => nil).where("(new_parent_id is null and parent_id = ? and status != ?) OR (new_parent_id = ? and status != ?)",parent_id,'deleted',parent_id,'deleted').order(:new_sort_order, :id).all
        sibs.each_with_index do |b2, i|      
          b2.new_sort_order = i
          b2.status = 'edited' if b2.status == 'published'
          b2.save
        end  

      end

      render :json => resp
    end

    # @route PUT /admin/pages/:page_id/blocks/:id/duplicate
    # @route PUT /admin/posts/:post_id/blocks/:id/duplicate
    def admin_duplicate
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      resp = StdClass.new
      b = Block.find(params[:id])
      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end
      resp.new_id = b.duplicate_block(@site.id, params[:page_id], params[:post_id], b.block_type_id, (b.new_parent_id.blank? ? b.parent_id : b.new_parent_id))
      resp.success = true
      render :json => resp
    end

    # @route GET /admin/pages/:page_id/blocks/:id/new-child-blocks
    # @route GET /admin/posts/:post_id/blocks/:id/new-child-blocks
    # def admin_new_child_blocks
    #   return unless user_is_allowed('pages', 'edit')
    #   resp = StdClass.new
    #   resp.blocks = []

    #   Block.where(:new_parent_id => params[:id]).all.each do |b|
    #     resp.blocks << b
    #   end

    #   render :json => resp
    # end

    # @route GET /admin/pages/:page_id/blocks/:id/api-info
    # @route GET /admin/posts/:post_id/blocks/:id/api-info
    def admin_block_info
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      resp = StdClass.new
      b = Block.find(params[:id])
      bt = b.block_type if b
      resp.block_name = b.name
      resp.bt_name = bt.name
      resp.use_js_for_modal = bt.use_js_for_modal
      resp.field_type = bt.field_type
      render :json => resp
    end

    # @route GET /admin/pages/:page_id/blocks/:id/parent-block
    # @route GET /admin/posts/:post_id/blocks/:id/parent-block
    def admin_parent_block
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      resp = StdClass.new
      b = Block.find(params[:id])
      par = Block.where("name is null or name like '%column%'").where(:id => (b.new_parent_id.blank? ? b.parent_id : b.new_parent_id)).first
      resp.parent_id = par ? par.id : nil
      gp = par ? Block.where("name is null or name like '%column%'").where(:id => (par.new_parent_id.blank? ? par.parent_id : par.new_parent_id)).first : nil
      resp.grandparent_id = gp ? gp.id : nil
      render :json => resp
    end

    # @route POST /admin/pages/:page_id/blocks/:id/move
    # @route POST /admin/posts/:post_id/blocks/:id/move
    def admin_move
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      resp = StdClass.new
      b = Block.find(params[:id])
      if !params[:before_id].blank?
        b2 = Block.find(params[:before_id].to_i)
        b.new_sort_order = (b2.new_sort_order.blank? ? b2.sort_order : b2.new_sort_order)
        i = 1
        sibs = b2.siblings(b.new_sort_order)
    #    Caboose.log("updating #{sibs.count} siblings")
        sibs.each do |b3|
          b3.new_sort_order = b.new_sort_order + i
          b3.status = 'edited' if b3.status == 'published'
          b3.save
          i = i + 1                  
        end
      elsif !params[:after_id].blank?
        b2 = Block.find(params[:after_id].to_i)
        b.new_sort_order = (b2.new_sort_order.blank? ? (b2.sort_order + 1) : (b2.new_sort_order + 1))
        i = 1
        sibs = b2.siblings(b.new_sort_order)
     #   Caboose.log("updating #{sibs.count} siblings")
        sibs.each do |b3|
          b3.new_sort_order = b.new_sort_order + i
          b3.status = 'edited' if b3.status == 'published'
          b3.save
          i = i + 1
        end
      elsif params[:parent_id]
        b.new_sort_order = b.siblings.count        
      end
      b.new_parent_id = params[:parent_id]  # if params[:parent_id] != b.parent_id.to_s
      b.status = 'edited' if b.status == 'published'
      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end
      resp.success = true
      b.save
      render :json => resp
    end
    
    # @route PUT /admin/pages/:page_id/blocks/:id/move-up
    # @route PUT /admin/posts/:post_id/blocks/:id/move-up
    def admin_move_up
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new
      b = Block.find(params[:id])
      changed = b.move_up
      if !changed
        resp.error = "The block is already at the top."
      else
        resp.success = "The block has been moved up successfully."
      end
      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end
      render :json => resp
    end
    
    # @route PUT /admin/pages/:page_id/blocks/:id/move-down
    # @route PUT /admin/posts/:post_id/blocks/:id/move-down
    def admin_move_down
      return unless user_is_allowed("#{page_or_post}s", 'edit')
      
      resp = StdClass.new
      b = Block.find(params[:id])
      changed = b.move_down
      if !changed
        resp.error = "The block is already at the bottom."
      else
        resp.success = "The block has been moved down successfully."
      end
      # if b.page
      #   b.page.status = 'edited'
      #   b.page.save
      # elsif b.post
      #   b.post.status = 'edited'
      #   b.post.save
      # end

      render :json => resp
    end
		
  end
end
