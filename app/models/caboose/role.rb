
class Caboose::Role < ActiveRecord::Base
  self.table_name = "roles"
  
  belongs_to :site, :class_name => 'Caboose::Site'
  belongs_to :parent, :class_name => "Caboose::Role"  
  has_many :role_memberships
  has_many :users, :through => :role_memberships      
  has_many :role_permissions
  has_many :permissions, :through => :role_permissions    
  has_many :page_permissions

  attr_accessible :id,
    :name, 
    :description,
    :parent_id,
    :site_id
  attr_accessor :children
     
  def self.admin_role(site_id)
    return self.where(:site_id => site_id, :name => 'Admin').first
  end
  
  def self.admin_role_id(site_id)
    return self.where(:site_id => site_id, :name => 'Admin').limit(1).pluck(:id)[0]
  end
  
  def self.logged_out_role(site_id)
    return self.where(:site_id => site_id, :name => 'Everyone Logged Out').first
  end
  
  def self.logged_out_role_id(site_id)
    return self.where(:site_id => site_id, :name => 'Everyone Logged Out').limit(1).pluck(:id)[0]
  end
  
  def self.logged_in_role(site_id)
    return self.where(:site_id => site_id, :name => 'Everyone Logged In').first
  end
  
  def self.logged_in_role_id(site_id)
    return self.where(:site_id => site_id, :name => 'Everyone Logged In').limit(1).pluck(:id)[0]
  end
  
  def is_allowed(resource, action)    
    # Check for the admin permission
    for perm in permissions
      return true if (perm.resource == "all" && perm.action == "all")
    end
        
    if (resource.is_a?(Caboose::Page))      
      for perm in page_permissions
        return true if (perm.page_id == resource.id && perm.action == action)
      end        
    elsif
      for perm in permissions
        return true if (perm.resource == resource && perm.action == action)
      end
    end
    return false
  end		
  
  def children
    Caboose::Role.where(:parent_id => id).reorder("name").all
  end
  
  #-----------------------------------------------------------------------------
  # Class methods
  #-----------------------------------------------------------------------------
  
  def self.roles_with_user(user_id)
    return self.where("users.id" => user_id).all(:include => :users)
  end
  
  def self.tree(site_id)
    return self.where(:parent_id => -1, :site_id => site_id).reorder("name").all
  end
  
  def self.flat_tree(site_id, prefix = '-')
    arr = []
    self.tree(site_id).each do |r|
      arr += self.flat_tree_helper(r, prefix, '')
    end
    return arr
  end
  
  def self.flat_tree_helper(role, prefix, str)
    role.name = "#{str}#{role.name}"
    arr = [role]
    role.children.each do |r|
      arr += self.flat_tree_helper(r, prefix, "#{str}#{prefix}")
    end
    return arr
  end
  
  def is_ancestor_of?(role)    
    if (role.is_a?(Integer) || role.is_a?(String))
      role_id = role.to_i
      return false if role_id == -1
      role = Caboose::Role.find(role)
    end
    return false if role.parent_id == -1
    return false if role.parent.nil?
    return true  if role.parent.id == id
    return is_ancestor_of?(role.parent)      
  end
  
  def is_child_of?(role)    
    role = Role.find(role) if role.is_a?(Integer)
    return role.is_ancestor_of?(self)      
  end    
  
  def duplicate(site_id)
    r = Caboose::Role.where(:site_id => site_id, :name => self.name).first
    return if r

    # If we're at the top of the role hierarchy
    if self.parent_id == -1
      r = Caboose::Role.create(
        :site_id => site_id,
        :parent_id => -1, 
        :name => r.name,
        :description => r.description
      )
      self.role_permissions.each{ |rp| Caboose::RolePermission.create(:permission_id => rp.permission_id, :role_id => r.id) }
      self.children.each{ |r2| r2.duplicate(site_id) }
      return
    end
    
    # Otherwise, there is a parent, try to find it
    new_parent = Caboose::Role.where(:site_id => site_id, :name => self.parent.name).first
    if new_parent
      r = Caboose::Role.create(
        :site_id => site_id,
        :parent_id => new_parent.id, 
        :name => r.name,
        :description => r.description
      )
      self.role_permissions.each{ |rp| Caboose::RolePermission.create(:permission_id => rp.permission_id, :role_id => r.id) }
      self.children.each{ |r2| r2.duplicate(site_id) }
      return
    end
    
    # Since we can't find the parent, recursively duplicate the current role's parent into the new site
    self.parent.duplicate(site_id)
  end
    	
end
