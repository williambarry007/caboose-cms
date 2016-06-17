require 'activemerchant'

module Caboose
  class Authnet
    
    @api_login_id = false
    @api_transaction_key = false    

    def initialize(login_id, trans_key)
      @api_login_id = login_id
      @api_transaction_key = trans_key
    end
    
    def gateway
      return @_gateway if @_gateway
      @_gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
        :login    => @api_login_id,
        :password => @api_transaction_key,
        :test     => false
      )
      return @_gateway
    end
    
    #=============================================================================
    # Create or update the CIM record in authorize.net for the given user.
    def customer_profile(user)
      resp = Caboose::StdClass.new('success' => true)    
      options = { :profile => { :merchant_customer_id => user.id, :email => user.email }}
      
      if user.authnet_customer_profile_id.nil? || user.authnet_customer_profile_id.strip.length == 0 # No customer profile, so create it 
        response = self.gateway.create_customer_profile(options)
        if response.success?
          user.authnet_customer_profile_id = response.params['customer_profile_id']
          user.save
        elsif response.message.starts_with?("A duplicate record with ID ")
          user.authnet_customer_profile_id = response.message.gsub("A duplicate record with ID ", '').gsub(" already exists.", '')
          user.save
        else
          resp.success = false
          resp.error = "A fatal error occured, the web administrator has been notified. Please try again later."        
        end        	
      else # Update the profile
        options[:profile][:customer_profile_id] = user.authnet_customer_profile_id      
        response = self.gateway.update_customer_profile(options)    
        if !response.success?
          resp.success = false
          resp.error = "A fatal error occured, the web administrator has been notified. Please try again later."        
        end
      end
      return resp 
    end
    
    #=============================================================================
    # Create or update the authorize.net payment profile for the given user.
    def payment_profile(user, params)
      resp = Caboose::StdClass.new('success' => true)            
      response = nil
      
      card_num = params[:credit_card][:number]
      user.card_brand = 'Amex'       if card_num.starts_with?('3')   
      user.card_brand = 'Visa'       if card_num.starts_with?('4')   
      user.card_brand = 'MasterCard' if card_num.starts_with?('5')   
      user.card_brand = 'Discover'   if card_num.starts_with?('6011')
      user.save
    
      # Make sure the customer profile exists    
      if user.authnet_customer_profile_id.nil?      
        response = self.customer_profile(user)
        if !response.success
          user.authnet_customer_profile_id = nil
          user.authnet_payment_profile_id = nil
          user.save
          resp.error = "Error creating customer profile."
        else
          user.authnet_payment_profile_id = nil
          user.save
        end
      end
    
      # Now see if the payment profile exists
      if user.authnet_customer_profile_id && user.authnet_payment_profile_id
        options = payment_profile_options(user, params)
        options[:payment_profile][:customer_payment_profile_id] = user.authnet_payment_profile_id
        response = self.gateway.update_customer_payment_profile(options)            
        if response.success?
          user.authnet_payment_profile_id = response.params['customer_payment_profile_id']        
          user.save        
          resp.success = true
        elsif response.message == 'ProfileID is invalid.'
          user.authnet_customer_profile_id = nil
          user.authnet_payment_profile_id = nil
          user.save
          resp.error = "Invalid customer profile ID. Please submit again."
        elsif response.message == "The credit card number is invalid."
          resp.error = "The credit card number is invalid."
        elsif response.message == "This transaction has been declined."                
          resp.error = "We couldn't validate the credit card information."
        elsif response.message == "A duplicate transaction has been submitted." # The user submitted the same information within two minutes                
          resp.error = "We couldn't validate the credit card information."
        else        
          puts "=================================================================="
          puts "Response from gateway.update_customer_payment_profile(#{options})"
          puts ""
          puts response.message
          puts ""
          puts response.inspect
          puts "=================================================================="
          user.authnet_payment_profile_id = nil
          user.save        
        end
      end
      
      if user.authnet_customer_profile_id && user.authnet_payment_profile_id.nil?
        options = payment_profile_options(user, params)
        response = self.gateway.create_customer_payment_profile(options)            
        if response.success?        
          user.authnet_payment_profile_id = response.params['customer_payment_profile_id']        
          user.save
          resp.success = true        
        elsif response.message == "A duplicate customer payment profile already exists."
          response = self.gateway.get_customer_profile({ :customer_profile_id => user.authnet_customer_profile_id })        
          if response.success?
            arr = response.params['profile']['payment_profiles']
            arr = [arr] if arr.is_a?(Hash)
            arr.each do |h|
              if h['payment'] && h['payment']['credit_card'] && h['payment']['credit_card']['card_number']
                x = h['payment']['credit_card']['card_number'].split(//).last(4).join("")
                y = params[:credit_card][:number].split(//).last(4).join("")            
                if x == y
                  user.authnet_payment_profile_id = h['customer_payment_profile_id']
                  user.save
                  break
                end
              end
            end
          end
        elsif response.message == "The credit card number is invalid."                
          resp.error = "The credit card number is invalid."
        elsif response.message == "This transaction has been declined."        
          resp.error = "We couldn't validate the credit card information."
        elsif response.message == "A duplicate transaction has been submitted." # The user submitted the same information within two minutes        
          resp.error = "We couldn't validate the credit card information."
        else
          puts "=================================================================="
          puts "Response from gateway.create_customer_payment_profile(#{options})"
          puts ""
          puts response.message
          puts ""
          puts response.inspect
          puts "=================================================================="
          resp.error = "A fatal error occured, the web administrator has been notified. Please try again later."
        end          
      end
      return resp
    end
    
    #============================================================================= 
    # Returns the options hash for the gateway.create_customer_payment_profile method.  
    def payment_profile_options(user, params)
      bt_address = "#{params[:billing][:address]}"
      bt_address << ", #{params[:billing][:address2]}" if params[:billing][:address2] && params[:billing][:address2].strip.length > 0          
                
      return {      
        :customer_profile_id => user.authnet_customer_profile_id.to_i,      
        :payment_profile => {
          :bill_to => {
            :first_name   => params[:billing][:first_name],
            :last_name    => params[:billing][:last_name],
            :address      => bt_address,
            :city         => params[:billing][:city],
            :state        => params[:billing][:state],
            :zip          => params[:billing][:zip],
            :phone_number => user.phone,
            :email        => user.email
          },        
          :payment => {
            :credit_card => Caboose::StdClass.new({
              :number     => params[:credit_card][:number],
              :month      => params[:credit_card][:expiration_month].to_i,
              :year       => "20#{params[:credit_card][:expiration_year].to_i}",
              :first_name => params[:billing][:first_name],
              :last_name  => params[:billing][:last_name]
            })
          }
        },
        :validation_mode => :live
      }
    end
    
    #=============================================================================
    # Verifies that the given user has a CIM record.
    def verify_customer_profile(user)
    
      if user.authnet_customer_profile_id
        resp = self.gateway.get_customer_profile({ :customer_profile_id => user.authnet_customer_profile_id })
        if resp.success? # The profile id is valid
          return true
        else
          user.authnet_customer_profile_id = nil
          user.save
        end
      end
    
      # No customer profile, so create it 
      resp = self.gateway.create_customer_profile({ :profile => { :merchant_customer_id => user.id, :email => user.email }})
      Caboose.log(resp.inspect)
      if resp.success?
        user.authnet_customer_profile_id = resp.params['customer_profile_id']
        user.save
      elsif resp.message.starts_with?("A duplicate record with ID ")
        user.authnet_customer_profile_id = resp.message.gsub("A duplicate record with ID ", '').gsub(" already exists.", '')
        user.save
      else
        Caboose.log("Error creating authnet customer profile for user #{user.id}")
        return false                
      end
      return true         
    end
    
    #=============================================================================
    # Verifies that the user has a payment profile and that the payment profile is valid.
    # Creates an empty payment profile for the user if the payment profile is missing or invalid.  
    def verify_payment_profile(user)            
      resp = self.gateway.get_customer_profile({ :customer_profile_id => user.authnet_customer_profile_id })      
      if resp.success?
        arr = resp.params['profile']['payment_profiles']      
        arr = [arr] if arr && arr.is_a?(Hash)
        if arr.nil? || arr.count == 0
          self.create_empty_payment_profile(user)
          user.valid_authnet_payment_profile_id = false        
        else                
          h = arr[0]
          user.authnet_payment_profile_id = h['customer_payment_profile_id']                 
          user.valid_authnet_payment_profile_id = h['bill_to'] && h['bill_to']['address'] && h['bill_to']['address'].strip.length > 0                    
          user.save
        end
      end    
    end
    
    #=============================================================================
    # Create empty payment profile  
    def create_empty_payment_profile(user)      
      options = {
        :customer_profile_id => user.authnet_customer_profile_id.to_i,      
        :payment_profile => {
          :bill_to => { :first_name => user.first_name, :last_name => user.last_name, :address => '', :city => '', :state => '', :zip => '', :phone_number => '', :email => user.email },        
          :payment => { :credit_card => Caboose::StdClass.new({ :number => '4111111111111111', :month => 1, :year => 2020, :first_name => user.first_name, :last_name => user.last_name }) }
        }
        #, :validation_mode => :live
      }    
      resp = self.gateway.create_customer_payment_profile(options)            
      if resp.success?        
        user.authnet_payment_profile_id = resp.params['customer_payment_profile_id']        
        user.save
      else
        puts "=================================================================="            
        puts resp.message
        puts ""
        puts resp.inspect
        puts "=================================================================="
      end
    end
    
    #============================================================================= 
    # Get hosted profile token
    #=============================================================================
    
    def get_hosted_profile_page_request(profile_id, return_url)
        
      xml = ""
      xml << "<?xml version=\"1.0\"?>\n"
      xml << "<getHostedProfilePageRequest xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\">\n"    
      xml << "  <merchantAuthentication>\n"             
      xml << "    <name>#{@api_login_id}</name>\n"
      xml << "    <transactionKey>#{@api_transaction_key}</transactionKey>\n"
      xml << "  </merchantAuthentication>\n"
      xml << "  <customerProfileId>#{profile_id}</customerProfileId>\n"
      xml << "  <hostedProfileSettings>\n"
      xml << "    <setting><settingName>hostedProfilePageBorderVisible</settingName><settingValue>false</settingValue></setting>\n"
      xml << "    <setting><settingName>hostedProfileHeadingBgColor</settingName><settingValue>#ffffff</settingValue></setting>\n"
      xml << "    <setting><settingName>hostedProfileBillingAddressRequired</settingName><settingValue>true</settingValue></setting>\n"
      xml << "    <setting><settingName>hostedProfileCardCodeRequired</settingName><settingValue>true</settingValue></setting>\n"
      xml << "    <setting><settingName>hostedProfileReturnUrl</settingName><settingValue>#{return_url}</settingValue></setting>\n"
      xml << "  </hostedProfileSettings>\n"
      xml << "</getHostedProfilePageRequest>\n"
      
      response = HTTParty.post('https://api.authorize.net/xml/v1/request.api', { :body => xml, :headers => { 'Content-Type' => 'text/xml' }})
      #Caboose.log(response.body)
      
      # Note: Can't parse response with httparty because of namespace issue in the 
      #       response xml. Have to strip the namespace out before parsing.            
      str = response.body.gsub("xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"", '')
      xml = Nokogiri::XML(str)
      token_nodes = xml.xpath('//getHostedProfilePageResponse//token')
      token = token_nodes ? token_nodes.first.content : nil
      #Caboose.log(token)
      
      return token    
    end
    
    #=============================================================================
    # Get card number from profile
    #=============================================================================
    def get_card_suffix(user)
      card_number = nil
      if user.valid_authnet_payment_profile_id && user.authnet_payment_profile_id
        resp = self.gateway.get_customer_payment_profile({
          :customer_profile_id => user.authnet_customer_profile_id.to_i,
          :customer_payment_profile_id => user.authnet_payment_profile_id.to_i
        })            
        if resp.success? && resp.params['payment_profile'] && resp.params['payment_profile']['payment'] && resp.params['payment_profile']['payment']['credit_card'] && resp.params['payment_profile']['payment']['credit_card']['card_number']                         
          card_number = resp.params['payment_profile']['payment']['credit_card']['card_number'].gsub('X', '')         
        end
      end    
      return card_number
    end
          
  end
end
