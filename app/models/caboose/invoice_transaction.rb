module Caboose
  class InvoiceTransaction < ActiveRecord::Base
    self.table_name  = 'store_invoice_transactions'
    self.primary_key = 'id'
    
    belongs_to :invoice
    attr_accessible :id,    
      :invoice_id,
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
        when 'settledSuccessfully'        then InvoiceTransaction::TYPE_CAPTURE
        when 'voided'                     then InvoiceTransaction::TYPE_VOID
        when 'declined'                   then InvoiceTransaction::TYPE_AUTHORIZE
        when 'authorizedPendingCapture'   then InvoiceTransaction::TYPE_AUTHORIZE
        when 'refundSettledSuccessfully'  then InvoiceTransaction::TYPE_REFUND
      end
    end
    
  end
end
   
    