require 'csv'

module Caboose
  class StoreController < ApplicationController
    layout 'caboose/admin'
                  
    # @route GET /admin/store/json
    def admin_json_single
      return if !user_is_allowed('invoices', 'view')
      sc = @site.store_config
      render :json => sc
    end
    
    # @route GET /admin/store
    def admin_edit_general
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default            
    end
    
    # @route GET /admin/store/defaults
    def admin_edit_defaults
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default            
    end
    
    # @route GET /admin/store/payment
    def admin_edit_payment
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default
    end
    
    # @route GET /admin/store/shipping
    def admin_edit_shipping
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default
    end
    
    # @route GET /admin/store/tax
    def admin_edit_tax
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default
    end
    
    # @route GET /admin/store/packages
    def admin_edit_packages
      return if !user_is_allowed('sites', 'edit')
      @store_config = @site.store_config
      @store_config = StoreConfig.create(:site_id => @site.id) if @store_config.nil?
      @product_default = @site.product_default
      @variant_default = @site.variant_default
    end
    
    # @route PUT /admin/store
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sc = @site.store_config
      sc = StoreConfig.create(:site_id => @site.id) if sc.nil?
      pd = @site.product_default
      vd = @site.variant_default
          
      save = true
      params.each do |name,value|
        case name
          when 'site_id'                          then sc.site_id                          = value
          when 'pp_name'                          then sc.pp_name                          = value
          when 'pp_testing'                       then sc.pp_testing                       = value                              
          when 'authnet_api_login_id'             then sc.authnet_api_login_id             = value
          when 'authnet_api_transaction_key'      then sc.authnet_api_transaction_key      = value
          when 'authnet_relay_domain'             then sc.authnet_relay_domain             = value
          when 'stripe_secret_key'                then sc.stripe_secret_key                = value
          when 'stripe_publishable_key'           then sc.stripe_publishable_key           = value                                                          
          when 'ups_username'                     then sc.ups_username                     = value
          when 'ups_password'                     then sc.ups_password                     = value
          when 'ups_key'                          then sc.ups_key                          = value
          when 'ups_origin_account'               then sc.ups_origin_account               = value
          when 'usps_username'                    then sc.usps_username                    = value
          when 'usps_secret_key'                  then sc.usps_secret_key                  = value
          when 'usps_publishable_key'             then sc.usps_publishable_key             = value
          when 'fedex_username'                   then sc.fedex_username                   = value
          when 'fedex_password'                   then sc.fedex_password                   = value
          when 'fedex_key'                        then sc.fedex_key                        = value
          when 'fedex_account'                    then sc.fedex_account                    = value
          when 'ups_min'                          then sc.ups_min                          = value
          when 'ups_max'                          then sc.ups_max                          = value
          when 'usps_min'                         then sc.usps_min                         = value
          when 'usps_max'                         then sc.usps_max                         = value
          when 'fedex_min'                        then sc.fedex_min                        = value                
          when 'fedex_max'                        then sc.fedex_max                        = value        
          when 'taxcloud_api_id'                  then sc.taxcloud_api_id                  = value
          when 'taxcloud_api_key'                 then sc.taxcloud_api_key                 = value
          when 'origin_address1'                  then sc.origin_address1                  = value
          when 'origin_address2'                  then sc.origin_address2                  = value
          when 'origin_state'                     then sc.origin_state                     = value
          when 'origin_city'                      then sc.origin_city                      = value
          when 'origin_zip'                       then sc.origin_zip                       = value
          when 'origin_country'                   then sc.origin_country                   = value
          when 'fulfillment_email'                then sc.fulfillment_email                = value
          when 'shipping_email'                   then sc.shipping_email                   = value
          when 'handling_percentage'              then sc.handling_percentage              = value            
          when 'auto_calculate_packages'          then sc.auto_calculate_packages          = value
          when 'auto_calculate_shipping'          then sc.auto_calculate_shipping          = value
          when 'auto_calculate_tax'               then sc.auto_calculate_tax               = value          
          when 'custom_packages_function'         then sc.custom_packages_function         = value
          when 'custom_shipping_function'         then sc.custom_shipping_function         = value   
          when 'custom_tax_function'              then sc.custom_tax_function              = value        
          when 'length_unit'                      then sc.length_unit                      = value
          when 'weight_unit'                      then sc.weight_unit                      = value
          when 'download_instructions'            then sc.download_instructions            = value
          when 'download_url_expires_in'          then sc.download_url_expires_in          = value            
          when 'starting_invoice_number'          then sc.starting_invoice_number          = value
          when 'default_payment_terms'            then sc.default_payment_terms            = value
          when 'allow_instore_pickup'             then sc.allow_instore_pickup             = value
                                
          when 'product_vendor_id'                      then pd.vendor_id                      = value   
          when 'product_option1'                        then pd.option1                        = value
          when 'product_option2'                        then pd.option2                        = value
          when 'product_option3'                        then pd.option3                        = value
          when 'product_status'                         then pd.status                         = value
          when 'product_on_sale'                        then pd.on_sale                        = value
          when 'product_allow_gift_wrap'                then pd.allow_gift_wrap                = value
          when 'product_gift_wrap_price'                then pd.gift_wrap_price                = value
            
          when 'variant_site_id'                        then vd.site_id                        = value                    
          when 'variant_cost'                           then vd.cost                           = value
          when 'variant_price'                          then vd.price                          = value
          when 'variant_available'                      then vd.available                      = value
          when 'variant_quantity_in_stock'              then vd.quantity_in_stock              = value
          when 'variant_ignore_quantity'                then vd.ignore_quantity                = value
          when 'variant_allow_backorder'                then vd.allow_backorder                = value
          when 'variant_weight'                         then vd.weight                         = value
          when 'variant_length'                         then vd.length                         = value
          when 'variant_width'                          then vd.width                          = value
          when 'variant_height'                         then vd.height                         = value
          when 'variant_volume'                         then vd.volume                         = value
          when 'variant_cylinder'                       then vd.cylinder                       = value
          when 'variant_requires_shipping'              then vd.requires_shipping              = value
          when 'variant_taxable'                        then vd.taxable                        = value
          when 'variant_shipping_unit_value'            then vd.shipping_unit_value            = value
          when 'variant_flat_rate_shipping'             then vd.flat_rate_shipping             = value
          when 'variant_flat_rate_shipping_package_id'  then vd.flat_rate_shipping_package_id  = value
          when 'variant_flat_rate_shipping_method_id'   then vd.flat_rate_shipping_method_id   = value
          when 'variant_flat_rate_shipping_single'      then vd.flat_rate_shipping_single      = value
          when 'variant_flat_rate_shipping_combined'    then vd.flat_rate_shipping_combined    = value
          when 'variant_status'                         then vd.status                         = value
          when 'variant_downloadable'                   then vd.downloadable                   = value
          when 'variant_is_bundle'                      then vd.is_bundle                      = value
      
    	  end
    	end
    	
    	resp.success = save && sc.save && pd.save && vd.save
    	render :json => resp
    end        
    
    # @route GET /admin/store/:field-options    
    def admin_options
      return if !user_is_allowed('sites', 'view')
      
      options = []
      case params[:field]
        when 'payment-processor'            
          options = [
            { 'value' => 'authorize.net'  , 'text' => 'Authorize.net' },
            { 'value' => 'stripe'         , 'text' => 'Stripe' }        
          ]
        when 'length-unit'
          options = [
            { 'value' => 'in' , 'text' => 'Inches (in)'     },
            { 'value' => 'ft' , 'text' => 'Feet (ft)'       },
            { 'value' => 'mm' , 'text' => 'Millimeter (mm)' },
            { 'value' => 'cm' , 'text' => 'Centimeter (cm)' },
            { 'value' => 'm'  , 'text' => 'Meter (m)'       }
          ]
        when 'weight-unit'
          options = [
            { 'value' => 'oz' , 'text' => 'Ounces (oz)'    },
            { 'value' => 'lb' , 'text' => 'Pounds (lb)'    },
            { 'value' => 'g'  , 'text' => 'Grams (g)'      },
            { 'value' => 'kg' , 'text' => 'Kilograms (kg)' }
          ]
        when 'default-payment-terms'
          options = [
            { 'value' => Invoice::PAYMENT_TERMS_PIA   , 'text' => 'Pay In Advance' },
            { 'value' => Invoice::PAYMENT_TERMS_NET7  , 'text' => 'Net 7'          },
            { 'value' => Invoice::PAYMENT_TERMS_NET10 , 'text' => 'Net 10'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET30 , 'text' => 'Net 30'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET60 , 'text' => 'Net 60'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET90 , 'text' => 'Net 90'         },
            { 'value' => Invoice::PAYMENT_TERMS_EOM   , 'text' => 'End of Month'   }            
          ]
      end
      render :json => options
    end
                
  end
end
