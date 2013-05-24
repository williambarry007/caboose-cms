
class Caboose::Role < ActiveRecord::Base
  self.table_name = "roles"  
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
	
end
