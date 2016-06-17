require 'csv'

module Caboose
  class ShippingPackagesController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
  
    # @route GET /admin/shipping-packages
    def admin_index
      return if !user_is_allowed('sites', 'view')            
    end
    
    # @route GET /admin/shipping-packages/json
    def admin_json
      return if !user_is_allowed('sites', 'view')
      
      pager = PageBarGenerator.new(params, {
          'site_id' => @site.id,    		  
    		},{
    		  'model'          => 'Caboose::ShippingPackage',
    	    'sort'			     => 'name',
    		  'desc'			     => false,
    		  'base_url'		   => "/admin/shipping-packages",
    		  'use_url_params' => false
    	})
    	render :json => {
    	  :pager => pager,
    	  :models => pager.items.as_json(:include => :shipping_methods)
    	}    	      	  
    end
    
    # @route GET /admin/shipping-packages/new
    def admin_new
      return if !user_is_allowed('sites', 'add')
      @shipping_package = ShippingPackage.new      
    end
    
    # @route GET /admin/shipping-packages/:id/json
    def admin_json_single
      return if !user_is_allowed('sites', 'edit')
      sp = ShippingPackage.find(params[:id])
      render :json => sp.as_json(:include => :shipping_methods)
    end
    
    # @route GET /admin/shipping-packages/:id
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      @shipping_package = ShippingPackage.find(params[:id])      
    end
        
    # @route POST /admin/shipping-packages
    def admin_add
      return if !user_is_allowed('sites', 'add')
      
      resp = StdClass.new
                              
      if    params[:inside_length].strip.length  == 0 then resp.error = "Please enter a valid inside length."
      elsif params[:inside_width ].strip.length  == 0 then resp.error = "Please enter a valid inside width."
      elsif params[:inside_height].strip.length  == 0 then resp.error = "Please enter a valid inside height."
      elsif params[:outside_length].strip.length == 0 then resp.error = "Please enter a valid outside length."
      elsif params[:outside_width ].strip.length == 0 then resp.error = "Please enter a valid outside width."
      elsif params[:outside_height].strip.length == 0 then resp.error = "Please enter a valid outside height."
      else

        sp = ShippingPackage.new(
          :site_id         => @site.id,
          :name            => params[:name].strip,
          :inside_length   => params[:inside_length].to_f,
          :inside_width    => params[:inside_width ].to_f,
          :inside_height   => params[:inside_height].to_f,
          :outside_length  => params[:outside_length].to_f,
          :outside_width   => params[:outside_width ].to_f,
          :outside_height  => params[:outside_height].to_f
        )
        sp.volume = sp.inside_length * sp.inside_width * sp.inside_height
        sp.save        
        resp.redirect = "/admin/sites/#{@site.id}/shipping-packages/#{sp.id}"
        
      end
      
      render :json => resp
    end
    
    # @route POST /admin/shipping-packages/bulk
    def admin_bulk_add
      return if !user_is_allowed('sites', 'add')
      
      resp = Caboose::StdClass.new

      i = 0
      CSV.parse(params[:csv_data].strip).each do |row|
           if row[1].nil? || row[0].strip.length == 0 then resp.error = "Inside Length  not defined on row #{i+1}."
        elsif row[2].nil? || row[1].strip.length == 0 then resp.error = "Inside Width   not defined on row #{i+1}."
        elsif row[3].nil? || row[2].strip.length == 0 then resp.error = "Inside Height  not defined on row #{i+1}."
        elsif row[4].nil? || row[3].strip.length == 0 then resp.error = "Outside Length  not defined on row #{i+1}."
        elsif row[5].nil? || row[4].strip.length == 0 then resp.error = "Outside Width   not defined on row #{i+1}."
        elsif row[6].nil? || row[5].strip.length == 0 then resp.error = "Outside Height  not defined on row #{i+1}."
        end
        i = i + 1
      end
      
      if resp.error.nil?
        CSV.parse(params[:csv_data]).each do |row|
          sp = Caboose::ShippingPackage.new(
            :site_id  => @site.id,
            :name => row[0].strip,            
            :inside_length   => row[1].to_f,
            :inside_width    => row[2].to_f,
            :inside_height   => row[3].to_f,
            :outside_length  => row[4].to_f,
            :outside_width   => row[5].to_f,
            :outside_height  => row[6].to_f            
          )                      
          sp.volume = sp.inside_length * sp.inside_width * sp.inside_height
          sp.save
        end
        resp.success = true
      end
      
      render :json => resp
    end
    
    # @route PUT /admin/shipping-packages/:id
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sp = ShippingPackage.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'site_id'            then sp.site_id             = value  
          when 'name'               then sp.name                = value
          when 'inside_length'      then sp.inside_length       = value.to_f
          when 'inside_width'       then sp.inside_width        = value.to_f
          when 'inside_height'      then sp.inside_height       = value.to_f
          when 'outside_length'     then sp.outside_length      = value.to_f
          when 'outside_width'      then sp.outside_width       = value.to_f
          when 'outside_height'     then sp.outside_height      = value.to_f
          when 'volume'             then sp.volume              = value.to_f
          when 'empty_weight'       then sp.empty_weight        = value.to_f
          when 'cylinder'           then sp.cylinder            = value.to_i
          when 'flat_rate_price'    then sp.flat_rate_price     = value.to_f
          when 'priority'           then sp.priority            = value.to_i
          when 'shipping_method_id' then sp.toggle_shipping_method(value[0], value[1])          
        end
    	end
    	
    	resp.success = save && sp.save
    	render :json => resp
    end    

    # @route PUT /admin/:shipping-packages/bulk
    def admin_bulk_update
      return unless user_is_allowed_to 'edit', 'sites'
    
      resp = Caboose::StdClass.new    
      shipping_packages = params[:model_ids].collect{ |sp_id| ShippingPackage.find(sp_id) }
    
      save = true
      params.each do |k,v|
        case k
          when 'site_id'            then shipping_packages.each{ |sp| sp.site_id             = v            }          
          when 'name'               then shipping_packages.each{ |sp| sp.name                = v            }
          when 'inside_length'      then shipping_packages.each{ |sp| sp.inside_length       = v.to_f       }
          when 'inside_width'       then shipping_packages.each{ |sp| sp.inside_width        = v.to_f       }
          when 'inside_height'      then shipping_packages.each{ |sp| sp.inside_height       = v.to_f       }
          when 'outside_length'     then shipping_packages.each{ |sp| sp.outside_length      = v.to_f       }
          when 'outside_width'      then shipping_packages.each{ |sp| sp.outside_width       = v.to_f       }
          when 'outside_height'     then shipping_packages.each{ |sp| sp.outside_height      = v.to_f       }
          when 'volume'             then shipping_packages.each{ |sp| sp.height              = v.to_f       }
          when 'empty_weight'       then shipping_packages.each{ |sp| sp.empty_weight        = v.to_f       }
          when 'cylinder'           then shipping_packages.each{ |sp| sp.cylinder            = v.to_i       }
          when 'flat_rate_price'    then shipping_packages.each{ |sp| sp.flat_rate_price     = v.to_f       }
          when 'priority'           then shipping_packages.each{ |sp| sp.priority            = v.to_i       }
          when 'shipping_method_id' then shipping_packages.each{ |sp| sp.toggle_shipping_method(v[0], v[1]) }
        end        
      end
      shipping_packages.each{ |sp| sp.save }
    
      resp.success = true
      render :json => resp
    end    
      
    # @route DELETE /admin/shipping-packages/:id
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
      sp = ShippingPackage.find(params[:id])
      sp.destroy
      
      resp = StdClass.new({ 'redirect' => "/admin/shipping-packages" })
      render :json => resp
    end
    
    # @route DELETE /admin/shipping-packages/:id/bulk    
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
            
    # @route_priority 1
    # @route GET /admin/shipping-packages/options
    def options
      return if !user_is_allowed('sites', 'view')
      options = ShippingPackage.where(:site_id => @site.id).reorder('service_name').all.collect { |sp| { 'value' => sp.id, 'text' => sp.service_name }}
      render :json => options
    end
        
    # @route_priority 3
    # @route GET /admin/shipping-methods/options
    # @route GET /admin/shipping-packages/:id/shipping-method-options
    def admin_shipping_method_options
      options = nil
      if params[:id]
        sp = ShippingPackage.find(params[:id])
        options = sp.shipping_methods.reorder(:carrier, :service_name).all.collect { |sm| { :value => sm.id, :text => sm.service_name }}
      else
        options = ShippingMethod.reorder(:carrier, :service_name).all.collect { |sm| { :value => sm.id, :text => "#{sm.service_code} - #{sm.service_name}" }}        
      end
      render :json => options              
    end
    
    # @route_priority 2
    # @route GET /admin/shipping-packages/package-method-options
    def admin_package_method_options      
      return if !user_is_allowed('sites', 'view')
      options = []
      ShippingPackage.where(:site_id => @site.id).reorder('name').all.each do |sp|
        prefix = sp.name ? sp.name : "#{sp.outside_length}x#{sp.outside_width}x#{sp.outside_height}"
        sp.shipping_methods.reorder("carrier, service_name").each do |sm|
          options << { 'value' => "#{sp.id}_#{sm.id}", 'text' => "#{prefix} - #{sm.carrier} - #{sm.service_name}" }
        end
      end
      render :json => options
    end

  end
end
