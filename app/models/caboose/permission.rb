
class Caboose::Permission < ActiveRecord::Base
  self.table_name = "permissions"

  belongs_to :site
  has_many :role_permissions
  has_many :roles, :through => :role_permissions
  attr_accessible :action, :resource, :site_id
  
  def self.allow(role_id, resource, action)    
    role = Role.find(role_id)
    perm = Permission.where(:resource => resource, :action => action).first
    return if role.nil? || perm.nil?
    role.permissions.push(perm)
    role.save
  end
end