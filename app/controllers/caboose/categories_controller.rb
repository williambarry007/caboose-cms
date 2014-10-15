module Caboose
  class CategoriesController < Caboose::ApplicationController  
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/categories
    def admin_index
      return unless user_is_allowed('categories', 'view')
      render layout: 'caboose/admin'
    end
    
    # GET /admin/categories/new
    def admin_new
      return unless user_is_allowed('categories', 'add')
      render layout: 'caboose/admin'
    end
    
    # POST /admin/categories
    def admin_add
      return unless user_is_allowed('categories', 'add')
      
      if params[:parent_id].nil? or params[:parent_id].empty?
        render :json => { :error => 'Please select a parent category.' }
      elsif params[:name].nil? or params[:name].empty?
        render :json => { :error => 'This title cannot be empty' }
      else
        category           = Category.new
        category.parent_id = params[:parent_id]
        category.name      = params[:name]
        category.slug      = category.generate_slug
        category.url       = "#{Category.find(params[:parent_id]).url}/#{category.slug}"
        
        if category.save
          render :json => { :success => true, :redirect => "/admin/categories/#{category.id}/edit" }
        else
          render :json => { :error => 'There was an error saving the category.' }
        end
      end
    end
      
    # GET /admin/categories/:id/edit
    def admin_edit
      return unless user_is_allowed('categories', 'edit')    
      @category = Category.find(params[:id])
      render layout: 'caboose/admin'
    end        
    
    # PUT /admin/categories/:id
    def admin_update
      return unless user_is_allowed('categories', 'edit')
      
      # Define category and initialize response
      category = Category.find(params[:id])
      response = { attributes: Hash.new }
      
      # Iterate over params and update relevant attributes
      params.each do |key, value|
        case key
        when 'name' then category.name = value
        when 'slug' then category.slug = value
        when 'status' then category.status = value
        when 'image' then category.image = value
        end
      end
      
      # Try and save category
      response[:success] = category.save
      
      # If an image is passed, return the url
      response[:attributes][:image] = { value: category.image.url(:medium) } if params[:image]
      
      # Respond to update request
      render :json => response
    end
    
    # DELETE /admin/categories/:id
    def admin_delete
      return unless user_is_allowed('categories', 'delete')
      
      category = Category.find(params[:id])
      
      if category.products.any?
        render :json => { :error => "Can't delete a category that has products in it." }
      elsif category.children.any?
        render :json => { :error => "You can't delete a category that has child categories." }
      else
        render :json => { :success => category.destroy, :redirect => '/admin/categories' }
      end
    end
    
    
    # GET /admin/products/status-options
    def admin_status_options
      arr = ['Active', 'Inactive', 'Deleted']
      options = []
      arr.each do |status|
        options << {
          :value => status,
          :text => status
        }
      end
      render :json => options
    end
  end
end

