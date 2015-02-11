module Caboose
  class OrderTransaction < ActiveRecord::Base
    self.table_name  = 'store_order_transactions'
    self.primary_key = 'id'
    
    belongs_to :order
    attr_accessible :id,    
      :order_id,
      :transaction_id,
      :transaction_type,
      :amount,
      :auth_code,
      :date_processed,
      :response_code,
      :success 
        
    TYPE_AUTHORIZE = 'auth'
    TYPE_CAPTURE   = 'capture'
    TYPE_VOID      = 'void'
    TYPE_REFUND    = 'refund'
    
    after_initialize :check_nil_fields
    
    def check_nil_fields
      self.amount = 0.00 if self.amount.nil?        
    end
    
  end
end
   
    