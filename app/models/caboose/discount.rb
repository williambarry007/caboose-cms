module Caboose
  class Discount < ActiveRecord::Base
    self.table_name  = 'store_discounts'
    self.primary_key = 'id'
    
    attr_accessible :id,
      :name,              # The name of this discount
      :code,              # The code the customer has to input to apply for this discount
      :amount_current,
      :amount_total,
      :amount_flat,       # Amount of the savings flat off the total
      :amount_percentage, # Amount of savings as a percentage off the total
      :no_shipping,       # Whether or not it's a free shipping discount
      :no_tax             # Whether or not it's a free shipping discount
  end
end
