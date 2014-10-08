module Caboose
  class LoginController < Caboose::ApplicationController
    layout 'caboose/modal'
    
    # GET /login
    def index
      if params[:logout]
        logout_user
        elo = User.find(User::LOGGED_OUT_USER_ID)        
        login_user(elo)
      end      
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      @modal = params[:modal].nil? ? false : params[:modal]
      redirect_to @return_url and return if logged_in?
    end
    
    # POST /login
    def login      
      resp = StdClass.new('error' => '', 'redirect' => '')
      return_url = params[:return_url].nil? ? "/" : params[:return_url]
      
      if logged_in?
        resp.redirect = return_url
      else
        username = params[:username].downcase
        password = params[:password]
                           
        if username.nil? || password.nil? || password.strip.length == 0
          resp.error = "Invalid credentials"
        else          
          bouncer_class = Caboose::authenticator_class.constantize
          bouncer = bouncer_class.new
          login_resp = bouncer.authenticate(username, password)
          
          if login_resp.error
            resp.error = login_resp.error
          else
            remember = params[:remember] && (params[:remember] == 1 || params[:remember] == "1")            
            login_user(login_resp.user, remember)            
            resp.redirect = return_url
            resp.modal = false
            Caboose.plugin_hook('login_success', login_resp.user.id)            
          end
        end
      end
      render :json => resp      
    end
    
    # GET /login/forgot-password
    def forgot_password_form
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      @modal = params[:modal].nil? ? false : params[:modal]
      redirect_to @return_url if logged_in?
    end
        
    # POST /login/forgot-password
    def send_reset_email
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      redirect_to @return_url if logged_in?
    
      resp = Caboose::StdClass.new		      		
      username = params[:username]
      
		  if username.nil? || username.strip.length == 0       
		  	resp.error = "You must enter a username."
        render :json => resp		  	
		  	return
		  end
		  
		  bob = nil
		  bob = Caboose::User.where(:username => username).first if Caboose::User.where(:username => username).exists?
		  bob = Caboose::User.where(:email => username).first if bob.nil? && bob = Caboose::User.where(:email => username)
		  
		  if bob.nil?		
			  resp.error = "The given username is not in our system."
			  render :json => resp
			  return
			end
			
		  rand = Array.new(20){rand(36).to_s(36)}.join		  
		  bob.password_reset_id = rand
		  bob.password_reset_sent = DateTime.now
		  bob.save
		  
		  LoginMailer.forgot_password_email(bob).deliver
		  		  
		  resp.success = "We just sent you an email.  The reset link inside is good for 3 days."
		  render :json => resp
		end
	
		# GET /login/reset-password/:reset_id
		def reset_password_form
		  @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      redirect_to @return_url if logged_in?
            
      @reset_id = params[:reset_id]      
      @user = Caboose::User.user_for_reset_id(@reset_id)            
    end
    
    # POST /login/reset-password
    def reset_password
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      redirect_to @return_url if logged_in?
      
      resp = Caboose::StdClass.new
	
	    reset_id = params[:id]
	    pass1    = params[:pass1]
	    pass2    = params[:pass2]
	    
	    if reset_id.nil? || reset_id.strip.length == 0
	      resp.error = "No reset ID was given."
	    else
	      user = Caboose::User.user_for_reset_id(reset_id)
	    	
	    	if user.nil?
	    	  resp.error = "The given reset ID is invalid."
	    	elsif pass1 != pass2
	    		resp.error = "Passwords don't match."
	    	elsif pass1.length < 8
	    	  resp.error = "Passwords must be at least 8 characters"
	    	else          
	    	  user.password = Digest::SHA1.hexdigest(Caboose::salt + pass1)
	    	  user.password_reset_id = ''
	    	  user.password_reset_sent = ''
	    	  user.save
	    		resp.redirect = '/login'
	    	end
	    	
	    end
	    render :json => resp
	  end
	
  end  
end
