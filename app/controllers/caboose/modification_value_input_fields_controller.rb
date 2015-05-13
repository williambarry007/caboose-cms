module Caboose
  class ModificationValueInputFieldsController < Caboose::ApplicationController
    
    # GET /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      mv = ModificationValue.find(params[:mod_value_id])
      render :json => mv.input_fields            
    end
    
    # GET /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/:id/json
    def admin_json_single
      ip = ModificationValueInputField.find(params[:id])
      render :json => ip
    end
    
    # GET /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/:id
    def admin_edit
      return if !user_is_allowed('products', 'edit')
      @product = Product.find(params[:product_id])
      @modification = Modification.find(params[:mod_id])
      @modification_value_input_field = ModificationValueInputField.find(params[:id])
      render :layout => 'caboose/modal'
    end
          
    # PUT /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/:id    
    def admin_update
      return if !user_is_allowed('products', 'edit')
      
      resp = Caboose::StdClass.new
      ip = ModificationValueInputField.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name                        
          when 'sort_order'    then ip.sort_order     = value 
          when 'name'          then ip.name           = value
          when 'description'   then ip.description    = value
          when 'field_type'    then ip.field_type     = value
          when 'default_value' then ip.default_value  = value                                              
          when 'width'         then ip.width          = value
          when 'height'        then ip.height         = value
          when 'options'       then ip.options        = value
          when 'options_url'   then ip.options_url    = value
        end
      end
      resp.success = save && ip.save
      render :json => resp
    end
        
    # POST /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new
      name = params[:name]
            
      if name.length == 0
        resp.error = "The name cannot be empty."
      elsif ModificationValueInputField.where(:modification_value_id => params[:mod_value_id], :name => name).exists?
        resp.error = "An input field with that name already exists for this modification value."
      else
        last_ip = ModificationValueInputField.where(:modification_value_id => params[:mod_value_id]).reorder("sort_order desc").limit(1).first
        sort_order = last_ip ? last_ip.sort_order + 1 : 0
        ip = ModificationValueInputField.new(:modification_value_id => params[:mod_value_id], :name => name, :sort_order => sort_order)                  
        ip.save
        resp.success = true        
      end
      render :json => resp    
    end
        
    # DELETE /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      ip = ModificationValueInputField.find(params[:id]).destroy      
      render :json => Caboose::StdClass.new({
        :success => true
      })
    end
        
    # PUT /admin/products/:product_id/modifications/:mod_id/values/:mod_value_id/input-fields/sort-order
    def admin_update_sort_order            
      params[:input_field_ids].each_with_index do |ip_id, i|
        ip = ModificationValueInputField.where(:id => ip_id).first
        ip.sort_order = i
        ip.save
      end      
      render :json => { :success => true }
    end
    
    # PUT /admin/products/modifications/values/input-fields/field-type-options
    def admin_field_type_options
      render :json => [      
        { :value => 'color'       , :text => 'Color'      },        
        { :value => 'checkbox'    , :text => 'Checkbox'   }, 
        { :value => 'date'        , :text => 'Date'       },
        { :value => 'time'        , :text => 'Time'       },
        { :value => 'date_time'   , :text => 'Date/Time'  },  
        { :value => 'select'      , :text => 'Select'     },
        { :value => 'text'        , :text => 'Text'       },
        { :value => 'textarea'    , :text => 'Textarea'   }
      ]
    end
        
  end
end

