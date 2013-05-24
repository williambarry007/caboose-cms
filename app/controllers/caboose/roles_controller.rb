module Caboose
  class RolesController < ApplicationController
    
    # GET /roles
    def index
      return if !user_is_allowed('roles', 'view')
      top_roles = Role.tree
      arr = []
      top_roles.each { |r| arr += add_role_options(r, 0) }
      @roles = arr        
    end
    
    # GET /roles/new
    def new
      return if !user_is_allowed('roles', 'add')
      @role = Role.new
    end
    
    # GET /roles/1/edit
    def edit
      return if !user_is_allowed('roles', 'edit')
      @role = Role.find(params[:id])
      @users = User.users_with_role(@role.id)
    end
    
    # POST /roles
    def create
      return if !user_is_allowed('roles', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      role = Role.new()
      role.parent_id = params[:parent_id]
      role.name = params[:name]    
      role.save
      
      resp.redirect = "/roles/#{role.id}/edit"
      render json: resp
    end
    
    # PUT /roles/1
    def update
      return if !user_is_allowed('roles', 'edit')
      
      resp = StdClass.new     
      role = Role.find(params[:id])
      name = params[:name]
      value = params[:value]
      
      save = true
      case name
    		when "name"
    		  role.name = value
    		when "parent_id"			  
    		  if (role.id == value)
    		    resp.error = "You can't set the parent to be this role."
    		    save = false
    			#elsif (role.is_parent_of(value))
    			#  resp.error = "You can't set the parent to be one of the child roles."
    			#  save = false
    			else
    			  role.parent_id = value
    			end
    		when "users"
    		  role.users = []
    		  value.each { |uid| role.users << User.find(uid) } unless value.nil?
    		  resp.attribute = { 'text' => role.users.collect{ |u| "#{u.first_name} #{u.last_name}" }.join(', ') }    		  
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end
    
    # DELETE /roles/1
    def destroy
      return if !user_is_allowed('roles', 'delete')
      @role = Role.find(params[:id])
      @role.destroy
    
      respond_to do |format|
        format.html { redirect_to roles_url }
        format.json { head :no_content }
      end
    end
    
    # GET /roles/options
    def options
      return if !user_is_allowed('roles', 'view')
      @top_roles = Role.tree
      arr = []
      @top_roles.each { |r| arr += add_role_options(r, 0) }
      render json: arr.to_json    
    end
    
    def add_role_options(role, level) 
      arr = [{ 
        "value" => role.id, 
        "text" => (" - " * level) + role.name 
      }]
      role.children.each do |kid|
        arr += add_role_options(kid, level+1)
      end
      return arr
    end
  end
end
