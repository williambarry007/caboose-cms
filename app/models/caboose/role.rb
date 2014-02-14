
class Caboose::Role < ActiveRecord::Base
  self.table_name = "roles"
  belongs_to :parent, :class_name => "Caboose::Role"

  #has_and_belongs_to_many :users
  has_many :role_memberships
  has_many :users, :through => :role_memberships
    
  #has_and_belongs_to_many :permissions
  has_many :role_permissions
  has_many :permissions, :through => :role_permissions  
  
  has_many :page_permissions

  attr_accessible :name, :description, :parent_id
  attr_accessor :children
     
  def self.admin_role
    return self.where('name' => 'Admin').first
  end
  
  def self.admin_role_id
    return self.where('name' => 'Admin').limit(1).pluck(:id)[0]
  end
  
  def self.logged_out_role
    return self.where('name' => 'Everyone Logged Out').first
  end
  
  def self.logged_out_role_id
    return self.where('name' => 'Everyone Logged Out').limit(1).pluck(:id)[0]
  end
  
  def self.logged_in_role
    return self.where('name' => 'Everyone Logged In').first
  end
  
  def self.logged_in_role_id
    return self.where('name' => 'Everyone Logged In').limit(1).pluck(:id)[0]
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
  
  def self.tree
    return self.where(:parent_id => -1).reorder("name").all
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
	
end
