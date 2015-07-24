
module Caboose
  class MediaCategoriesController < ApplicationController
    
    # GET /admin/media-categories/json
    def admin_json
      return unless user_is_allowed('mediacategories', 'view')       
      tree = Caboose::MediaCategory.flat_tree(@site.id)
      render :json => tree
    end
    
    # GET /admin/media-categories/flat-tree
    def admin_flat_tree
      return unless user_is_allowed('mediacategories', 'view')
      prefix = params[:prefix] ? params[:prefix] : '-&nbsp;&nbsp;'
      tree = Caboose::MediaCategory.flat_tree(@site.id, prefix)
      render :json => tree
    end
    
    # GET /admin/media-categories/options
    def admin_options
      return unless user_is_allowed('mediacategories', 'view')
      prefix = params[:prefix] ? params[:prefix] : '-&nbsp;&nbsp;'
      tree = Caboose::MediaCategory.flat_tree(@site.id, prefix)
      options = tree.collect{ |mc| { 'value' => mc[:id], 'text' => mc[:name] }}
      render :json => options
    end

    # POST /admin/media-categories
    def admin_add
      return unless user_is_allowed('mediacategories', 'add')

      resp = Caboose::StdClass.new
      
      cat = MediaCategory.new(
        :site_id   => @site.id,
        :parent_id => params[:parent_id],
        :name      => params[:name]
      )      
      if !cat.save
        resp.error = cat.errors.first[1]
      else
        resp.new_id = cat.id
        resp.refresh = true
      end
     
      render :json => resp
    end
    
    # PUT /admin/media-categories/:id
    def admin_update
      return unless user_is_allowed('mediacategories', 'edit')
      
      resp = StdClass.new
      cat = MediaCategory.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name          
          when 'name' then cat.name = value
          when 'parent_id'
            parent = MediaCategory.find(value.to_i)
            if cat.is_ancestor_of?(parent)
              resp.error = "The new parent cannot be a child of itself."
              save = false
            else
              cat.parent_id = value
            end            
        end
      end
    
      resp.success = save && cat.save
      render :json => resp
    end
    
    # DELETE /admin/media-categories/:id
    def admin_delete
      return unless user_is_allowed('mediacategories', 'delete')
      cat = MediaCategory.find(params[:id])
      Media.where(:media_category_id => cat.id).destroy_all
      cat.destroy            
      render :json => { :success => true }
    end
    
    # POST /admin/media-categories/:id/attach
    def admin_attach
      return unless user_is_allowed('mediacategories', 'view')
      
      media_category_id = params[:id]
      ids = params[:media_id]
      ids = [ids] if !ids.is_a?(Array)
      ids.each do |id|
        m = Media.where(:id => id).first
        next if m.nil?
        m.update_attribute(:media_category_id, media_category_id)
        p = Product.where(:media_category_id => media_category_id).last
        if p
          pi = ProductImage.where(:media_id => id).exists? ? ProductImage.where(:media_id => id).first : ProductImage.create(:media_id => id, :product_id => p.id)
          pi.product_id = p.id
          pi.save
          ProductImageVariant.where(:product_image_id => pi.id).destroy_all
        end
      end
        
      render :json => { :success => true }
    end        
        		
  end
end
