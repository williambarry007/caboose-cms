
class Caboose::Domain < ActiveRecord::Base
  self.table_name = "domains"
       
  belongs_to :site, :class_name => 'Caboose::Site'        
  attr_accessible :id, :site_id, :domain, :primary
      
end
