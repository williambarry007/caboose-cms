require "caboose/engine"

module Caboose
      
  mattr_accessor :salt
  @@salt = "This needs to be changed pronto."

  mattr_accessor :assets_path
  @@assets_path = "assets"
  
  mattr_accessor :plugins
  @@plugins = ['Caboose::CorePlugin']

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
  
end
