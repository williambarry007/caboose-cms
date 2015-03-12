require 'csv'

module Caboose
  class StoreController < ApplicationController
    layout 'caboose/admin'
    
    # GET /admin/store
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?      
    end
    
    # PUT /admin/store
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sc = @site.store_config
      sc = StoreConfig.create(:site_id => @site.id) if sc.nil?
          
      save = true
      params.each do |name,value|
        case name
          when 'site_id'                   then sc.site_id                   = value
          when 'pp_name'                   then sc.pp_name                   = value
          when 'pp_username'               then sc.pp_username               = value
          when 'pp_password'               then sc.pp_password               = value
          when 'pp_testing'                then sc.pp_testing                = value
          when 'pp_relay_domain'           then sc.pp_relay_domain           = value
          when 'ups_username'              then sc.ups_username              = value
          when 'ups_password'              then sc.ups_password              = value
          when 'ups_key'                   then sc.ups_key                   = value
          when 'ups_origin_account'        then sc.ups_origin_account        = value
          when 'usps_username'             then sc.usps_username             = value
          when 'usps_secret_key'           then sc.usps_secret_key           = value
          when 'usps_publishable_key'      then sc.usps_publishable_key      = value
          when 'fedex_username'            then sc.fedex_username            = value
          when 'fedex_password'            then sc.fedex_password            = value
          when 'fedex_key'                 then sc.fedex_key                 = value
          when 'fedex_account'             then sc.fedex_account             = value
          when 'taxcloud_api_id'           then sc.taxcloud_api_id           = value
          when 'taxcloud_api_key'          then sc.taxcloud_api_key          = value
          when 'origin_address1'           then sc.origin_address1           = value
          when 'origin_address2'           then sc.origin_address2           = value
          when 'origin_state'              then sc.origin_state              = value
          when 'origin_city'               then sc.origin_city               = value
          when 'origin_zip'                then sc.origin_zip                = value
          when 'origin_country'            then sc.origin_country            = value
          when 'fulfillment_email'         then sc.fulfillment_email         = value
          when 'shipping_email'            then sc.shipping_email            = value
          when 'handling_percentage'       then sc.handling_percentage       = value            
          when 'auto_calculate_packages'   then sc.auto_calculate_packages   = value
          when 'auto_calculate_shipping'   then sc.auto_calculate_shipping   = value
          when 'auto_calculate_tax'        then sc.auto_calculate_tax        = value
          when 'custom_packages_function'  then sc.custom_packages_function  = value   
          when 'custom_shipping_function'  then sc.custom_shipping_function  = value   
          when 'custom_tax_function'       then sc.custom_tax_function       = value        
          when 'length_unit'               then sc.length_unit               = value
          when 'weight_unit'               then sc.weight_unit               = value
          when 'download_url_expires_in'   then sc.download_url_expires_in   = value            
          when 'starting_order_number'     then sc.starting_order_number     = value                
    	  end
    	end
    	
    	resp.success = save && sc.save
    	render :json => resp
    end        
    
    # GET /admin/store/payment-processor-options
    def payment_processor_options
      return if !user_is_allowed('sites', 'view')
      options = [
        { 'value' => 'authorize.net'  , 'text' => 'Authorize.net' },
        { 'value' => 'stripe'         , 'text' => 'Stripe' }        
      ]
      render :json => options
    end
    
    # GET /admin/store/length-unit-options
    def length_unit_options
      return if !user_is_allowed('sites', 'view')
      options = [
        { 'value' => 'in' , 'text' => 'Inches (in)'     },
        { 'value' => 'ft' , 'text' => 'Feet (ft)'       },
        { 'value' => 'mm' , 'text' => 'Millimeter (mm)' },
        { 'value' => 'cm' , 'text' => 'Centimeter (cm)' },
        { 'value' => 'm'  , 'text' => 'Meter (m)'       }
      ]
      render :json => options
    end
    
    # GET /admin/store/weight-unit-options
    def weight_unit_options
      return if !user_is_allowed('sites', 'view')
      options = [
        { 'value' => 'oz' , 'text' => 'Ounces (oz)'    },
        { 'value' => 'lb' , 'text' => 'Pounds (lb)'    },
        { 'value' => 'g'  , 'text' => 'Grams (g)'      },
        { 'value' => 'kg' , 'text' => 'Kilograms (kg)' }
      ]
      render :json => options
    end
    
  end
end
