module Caboose
  class StoreConfig < ActiveRecord::Base
    self.table_name = 'store_configs'    
    
    belongs_to :site    
    attr_accessible :id,
      :site_id,            
      :pp_name,     
      :pp_username,
      :pp_password,      
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
      :origin_country, 
      :origin_state, 
      :origin_city, 
      :origin_zip,           
      :fulfillment_email,
      :shipping_email,
      :handling_percentage,
      :calculate_packages,
      :shipping_rates_function,
      :length_unit,
      :weight_unit
        
  end
end
