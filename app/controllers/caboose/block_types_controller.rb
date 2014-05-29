
module Caboose
  class BlockTypesController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/block-types
    def admin_index
      return if !user_is_allowed('pages', 'view')
      @block_types = BlockType.reorder(:name).all
      render :layout => 'caboose/admin'      
    end
    
    # GET /admin/block-types/:id
    def admin_show
      return if !user_is_allowed('pages', 'view')
      block_type = BlockType.find(params[:id])
      render :json => block_type      
    end

    # GET /admin/block-types/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = BlockType.new
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/block-types/:id/edit
    def admin_edit
      return unless user_is_allowed('pages', 'edit')      
      @block_type = BlockType.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/block-types
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })

      bt = BlockType.new(
        :name => params[:name].downcase.gsub(' ', '_'),
        :description => params[:name],
        :use_render_function => false
      )
      bt.save      
      
      # Send back the response
      resp.redirect = "/admin/block-types/#{bt.id}/edit"
      render :json => resp
    end
    
    # PUT /admin/block-types/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      bt = BlockType.find(params[:id])

      save = true
      user = logged_in_user

      params.each do |k,v|
        case k
          when 'name'                            then bt.name                = v
          when 'description'                     then bt.description         = v
          when 'render_function'                 then bt.render_function     = v
          when 'use_render_function'             then bt.use_render_function = v
          when 'use_render_function_for_layout'  then bt.use_render_function_for_layout = v                      
        end
      end
    
      resp.success = save && bt.save
      render :json => resp
    end
    
    # DELETE /admin/block-types/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')                  
      BlockType.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/block-types"
      })
      render :json => resp
    end
    
    # GET /admin/block-types/options
    def admin_options
      return unless user_is_allowed('pages', 'edit')      
      options = BlockType.reorder(:name).all.collect do |bt| 
        { 'value' => bt.id, 'text' => bt.description } 
      end      
      render :json => options
    end
		
  end  
end
