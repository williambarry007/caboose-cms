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
    TYPE_AUTHCAP   = 'authcap'    
    TYPE_VOID      = 'void'
    TYPE_REFUND    = 'refund'
    
    after_initialize :check_nil_fields
    
    def check_nil_fields
      self.amount = 0.00 if self.amount.nil?        
    end
    
    def self.type_from_authnet_status(status)
      case status
        when 'settledSuccessfully'        then OrderTransaction::TYPE_CAPTURE
        when 'voided'                     then OrderTransaction::TYPE_VOID
        when 'declined'                   then OrderTransaction::TYPE_AUTHORIZE
        when 'authorizedPendingCapture'   then OrderTransaction::TYPE_AUTHORIZE
        when 'refundSettledSuccessfully'  then OrderTransaction::TYPE_REFUND
      end
    end
    
  end
end
   
    