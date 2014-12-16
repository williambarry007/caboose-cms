require 'csv'

module Caboose
  class ShippingPackagesController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
  
    # GET /admin/sites/:site_id/shipping-packages
    def admin_index
      return if !user_is_allowed('sites', 'view')            
    end
    
    # GET /admin/sites/:site_id/shipping-packages/json
    def admin_json
      return if !user_is_allowed('sites', 'view')
      
      pager = PageBarGenerator.new(params, {
          'site_id' => @site.id,    		  
    		},{
    		  'model'          => 'Caboose::ShippingPackage',
    	    'sort'			     => 'shipping_method_id',
    		  'desc'			     => false,
    		  'base_url'		   => "/admin/sites/#{@site.id}/shipping-packages",
    		  'use_url_params' => false
    	})
    	render :json => {
    	  :pages => pager,
    	  :models => pager.items
    	}    	      	  
    end
    
    # GET /admin/sites/:site_id/shipping-packages/new
    def admin_new
      return if !user_is_allowed('sites', 'add')
      @shipping_package = ShippingPackage.new      
    end
    
    # GET /admin/sites/:site_id/shipping-packages/:id
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      @shipping_package = ShippingPackage.find(params[:id])      
    end
    
    # GET /admin/sites/:site_id/shipping-packages/:id/json
    def admin_json_single
      return if !user_is_allowed('sites', 'edit')
      sp = ShippingPackage.find(params[:id])
      render :json => sp      
    end
    
    # GET /admin/sites/:site_id/shipping-packages/:id/delete
    def admin_delete_form
      return if !user_is_allowed('sites', 'edit')
      @shipping_package = ShippingPackage.find(params[:id])      
    end
        
    # POST /admin/sites/:site_id/shipping-packages
    def admin_add
      return if !user_is_allowed('sites', 'add')
      
      resp = StdClass.new
                  
      if    params[:shipping_method_id].strip.length == 0 then resp.error = "Please select a shipping method."      
      elsif params[:length].strip.length             == 0 then resp.error = "Please enter a valid length."
      elsif params[:width ].strip.length             == 0 then resp.error = "Please enter a valid width."
      elsif params[:height].strip.length             == 0 then resp.error = "Please enter a valid height."
      else

        sp = ShippingPackage.new(
          :site_id            => @site.id,
          :shipping_method_id => params[:shipping_method_id],          
          :length             => params[:length].to_f,
          :width              => params[:width ].to_f,
          :height             => params[:height].to_f        
        )
        sp.volume = sp.length * sp.width * sp.height
        sp.save        
        resp.redirect = "/admin/sites/#{@site.id}/shipping-packages/#{sp.id}"
        
      end
      
      render :json => resp
    end
    
    # POST /admin/products/:product_id/variants/bulk
    def admin_bulk_add
      return if !user_is_allowed('sites', 'add')
      
      resp = Caboose::StdClass.new

      i = 0
      CSV.parse(params[:csv_data].strip).each do |row|        
        if    row[0].nil? || row[0].strip.length == 0 then resp.error = "Shipping method not defined on row #{i+1}."        
        elsif row[3].nil? || row[1].strip.length == 0 then resp.error = "Length       not defined on row #{i+1}."
        elsif row[4].nil? || row[2].strip.length == 0 then resp.error = "Width        not defined on row #{i+1}."
        elsif row[5].nil? || row[3].strip.length == 0 then resp.error = "Height       not defined on row #{i+1}."                
        end
        i = i + 1
      end
      
      if resp.error.nil?
        CSV.parse(params[:csv_data]).each do |row|
          sp = Caboose::Variant.new(
            :site_id            => @site.id,
            :shipping_method_id => row[0],            
            :length             => row[1].to_f,
            :width              => row[2].to_f,
            :height             => row[3].to_f
          )                      
          sp.save
        end
        resp.success = true
      end
      
      render :json => resp
    end
    
    # PUT /admin/sites/:site_id/shipping-packages/:id
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sp = ShippingPackage.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'site_id'            then sp.site_id             = value
          when 'shipping_method_id' then sp.shipping_method_id  = value          
          when 'length'             then sp.length              = value.to_f
          when 'width'              then sp.width               = value.to_f
          when 'height'             then sp.height              = value.to_f
        end                    
    	end
    	
    	resp.success = save && sp.save
    	render :json => resp
    end        
      
    # DELETE /admin/sites/:site_id/shipping-packages/:id
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
      sp = ShippingPackage.find(params[:id])
      sp.destroy
      
      resp = StdClass.new({
        'redirect' => "/admin/sites/#{@site.id}/shipping-packages"
      })
      render :json => resp
    end
    
    # DELETE /admin/sites/:site_id/shipping-packages/:id/bulk    
    def admin_bulk_delete
      return if !user_is_allowed('sites', 'delete')
      
      resp = Caboose::StdClass.new
      params[:model_ids].each do |sp_id|
        sp = ShippingPackage.find(sp_id)
        sp.destroy        
      end
      resp.success = true
      render :json => resp
    end
            
    # GET /admin/sites/:site_id/shipping-packages/options
    def options
      return if !user_is_allowed('sites', 'view')
      options = ShippingPackage.where(:site_id => @site.id).reorder('service_name').all.collect { |sp| { 'value' => sp.id, 'text' => sp.service_name }}
      render :json => options
    end
    
    # GET /admin/sites/:site_id/shipping-packages/shipping-method-options
    def admin_shipping_method_options
      options = ShippingMethod.reorder(:carrier, :service_name).all.collect { |sm| { :value => sm.id, :text => sm.service_name }}
      render :json => options              
    end

  end
end
