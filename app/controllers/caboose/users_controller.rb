
module Caboose
  class UsersController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri('/admin')
    end
    
    #===========================================================================
    # Non-admin actions
    #===========================================================================
    
    # GET /my-account
    def my_account
      return if !logged_in?
      @user = logged_in_user
      render :layout => 'caboose/modal'
    end
    
    # PUT /my-account
    def update_my_account  
      return if !logged_in?
      
      resp = StdClass.new     
      user = logged_in_user
    
      save = true
      params.each do |name,value|
        case name
    	  	when "first_name", "last_name", "username", "email", "phone"
    	  	  user[name.to_sym] = value
    	  	when "password"			  
    	  	  confirm = params[:confirm]
    	  		if (value != confirm)			
    	  		  resp.error = "Passwords do not match.";
    	  		  save = false
    	  		elsif (value.length < 8)
    	  		  resp.error = "Passwords must be at least 8 characters.";
    	  		  save = false
    	  		else
    	  		  user.password = Digest::SHA1.hexdigest(Caboose::salt + value)
    	  		end    	  	    		  
    	  end
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end
  
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/users
    def index
      return if !user_is_allowed('users', 'view')
      
      @gen = PageBarGenerator.new(params, {
    		  'first_name_like' => '',
    		  'last_name_like'	=> '',
    		  'username_like'	  => '',
    		  'email_like' 		  => '',
    		},{
    		  'model'          => 'Caboose::User',
    	    'sort'			     => 'last_name, first_name',
    		  'desc'			     => false,
    		  'base_url'		   => '/admin/users',
    		  'use_url_params' => false
    	})
    	@users = @gen.items
    end
    
    # GET /admin/users/new
    def new
      return if !user_is_allowed('users', 'add')
      @newuser = User.new
    end
    
    # GET /admin/users/1/edit
    def edit
      return if !user_is_allowed('users', 'edit')
      @edituser = User.find(params[:id])    
      @all_roles = Role.tree
      @roles = Role.roles_with_user(@edituser.id)
    end
    
    # GET /admin/users/1/edit-password
    def edit_password
      return if !user_is_allowed('users', 'edit')
      @edituser = User.find(params[:id])
    end
    
    # POST /admin/users
    def create
      return if !user_is_allowed('users', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      user = User.new()
      user.username = params[:username]
      
      if (user.username.length == 0)
        resp.error = "Your username is required."
      elsif      
        user.save
        resp.redirect = "/admin/users/#{user.id}/edit"
      end
      render json: resp
    end
    
    # PUT /admin/users/1
    def update
      return if !user_is_allowed('users', 'edit')

      resp = StdClass.new     
      user = User.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'first_name'           then user.first_name          = value     
          when 'last_name'            then user.last_name           = value 
          when 'username'             then user.username            = value 
          when 'email'                then user.email               = value         
          when 'address'              then user.address             = value
          when 'address2'             then user.address2            = value
          when 'city'                 then user.city                = value
          when 'state'                then user.state               = value
          when 'zip'                  then user.zip                 = value
          when 'phone'                then user.phone               = value
          when 'fax'                  then user.fax                 = value
          when 'utc_offset'           then user.utc_offset          = value.to_f        
    	  	when "password"			  
    	  	  confirm = params[:password2]
    	  		if (value != confirm)			
    	  		  resp.error = "Passwords do not match.";
    	  		  save = false
    	  		elsif (value.length < 8)
    	  		  resp.error = "Passwords must be at least 8 characters.";
    	  		  save = false
    	  		else
    	  		  user.password = Digest::SHA1.hexdigest(Caboose::salt + value)
    	  		end
    	  	when "roles"
    	  	  user.roles = [];
    	  	  value.each { |rid| user.roles << Role.find(rid) } unless value.nil?
    	  	  resp.attribute = { 'text' => user.roles.collect{ |r| r.name }.join(', ') }    		  
    	  end
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end
    
    # POST /admin/users/1/update-pic
    def update_pic
      @edituser = User.find(params[:id])
      @new_value = "Testing"
    end
      
    # DELETE /admin/users/1
    def destroy
      return if !user_is_allowed('users', 'delete')
      user = User.find(params[:id])
      user.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/users'
      })
      render json: resp
    end
    
    # GET /admin/users/options
    def options
      return if !user_is_allowed('users', 'view')
      @users = User.reorder('last_name, first_name').all
      options = @users.collect { |u| { 'value' => u.id, 'text' => "#{u.first_name} #{u.last_name}"}}
      render json: options
    end
    
    # GET /admin/users/:id/su
    def admin_su
      return if !user_is_allowed('users', 'sudo')
      user = User.find(params[:id])
      
      # Log out the current user
      cookies.delete(:caboose_user_id)
      reset_session
      
      # Login the new user
      login_user(user, false)      
      redirect_to "/"      
    end
    
  end
end

