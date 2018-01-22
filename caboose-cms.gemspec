# Copyright 2013 William Barry
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "caboose/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "caboose-cms"
  s.version     = Caboose::VERSION
  s.authors     = ["William Barry"]
  s.email       = ["william@nine.is"]
  s.homepage    = "http://github.com/williambarry007/caboose-cms"
  s.summary     = "CMS built on rails."
  s.description = "CMS built on rails with love."

  s.files = Dir["{app,bin,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]
  s.executables = ["caboose"]

  # Production  
  s.add_dependency "pg"
  s.add_dependency "rails", "~> 3.2.22"
  s.add_dependency "underscore-rails"
  s.add_dependency "jquery-rails", "~> 3.1.1"
  s.add_dependency "jquery-ui-rails", "~> 5.0.0"
  s.add_dependency "trollop"
  s.add_dependency "colorbox-rails", "~> 0.1.2"
  s.add_dependency "paperclip"
  s.add_dependency "awesome_print"
  s.add_dependency "ejs"
  s.add_dependency "httparty"
  s.add_dependency "prawn"
  s.add_dependency "prawn-table"
  s.add_dependency "nokogiri"
  s.add_dependency "nokogiri-styles"
  s.add_dependency 'delayed_job_active_record'  
  s.add_dependency 'aws-sdk', '< 2.0'
  s.add_dependency 'asset_sync', '~> 1.3.0'
  s.add_dependency 'unf'
  s.add_dependency 'highline'
  
  s.add_dependency "authorizenet"
  s.add_dependency 'authorize-net'
  s.add_dependency "active_shipping"  
  s.add_dependency "activemerchant"  
  s.add_dependency 'box_packer'
  s.add_dependency 'tax_cloud'
  
  #s.add_dependency "oauth"
  #s.add_dependency "roxml"
  #s.add_dependency "spreadsheet"
  #s.add_dependency "thin"
    
  # Development
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'
  
  # Testing  
  s.add_development_dependency 'faker'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'launchy'

end
