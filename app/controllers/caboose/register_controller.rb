module Caboose
  class RegisterController < Caboose::ApplicationController
    layout 'caboose/modal'
    
    # GET /register
    def index
      @return_url = params[:return_url].nil? ? "/" : params[:return_url];
      redirect_to @return_url if logged_in?
    end
    
    # POST /register
    def register
      
      resp = StdClass.new('error' => '', 'redirect' => '')
      return_url = params[:return_url].nil? ? "/" : params[:return_url];
      
      if (logged_in?)
        resp.error = "Already logged in"
      else
        
        first_name  = params[:first_name]
        last_name   = params[:last_name]
        email       = params[:email]
        pass1       = params[:pass1]
        pass2       = params[:pass2]
                          
        if (first_name.nil? || first_name.strip.length == 0)
          resp.error = "Your first name is required."
        elsif (last_name.nil? || last_name.strip.length == 0)
          resp.error = "Your last name is required."
        elsif (email.nil? || email.strip.length == 0)
          resp.error = "Your email address is required."
        elsif (pass1.nil? || pass1.strip.length < 8)
          resp.error = "Your password must be at least 8 characters."
        elsif (pass2.nil? || pass1 != pass2)
          resp.error = "Your passwords don't match."
        else
          
          u = Caboose::User.new
          u.first_name    = first_name
          u.last_name     = last_name
          u.email         = email
          u.password      = Digest::SHA1.hexdigest(Caboose::salt + pass1)
          u.creation_date = DateTime.now
          u.save                    
          resp.redirect = "/login?return_url=#{return_url}"

        end
      end
      render json: resp
    end
  end
end