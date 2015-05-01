module Caboose
  class ModificationValuesController < Caboose::ApplicationController
    
    # GET /admin/products/:product_id/modifications/:mod_id/values/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      m = Modification.find(params[:mod_id])
      render :json => m.modification_values            
    end
    
    # GET /admin/products/:product_id/modifications/:mod_id/values/:id/json
    def admin_json_single
      mv = ModificationValue.find(params[:id])
      render :json => mv      
    end
          
    # PUT /admin/products/:product_id/modifications/:mod_id/values/:id    
    def admin_update
      return if !user_is_allowed('products', 'edit')
      
      resp = Caboose::StdClass.new
      mv = ModificationValue.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'sort_order'        then mv.sort_order        = value
          when 'value'             then mv.value             = value
          when 'is_default'        then
            if value.to_i == 1
              ModificationValue.where(:modification_id => params[:mod_id]).all.each do |mv2|
                mv2.is_default = false
                mv2.save
              end
            end
            mv.is_default = value
            
          when 'price'             then mv.price             = value
          when 'requires_input'    then mv.requires_input    = value
          when 'input_description' then mv.input_description = value
        end
      end
      resp.success = save && mv.save
      render :json => resp
    end
    
    # POST /admin/products/:product_id/modifications/:mod_id/values
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new
      value = params[:value]
            
      if value.length == 0
        resp.error = "The value cannot be empty."
      else
        last_mv = ModificationValue.where(:modification_id => params[:mod_id]).reorder("sort_order desc").limit(1).first
        sort_order = last_mv ? last_mv.sort_order + 1 : 0
        mv = ModificationValue.new(:modification_id => params[:mod_id], :value => value, :sort_order => sort_order)                  
        mv.save
        resp.success = true        
      end
      render :json => resp    
    end
    
    # DELETE /admin/products/:product_id/modifications/:mod_id/values/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      mv = ModificationValue.find(params[:id]).destroy      
      render :json => Caboose::StdClass.new({
        :success => true
      })
    end
    
    # PUT /admin/products/:product_id/modifications/:mod_id/values/sort-order
    def admin_update_sort_order            
      params[:modification_value_ids].each_with_index do |mv_id, i|
        mv = ModificationValue.where(:id => mv_id).first
        mv.sort_order = i
        mv.save
      end      
      render :json => { :success => true }
    end
        
  end
end

