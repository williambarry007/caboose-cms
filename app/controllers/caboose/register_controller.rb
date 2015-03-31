module Caboose
  class RegisterController < Caboose::ApplicationController
    #layout 'caboose/modal'
    
    # GET /register
    def index
      @return_url = params[:return_url].nil? ? "/" : params[:return_url];
      @modal = params[:modal].nil? ? false : params[:modal]
      redirect_to @return_url if logged_in?
      render :layout => Caboose::register_layout 
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
        phone       = params[:phone]
        pass1       = params[:pass1]
        pass2       = params[:pass2]
                          
        if first_name.nil? || first_name.strip.length == 0                             then resp.error = "Your first name is required."
        elsif last_name.nil? || last_name.strip.length == 0                            then resp.error = "Your last name is required."
        elsif email.nil? || email.strip.length == 0                                    then resp.error = "Your email address is required."
        elsif User.where(:site_id => @site.id, :email => email.strip.downcase).exists? then resp.error = "A user with that email address already exists."
        elsif phone.nil? || phone.strip.length < 10                                    then resp.error = "Your phone number is required. Please include your area code."
        elsif pass1.nil? || pass1.strip.length < 8                                     then resp.error = "Your password must be at least 8 characters."
        elsif pass2.nil? || pass1 != pass2                                             then resp.error = "Your passwords don't match."
        else
          
          u = Caboose::User.new
          u.site_id       = @site.id
          u.first_name    = first_name
          u.last_name     = last_name
          u.email         = email.strip.downcase
          u.phone         = phone
          u.password      = Digest::SHA1.hexdigest(Caboose::salt + pass1)
          u.date_created  = DateTime.now          
          u.save
          
          # Go ahead and log the user in
          u = Caboose::User.find(u.id)
          login_user(u, true)          
          
          resp.redirect = "/login?return_url=#{return_url}"

        end
      end
      render json: resp
    end
  end
end