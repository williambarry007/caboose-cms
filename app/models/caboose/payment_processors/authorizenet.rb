class Caboose::PaymentProcessors::Authorizenet < Caboose::PaymentProcessors::Base
  
  def self.api(root, body, test=false)
  end
  
  def self.form_url(invoice=nil)
    if Rails.env == 'development'
      'https://test.authorize.net/gateway/transact.dll'
    else
      'https://secure.authorize.net/gateway/transact.dll'
    end
  end
  
  def self.authorize(invoice, params)
    invoice.update_attribute(:transaction_id, params[:x_trans_id]) if params[:x_trans_id]
    return params[:x_response_code] == '1'
  end
  
  def self.void(invoice)
    sc = invoice.site.store_config
    response = AuthorizeNet::SIM::Transaction.new(
      sc.authnet_api_login_id, sc.authnet_api_transaction_key, invoice.total,
      :transaction_type => 'VOID',
      :transaction_id => invoice.transaction_id
    )    
    #ap response
  end
  
  def self.capture(invoice)
    sc = invoice.site.store_config
    response = AuthorizeNet::SIM::Transaction.new(
      sc.authnet_api_login_id, sc.authnet_api_transaction_key, invoice.total,
      :transaction_type => 'CAPTURE_ONLY',
      :transaction_id => invoice.transaction_id
    )    
    #ap response
  end
  
  def self.refund(invoice)
    sc = invoice.site.store_config
    response = AuthorizeNet::SIM::Transaction.new(
      sc.authnet_api_login_id, sc.authnet_api_transaction_key, invoice.total,
      :transaction_type => 'CREDIT',
      :transaction_id => invoice.transaction_id
    )    
    #ap response
  end
end
