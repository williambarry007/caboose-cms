module Caboose
  class PostsController < ApplicationController  
     
    # GET /posts
    def index
    	@posts = Post.where(:published => true).limit(5).order('created_at DESC')
    end
    
    # GET /posts/:id
    def detail
    	@post = Post.find_by_id(params[:id])
    	unless @post.present?
    		flash[:notice] = 'The posts post you tried to access does not exist.'
    		redirect_to action: :index
    	end
    end
  
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/posts
    def admin_index
      return if !user_is_allowed('posts', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'name'       => ''
      },{
          'model'       => 'Caboose::Post',
          'sort'        => 'created_at DESC',
          'desc'        => false,
          'base_url'    => '/admin/posts'
      })
      @posts = @gen.items    
      render :layout => 'caboose/admin'
    end
  
    # GET /admin/posts/:id/edit
    def admin_edit_general
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/content
    def admin_edit_content
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/posts/:id/categories
    def admin_edit_categories
      return if !user_is_allowed('posts', 'edit')    
      @post = Post.find(params[:id])
      @categories = PostCategory.reorder(:name).all
      render :layout => 'caboose/admin'
    end
  
    # POST /admin/posts/:id
    def admin_update
      Caboose.log(params)
      return if !user_is_allowed('posts', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      post = Post.find(params[:id])
      
      save = true
      params.each do |name, value|    
        case name
          when 'category_id'
            post.category_id = value
          when 'title'            
            post.title = value
          when 'body'
            post.body = value
          when 'image'
            post.image = value
          when 'published'
            post.published = value.to_i == 1
          when 'created_at'
            post.created_at = DateTime.parse(value)
        end
      end
      resp.success = save && post.save
      if params[:image]
        resp.attributes['image'] = { 'value' => post.image.url(:thumb) }
      end
      render :json => resp
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
      post.title = params[:title]      
      post.published = false
  
      if post.title == nil || post.title.length == 0
        resp.error = 'A title is required.'      
      else
        post.save
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
