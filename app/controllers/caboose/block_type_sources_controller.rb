module Caboose
  class BlockTypeSourcesController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/block-type-sources
    def admin_index
      return if !user_is_allowed('blocktypesources', 'view')
      @block_type_sources = BlockTypeSource.reorder("priority, name").all
      render :layout => 'caboose/admin'      
    end
    
    # GET /admin/block-type-sources/new    
    def admin_new
      return unless user_is_allowed('blocktypesources', 'add')
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/block-type-sources/:id
    def admin_edit
      return unless user_is_allowed('blocktypesources', 'edit')      
      @block_type_source = BlockTypeSource.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/block-type-sources
    def admin_create
      return unless user_is_allowed('blocktypesources', 'add')

      resp = Caboose::StdClass.new          
      max_priority = BlockTypeSource.maximum(:priority)
      max_priority = 0 if max_priority.nil?
      bts = BlockTypeSource.new(
        :name => params[:name], 
        :priority => max_priority + 1,
        :active => true
      )                           
      bts.save      
      
      # Send back the response
      resp.redirect = "/admin/block-types/store/sources/#{bts.id}/edit"
      render :json => resp
    end
    
    # PUT /admin/block-type-sources/:id
    def admin_update
      return unless user_is_allowed('blocktypesources', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      bts = BlockTypeSource.find(params[:id])
      save = true      

      params.each do |k,v|
        case k
          when 'name'       then bts.name     = v
          when 'url'        then bts.url      = v
          when 'token'      then bts.token    = v
          when 'priority'   then bts.priority = v
          when 'active'     then bts.active   = v
        end
      end
    
      resp.success = save && bts.save
      render :json => resp
    end
    
    # DELETE /admin/block-type-sources/:id
    def admin_delete
      return unless user_is_allowed('blocktypesources', 'delete')                  
      BlockTypeSource.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/block-types/store/sources"
      })
      render :json => resp
    end
    
    # GET /admin/block-type-sources/:id/refresh
    def admin_refresh      
      return unless user_is_allowed('blocktypesources', 'edit')
      
      resp = StdClass.new

      bts = BlockTypeSource.find(params[:id])           
      if bts.refresh_summaries
        resp.success = "Block types from the source have been refreshed successfully."
      else
        resp.error = "There was an error refreshing block types from the source."
      end
      render :json => resp      
    end
    
    # GET /admin/block-type-sources/options
    def admin_options
      return unless user_is_allowed('blocktypesources', 'edit')      
      options = BlockType.reorder(:name).all.collect do |bts| 
        { 'value' => bts.id, 'text' => bts.name } 
      end      
      render :json => options
    end
		
  end  
end
