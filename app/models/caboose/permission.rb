
class Caboose::Permission < ActiveRecord::Base
  self.table_name = "permissions"
  #has_and_belongs_to_many :roles
  has_many :role_permissions
  has_many :roles, :through => :role_permissions  
  attr_accessible :action, :resource
  
  def self.allow(role_id, resource, action)    
    role = Role.find(role_id)
    perm = Permission.where(:resource => resource, :action => action).first
    return if role.nil? || perm.nil?
    role.permissions.push(perm)
    role.save
  end
end
