
class Caboose::SiteMembership < ActiveRecord::Base
  self.table_name = "site_membership"
       
  belongs_to :site, :class_name => 'Caboose::Site'
  belongs_to :user, :class_name => 'Caboose::User'      
  attr_accessible :id, :site_id, :user_id, :role
  
  ROLE_ADMIN = 'Admin'
  ROLE_USER = 'User'
  
end
