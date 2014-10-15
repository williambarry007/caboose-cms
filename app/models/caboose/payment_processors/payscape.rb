require "rexml/document"

class Caboose::PaymentProcessors::Payscape < Caboose::PaymentProcessors::Base
  def self.api(root, body, test=false)
    
    # Determine if transaction should be a test
    body['api-key'] = if test or Rails.env == 'development'
      '2F822Rw39fx762MaV7Yy86jXGTC7sCDy'
    else
      Caboose::api_key
    end
    
    ap "API key used: #{body['api-key']}"
    # ap "AUTH USERNAME: #{Caboose::payscape_username}"
    # ap "AUTH PASSWORD: #{Caboose::payscape_password}"
    
    uri                  = URI.parse('https://secure.payscapegateway.com/api/v2/three-step')
    http                 = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl         = true
    request              = Net::HTTP::Post.new(uri.path)
    request.content_type = 'text/xml'
    request.body         = body.to_xml({:root => root})
    xml_response         = http.request(request)
    document             = REXML::Document.new(xml_response.body.to_s)
    response             = Hash.new
    
    document.root.elements.each { |element| response[element.name] = element.text }
    
    ap response
    
    return response
  end
  
  def self.form_url(order)
    response = self.api 'auth', {
      'redirect-url' => "#{Caboose::store_url}/checkout/relay/#{order.id}",
      'amount'       => order.total.to_s,
      'billing'      => {
        'first-name' => order.billing_address.first_name,
        'last-name'  => order.billing_address.last_name,
        'address1'   => order.billing_address.address1,
        'address2'   => order.billing_address.address2,
        'city'       => order.billing_address.city,
        'state'      => order.billing_address.state,
        'postal'     => order.billing_address.zip
      }
    }, order.test?
    
    order.transaction_id = response['transaction-id']
    order.transaction_service = 'payscape'
    order.save
    
    return response['form-url']
  end
  
  def self.authorized?(order)
    uri              = URI.parse("https://secure.payscapegateway.com/api/query.php?username=#{Caboose::payscape_username}&password=#{Caboose::payscape_password}&transaction_id=#{order.transaction_id}")
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request          = Net::HTTP::Get.new(uri.request_uri)
    response         = http.request(request)
    document         = Nokogiri::XML response.body
    actions          = Hash.new
    
    document.xpath('//action').each { |action| actions[action.xpath('action_type').text] = action.xpath('success').text == '1' }
    return actions['auth']
  end
  
  def self.authorize(order, params)
    response = self.api 'complete-action', { 'token-id' => params['token-id'] }, order.test?
    order.update_attribute(:transaction_id, params['transaction-id']) if params['transaction-id']
    return response['result-code'].to_i == 100
  end
  
  def self.void(order)
    response = self.api 'void', { 'transaction-id' => order.transaction_id }, order.test?
    return response['result-code'].to_i == 100
  end
  
  def self.capture(order)
    response = self.api 'capture', { 'transaction-id' => order.transaction_id }, order.test?
    return response['result-code'].to_i == 100
  end
  
  def self.refund(order)
    response = self.api 'refund', {
      'transaction-id' => order.transaction_id,
      'amount'         => order.total.to_s
    }, order.test?
    
    return response['result-code'].to_i == 100
  end
end
