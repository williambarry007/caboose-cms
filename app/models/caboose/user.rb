class Caboose::User < ActiveRecord::Base
  self.table_name = "users"
  has_and_belongs_to_many :roles
  attr_accessible :email, :first_name, :last_name, :username, :token, :password
  
  def self.logged_out_user
    return self.where('username' => 'elo').first
  end
  
  def self.logged_out_user_id
    return self.where('username' => 'elo').limit(1).pluck(:id)[0]
  end
  
  def is_allowed(resource, action)
    for role in roles
      if role.is_allowed(resource, action)
        return true
      end
    end
    return false;
  end
  
  def self.validate_token(token)
    user = self.where('token' => token).first
    return user 
  end
  
  def add_to_role_with_name(role_name)
    r = Caboose::Role.where(:name => role_name).first
    return false if r.nil?
    return add_to_role(r.id)
  end
  
  def add_to_role(role_id)
    r = Caboose::Role.find(role_id)
    return false if r.nil?
    
    if (!is_member?(r.id))
      roles.push r
      save
    end
    return true
  end
  
  def is_member?(role_id)
    roles.each do |r|
      return true if (r.id == role_id)
    end
    return false
  end
end
