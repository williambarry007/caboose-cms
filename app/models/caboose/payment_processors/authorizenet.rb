class Caboose::PaymentProcessors::Authorizenet < Caboose::PaymentProcessors::Base
  def self.api(root, body, test=false)
  end
  
  def self.form_url(order=nil)
    #if Rails.env == 'development'
    'https://test.authorize.net/gateway/transact.dll'
    #else
    #  'https://secure.authorize.net/gateway/transact.dll'
    #end
  end
  
  def self.authorize(order, params)
    order.update_attribute(:transaction_id, params[:x_trans_id]) if params[:x_trans_id]
    return params[:x_response_code] == '1'
  end
  
  def self.void(order)
    response = AuthorizeNet::SIM::Transaction.new(
      Caboose::authorize_net_login_id,
      Caboose::authorize_net_transaction_key,
      order.total,
      :transaction_type => 'VOID',
      :transaction_id => order.transaction_id
    )
    
    ap response
  end
  
  def self.capture(order)
    response = AuthorizeNet::SIM::Transaction.new(
      Caboose::authorize_net_login_id,
      Caboose::authorize_net_transaction_key,
      order.total,
      :transaction_type => 'CAPTURE_ONLY',
      :transaction_id => order.transaction_id
    )
    
    ap response
  end
  
  def self.refund(order)
    response = AuthorizeNet::SIM::Transaction.new(
      Caboose::authorize_net_login_id,
      Caboose::authorize_net_transaction_key,
      order.total,
      :transaction_type => 'CREDIT',
      :transaction_id => order.transaction_id
    )
    
    ap response
  end
end
