class Caboose::Font < ActiveRecord::Base
  self.table_name = "fonts"
       
  belongs_to :site, :class_name => 'Caboose::Site'        
  attr_accessible :id, :site_id, :name, :family, :variant, :url
      
end