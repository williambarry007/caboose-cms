
class Caboose::RoleMembership < ActiveRecord::Base
  self.table_name = "role_memberships"
  
  belongs_to :user
  belongs_to :role  
  attr_accessible :user_id, :role_id
  
end
