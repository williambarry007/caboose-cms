class Caboose::User < ActiveRecord::Base
  self.table_name = "users"

  belongs_to :site, :class_name => 'Caboose::Site'    
  has_many :role_memberships
  has_many :roles, :through => :role_memberships
  has_attached_file :image, 
    :path => ':caboose_prefixusers/:id_:style.:extension',    
    :default_url => 'http://placehold.it/300x300',    
    :styles => {
      :tiny  => '150x200>',
      :thumb => '300x400>',
      :large => '600x800>'
    }
  do_not_validate_attachment_file_type :image
  attr_accessible :id, :site_id, :email, :first_name, :last_name, :username, :token, :password, :phone, :timezone
  
  validates :email, :presence => true
  
  ADMIN_USER_ID = 1
  LOGGED_OUT_USER_ID = 2
  
  before_save do
    self.email = self.email.downcase if self.email
  end
  
  def self.logged_out_user(site_id)
    return self.where(:site_id => site_id, :username => 'elo').first
    #return self.where(:id => self::LOGGED_OUT_USER_ID).first
  end
  
  def self.logged_out_user_id(site_id)
    return self.where(:site_id => site_id, :username => 'elo').limit(1).pluck(:id)[0]
    #return self::LOGGED_OUT_USER_ID
  end
  
  def is_allowed(resource, action)
    
    elo = Caboose::Role.logged_out_role(self.site_id)
    return true if elo.is_allowed(resource, action)
    eli = Caboose::Role.logged_in_role(self.site_id)
    return true if self.id != elo.id && eli.is_allowed(resource, action)
    for role in roles
      #Caboose.log("Checking permissions for #{role.name} role")
      if role.is_allowed(resource, action)
        #Caboose.log("Role #{role.name} is allowed to view page")
        return true
      else
        #Caboose.log("Role #{role.name} is not allowed to view page")
      end
      #return true if role.is_allowed(resource, action)
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
  
  def self.user_for_reset_id(reset_id)          
    return nil if reset_id.nil?          
    d = DateTime.now - 3.days
    if self.where("password_reset_id = ? and password_reset_sent > ?", reset_id, d).exists?
      return self.where("password_reset_id = ? and password_reset_sent > ?", reset_id, d).first
    end
    return nil
  end
end
