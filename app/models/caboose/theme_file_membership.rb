class Caboose::ThemeFileMembership < ActiveRecord::Base
  self.table_name = "theme_file_memberships"
  
  belongs_to :theme
  belongs_to :theme_file  
  attr_accessible :theme_id, :theme_file_id
  
end