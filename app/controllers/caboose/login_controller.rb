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
      resp = StdClass.new('error' => '', 'redirect' => '')
      return_url = params[:return_url].nil? ? "/" : params[:return_url]
      
      if (logged_in?)
        resp.redirect = return_url
      else
        username = params[:username].downcase
        password = params[:password]
                           
        if (username.nil? || password.nil? || password.strip.length == 0)
          resp.error = "Invalid credentials"
        else
          
          bouncer_class = Caboose::authenticator_class.constantize
          bouncer = bouncer_class.new
          user = bouncer.authenticate(username, password)
          
          if (user.nil? || user == false)
            resp.error = "Invalid credentials"
          else
            remember = params[:remember] && (params[:remember] == 1 || params[:remember] == "1")
            login_user(user, remember)
            resp.redirect = return_url
          end
        end
      end
      render :json => resp
    end
  end
end
