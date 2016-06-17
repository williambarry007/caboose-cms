module Caboose
  class PermissionsController < ApplicationController
    layout 'caboose/admin'
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # @route GET /admin/permissions
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
  
    # @route GET /admin/permissions/new
    def new
      return if !user_is_allowed('permissions', 'add')
      @permission = Permission.new
    end
  
    # @route GET /admin/permissions/:id
    def edit
      return if !user_is_allowed('permissions', 'edit')
      @permission = Permission.find(params[:id])
    end
  
    # @route POST /admin/permissions
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
  
    # @route PUT /admin/permissions/:id
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
  
    # @route DELETE /admin/permissions/:id
    def destroy
      return if !user_is_allowed('permissions', 'delete')
      perm = Permission.find(params[:id])
      perm.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/permissions'
      })
      render json: resp
    end
    
    # @route_priority 1
    # @route GET /admin/permissions/options
    def options
      return if !user_is_allowed('permissions', 'view')
      perms = Permission.reorder('resource, action').all
      options = perms.collect { |p| { 'value' => p.id, 'text' => "#{p.resource}_#{p.action}"}}
      render json: options
    end
  end
end
