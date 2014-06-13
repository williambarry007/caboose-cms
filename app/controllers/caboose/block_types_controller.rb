
module Caboose
  class BlockTypesController < ApplicationController
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/block-types
    def admin_index
      return if !user_is_allowed('pages', 'view')
      @block_types = BlockType.where("parent_id is null or parent_id = 0").reorder(:name).all
      render :layout => 'caboose/admin'      
    end
    
    # GET /admin/block-types/:id
    def admin_show
      return if !user_is_allowed('pages', 'view')
      block_type = BlockType.find(params[:id])
      render :json => block_type      
    end

    # GET /admin/block-types/new
    # GET /admin/block-types/:id/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = BlockType.new
      @parent_id = params[:id]
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
        :parent_id           => params[:parent_id] ? params[:parent_id] : nil,
        :name                => params[:name].downcase.gsub(' ', '_'),
        :description         => params[:name],                                                                
        :field_type          => params[:field_type],
        :allow_child_blocks  => true        
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

      params.each do |k,v|
        case k
          when 'parent_id'                       then bt.parent_id                      = v
          when 'name'                            then bt.name                           = v
          when 'description'                     then bt.description                    = v
          when 'render_function'                 then bt.render_function                = v
          when 'use_render_function'             then bt.use_render_function            = v
          when 'use_render_function_for_layout'  then bt.use_render_function_for_layout = v
          when 'allow_child_blocks'              then bt.allow_child_blocks             = v
          when 'name'                            then bt.name                           = v
          when 'field_type'                      then bt.field_type                     = v                       
          when 'default'                         then bt.default                        = v
          when 'width'                           then bt.width                          = v
          when 'height'                          then bt.height                         = v
          when 'fixed_placeholder'               then bt.fixed_placeholder              = v
          when 'options'                         then bt.options                        = v
          when 'options_function'                then bt.options_function               = v
          when 'options_url'                     then bt.options_url                    = v         
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
    
    # GET /admin/block-types/field-type-options
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
        { 'value' => 'block'              , 'text' => 'Block'                        }
      ]      
      render :json => options
    end
    
    # GET /admin/block-types/:id/options
    def admin_value_options
      return unless user_is_allowed('pages', 'edit')
      bt = BlockType.find(params[:id])            
      options = []
      if bt.options_function
        options = bt.render_options
      elsif bt.options
        options = bt.options.strip.split("\n").collect { |line| { 'value' => line, 'text' => line }}
      end        
      render :json => options
    end
    
    # GET /admin/block-types/options
    def admin_options
      return unless user_is_allowed('pages', 'edit')      
      options = BlockType.where("parent_id is null").reorder(:name).all.collect do |bt| 
        { 'value' => bt.id, 'text' => bt.description } 
      end      
      render :json => options
    end
    
    # GET /admin/block-types/tree-options
    def admin_tree_options
      return unless user_is_allowed('pages', 'edit')
      options = []            
      BlockType.where("parent_id is null or parent_id = 0").reorder(:name).all.each do |bt|        
        admin_tree_options_helper(options, bt, '')         
      end      
      render :json => options
    end
    
    def admin_tree_options_helper(options, bt, prefix)      
      options << { 'value' => bt.id, 'text' => "#{prefix}#{bt.description}" }
      bt.children.each do |bt2|
        admin_tree_options_helper(options, bt2, " - #{prefix}")
      end      
    end
		
  end  
end
