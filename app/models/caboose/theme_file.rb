class Caboose::ThemeFile < ActiveRecord::Base
  self.table_name = "theme_files"
  
  attr_accessible :filename, :nice_name, :default_included
  
end