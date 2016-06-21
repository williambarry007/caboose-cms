module Caboose
  class CategoriesController < Caboose::ApplicationController  
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # @route GET /admin/categories
    def admin_index
      return unless user_is_allowed('categories', 'view')
      
      @top_cat = Caboose::Category.where("site_id = ? and parent_id is null", @site.id).first      
      if @top_cat.nil?
        @top_cat = Caboose::Category.create(:site_id => @site.id, :name => 'All Products', :url => '/')
      end
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/categories/new
    def admin_new
      return unless user_is_allowed('categories', 'add')
      render :layout => 'caboose/admin'
    end

    # @route GET /admin/categories/options
    def admin_options
      @options = []
      cat = Category.where("site_id = ? and parent_id is null", @site.id).first      
      if cat.nil?
        cat = Category.create(:site_id => @site.id, :name => 'All Products', :url => '/')
      end
      admin_options_helper(cat, '')
      render :json => @options
    end

    # @route GET /admin/categories/status-options
    def admin_status_options
      render :json => [
        { :value => 'Active'   , :text => 'Active'    },
        { :value => 'Inactive' , :text => 'Inactive'  },
        { :value => 'Deleted'  , :text => 'Deleted'   }
      ]
    end

    # @route GET /admin/categories/:id/sort-children
    def admin_sort_children
      return unless user_is_allowed('categories', 'edit')    
      @category = Category.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route PUT /admin/categories/:id/children/sort-order
    def admin_update_sort_order
      return unless user_is_allowed('categories', 'edit')            
      params[:category_ids].each_with_index do |cat_id, i|
        cat = Category.find(cat_id)
        cat.sort_order = i
        cat.save
      end      
      render :json => { :success => true }
    end

    # @route GET /admin/categories/:category_id/products/json
    def admin_category_products
      query = ["select P.id, P.title from store_category_memberships CM
        left join store_products P on P.id = CM.product_id
        where CM.category_id = ? AND P.status = 'Active'
        order by CM.sort_order, P.title", params[:id]]             
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      arr = rows.collect{ |row| { :id => row[0], :title => row[1] }}
      render :json => arr
    end

    # @route GET /admin/categories/:id
    def admin_edit
      return unless user_is_allowed('categories', 'edit')    
      @category = Category.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # @route PUT  /admin/categories/:id
    # @route POST /admin/categories/:id
    def admin_update
      return unless user_is_allowed('categories', 'edit')
      
      # Define category and initialize response
      cat = Category.find(params[:id])
      resp = Caboose::StdClass.new({ :attributes => {} })
      
      # Iterate over params and update relevant attributes
      params.each do |key, value|
        case key
          when 'site_id' then cat.name   = value
          when 'name'    then cat.name   = value
          when 'slug'    then cat.slug   = value
          when 'status'  then cat.status = value
          when 'image'   then cat.image  = value
          when 'parent_id' then cat.parent_id = value
        end
      end
      
      # Try and save category
      resp.success = cat.save
      
      # If an image is passed, return the url
      resp.attributes[:image] = { :value => cat.image.url(:medium) } if params[:image]
      
      # Respond to update request
      render :json => resp
    end

    # @route POST /admin/categories
    def admin_add
      return unless user_is_allowed('categories', 'add')
      
      resp = Caboose::StdClass.new
      
      p = Category.where(:id => params[:parent_id]).first
      
      if params[:parent_id].nil? || params[:parent_id].empty? || p.nil?
        resp.error = 'Please select a parent category.'
      elsif params[:name].nil? || params[:name].empty?
        resp.error = 'This title cannot be empty'
      else        
        cat = Category.new(
          :site_id   => @site.id,
          :parent_id => p.id,
          :name      => params[:name],
          :status    => 'Active'
        )
        cat.slug = cat.generate_slug
        cat.url  = "#{p.url}/#{cat.slug}"
        
        if cat.save
          resp.redirect = "/admin/categories/#{cat.id}"
        else
          resp.error = 'There was an error saving the category.'
        end
      end
      
      render :json => resp
    end

    # @route DELETE /admin/categories/:id
    def admin_delete
      return unless user_is_allowed('categories', 'delete')
      
      resp = Caboose::StdClass.new
      cat = Category.find(params[:id])
      
      if cat.products.any?
        resp.error = "Can't delete a category that has products in it."
      elsif cat.children.any?
        resp.error = "You can't delete a category that has child categories."
      else
        resp.success = cat.destroy
        resp.redirect = '/admin/categories'
      end
      render :json => resp
    end

    def admin_options_helper(cat, prefix)
      @options << { :value => cat.id, :text => "#{prefix}#{cat.name}" }      
      cat.children.each do |c|
        admin_options_helper(c, "#{prefix} - ")
      end      
    end

  end
end

