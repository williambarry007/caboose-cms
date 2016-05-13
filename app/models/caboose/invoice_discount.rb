module Caboose        
  class InvoiceDiscount < ActiveRecord::Base
    self.table_name = 'store_invoice_discounts'
    
    belongs_to :invoice
    belongs_to :discount
    
    attr_accessible :invoice_id, :discount_id
  end
end
