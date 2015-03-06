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

    def name_and_address
      str = "#{self.first_name} #{self.last_name}"
      str << "<br />#{self.address1}"      
      str << "<br />#{self.address2}" if self.address2 && self.address2.length > 0
      str << "<br />#{self.city}, #{self.state} #{self.zip}"
      return str
    end
    
  end
end

