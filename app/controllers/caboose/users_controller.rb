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
    def admin_index
      return if !user_is_allowed('users', 'view')            
    end
    
    # GET /admin/users/json
    def admin_json
      return if !user_is_allowed('users', 'view')
      
      pager = PageBarGenerator.new(params, {
          'site_id'         => @site.id,
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
    	render :json => {
    	  :pager => pager,
    	  :models => pager.items.as_json(:include => :roles)    	  
    	}
    end
        
    # GET /admin/users/:id/json
    def admin_json_single
      return if !user_is_allowed('users', 'view')    
      u = User.find(params[:id])      
      render :json => u.as_json(:include => :roles)
    end
    
    # GET /admin/users/new
    def admin_new
      return if !user_is_allowed('users', 'add')
      @newuser = User.new
    end
    
    # GET /admin/users/:id
    def admin_edit
      return if !user_is_allowed('users', 'edit')
      @edituser = User.find(params[:id])    
      @all_roles = Role.tree(@site.id)
      @roles = Role.roles_with_user(@edituser.id)
    end
    
    # GET /admin/users/:id/edit-password
    def admin_edit_password
      return if !user_is_allowed('users', 'edit')
      @edituser = User.find(params[:id])
    end
    
    # GET /admin/users/import
    def admin_import_form
      return if !user_is_allowed('users', 'edit')      
    end
    
    def random_string(length)
      o = [('a'..'z'),('A'..'Z'),('0'..'9')].map { |i| i.to_a }.flatten
      return (0...length).map { o[rand(o.length)] }.join
    end
          
    # POST /admin/users/import
    def admin_import
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
            :password   => Digest::SHA1.hexdigest(Caboose::salt + password),
            :site_id    => @site.id
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
    def admin_add
      return if !user_is_allowed('users', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      user = User.new()
      user.email = params[:email] ? params[:email].strip.downcase : nil
      user.site_id = @site.id
      
      if user.email.length == 0
        resp.error = "Please enter a valid email address."
      elsif User.where(:site_id => @site.id, :email => user.email).exists?
        resp.error = "That email is already in the system for this site."
      else
        user.save
        resp.redirect = "/admin/users/#{user.id}"
      end
      
      render :json => resp
    end
    
    # PUT /admin/users/:id
    def admin_update
      return if !user_is_allowed('users', 'edit')

      resp = StdClass.new     
      user = User.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'site_id'              then user.site_id             = value
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
          when 'locked'               then user.locked              = value
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
    	    when 'role_ids'             then user.toggle_roles(value[0], value[1])
    	  	when "roles"
    	  	  user.roles = [];
    	  	  value.each { |rid| user.roles << Role.find(rid) } unless value.nil?
    	  	  resp.attribute = { 'text' => user.roles.collect{ |r| r.name }.join(', ') }    		  
    	  end
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end
    
    # POST /admin/users/:id/update-pic
    def admin_update_pic
      @edituser = User.find(params[:id])
      @new_value = "Testing"
    end
      
    # DELETE /admin/users/:id
    def admin_delete
      return if !user_is_allowed('users', 'delete')
      user = User.find(params[:id])
      user.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/users'
      })
      render :json => resp
    end
    
    # POST /admin/users/:id/roles/:role_id
    def admin_add_to_role
      return if !user_is_allowed('users', 'edit')
      if !RoleMembership.where(:user_id => params[:id], :role_id => params[:role_id]).exists?
        RoleMembership.create(:user_id => params[:id], :role_id => params[:role_id])
      end
      render :json => true
    end
    
    # DELETE /admin/users/:id/roles/:role_id
    def admin_remove_from_role
      return if !user_is_allowed('users', 'edit')
      RoleMembership.where(:user_id => params[:id], :role_id => params[:role_id]).destroy_all        
      render :json => true
    end
    
    # GET /admin/users/options
    def admin_options
      return if !user_is_allowed('users', 'view')
      @users = User.where(:site_id => @site.id).reorder('last_name, first_name').all
      options = @users.collect { |u| { 'value' => u.id, 'text' => "#{u.first_name} #{u.last_name} (#{u.email})"}}
      render json: options
    end
    
    # GET /admin/users/:id/su
    def admin_su
      return if !user_is_allowed('users', 'sudo')
      user = User.find(params[:id])
                                  
      # See if we're on the default domain               
      d = Caboose::Domain.where(:domain => request.host_with_port).first      
            
      if d.primary == true
        logout_user
        login_user(user, false) # Login the new user      
        redirect_to "/"
      end
               
      # Set a random token for the user
      user.token = (0...20).map { ('a'..'z').to_a[rand(26)] }.join
      user.save
      redirect_to "http://#{d.site.primary_domain.domain}/admin/users/#{params[:id]}/su/#{user.token}"                    
    end
    
    # GET /admin/users/:id/su/:token
    def admin_su_token
      return if params[:token].nil?
      user = User.find(params[:id])
      
      token = params[:token]      
      if user.token == params[:token]
        if logged_in? || logged_in_user.id == User::LOGGED_OUT_USER_ID
          Caboose.log(logged_in_user.id)          
          redirect_to "/logout?return_url=/admin/users/#{params[:id]}/su/#{user.token}"
          return
        end
        
        user.token = nil
        user.save                                
        login_user(user)
        redirect_to '/'
      else
        render :json => false     
      end                    
    end
    
  end
end

