
module Caboose
  class PageBlockTypesController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/page-block-types
    def admin_index
      return if !user_is_allowed('pages', 'view')
      @block_types = PageBlockType.reorder(:name).all
      render :layout => 'caboose/admin'      
    end
    
    # GET /admin/page-block-types/:id
    def admin_show
      return if !user_is_allowed('pages', 'view')
      block_type = PageBlockType.find(params[:id])
      render :json => block_type      
    end

    # GET /admin/page-block-types/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = PageBlockType.new
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/page-block-types/:id/edit
    def admin_edit
      return unless user_is_allowed('pages', 'edit')      
      @block_type = PageBlockType.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/page-block-types
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })

      bt = PageBlockType.new(
        :name => params[:name].downcase.gsub(' ', '_'),
        :description => params[:name],
        :use_render_function => false
      )
      bt.save      
      
      # Send back the response
      resp.redirect = "/admin/page-block-types/#{bt.id}/edit"
      render :json => resp
    end
    
    # PUT /admin/page-block-types/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      bt = PageBlockType.find(params[:id])

      save = true
      user = logged_in_user

      params.each do |k,v|
        case k
          when 'name'
            bt.name = v
            break
          when 'description'
            bt.description = v
            break
          when 'use_render_function'
            bt.use_render_function = v
            break
          when 'render_function'
            bt.render_function = v
            break            
        end
      end
    
      resp.success = save && bt.save
      render :json => resp
    end
    
    # DELETE /admin/page-block-types/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')                  
      PageBlockType.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/page-block-types"
      })
      render :json => resp
    end
		
  end  
end
