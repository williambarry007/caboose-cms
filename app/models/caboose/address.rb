module Caboose
  class Address < ActiveRecord::Base
    self.table_name = 'store_addresses'
    
    attr_accessible :id,
      :name,
      :first_name,
      :last_name,
      :street,
      :address1,
      :address2,
      :company,
      :city,
      :state,
      :province,
      :province_code,
      :zip,
      :country,
      :country_code,
      :phone
    
    validates :first_name, :last_name, :address1, :city, :state, :zip, :presence => true
    validates :zip, :format => { :with => /^\d{5}(-\d{4})?$/, :message => 'Invalid zip code' }
  end
end

