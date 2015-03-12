module Caboose
  class StoreConfig < ActiveRecord::Base
    self.table_name = 'store_configs'    
    
    belongs_to :site    
    attr_accessible :id,
      :site_id,            
      :pp_name,     
      :pp_username,
      :pp_password,
      :pp_testing,
      :pp_relay_url,      
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
      :weight_unit
      
    def next_order_number
      x = Order.where("order_number is not null").reorder("order_number desc").limit(1).first
      return x.order_number + 1 if x
      return self.starting_order_number      
    end
        
  end
end
