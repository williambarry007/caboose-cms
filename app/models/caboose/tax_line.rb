module Caboose
  class TaxLine < ActiveRecord::Base
    attr_accessible :id,
      :title,           # The name of the tax, eg. QST or VAT
      :price,           # The amount
      :rate,            # The rate. It will return 0.175 if it is 17.5%
      :rate_percentage  # The tax rate in human readable form. It will return 17.5 if the rate is 0.175
  end
end
