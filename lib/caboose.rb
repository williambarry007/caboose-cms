require 'caboose/engine'
require 'asset_sync'
require 'delayed_job_active_record'
require 'awesome_print'

module Caboose
  
  def self.root
    File.expand_path '../..', __FILE__
  end
      
  mattr_accessor :salt
  @@salt = "This needs to be changed pronto."

  mattr_accessor :assets_path
  @@assets_path = "assets"
  
  mattr_accessor :plugins
  @@plugins = ['Caboose::CorePlugin']
  
  mattr_accessor :schemas
  @@schemas = ['Caboose::Schema', 'Schema']
  
  # Any paths to modeljs javascript files  
  mattr_accessor :modeljs_js_files
  @@modeljs_js_files = []
  
  mattr_accessor :modeljs_js_paths
  @@modeljs_js_paths = []
  
  # Any modeljs stylesheets
  mattr_accessor :modeljs_css_files
  @@modeljs_css_files = []
  
  # The login authenticator
  mattr_accessor :authenticator_class
  @@authenticator_class = 'Caboose::Authenticator'
  
  # Whether or not to use URL parameters (parameters embedded in the URL before the querystring)
  mattr_accessor :use_url_params
  @@use_url_params = true
  
  # Whether or not to use AB Testing
  mattr_accessor :use_ab_testing
  @@use_ab_testing = true
  
  # Website name
  mattr_accessor :website_name
  @@website_name = "Website"
  
  # Website domain name (with the protocol)
  mattr_accessor :website_domain
  @@website_domain = "http://www.google.com"
  
  # CDN domain
  mattr_accessor :cdn_domain
  @@cdn_domain = ""
  
  # Email settings
  mattr_accessor :email_from
  @@email_from = "webmaster@caboosecms.com"
  
  # Define asset collections
  mattr_accessor :javascripts, :stylesheets
  @@javascripts = []
  @@stylesheets = []    

  # Session length (in hours)
  mattr_accessor :session_length
  @@session_length = 24

  # Parse rich text blocks
  mattr_accessor :parse_richtext_blocks
  @@parse_richtext_blocks = true

  # Default timezone
  mattr_accessor :timezone
  @@timezone = 'Central Time (US & Canada)'

  # Register layout
  mattr_accessor :register_layout
  @@register_layout = 'caboose/modal'

  # Login layout
  mattr_accessor :login_layout
  @@login_layout = 'caboose/modal'

  # Whether or not to use the store
  mattr_accessor :use_store
  @@use_store = false
  
  # The root URL for the store
  mattr_accessor :store_url
  @@store_url = ''
  
  # The payment processor details
  mattr_accessor :payment_processor
  @@payment_processor = {
    :name => 'stripe',
    :api_key => '',
    :username => '',
    :password => ''
  }    
  
  # Store shipping details
  mattr_accessor :store_shipping
  @@store_shipping = {
    :ups    => { :username => '', :password => '', :key => '' },  
    :usps   => { :username => 'avondalebrewing', :password => 'Missfancy2011', :key => '' },  
    :origin => { :country  => '', :state => '', :city => '', :zip => '' },
    :allowed_shipping_method_codes => [],
    :default_shipping_method_code => ''  
  }
  
  # Who gets the email when an order is received
  mattr_accessor :store_fulfillment_email
  @@store_fulfillment_email = ''
  
  # Who gets the email when an order is ready to be shipped
  mattr_accessor :store_shipping_email
  @@store_shipping_email = ''
  
  mattr_accessor :store_contact_email
  @@store_contact_email = ''
  
  # How much to charge for handling (of the order subtotal)
  mattr_accessor :store_handling_percentage
  @@store_handling_percentage = ''
  
  mattr_accessor :from_address  
  @@from_address = ''
  
  mattr_accessor :uploads_bucket  
  @@uploads_bucket = ''
  
  mattr_accessor :use_comment_routes
  @@use_comment_routes = true
  
end

# These are used so that both local filestorage and S3 can work without having to change paperclip paths in models
Paperclip.interpolates :caboose_prefix do |attachment, style|  
  return "#{Rails.root}/public/" if Caboose::cdn_domain.nil? || Caboose::cdn_domain == '/'
  return ''
end

#Paperclip.interpolates :model_url do |attachment, style|
#  # Local file storeage
#  if Caboose::cdn_domain.nil? || Caboose::cdn_domain == '/'
#    p = attachment.path.gsub("#{Rails.root}/public/", '')
#    return "/#{p}"
#  end  
#  # Otherwise S3
#  return "#{Caboose::cdn_domain}/#{attachment.path}"
#end

Paperclip.interpolates :block_file_upload_name do |attachment, style|
  b = attachment.instance
  return b.id if b.file_upload_name.nil? || b.file_upload_name.strip.length == 0
  return b.file_upload_name        
end

Paperclip.interpolates :block_image_upload_name do |attachment, style|
  b = attachment.instance
  return b.id if b.image_upload_name.nil? || b.image_upload_name.strip.length == 0
  return b.image_upload_name        
end

Paperclip.interpolates :media_name do |attachment, style|
  m = attachment.instance
  return '' if m.name.nil? || m.name.strip.length == 0
  return m.name            
end
