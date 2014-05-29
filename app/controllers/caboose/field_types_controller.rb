
module Caboose
  class FieldTypesController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/block-types/:block_type_id/field-types
    def admin_index
      return if !user_is_allowed('pages', 'view')
      field_types = FieldTypes.where(:block_type_id => params[:block_type_id]).reorder(:name).all
      render :json => field_types      
    end

    # GET /admin/block-types/:block_type_id/field-types/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = BlockType.find(params[:block_type_id])
      @field_type = FieldType.new
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/block-types/:block_type_id/field-types/:id/edit
    def admin_edit
      return unless user_is_allowed('pages', 'edit')      
      @field_type = FieldType.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/block-types/:block_type_id
    def admin_create
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })

      ft = FieldType.new(
        :block_type_id => params[:block_type_id],
        :name => params[:name].downcase.gsub(' ', '_'),
        :nice_name => params[:name],                
        :field_type => 'text'
      )
      ft.save      

      # Send back the response
      resp.redirect = "/admin/block-types/#{params[:block_type_id]}/field-types/#{ft.id}/edit"
      render :json => resp
    end
    
    # PUT /admin/block-types/:block_type_id/field-types/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      ft = FieldType.find(params[:id])      
      save = true      

      params.each do |k,v|
        case k
          when 'block_type_id'      then ft.block_type_id      = v
          when 'name'               then ft.name               = v
          when 'field_type'         then ft.field_type         = v             
          when 'nice_name'          then ft.nice_name          = v
          when 'default'            then ft.default            = v
          when 'width'              then ft.width              = v
          when 'height'             then ft.height             = v
          when 'fixed_placeholder'  then ft.fixed_placeholder  = v
          when 'options'            then ft.options            = v
          when 'options_function'   then ft.options_function   = v
          when 'options_url'        then ft.options_url        = v
        end
      end
    
      resp.success = save && ft.save
      render :json => resp
    end
    
    # DELETE /admin/block-types/:block_type_id/field-types/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')                    
      FieldType.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/block-types/#{params[:block_type_id]}/edit"
      })
      render :json => resp
    end
    
    # GET /admin/field-types/field-type-options
    def admin_field_type_options
      return unless user_is_allowed('pages', 'edit')      
      options = [ 
        { 'value' => 'checkbox'           , 'text' => 'Checkbox'                     }, 
        { 'value' => 'checkbox_multiple'  , 'text' => 'Checkbox (multiple)'          }, 
        { 'value' => 'image'              , 'text' => 'Image'                        },
        { 'value' => 'file'               , 'text' => 'File'                         },
        { 'value' => 'richtext'           , 'text' => 'Rich Text'                    }, 
        { 'value' => 'select'             , 'text' => 'Multiple choice (select box)' }, 
        { 'value' => 'text'               , 'text' => 'Textbox'                      }, 
        { 'value' => 'textarea'           , 'text' => 'Textarea'                     },
        { 'value' => 'block'              , 'text' => 'Block - User can select type' }
      ]
      BlockType.reorder(:name).all.each do |bt|
        options << { 'value' => "block_#{bt.id}", 'text' => "Block - #{bt.description}" }
      end
      render :json => options
    end
    
    # GET /admin/field-types/:id/options
    def admin_options
      return unless user_is_allowed('pages', 'edit')
      ft = FieldType.find(params[:id])            
      options = []
      if ft.options_function
        options = ft.render_options
      elsif ft.options
        options = ft.options.strip.split("\n").collect { |line| { 'value' => line, 'text' => line }}
      end        
      render :json => options
    end
		
  end  
end
