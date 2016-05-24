module Caboose
  class ModificationsController < Caboose::ApplicationController
    
    # @route GET /admin/products/:product_id/modifications/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      p = Product.find(params[:product_id])
      render :json => p.modifications.as_json(:include => :modification_values)            
    end
    
    # @route GET /admin/products/:product_id/modifications/:id/json
    def admin_json_single
      m = Modification.find(params[:id])
      render :json => m.as_json(:include => :modification_values)      
    end
          
    # @route PUT /admin/products/:product_id/modifications/:id    
    def admin_update
      return if !user_is_allowed('products', 'edit')
      
      resp = Caboose::StdClass.new
      m = Modification.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name          
          when 'name' then m.name = value                                    
        end
      end
      resp.success = save && m.save
      render :json => resp
    end
    
    # @route POST /admin/products/:product_id/modifications
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new
      name = params[:name]
            
      if name.length == 0
        resp.error = "The name cannot be empty."
      else
        m = Modification.new(:product_id => params[:product_id], :name => name)                  
        m.save
        resp.success = true        
      end
      render :json => resp    
    end
    
    # @route DELETE /admin/products/:product_id/modifications/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      m = Modification.find(params[:id]).destroy      
      render :json => Caboose::StdClass.new({
        :success => true
      })
    end
    
    # @route_priority 1
    # @route PUT /admin/products/:product_id/modifications/sort-order
    def admin_update_sort_order            
      params[:modification_ids].each_with_index do |mod_id, i|
        m = Modification.where(:id => mod_id).first
        m.sort_order = i
        m.save
      end      
      render :json => { :success => true }
    end
        
  end
end

