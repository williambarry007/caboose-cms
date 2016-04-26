
module Caboose
  class Authenticator

    def authenticate(username, password, site = nil, request = nil)
      resp = StdClass.new        
      pass = Digest::SHA1.hexdigest(Caboose::salt + password)
      
      user = nil
      if username == 'superadmin'
        user = User.where(:username => username).first        
      else
        user = User.where(:username => username, :site_id => site.id).first
        user = User.where(:email    => username, :site_id => site.id).first if user.nil?
      end
      
      ll = LoginLog.new      
      ll.username       = username      
      ll.date_attempted = DateTime.now.utc                    
      ll.user_id        = user.id           if user
      ll.site_id        = user.site_id      if user
      ll.ip             = request.remote_ip if request
              
      valid_credentials = false
      if user && user.password == pass 
        valid_credentials = true
        resp.user = user
        ll.success = true      
        
      elsif user && user.password != pass
        
        fail_count = Caboose::LoginLog.fail_count(user)
        if (fail_count+1) >= user.site.login_fail_lock_count
          user.locked = true
          user.save                      
          LoginMailer.configure_for_site(user.site.id).locked_account(user).deliver
          resp.error = "Too many failed login attempts. Your account has been locked and the site administrator has been notified."
          ll.success = false
        else
          attempts_left = user.site.login_fail_lock_count - fail_count - 1
          resp.error = "Invalid password. You have #{attempts_left} attempt#{attempts_left == 1 ? '' : 's'} left before your account is locked."
          ll.success = false
        end                      
            
      elsif site
        
        mp = Setting.where(:site_id => site.id, :name => 'master_password').first
        mp = mp ? mp.value : nil
        if mp && mp.strip.length > 0 && mp == pass
          resp.user = user
          ll.success = true
        else
          resp.error = "Invalid credentials"
          ll.success = false
        end
        
      else
        resp.error = "Invalid credentials"
        ll.success = false
      end
      
      ll.save        
      return resp
    end
    
  end
end
