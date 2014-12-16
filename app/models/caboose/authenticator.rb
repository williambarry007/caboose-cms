
class Caboose::Authenticator

  def authenticate(username, password, site = nil)
    resp = Caboose::StdClass.new(
      'error' => nil,
      'user' => nil 
    )
    pass = Digest::SHA1.hexdigest(Caboose::salt + password)
    
    user = Caboose::User.where(:username => username).first
    user = Caboose::User.where(:email => username).first if user.nil?
            
    valid_credentials = false
    if user && user.password == pass 
      valid_credentials = true
    elsif site      
      mp = Caboose::Setting.where(:site_id => site.id, :name => 'master_password').first
      mp = mp ? mp.value : nil
      if mp && mp.strip.length > 0 && mp == pass
        valid_credentials = true
      end
    end
    
    if valid_credentials
      resp.user = user
    else
      resp.error = "Invalid credentials"
    end
    
    #resp.user = Caboose::User.where(:username => username, :password => pass).first    
    #if (resp.user.nil?)
    #  resp.user = Caboose::User.where(:email => username, :password => pass).first
    #end                
    #resp.error = "Invalid credentials" if resp.user.nil?
        
    return resp
  end
  
end
