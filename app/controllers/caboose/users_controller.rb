
module Caboose
  class UsersController < ApplicationController
      
    # GET /users
    def index
      return if !user_is_allowed('users', 'view')
      
      @gen = PageBarGenerator.new(params, {
    		  'first_name'  => '',
    		  'last_name'		=> '',
    		  'username'	  => '',
    		  'email' 		  => '',
    		},{
    	    'sort'			  => 'last_name, first_name',
    		  'desc'			  => false,
    		  'base_url'		=> '/users'
    	})
    	
    	if (@gen.options['page'] == 0) 
    		@gen.options['item_count'] = User.where(@gen.where).count
    	end
    	@users = User.where(@gen.where).limit(@gen.limit).offset(@gen.offset).reorder(@gen.reorder).all
    end
    
    # GET /users/new
    def new
      return if !user_is_allowed('users', 'add')
      @user = User.new
    end
    
    # GET /users/1/edit
    def edit
      return if !user_is_allowed('users', 'edit')
      @user = User.find(params[:id])    
      @all_roles = Role.tree
      @roles = Role.roles_with_user(@user.id)
    end
    
    # POST /users
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
        resp.redirect = "/users/#{user.id}/edit"
      end
      render json: resp
    end
    
    # PUT /users/1
    def update
      return if !user_is_allowed('users', 'edit')
      
      resp = StdClass.new     
      user = User.find(params[:id])
      name = params[:name]
      value = params[:value]
    
      save = true
      case name
    		when "first_name", "last_name", "username", "email"
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
    		when "roles"
    		  user.roles = [];
    		  value.each { |rid| user.roles << Role.find(rid) } unless value.nil?
    		  resp.attribute = { 'text' => user.roles.collect{ |r| r.name }.join(', ') }    		  
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end
    
    def update_pic
      @user = User.find(params[:id])
      @new_value = "Testing"
    end
    
    def update_resume
      @user = User.find(params[:id])
      @new_value = "Testing"
    end
      
    # DELETE /users/1
    def destroy
      return if !user_is_allowed('users', 'delete')
      user = User.find(params[:id])
      user.destroy
      
      resp = StdClass.new({
        'redirect' => '/users'
      })
      render json: resp
    end
  end
end
