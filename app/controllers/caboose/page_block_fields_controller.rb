
module Caboose
  class PageBlockFieldsController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/page-block-types/:block_type_id/fields
    def admin_index
      return if !user_is_allowed('pages', 'view')
      fields = PageBlockField.where(:page_block_type_id => params[:block_type_id]).reorder(:name).all
      render :json => fields      
    end

    # GET /admin/page-block-types/:block_type_id/fields/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = PageBlockType.find(params[:block_type_id])
      @field = PageBlockField.new
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/page-block-types/:block_type_id/fields/:id/edit
    def admin_edit
      return unless user_is_allowed('pages', 'edit')      
      @field = PageBlockField.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/page-block-types/:block_type_id
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })

      field = PageBlockField.new(
        :page_block_type_id => params[:block_type_id],
        :name => params[:name].downcase.gsub(' ', '_'),
        :nice_name => params[:name],                
        :field_type => 'text'
      )
      field.save      

      # Send back the response
      resp.redirect = "/admin/page-block-types/#{params[:block_type_id]}/fields/#{field.id}/edit"
      render :json => resp
    end
    
    # PUT /admin/page-block-types/:block_type_id/fields/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      field = PageBlockField.find(params[:id])      

      save = true
      user = logged_in_user

      params.each do |k,v|
        case k
          when 'page_block_type_id' 
            field.page_block_type_id = v
            break
          when 'name'               
            field.name = v
            break
          when 'field_type'
            field.field_type = v
            break
          when 'nice_name'      
            field.nice_name = v
            break
          when 'default'       
            field.default = v
            break
          when 'width'       
            field.width = v
            break
          when 'height'    
            field.height = v
            break
          when 'fixed_placeholder'
            field.fixed_placeholder = v
            break
          when 'options'            
            field.options = v
            break
          when 'options_url' 
            field.options_url = v
            break
        end
      end
    
      resp.success = save && field.save
      render :json => resp
    end
    
    # DELETE /admin/page-block-types/:block_type_id/fields/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')                    
      PageBlockField.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/page-block-types/#{params[:block_type_id]}/edit"
      })
      render :json => resp
    end
    
    # GET /admin/page-block-fields/field-type-options
    def admin_field_type_options
      return unless user_is_allowed('pages', 'edit')      
      options = [ 
        { 'value' => 'checkbox'           , 'text' => 'checkbox'          }, 
        { 'value' => 'checkbox_multiple'  , 'text' => 'checkbox_multiple' }, 
        { 'value' => 'image'              , 'text' => 'image'             },
        { 'value' => 'file'               , 'text' => 'file'              },
        { 'value' => 'richtext'           , 'text' => 'richtext'          }, 
        { 'value' => 'select'             , 'text' => 'select'            }, 
        { 'value' => 'text'               , 'text' => 'text'              }, 
        { 'value' => 'textarea'           , 'text' => 'textarea'          }
      ]
      render :json => options
    end
    
    # GET /admin/page-block-fields/:id/options
    def admin_field_options
      return unless user_is_allowed('pages', 'edit')
      f = PageBlockField.find(params[:id])            
      options = []
      if f.options
        options = f.options.strip.split("\n").collect { |line| { 'value' => line, 'text' => line }}
      end        
      render :json => options
    end
		
  end  
end
