module Caboose
  class LoginController < Caboose::ApplicationController
    layout 'caboose/modal'
    
    # GET /login
    def index
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      @modal = params[:modal].nil? ? false : params[:modal]
      redirect_to @return_url if logged_in?
    end
    
    # POST /login
    def login
      
      @resp = StdClass.new('error' => '', 'redirect' => '')
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      
      if (logged_in?)
        @resp.error = "Already logged in"
      else
        @username = params[:username]
        @password = params[:password]
                           
        if (@username.nil? || @password.nil? || @password.strip.length == 0)
          @resp.error = "Invalid credentials"
        else
          
          @password = Digest::SHA1.hexdigest(Caboose::salt + @password)
          user = User.where(:username => @username, :password => @password).first
          if (user.nil?)
            user = User.where(:email => @username, :password => @password).first
          end
          
          if (user.nil?)
            @resp.error = "Invalid credentials"
          else
            login_user(user)
            @resp.redirect = @return_url
          end
        end
      end
      render json: @resp
    end
  end
end