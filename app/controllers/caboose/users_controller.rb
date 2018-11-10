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
    
    # @route_priority 100
    # @route GET /admin/users
    def admin_index
      return if !user_is_allowed('users', 'view')            
    end
    
    # @route GET /admin/users/json
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
        
    # @route GET /admin/users/:id/json
    def admin_json_single
      return if !user_is_allowed('users', 'view')    
      u = get_edit_user(params[:id], @site.id)
      render :json => u.as_json(:include => :roles)
    end
    
    # @route GET /admin/users/:id/stripe/json
    def admin_stripe_json_single
      return if !user_is_allowed('users', 'view')
      sc = @site.store_config
      u = get_edit_user(params[:id], @site.id)
      render :json => {
        :stripe_key     => sc.stripe_publishable_key.strip,        
        :customer_id    => u.stripe_customer_id,                   
        :card_last4     => u.card_last4,     
        :card_brand     => u.card_brand,       
        :card_exp_month => u.card_exp_month, 
        :card_exp_year  => u.card_exp_year
      }          
    end
    
    # @route GET /admin/users/new
    def admin_new
      return if !user_is_allowed('users', 'add')
      @newuser = User.new
    end
    
    # @route GET /admin/users/import
    def admin_import_form
      return if !user_is_allowed('users', 'edit')      
    end
    
    # @route GET /admin/users/:id
    def admin_edit
      return if !user_is_allowed('users', 'edit')
      @edituser = get_edit_user(params[:id], @site.id)
      @all_roles = Role.tree(@site.id)
      @roles = Role.roles_with_user(@edituser.id) if @edituser
      redirect_to '/admin/users' if @edituser.nil?
    end
    
    # @route GET /admin/users/:id/roles
    def admin_edit_roles
      return if !user_is_allowed('users', 'edit')
      @edituser = get_edit_user(params[:id], @site.id)
      @all_roles = Role.tree(@site.id)
      @roles = Role.roles_with_user(@edituser.id) if @edituser
      redirect_to '/admin/users' if @edituser.nil?
    end

    # @route GET /admin/users/exports/:id/json    
    def admin_export_single
      return unless (user_is_allowed_to 'edit', 'users')
      e = Caboose::Export.where(:id => params[:id]).first      
      render :json => e
    end

    # @route POST /admin/users/export
    def admin_export
      return unless (user_is_allowed_to 'edit', 'users')      
      resp = Caboose::StdClass.new
      e = Caboose::Export.create(
        :kind => 'users',
        :date_created => DateTime.now.utc,        
        :params => params.to_json,
        :status => 'pending'
      )
      e.delay(:queue => 'caboose_general', :priority => 8).user_process if Rails.env.production?
      e.user_process if Rails.env.development?
      resp.new_id = e.id
      resp.success = true
      render :json => resp
    end
    
    # @route GET /admin/users/:id/payment-method
    def admin_edit_payment_method
      return if !user_is_allowed('users', 'edit')
      @edituser = get_edit_user(params[:id], @site.id)
    end
    
    # @route GET /admin/users/:id/password
    def admin_edit_password
      return if !user_is_allowed('users', 'edit')
      @edituser = get_edit_user(params[:id], @site.id)
      redirect_to '/admin/users' if @edituser.nil?
    end
            
    def random_string(length)
      o = [('a'..'z'),('A'..'Z'),('0'..'9')].map { |i| i.to_a }.flatten
      return (0...length).map { o[rand(o.length)] }.join
    end
    
    # @route GET /admin/users/:id/delete
    def admin_delete_form
      return if !user_is_allowed('users', 'edit')
      @edituser = get_edit_user(params[:id], @site.id)
      redirect_to '/admin/users' if @edituser.nil?
    end
          
    # @route POST /admin/users/import
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
    
    # @route POST /admin/users
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
    
    # @route PUT /admin/users/:id
    def admin_update
      return if !user_is_allowed('users', 'edit')

      resp = StdClass.new     
      user = get_edit_user(params[:id], @site.id)
    
      save = true
      params.each do |name,value|
        case name
          when 'site_id'              then user.site_id             = value
          when 'first_name'           then user.first_name          = value     
          when 'last_name'            then user.last_name           = value 
          when "username"
            uname = value.strip.downcase
            if uname.length < 3
              resp.error = "Username must be at least three characters."
            elsif Caboose::User.where(:username => uname, :site_id => @site.id).where('id != ?',user.id).exists?
              resp.error = "That username is already taken."
            else
              user.username    = uname
            end
          when "email"
            email = value.strip.downcase
            if !email.include?('@')
              resp.error = "Invalid email address."
            elsif Caboose::User.where(:email => email, :site_id => @site.id).where('id != ?',user.id).exists?
              resp.error = "That email address is already in the system."
            else
              user.email    = email
            end
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
    	  	
    	  	when 'card'
    	  	  
    	  	  sc = @site.store_config      
    	  	  Stripe.api_key = sc.stripe_secret_key.strip    	  	              
      
    	  	  c = nil
            if user.stripe_customer_id
              c = Stripe::Customer.retrieve(user.stripe_customer_id)
              begin          
                c.source = params[:token]
                c.save
              rescue          
                c = nil
              end
            end                  
            c = Stripe::Customer.create(:source => params[:token], :email => user.email, :metadata => { :user_id => user.id }) if c.nil?                  
            user.stripe_customer_id = c.id
            user.card_last4     = params[:card][:last4]
            user.card_brand     = params[:card][:brand]  
            user.card_exp_month = params[:card][:exp_month]
            user.card_exp_year  = params[:card][:exp_year]
            user.save
            
    	  end
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end

    # @route DELETE /admin/users/bulk
    def admin_bulk_delete
      return unless user_is_allowed_to 'delete', 'users'
      params[:model_ids].each do |user_id|
        user = get_edit_user(user_id, @site.id)
        user.destroy if user
      end
      resp = Caboose::StdClass.new('success' => true)
      render :json => resp
    end
      
    # @route DELETE /admin/users/:id
    def admin_delete
      return if !user_is_allowed('users', 'delete')
      user = get_edit_user(params[:id], @site.id)
      user.destroy
      resp = StdClass.new({
        'redirect' => '/admin/users'
      })
      render :json => resp
    end
    
    # @route POST /admin/users/:id/roles/:role_id
    def admin_add_to_role
      return if !user_is_allowed('users', 'edit')
      user = get_edit_user(params[:id], @site.id)
      role = Role.where(:id => params[:role_id], :site_id => @site.id).first
      if user && role && !RoleMembership.where(:user_id => user.id, :role_id => role.id).exists?
        RoleMembership.create(:user_id => user.id, :role_id => role.id)
      end
      render :json => true
    end
    
    # @route DELETE /admin/users/:id/roles/:role_id
    def admin_remove_from_role
      return if !user_is_allowed('users', 'edit')
      user = get_edit_user(params[:id], @site.id)
      role = Role.where(:id => params[:role_id], :site_id => @site.id).first
      if user && role
        RoleMembership.where(:user_id => user.id, :role_id => role.id).destroy_all
      end
      render :json => true
    end
    
    # @route_priority 1
    # @route GET /admin/users/options
    def admin_options
      return if !user_is_allowed('users', 'view')
      @users = User.where(:site_id => @site.id).reorder('last_name, first_name').all
      options = @users.collect { |u| { 'value' => u.id, 'text' => "#{u.first_name} #{u.last_name} (#{u.email})"}}
      render json: options
    end
    
    # @route_priority 1
    # @route GET /admin/users/:id/su
    def admin_su
      return if !user_is_allowed('users', 'sudo')
      user = get_edit_user(params[:id], @site.id)
      if user                               
        logout_user
        login_user(user, false)   
        redirect_to "/"
      end                        
    end
    
    # @route GET /admin/users/:id/su/:token
    def admin_su_token
      return if params[:token].nil?
      user = get_edit_user(params[:id], @site.id)
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

    private

    def get_edit_user(user_id, site_id)
      user = User.find(user_id)
      return user if user && (user.site_id == site_id || logged_in_user.is_super_admin?)
      return nil
    end
    
  end
end

