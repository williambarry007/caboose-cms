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

  s.files = Dir["{app,bin,config,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.executables = ["caboose"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "jquery-rails"
  s.add_dependency "jquery-ui-rails"
  s.add_dependency "activesupport"
  s.add_dependency "mysql2"
  s.add_dependency "modeljs", "= 0.0.8"
  s.add_dependency "tinymce-rails"
  s.add_dependency "trollop"
  
end
