module Caboose
  class MyAccountController < Caboose::ApplicationController
            
    # @route GET /my-account
    def index
      return if !verify_logged_in
      @user = logged_in_user      
    end
    
    # @route PUT /my-account
    def update  
      return if !logged_in?
      
      resp = StdClass.new     
      user = logged_in_user
    
      save = true
      params.each do |name,value|
        case name
    	  	when "first_name" then user.first_name  = value
    	  	when "last_name"  then user.last_name   = value
    	  	when "username"
            uname = value.strip.downcase
            if uname.length < 3
              resp.error = "Username must be at least three characters."
            elsif Caboose::User.where(:username => uname, :site_id => @site.id).where('id != ?',user.id).exists?
              resp.error = "That username is already taken."
            elsif uname == 'superadmin'
              resp.error = "Choose a different username."
            else
              user.username = uname
            end
    	  	when "email"
            email = value.strip.downcase
            if !email.include?('@')
              resp.error = "Invalid email address."
            elsif Caboose::User.where(:email => email, :site_id => @site.id).where('id != ?',user.id).exists?
              resp.error = "That email address is already in the system."
            else
              user.email = email
            end
    	  	when "phone"      then user.phone = value

          when "address"  then user.address   = value
          when "address2"  then user.address2   = value
          when "city"  then user.city   = value
          when "state"  then user.state   = value
          when "zip"  then user.zip   = value
          when "customer_profile_id"  then user.customer_profile_id   = value
          when "payment_profile_id"  then user.payment_profile_id   = value
          when "stripe_customer_id"  then user.stripe_customer_id   = value
          when "fax"  then user.fax   = value

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
