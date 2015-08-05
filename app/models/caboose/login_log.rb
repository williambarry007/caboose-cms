
class Caboose::LoginLog < ActiveRecord::Base
  self.table_name = "login_logs"
    
  belongs_to :site, :class_name => 'Caboose::Site'
  belongs_to :user, :class_name => 'Caboose::User'
  
  attr_accessible :id,  
    :site_id        ,
    :username       ,
    :user_id        ,
    :date_attempted ,
    :ip             ,        
    :success
    
  def self.fail_count(user)
    last_successful_login = Caboose::LoginLog.where(:user_id => user.id, :success => true).reorder("date_attempted desc").first
    id = last_successful_login ? last_successful_login.id : 1
    return Caboose::LoginLog.where("user_id = ? and success = ? and id > ?", user.id, false, id).count    
  end

end
