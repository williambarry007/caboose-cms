
class Caboose::Authenticator

  def authenticate(username, password)
    pass = Digest::SHA1.hexdigest(Caboose::salt + password)
    user = Caboose::User.where(:username => username, :password => pass).first
    if (user.nil?)
      user = Caboose::User.where(:email => username, :password => pass).first
    end
    return false if user.nil?
    return user       
  end
  
end
