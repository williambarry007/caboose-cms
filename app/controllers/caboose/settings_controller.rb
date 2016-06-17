module Caboose
  class SettingsController < ApplicationController
    layout 'caboose/admin'
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # @route GET /admin/settings
    def index
      return if !user_is_allowed('settings', 'view')
      
      @gen = PageBarGenerator.new(params, {
    		  'name'        => nil,
    		  'value'       => nil,
          'site_id'     => @site.id
    		},{
    		  'model'       => 'Caboose::Setting',
    	    'sort'			  => 'name',
    		  'desc'			  => false,
    		  'base_url'		=> '/admin/settings',
    		  'use_url_params' => false
    	})
    	@settings = @gen.items    	
    end
  
    # @route GET /admin/settings/new
    def new
      return if !user_is_allowed('settings', 'add')
      @setting = Setting.new
    end
  
    # @route GET /admin/settings/:id
    def edit
      return if !user_is_allowed('settings', 'edit')
      @setting = Setting.find(params[:id])
    end
  
    # @route POST /admin/settings
    def create
      return if !user_is_allowed('settings', 'add')
      
      resp = StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
      
      setting = Setting.new()
      setting.name  = params[:name]
      setting.value = params[:value]
      
      if (setting.name.strip.length == 0)
        resp.error = "The setting name is required."
      else      
        setting.save
        resp.redirect = "/admin/settings/#{setting.id}/edit"
      end
      render json: resp
    end
  
    # @route PUT /admin/settings/:id
    def update
      return if !user_is_allowed('settings', 'edit')

      resp = StdClass.new     
      setting = Setting.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
    	  	when "name"  then setting.name  = value
    	  	when "value" then setting.value = value
    	  end
    	end
    	
    	resp.success = save && setting.save
    	render :json => resp
    end
  
    # @route DELETE /admin/settings/:id
    def destroy
      return if !user_is_allowed('settings', 'delete')
      setting = Setting.find(params[:id])
      setting.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/settings'
      })
      render json: resp
    end
    
    # @route_priority 1
    # @route GET /admin/settings/options
    def options
      return if !user_is_allowed('settings', 'view')
      settings = Setting.reorder('name').all
      options = settings.collect { |s| { 'value' => s.id, 'text' => s.name }}
      render json: options
    end
    
  end
end
