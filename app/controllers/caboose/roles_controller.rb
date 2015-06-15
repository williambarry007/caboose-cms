module Caboose
  class RolesController < ApplicationController
    layout 'caboose/admin'
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # GET /admin/roles
    def index
      return unless user_is_allowed('roles', 'view')
      top_roles = Role.tree(@site.id)
      arr = []
      top_roles.each { |r| arr += add_role_options(r, 0) }
      @roles = arr        
    end
    
    # GET /admin/roles/new
    def new
      return unless user_is_allowed('roles', 'add')
      @role = Role.new
    end
    
    # GET /admin/roles/1/edit
    def edit
      return unless user_is_allowed('roles', 'edit')
      @role = Role.find(params[:id])
    end
    
    # POST /admin/roles
    def create
      return unless user_is_allowed('roles', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      parent = Role.where(:id => params[:parent_id]).first
      if parent.nil?
        resp.error = "Parent role must be part of this site."
      else              
        role = Role.new()
        role.site_id = @site.id
        role.parent_id = params[:parent_id]
        role.name = params[:name]    
        role.save
        resp.redirect = "/admin/roles/#{role.id}"
      end
            
      render json: resp
    end
    
    # PUT /admin/roles/1
    def update
      return unless user_is_allowed('roles', 'edit')
      
      resp = StdClass.new     
      role = Role.find(params[:id])
      
      save = true
      params.each do |name,value|
        case name
    	  	when "name"
    	  	  role.name = value
    	  	when "description"
    	  	  role.description = value
    	  	when "parent_id"
    	  	  value = value.to_i
    	  	  p = Role.where(:id => value).first
    	  	  if role.id == value
    	  	    resp.error = "You can't set the parent to be this role."
    	  	    save = false
    	  	  elsif value != -1 && (p.nil? || p.site_id != role.site_id)
    	  	    resp.error = "Invalid parent."
    	  	    save = false
    	  		elsif role.is_ancestor_of?(value)
    	  		  resp.error = "You can't set the parent to be one of the child roles."
    	  		  save = false
    	  		else
    	  		  role.parent_id = value
    	  		  if value == -1
    	  		    resp.attributes = { 'parent_id' => { 'text' => '[No parent]' }}
    	  		  else    	  		    
    	  		    resp.attributes = { 'parent_id' => { 'text' => p.name }}
    	  		  end
    	  		end    	  		
    	  	when "members"
    	  	  value = [] if value.nil? || value.length == 0
    	  	  role.users = value.collect { |uid| User.find(uid) }
    	  	  resp.attributes = { 'members' => { 'text' => role.users.collect{ |u| "#{u.first_name} #{u.last_name}" }.join('<br />') }}
    	  end
    	end
    	
    	resp.success = save && role.save
    	render json: resp
    end
    
    # DELETE /admin/roles/1
    def destroy
      return unless user_is_allowed('roles', 'delete')
      @role = Role.find(params[:id])
      @role.destroy
      render json: { 'redirect' => '/admin/roles' }
    end
    
    # POST /admin/roles/:id/permissions/:permission_id
    def add_permission
      return if !user_is_allowed('roles', 'edit')
      if !RolePermission.where(:role_id => params[:id], :permission_id => params[:permission_id], ).exists?
        RolePermission.create(:role_id => params[:id], :permission_id => params[:permission_id])
      end
      render :json => true
    end
    
    # DELETE /admin/roles/:id/permissions/:permission_id
    def remove_permission
      return if !user_is_allowed('roles', 'edit')
      RolePermission.where(:role_id => params[:id], :permission_id => params[:permission_id]).destroy_all        
      render :json => true
    end
    
    # GET /admin/roles/options
    def options
      return unless user_is_allowed('roles', 'view')
      @top_roles = Role.tree(@site.id)
      arr = [{ 
        "value" => -1, 
        "text" => 'Top Level'
      }]
      @top_roles.each { |r| arr += add_role_options(r, 1) }
      render json: arr.to_json    
    end
    
    def add_role_options(role, level)
      arr = [{ 
        "value" => role.id, 
        "text" => (" - " * level) + role.name 
      }]
      role.children.each do |kid|
        arr += add_role_options(kid, level + 1)
      end
      return arr
    end
  end
end
