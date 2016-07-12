
module Caboose
  class BlockTypesController < ApplicationController
       
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # @route GET /admin/block-types
    def admin_index
      return if !user_is_allowed('pages', 'view')
      @block_types = BlockType.where("parent_id is null or parent_id = 0").reorder(:name).all
      render :layout => 'caboose/admin'      
    end
    
    # @route GET /admin/block-types/json
    def admin_json
      h = {        
        'name'              => '',
        'description'       => '',
        'name_like'         => '',
        'description_like'  => '',
      }
      if params[:parent_id]
        h['parent_id'] = ''
      else
        h['parent_id_null'] = true
        params[:parent_id_null] = nil if params[:parent_id_null]
      end
      pager = Caboose::Pager.new(params, h, {      
        'model' => 'Caboose::BlockType',
        'sort'  => 'name',
        'desc'  => 'false',
        'base_url' => "/admin/block-types",
        'items_per_page' => 100,
        'skip' => ['parent_id_null']
      })      
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => :sites)
      }
    end
    
    # @route GET /admin/block-types/:id/json
    def admin_json_single
      return if !user_is_allowed('pages', 'view')
      block_type = BlockType.find(params[:id])
      render :json => block_type.as_json(:include => :sites)      
    end

    # @route GET /admin/block-types/new
    # @route GET /admin/block-types/:id/new
    def admin_new
      return unless user_is_allowed('pages', 'add')      
      @block_type = BlockType.new
      @parent_id = params[:id]
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/block-types/:id/icon
    def admin_edit_icon
      return unless user_is_allowed('pages', 'edit')      
      @block_type = BlockType.find(params[:id])
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/block-types/:id
    def admin_edit
      return unless user_is_allowed('pages', 'edit')      
      @block_type = BlockType.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/block-types
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
      resp.redirect = "/admin/block-types/#{bt.id}"
      render :json => resp
    end
    
    # @route PUT /admin/block-types/:id
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
          when 'is_global'                       then bt.is_global                      = v
          when 'icon'                            then bt.icon                           = v
          when 'block_type_category_id'          then bt.block_type_category_id         = v
          when 'render_function'                 then bt.render_function                = v
          when 'use_render_function'             then bt.use_render_function            = v
          when 'use_render_function_for_layout'  then bt.use_render_function_for_layout = v
          when 'allow_child_blocks'              then bt.allow_child_blocks             = v
          when 'default_child_block_type_id'     then bt.default_child_block_type_id    = v
          when 'name'                            then bt.name                           = v
          when 'field_type'                      then bt.field_type                     = v                       
          when 'default'                         then bt.default                        = v
          when 'width'                           then bt.width                          = v
          when 'height'                          then bt.height                         = v
          when 'fixed_placeholder'               then bt.fixed_placeholder              = v
          when 'options'                         then bt.options                        = v
          when 'options_function'                then bt.options_function               = v
          when 'options_url'                     then bt.options_url                    = v
          when 'default_constrain'               then bt.default_constrain              = v
          when 'default_full_width'              then bt.default_full_width             = v
          when 'site_id'                         then bt.toggle_site(v[0], v[1])
        end
      end
      
      # Trigger the page cache to be updated      
      query = ["update page_cache set refresh = true where page_id in (select distinct(page_id) from blocks where block_type_id = ?)", bt.id]
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))      
      PageCacher.delay.refresh
    
      resp.success = save && bt.save
      render :json => resp
    end
    
    # @route DELETE /admin/block-types/:id
    def admin_delete
      return unless user_is_allowed('pages', 'delete')                  
      BlockType.find(params[:id]).destroy            
      resp = StdClass.new({
        'redirect' => "/admin/block-types"
      })
      render :json => resp
    end
        
    # @route_priority 1
    # @route GET /admin/block-types/:field-options
    # @route GET /admin/block-types/options
    # @route GET /admin/block-types/:id/options
    def admin_options
      return unless user_is_allowed('pages', 'edit')

      options = []
      case params[:field]
        when nil
          if params[:id]          
            bt = BlockType.find(params[:id])            
            options = []
            if bt.options_function && bt.options_function.length > 0
              options = bt.render_options
            elsif bt.options
              options = bt.options.strip.split("\n").collect { |line| { 'value' => line, 'text' => line }}
            end
          else                  
            options = BlockType.where("parent_id is null").reorder(:name).all.collect do |bt| 
              { 'value' => bt.id, 'text' => bt.description } 
            end
          end
        when 'field-type'
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
        when 'site'      
          options = Site.reorder("description, name").all.collect{ |s| { 'value' => s.id, 'text' => s.description && s.description.strip.length > 0 ? s.description : s.name }}
        when 'tree'          
          options = []            
          BlockType.where("parent_id is null or parent_id = 0").reorder(:name).all.each do |bt|        
            admin_tree_options_helper(options, bt, '')         
          end
        when 'layout'
          options = []
          cat_ids = BlockTypeCategory.layouts.collect{ |cat| cat.id }
          q = ["block_type_category_id in (?)", cat_ids]
          q = ["block_type_category_id in (?) and block_type_site_memberships.site_id = ?", cat_ids, params[:site_id]] if params[:site_id]                                                                
          BlockType.includes(:block_type_site_memberships).where(q).reorder(:description).all.each do |bt|    
            options << { 'value' => bt.id, 'text' => bt.description }
          end    
      end        
      render :json => options
    end
    
    def admin_tree_options_helper(options, bt, prefix)      
      options << { 'value' => bt.id, 'text' => "#{prefix}#{bt.description}" }
      bt.children.each do |bt2|
        admin_tree_options_helper(options, bt2, " - #{prefix}")
      end      
    end        
            
    #===========================================================================
    # Public Repo Actions
    #===========================================================================
    
    # @route GET /caboose/block-types
    def api_block_type_list
      arr = BlockType.where("parent_id is null and share = ?", true).reorder(:name).all.collect do |bt|
        { 'name' => bt.name, 'description' => bt.description }
      end      
      render :json => arr      
    end
    
    # @route GET /caboose/block-types/:name
    def api_block_type
      bt = BlockType.where(:name => params[:name]).first
      render :json => { 'error' => 'Invalid block type.' } if bt.nil?            
      render :json => bt.api_hash        
    end        
		
  end  
end
