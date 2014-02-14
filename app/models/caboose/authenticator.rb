
class Caboose::Authenticator

  def authenticate(username, password)
    resp = Caboose::StdClass.new(
      'error' => nil,
      'user' => nil 
    )
    pass = Digest::SHA1.hexdigest(Caboose::salt + password)
    resp.user = Caboose::User.where(:username => username, :password => pass).first
    if (resp.user.nil?)
      resp.user = Caboose::User.where(:email => username, :password => pass).first
    end
    resp.error = "Invalid credentials" if resp.user.nil?      
    return resp
  end
  
end
