
module Caboose
  class MediaCategoriesController < ApplicationController

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
        end
      end
    
      resp.success = save && cat.save
      render :json => resp
    end
    
    # DELETE /admin/media-categories/:id
    def admin_delete
      return unless user_is_allowed('mediacategories', 'delete')
      cat = MediaCategory.find(params[:id])
      cat.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/media-categories'
      })
      render :json => resp
    end       
		
  end
end
