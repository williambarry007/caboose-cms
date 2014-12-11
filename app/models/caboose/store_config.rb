module Caboose
  class StoreConfig < ActiveRecord::Base
    self.table_name = 'store_configs'
    belongs_to :site    
    attr_accessible :id,
      :site_id,            
      :pp_name,     
      :pp_username,
      :pp_password,
      :use_usps,
      :usps_secret_key,
      :usps_publishable_key,
      :allowed_shipping_codes, # ['0','7','6','1','2','3'],
      :default_shipping_code,      
      :origin_country, 
      :origin_state, 
      :origin_city, 
      :origin_zip,           
      :fulfillment_email,
      :shipping_email,
      :handling_percentage      
  end
end
