module Caboose
  class StoreConfig < ActiveRecord::Base
    self.table_name = 'store_configs'    
    
    belongs_to :site    
    attr_accessible :id,
      :site_id,            
      :pp_name,
      :pp_testing,
      :authnet_api_login_id,        # pp_username
      :authnet_api_transaction_key, # pp_password      
      :authnet_relay_url,           # pp_relay_url
      :stripe_secret_key,
      :stripe_publishable_key,
      :ups_username,
      :ups_password,
      :ups_key,
      :ups_origin_account,
      :usps_username,
      :usps_secret_key,
      :usps_publishable_key,
      :fedex_username,
      :fedex_password,
      :fedex_key,
      :fedex_account,
      :ups_min,
      :ups_max,
      :usps_min,
      :usps_max,
      :fedex_min,                
      :fedex_max,
      :taxcloud_api_id,
      :taxcloud_api_key,
      :origin_country, 
      :origin_state, 
      :origin_city, 
      :origin_zip,           
      :fulfillment_email,
      :shipping_email,
      :handling_percentage,
      :auto_calculate_packages,
      :auto_calculate_shipping,
      :auto_calculate_tax,
      :custom_packages_function,   
      :custom_shipping_function,   
      :custom_tax_function,                  
      :length_unit,
      :download_instructions,
      :weight_unit
      
    WEIGHT_UNIT_METRIC   = 'g'
    WEIGHT_UNIT_IMPERIAL = 'oz'
    LENGTH_UNIT_METRIC   = 'cm'
    LENGTH_UNIT_IMPERIAL = 'in'
    
    PAYMENT_PROCESSOR_AUTHORIZENET
    PAYMENT_PROCESSOR_STRIPE
      
    def next_order_number
      x = Order.where("order_number is not null").reorder("order_number desc").limit(1).first
      return x.order_number + 1 if x
      return self.starting_order_number      
    end
        
  end
end
