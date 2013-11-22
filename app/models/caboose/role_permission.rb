
class Caboose::RolePermission < ActiveRecord::Base
  self.table_name = "role_permissions"
  
  belongs_to :permission
  belongs_to :role
  attr_accessible :permission_id, :role_id
  
end
