module Caboose
  class PermissionsController < ApplicationController
    layout 'caboose/admin'
    
    def before_action
      @page = Page.page_with_uri('/admin')
    end
    
    # GET /admin/permissions
    def index
      return if !user_is_allowed('permissions', 'view')
      
      @gen = PageBarGenerator.new(params, {
    		  'resource'  => nil
    		},{
    		  'model'       => 'Caboose::Permission',
    	    'sort'			  => 'resource, action',
    		  'desc'			  => false,
    		  'base_url'		=> '/admin/permissions'
    	})
    	@permissions = @gen.items    	
    end
  
    # GET /admin/permissions/new
    def new
      return if !user_is_allowed('permissions', 'add')
      @permission = Permission.new
    end
  
    # GET /admin/permissions/1/edit
    def edit
      return if !user_is_allowed('permissions', 'edit')
      @permission = Permission.find(params[:id])
    end
  
    # POST /admin/permissions
    def create
      return if !user_is_allowed('permissions', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      perm = Permission.new()
      perm.resource = params[:resource]
      perm.action   = params[:action2]
      
      if (perm.resource.strip.length == 0)
        resp.error = "The resource is required."
      elsif (perm.action.strip.length == 0)
        resp.error = "The action is required."
      else      
        perm.save
        resp.redirect = "/admin/permissions/#{perm.id}/edit"
      end
      render json: resp
    end
  
    # PUT /admin/permissions/1
    def update
      return if !user_is_allowed('permissions', 'edit')

      resp = StdClass.new     
      perm = Permission.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
    	  	when "resource"
    	  	  perm.resource = value
    	  	when "action2"
    	  	  perm.action = value
    	  end
    	end
    	
    	resp.success = save && perm.save
    	render json: resp
    end
  
    # DELETE /admin/permissions/1
    def destroy
      return if !user_is_allowed('permissions', 'delete')
      perm = Permission.find(params[:id])
      perm.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/permissions'
      })
      render json: resp
    end
    
    # GET /admin/permissions/options
    def options
      return if !user_is_allowed('permissions', 'view')
      perms = Permission.reorder('resource, action').all
      options = perms.collect { |p| { 'value' => p.id, 'text' => "#{p.resource}_#{p.action}"}}
      render json: options
    end
  end
end
