
module Caboose
  class Authnet
                         
    # Sandbox URL:    https://apitest.authorize.net/xml/v1/request.api
    # Production URL: https://api.authorize.net/xml/v1/request.api
      
    # Locker room
    # 47G9Y5vvQt
    # 4U6zLSj9u5V4Cq8B

    # williambarry007
    # API Login ID: 9qR2qa4ZWn
    # Transaction Key: 386TLme2j8yp4BQy
    # Secret Question: Simon
    
    # Repconnex
    # api_login_id: 3a79FjaHV
    # api_transaction_key: 3K4v7n423KvA5R9P

    def self.create_customer_profile(store_config, user)      
      params = {
        "createCustomerProfileRequest" => {
          "merchantAuthentication" => {
            "name"           => '9qR2qa4ZWn', #store_config.pp_username,
            "transactionKey" => '386TLme2j8yp4BQy', #store_config.pp_password
          },
          "profile" => {
            "merchantCustomerId" => user.id,
            "description"        => "#{user.first_name} #{user.last_name}",
            "email"              => user.email            
          }          
        }
      }            
      resp = nil      
      resp = HTTParty.post('https://apitest.authorize.net/xml/v1/request.api', 
        :headers => { 'Content-Type' => 'application/json' }, 
        :body => params.to_json,
        :debug_output => $stdout
      )
      resp = JSON.parse(resp.body.to_s[1..-1])
      Caboose.log(resp)
      # See if we have a duplicate
      if resp['messages'] && 
         resp['messages']['resultCode'] && 
         resp['messages']['resultCode'] == 'Error' && 
         resp['messages']['message'][0]['code'] == 'E00039'
        
        Caboose.log("Error: duplicate customer profile.")
        str = resp['messages']['message'][0]['text']
        str.gsub!('A duplicate record with ID ', '')
        str.gsub!(' already exists.', '')
        user.customer_profile_id = str
        user.save
      end      
      return user.customer_profile_id
    end
            
    def self.hosted_profile_page_token(store_config, user)
      params = {
        "getHostedProfilePageRequest" => {
          "merchantAuthentication" => {
            "name"           => '9qR2qa4ZWn', #store_config.pp_username,
            "transactionKey" => '386TLme2j8yp4BQy', #store_config.pp_password
          },
          "customerProfileId" => user.customer_profile_id,
          "hostedProfileSettings" => {
            "setting" => [
              { "settingName" => "hostedProfileReturnUrl"         , "settingValue" => "https://google.com" },
              { "settingName" => "hostedProfileReturnUrlText"     , "settingValue" => "Continue to confirmation page." },
              { "settingName" => "hostedProfilePageBorderVisible" , "settingValue" => "true" }
            ]
          }
        }
      }
      resp = nil      
      resp = HTTParty.get('https://apitest.authorize.net/xml/v1/request.api', 
        :headers => { 'Content-Type' => 'application/json' }, 
        :body => params.to_json,
        :debug_output => $stdout
      )
      resp = JSON.parse(resp.body.to_s[1..-1])
      Caboose.log(resp)
      if resp['messages'] && resp['messages']['resultCode'] && resp['messages']['resultCode'] == 'Ok'
        return resp['token']
      end
      return nil         
    end
           
    #def self.form_url(order=nil)
    #  #if Rails.env == 'development'
    #  'https://test.authorize.net/gateway/transact.dll'
    #  #else
    #  #  'https://secure.authorize.net/gateway/transact.dll'
    #  #end
    #end
    #
    #def self.authorize(order, params)
    #  order.update_attribute(:transaction_id, params[:x_trans_id]) if params[:x_trans_id]
    #  return params[:x_response_code] == '1'
    #end
    #
    #def self.void(order)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    order.total,
    #    :transaction_type => 'VOID',
    #    :transaction_id => order.transaction_id
    #  )
    #  
    #  ap response
    #end
    #
    #def self.capture(order)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    order.total,
    #    :transaction_type => 'CAPTURE_ONLY',
    #    :transaction_id => order.transaction_id
    #  )
    #  
    #  ap response
    #end
    #
    #def self.refund(order)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    order.total,
    #    :transaction_type => 'CREDIT',
    #    :transaction_id => order.transaction_id
    #  )
    #  
    #  ap response
    #end
    
  end
end
