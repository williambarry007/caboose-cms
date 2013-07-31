require "caboose/engine"

module Caboose
      
  mattr_accessor :salt
  @@salt = "This needs to be changed pronto."

  mattr_accessor :assets_path
  @@assets_path = "assets"
  
  mattr_accessor :plugins
  @@plugins = ['Caboose::UserPlugin', 'Caboose::RolePlugin', 'Caboose::PermissionPlugin', 'Caboose::PagePlugin', 'Caboose::SettingsPlugin']

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

end
