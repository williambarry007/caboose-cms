module Caboose
  class PostsController < ApplicationController
    
    helper :application
     
    # GET /posts
    def index
    	@posts = Post.where(:published => true).limit(5).order('created_at DESC')
    end
    
    ## GET /posts/:id
    #def detail
    #	@post = Post.find_by_id(params[:id])
    #	unless @post.present?
    #		flash[:notice] = 'The posts post you tried to access does not exist.'
    #		redirect_to action: :index
    #	end
    #end
    
    # GET /posts/:id
    # GET /posts/:year/:month/:day/:slug
    def show
      
      # Make sure we're not under construction or on a forwarded domain
      return if under_construction_or_forwarding_domain?
      
      if params[:id]
        @post = Post.where(:id => params[:id]).first
      else      
        # Find the page with an exact URI match        
        uri = "#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}"
        @post = Post.where(:site_id => @site.id, :uri => request.fullpath).first
      end      
      render :file => "caboose/extras/error404" and return if @post.nil?                 

      @post = Caboose.plugin_hook('post_content', @post)
      @editmode = !params['edit'].nil? && user.is_allowed('posts', 'edit') ? true : false  
    end
  
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/posts
    def admin_index
      return if !user_is_allowed('posts', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'site_id'     => @site.id,
          'name'        => ''
      },{
          'model'       => 'Caboose::Post',
          'sort'        => 'created_at DESC',
          'desc'        => false,
          'base_url'    => '/admin/posts'
      })
      @posts = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/json
    def admin_json_single
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      render :json => @post
    end
  
    # GET /admin/posts/:id/edit
    def admin_edit_general
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/preview
    def admin_edit_preview
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/content
    def admin_edit_content
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      if @post.body
        @post.preview = @post.body
        @post.body = nil
        @post.save
      end
      if @post.block.nil?      
        redirect_to "/admin/posts/#{@post.id}/layout"
        return
      end
      @editing = true
    end
    
    # GET /admin/posts/:id/categories
    def admin_edit_categories
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      @categories = PostCategory.where(:site_id => @site.id).reorder(:name).all
      if @categories.nil? || @categories.count == 0
        PostCategory.create(:site_id => @site.id, :name => 'General News')
        @categories = PostCategory.where(:site_id => @site.id).reorder(:name).all
      end
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/layout
    def admin_edit_layout
      return unless user_is_allowed('posts', 'edit')      
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/posts/:id/layout
    def admin_update_layout
      return unless user_is_allowed('posts', 'edit')      
      bt = BlockType.find(params[:block_type_id])
      Block.where(:post_id => params[:id]).destroy_all
      Block.create(:post_id => params[:id], :block_type_id => params[:block_type_id], :name => bt.name)
      resp = Caboose::StdClass.new({
        'redirect' => "/admin/posts/#{params[:id]}/content"
      })
      render :json => resp
    end
  
    # POST /admin/posts/:id
    def admin_update      
      return if !user_is_allowed('posts', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      post = Post.find(params[:id])
      
      save = true
      params.each do |name, value|    
        case name                      
          when 'site_id'    then post.site_id    = value.to_i
          when 'slug'       then post.set_slug_and_uri(value)                        
          when 'title'      then post.title      = value            
          when 'subtitle'   then post.subtitle   = value
          when 'author'     then post.author     = value
          when 'body'       then post.body       = value
          when 'preview'    then post.preview    = value
          when 'hide'       then post.hide       = value
          when 'image_url'  then post.image_url  = value
          when 'published'  then post.published  = value
          when 'created_at' then post.created_at = DateTime.parse(value)
          when 'updated_at' then post.updated_at = DateTime.parse(value)
        end
      end
      resp.success = save && post.save      
      render :json => resp
    end
    
    # POST /admin/posts/:id/image
    def admin_update_image
      return if !user_is_allowed('posts', 'edit')
      
      resp = Caboose::StdClass.new
      post = Post.find(params[:id])
      post.image = params[:image]            
      resp.success = post.save
      resp.attributes = { 'image' => { 'value' => post.image.url(:thumb) }}
      
      render :text => resp.to_json
    end
    
    # GET /admin/posts/new
    def admin_new
      return if !user_is_allowed('posts', 'new')  
      @new_post = Post.new  
      render :layout => 'caboose/admin'
    end
  
    # POST /admin/posts
    def admin_add
      return if !user_is_allowed('posts', 'add')
  
      resp = Caboose::StdClass.new({
        'error' => nil,
        'redirect' => nil
      })
    
      post = Post.new
      post.site_id = @site.id
      post.title = params[:title]                  
      post.published = false
  
      if post.title == nil || post.title.length == 0
        resp.error = 'A title is required.'      
      else
        post.save        
        post.set_slug_and_uri(post.title)                
        resp.redirect = "/admin/posts/#{post.id}/edit"
      end
      
      render :json => resp
    end
    
    # PUT /admin/posts/:id/add-to-category
    def admin_add_to_category
      return if !user_is_allowed('posts', 'edit')
      
      post_id = params[:id]
      cat_id = params[:post_category_id]
      
      if !PostCategoryMembership.exists?(:post_id => post_id, :post_category_id => cat_id)
        PostCategoryMembership.create(:post_id => post_id, :post_category_id => cat_id)
      end
  
      render :json => true      
    end
    
    # PUT /admin/posts/:id/remove-from-category
    def admin_remove_from_category
      return if !user_is_allowed('posts', 'edit')
      
      post_id = params[:id]
      cat_id = params[:post_category_id]
      
      if PostCategoryMembership.exists?(:post_id => post_id, :post_category_id => cat_id)
        PostCategoryMembership.where(:post_id => post_id, :post_category_id => cat_id).destroy_all
      end
  
      render :json => true      
    end
    
    # GET /admin/posts/:id/delete
    def admin_delete_form
      return if !user_is_allowed('posts', 'delete')
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # DELETE /admin/posts/:id
    def admin_delete
      return if !user_is_allowed('posts', 'edit')
      
      post_id = params[:id]
      PostCategoryMembership.where(:post_id => post_id).destroy_all
      Post.where(:id => post_id).destroy_all
  
      render :json => { 'redirect' => '/admin/posts' }      
    end
    
  end
end
