module Caboose
  class MyAccountController < Caboose::ApplicationController
            
    # GET /my-account
    def index
      return if !verify_logged_in
      @user = logged_in_user      
    end
    
    # PUT /my-account
    def update  
      return if !logged_in?
      
      resp = StdClass.new     
      user = logged_in_user
    
      save = true
      params.each do |name,value|
        case name
    	  	when "first_name" then user.first_name  = value
    	  	when "last_name"  then user.last_name   = value
    	  	when "username"   then user.username    = value
    	  	when "email"      then user.email       = value
    	  	when "phone"      then user.phone       = value
    	  	when "password"			  
    	  	  confirm = params[:confirm]
    	  		if value != confirm			
    	  		  resp.error = "Passwords do not match.";
    	  		  save = false
    	  		elsif value.length < 8
    	  		  resp.error = "Passwords must be at least 8 characters.";
    	  		  save = false
    	  		else
    	  		  user.password = Digest::SHA1.hexdigest(Caboose::salt + value)
    	  		end    	  	    		  
    	  end
    	end
    	
    	resp.success = save && user.save
    	render :json => resp
    end        
  end
end
