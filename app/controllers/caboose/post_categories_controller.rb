module Caboose
  class PostCategoriesController < Caboose::ApplicationController  
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/post-categories
    def admin_index
      return unless user_is_allowed('post_categories', 'view')
      
      @main_cat = PostCategory.where("site_id = ?", @site.id).first      
      if @main_cat.nil?
        @main_cat = PostCategory.create(:site_id => @site.id, :name => 'General News')
      end
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/post-categories/new
    def admin_new
      return unless user_is_allowed('post_categories', 'add')
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/post-categories
    def admin_add
      return unless user_is_allowed('post_categories', 'add')
      
      resp = Caboose::StdClass.new
    
      if params[:name].nil? || params[:name].empty?
        resp.error = 'The category name cannot be empty.'
      else        
        cat = PostCategory.new(
          :site_id   => @site.id,
          :name      => params[:name]
        )
        
        if cat.save
          resp.redirect = "/admin/post-categories/#{cat.id}"
        else
          resp.error = 'There was an error saving the category.'
        end
      end
      
      render :json => resp
    end
      
    # GET /admin/post-categories/:id
    def admin_edit
      return unless user_is_allowed('post_categories', 'edit')    
      @category = PostCategory.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/post-categories/:id
    def admin_update
      return unless user_is_allowed('post_categories', 'edit')
      
      # Define category and initialize response
      cat = PostCategory.find(params[:id])
      resp = Caboose::StdClass.new({ :attributes => {} })
      
      # Iterate over params and update relevant attributes
      params.each do |key, value|
        case key
          when 'site_id' then cat.name   = value
          when 'name'    then cat.name   = value
        end
      end
      
      # Try and save category
      resp.success = cat.save
      
      # Respond to update request
      render :json => resp
    end
    
    # DELETE /admin/post-categories/:id
    def admin_delete
      return unless user_is_allowed('post_categories', 'delete')
      
      resp = Caboose::StdClass.new
      cat = PostCategory.find(params[:id])
      
      if cat.posts.any?
        resp.error = "Can't delete a post category that has posts in it."
      else
        resp.success = cat.destroy
        resp.redirect = '/admin/post-categories'
      end
      render :json => resp
    end
        
    
  end
end

