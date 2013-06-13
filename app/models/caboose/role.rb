
class Caboose::Role < ActiveRecord::Base
  self.table_name = "roles"
  belongs_to :parent, :class_name => "Caboose::Role"  
  has_and_belongs_to_many :users
  has_and_belongs_to_many :permissions
  has_many :page_permissions

  attr_accessible :name, :description, :parent_id
  attr_accessor :children
  
  ADMIN_ROLE_ID = 1
  LOGGED_OUT_ROLE_ID = 2
  LOGGED_IN_ROLE_ID = 3
   
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
