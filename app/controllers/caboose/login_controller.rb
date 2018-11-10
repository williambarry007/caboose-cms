module Caboose
  class LoginController < Caboose::ApplicationController
    #layout 'caboose/modal'
    
    # @route GET /login
    def index
      if params[:logout]
        logout_user
        elo = User.find(User::LOGGED_OUT_USER_ID)        
        login_user(elo)
      end      
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      @modal = params[:modal].nil? ? false : params[:modal]
      @page.title = "Login" if @page
      redirect_to @return_url and return if logged_in?
      render :layout => "caboose/application"
    end
    
    # @route POST /login
    def login      
      resp = StdClass.new('error' => '', 'redirect' => '')
      return_url = params[:return_url].nil? ? "/" : params[:return_url]
      if logged_in?
        resp.redirect = return_url
      elsif params[:username].blank?
        resp.error = "Please provide a username."
      elsif params[:password].blank?
        resp.error = "Please provide a password."
      else
        username = params[:username].downcase
        password = params[:password]
        bouncer_class = Caboose::authenticator_class.constantize
        bouncer = bouncer_class.new
        login_resp = bouncer.authenticate(username, password, @site, request)
        if login_resp.error
          resp.error = login_resp.error
        else
          remember = params[:remember] && (params[:remember] == 1 || params[:remember] == "1")            
          login_user(login_resp.user, remember)
          resp.redirect = Caboose.plugin_hook('login_success', return_url, login_resp.user)
          resp.modal = false                        
        end
      end
      render :json => resp      
    end
    
    # @route GET /login/forgot-password
    def forgot_password_form
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      @modal = params[:modal].nil? ? false : params[:modal]
      redirect_to @return_url and return if logged_in?
      @page.title = "Forgot Password" if @page
      render :layout => "caboose/application"
    end
        
    # @route POST /login/forgot-password
    def send_reset_email
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      redirect_to @return_url if logged_in?
      resp = Caboose::StdClass.new		      		
      username = params[:username]
		  if username.blank?
		  	resp.error = "You must enter a username or email address."
        render :json => resp		  	
		  	return
		  end
		  
		  bob = Caboose::User.where(:site_id => @site.id, :username => username.strip.downcase).first
		  bob = Caboose::User.where(:site_id => @site.id, :email    => username.strip.downcase).first if bob.nil?		  
		  
		  if bob.nil?		
			  resp.error = "The given username or email address does not exist."
			  render :json => resp
			  return
			end
			
		  rand = Array.new(20){rand(36).to_s(36)}.join		  
		  bob.password_reset_id = rand
		  bob.password_reset_sent = DateTime.now
		  bob.save
		  		  		  
		  LoginMailer.configure_for_site(@site.id).forgot_password_email(bob).deliver		  
		  		  
		  resp.success = "Please check your email for a link to reset your password. This link is good for 3 days."
		  render :json => resp
		end
	
		# @route GET /login/reset-password/:reset_id
		def reset_password_form
		  @return_url = params[:return_url].nil? ? "/" : params[:return_url]
		  if logged_in?
		    redirect_to @return_url 
		    return
		  end
      @reset_id = params[:reset_id]      
      @user = Caboose::User.user_for_reset_id(@reset_id)
      @page.title = "Reset Password" if @page
      render :layout => "caboose/application"
    end
    
    # @route POST /login/reset-password
    def reset_password
      @return_url = params[:return_url].nil? ? "/" : params[:return_url]
      redirect_to @return_url if logged_in?
      
      resp = Caboose::StdClass.new
	
	    reset_id = params[:id]
	    pass1    = params[:pass1]
	    pass2    = params[:pass2]
	    
	    if reset_id.blank?
	      resp.error = "This password reset link is invalid."
	    else
	      user = Caboose::User.user_for_reset_id(reset_id)
	    	if user.nil?
	    	  resp.error = "This password reset link is invalid."
	    	elsif pass1.length < 8
	    	  resp.error = "Passwords must be at least 8 characters."
        elsif pass1 != pass2
          resp.error = "Your passwords don't match."
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
