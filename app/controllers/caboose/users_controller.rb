require 'csv'

module Caboose
  class UsersController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    #===========================================================================
    # Non-admin actions
    #===========================================================================
    
    
  
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
    
    # GET /admin/users/import
    def import_form
      return if !user_is_allowed('users', 'edit')      
    end
    
    def random_string(length)
      o = [('a'..'z'),('A'..'Z'),('0'..'9')].map { |i| i.to_a }.flatten
      return (0...length).map { o[rand(o.length)] }.join
    end
          
    # POST /admin/users/import
    def import
      return if !user_is_allowed('users', 'add')
      
      resp = StdClass.new
      csv_data = params[:csv_data]
      arr = []
      good_count = 0
      bad_count = 0            
      csv_data.strip.split("\n").each do |line|        
        data = CSV.parse_line(line)

        if data.count < 3
          arr << [line, true, "Too few columns"] 
          bad_count = bad_count + 1
          next
        end
        
        first_name = data[0].nil? ? nil : data[0].strip
        last_name  = data[1].nil? ? nil : data[1].strip
        email      = data[2].nil? ? nil : data[2].strip.downcase
        username   = data.count >= 4 && !data[3].nil? ? data[3].strip.downcase : nil
        password   = data.count >= 5 && !data[4].nil? ? data[4].strip : random_string(8)
        
        first_name = data[0]
        last_name  = data[1]
        email      = data[2]
        username   = data.count >= 4 ? data[3] : nil
        password   = data.count >= 5 ? data[4] : random_string(8)

        if first_name.nil? || first_name.length == 0
          arr << [line, false, "Missing first name."]
          bad_count = bad_count + 1
        elsif last_name.nil? || last_name.length == 0
          arr << [line, false, "Missing last name."]
          bad_count = bad_count + 1          
        elsif email.nil? || email.length == 0 || !email.include?('@')
          arr << [line, false, "Email is invalid."]
          bad_count = bad_count + 1          
        elsif Caboose::User.where(:email => email).exists?
          arr << [line, false, "Email already exists."]
          bad_count = bad_count + 1                    
        else                  
          Caboose::User.create(
            :first_name => first_name,
            :last_name  => last_name,
            :email      => email,
            :username   => username,          
            :password   => Digest::SHA1.hexdigest(Caboose::salt + password)
          )
          good_count = good_count + 1
        end
      end
      
      resp.success = "#{good_count} user#{good_count == 1 ? '' : 's'} were added successfully."     
      if bad_count > 0
        resp.success << "<br />#{bad_count} user#{bad_count == 1 ? '' : 's'} were skipped."
        resp.success << "<br /><br />Please check the log below for more details."
        resp.log = arr
      end      
      render :json => resp
    end
    
    # POST /admin/users
    def create
      return if !user_is_allowed('users', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      user = User.new()
      user.email = params[:email] ? params[:email].strip.downcase : nil
      
      if user.email.length == 0
        resp.error = "Please enter a valid email address."
      elsif User.where(:email => user.email).exists?
        resp.error = "That email is already in the system."
      else
        user.save
        resp.redirect = "/admin/users/#{user.id}"
      end
      
      render :json => resp
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
      render :json => resp
    end
    
    # POST /admin/users/:id/roles/:role_id
    def add_to_role
      return if !user_is_allowed('users', 'edit')
      if !RoleMembership.where(:user_id => params[:id], :role_id => params[:role_id]).exists?
        RoleMembership.create(:user_id => params[:id], :role_id => params[:role_id])
      end
      render :json => true
    end
    
    # DELETE /admin/users/:id/roles/:role_id
    def remove_from_role
      return if !user_is_allowed('users', 'edit')
      RoleMembership.where(:user_id => params[:id], :role_id => params[:role_id]).destroy_all        
      render :json => true
    end
    
    # GET /admin/users/options
    def options
      return if !user_is_allowed('users', 'view')
      @users = User.where(:site_id => @site.id).reorder('last_name, first_name').all
      options = @users.collect { |u| { 'value' => u.id, 'text' => "#{u.first_name} #{u.last_name} (#{u.email})"}}
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

