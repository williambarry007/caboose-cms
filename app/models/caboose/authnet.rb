
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
            "name"           => '9qR2qa4ZWn'        , # store_config.authnet_api_login_id,
            "transactionKey" => '386TLme2j8yp4BQy'  , # store_config.authnet_api_transaction_key
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
            "name"           => '9qR2qa4ZWn'       , # store_config.authnet_api_login_id
            "transactionKey" => '386TLme2j8yp4BQy' , # store_config.authnet_api_transaction_key
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
           
    #def self.form_url(invoice=nil)
    #  #if Rails.env == 'development'
    #  'https://test.authorize.net/gateway/transact.dll'
    #  #else
    #  #  'https://secure.authorize.net/gateway/transact.dll'
    #  #end
    #end
    #
    #def self.authorize(invoice, params)
    #  invoice.update_attribute(:transaction_id, params[:x_trans_id]) if params[:x_trans_id]
    #  return params[:x_response_code] == '1'
    #end
    #
    #def self.void(invoice)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    invoice.total,
    #    :transaction_type => 'VOID',
    #    :transaction_id => invoice.transaction_id
    #  )
    #  
    #  ap response
    #end
    #
    #def self.capture(invoice)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    invoice.total,
    #    :transaction_type => 'CAPTURE_ONLY',
    #    :transaction_id => invoice.transaction_id
    #  )
    #  
    #  ap response
    #end
    #
    #def self.refund(invoice)
    #  response = AuthorizeNet::SIM::Transaction.new(
    #    CabooseStore::authorize_net_login_id,
    #    CabooseStore::authorize_net_transaction_key,
    #    invoice.total,
    #    :transaction_type => 'CREDIT',
    #    :transaction_id => invoice.transaction_id
    #  )
    #  
    #  ap response
    #end
        
    def self.sync_invoice_transactions(site_id, d1, d2)
              
      site = Site.find(site_id)
      sc = site.store_config
      
      # Get all the batches in the date period
      rt = AuthorizeNet::Reporting::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)                      
      resp = rt.get_settled_batch_list(d1, d2, true)
      return false if !resp.success?          
      batch_ids = []
      batches = resp.batch_list
      batch_ids = batches.collect{ |batch| batch.id }
                  
      invoices = {}
      
      # Settled transactions
      batch_ids.each do |batch_id|              
        rt = AuthorizeNet::Reporting::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)
        resp = rt.get_transaction_list(batch_id)
        next if !resp.success?
        
        transactions = resp.transactions
        transactions.each do |t|
          invoice_id = t.invoice.invoice_num
          invoices[invoice_id] = [] if invoices[invoice_id].nil?
          invoices[invoice_id] << t
        end
      end
      
      # Unsettled transactions
      rt = AuthorizeNet::Reporting::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)
      resp = rt.get_unsettled_transaction_list
      if resp.success?        
        transactions = resp.transactions
        transactions.each do |t|           
          invoice_id = t.invoice.invoice_num
          invoices[invoice_id] = [] if invoices[invoice_id].nil?
          invoices[invoice_id] << t
        end
      end

      # Verify all the transactions exist locally
      invoices.each do |invoice_id, transactions|                        
        transactions.each do |t|
          self.verify_invoice_transaction_exists(t)                                                                
        end                                
      end
      
      # Update the financial_status and status of all affected invoices
      invoices.each do |invoice_id, transactions|      
        invoice = Invoice.where(:id => invoice_id).first
        next if invoice.nil?
        invoice.determine_statuses
      end                
    end
    
    def self.verify_invoice_transaction_exists(t)
      
      invoice_id = t.invoice.invoice_num
      ttype = InvoiceTransaction.type_from_authnet_status(t.status)
      
      ot = InvoiceTransaction.where(:invoice_id => invoice_id, :transaction_id => t.id, :transaction_type => ttype).first
      if ot   
        puts "Found invoice transaction for #{t.id}."
        return
      end
                
      puts "Creating invoice transaction for #{t.id}..."      
      ot = InvoiceTransaction.create(                      
        :invoice_id         => invoice_id,
        :transaction_id   => t.id,
        :transaction_type => ttype,
        :amount           => t.settle_amount,        
        :date_processed   => t.submitted_at,        
        :success          => !(t.status == 'declined')
      )
    end
    
        
  end
end
