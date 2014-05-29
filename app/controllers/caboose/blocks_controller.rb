
module Caboose
  class BlocksController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/pages/:page_id/blocks
    def admin_index
      return if !user_is_allowed('pages', 'view')
      blocks = Block.where(:page_id => params[:page_id]).reorder(:sort_order)
      render :json => blocks      
    end

    # GET /admin/pages/:page_id/blocks/new
    def admin_new
      return unless user_is_allowed('pages', 'add')
      @page = Page.find(params[:page_id])
      @block = Block.new(:page_id => params[:page_id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/pages/:page_id/blocks/:id
    def admin_show
      return unless user_is_allowed('pages', 'edit')      
      block = Block.find(params[:id])
      render :json => block
    end
    
    # GET /admin/pages/:page_id/blocks/:id/render
    def admin_render
      return unless user_is_allowed('pages', 'edit')      
      b = Block.find(params[:id])
      bt = b.block_type
      if bt.nil?
        bt = BlockType.where(:name => 'richtext').first 
        b.block_type_id = bt.id
        b.save
      end
      html = nil
      
      if bt.use_render_function && bt.render_function
        html = b.render_from_function(params[:empty_text], true)        
      else        
        html = render_to_string({
          :partial => "caboose/blocks/#{b.block_type.name}",
          :locals => { 
            :block => b,
            :empty_text => params[:empty_text],
            :editing => true
          }
        })
      end
      render :json => html            
    end
    
    # GET /admin/pages/:page_id/blocks/render
    def admin_render_all
      return unless user_is_allowed('pages', 'edit')
      p = Page.find(params[:page_id])
      blocks = p.blocks.where("field_id is null").collect do |b|
        bt = b.block_type
        if bt.nil?
          bt = BlockType.where(:name => 'richtext').first 
          b.block_type_id = bt.id
          b.save
        end
        html = nil  
        Caboose.log(b.id)
        if bt.use_render_function && bt.render_function
          html = b.render_from_function(params[:empty_text], true)        
        else        
          html = render_to_string({
            :partial => "caboose/blocks/#{bt.name}",
            :locals => { :block => b, :empty_text => params[:empty_text], :editing => true }
          })
        end                     
        {
          :id => b.id,
          :block_type_id => bt.id,
          :sort_order => b.sort_order,
          :html => html        
        }
      end
      render :json => blocks
    end
    
    # GET /admin/pages/:page_id/blocks/:id/edit
    def admin_edit
      return unless user_is_allowed('pages', 'edit')
      @page = Page.find(params[:page_id])
      @block = Block.find(params[:id])
      @block.create_fields      
                    
      #render "caboose/blocks/admin_edit_#{@block.block_type}", :layout => 'caboose/modal'
      render :layout => 'caboose/modal'
    end
    
    # POST /admin/pages/:page_id/blocks
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })

      b = Block.new            
      b.page_id = params[:page_id].to_i
      b.block_type_id = params[:block_type_id]
                    
      if !params[:index].nil?      
        b.sort_order = params[:index].to_i
      elsif params[:after_id]
        b2 = Block.find(params[:after_id].to_i)
        b.sort_order = b2.sort_order + 1        
      end
      
      i = b.sort_order + 1
      Block.where("page_id = ? and sort_order >= ?", b.page_id, b.sort_order).reorder(:sort_order).each do |b2|
        b2.sort_order = i
        b2.save        
        i = i + 1
      end      
      
      # Save the block
      b.save
      
      # Ensure that all the fields are created for the block
      b.create_fields

      # Send back the response
      resp.block = b
      render :json => resp
    end
    
    # PUT /admin/pages/:page_id/blocks/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      b = Block.find(params[:id])

      save = true
      params.each do |k,v|
        case k
          when 'page_id'       then b.page_id       = v
          when 'field_id'      then b.field_id      = v
          when 'block_type_id' then b.block_type_id = v
          when 'sort_order'    then b.sort_order    = v
          when 'name'          then b.name          = v
          when 'value'         then b.value         = v                                        
        end
      end
    
      resp.success = save && b.save
      b.create_fields
      render :json => resp      
    end
    
    # DELETE /admin/pages/:page_id/blocks/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')
      Block.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/pages/#{params[:page_id]}/edit"
      })
      render :json => resp
    end
		
  end
  
end
