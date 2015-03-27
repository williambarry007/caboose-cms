require 'csv'

module Caboose
  class SitesController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # GET /admin/sites
    def admin_index
      return if !user_is_allowed('sites', 'view')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      
      @pager = PageBarGenerator.new(params, {
    		  'name_like' => '',    		  
    		},{
    		  'model'          => 'Caboose::Site',
    	    'sort'			     => 'name',
    		  'desc'			     => false,
    		  'base_url'		   => '/admin/sites',
    		  'use_url_params' => false
    	})
    	@sites = @pager.items
    end
    
    # GET /admin/sites/new
    def admin_new
      return if !user_is_allowed('sites', 'add')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      
      @site = Site.new
    end
    
    # GET /admin/sites/:id
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      
      @site = Site.find(params[:id])      
      
      # Create an admin user for the account
      if User.where(:username => 'admin', :site_id => @site.id).exists?
        admin_user = User.create(:username => 'admin', :site_id => @site.id, :password => Digest::SHA1.hexdigest(Caboose::salt + 'caboose'))
        admin_role = Role.where(:name => 'Admin').first
        if admin_role
          RoleMembership.create(:user_id => admin_user.id, :role_id => admin_role.id)
        else
          Caboose.log("Error: no admin role exists.")
        end
      end
    end
    
    # GET /admin/sites/:id/block-types
    def admin_edit_block_types
      return if !user_is_allowed('sites', 'edit')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      
      @site = Site.find(params[:id])      
    end
    
    # GET /admin/sites/:id/delete
    def admin_delete_form
      return if !user_is_allowed('sites', 'edit')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      @site = Site.find(params[:id])      
    end
        
    # POST /admin/sites
    def admin_add
      return if !user_is_allowed('sites', 'add')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
              
      resp = StdClass.new      
      site = Site.new
      site.name = params[:name].strip
      
      if site.name.length == 0
        resp.error = "Please enter a valid domain."      
      else        
        site.save
        StoreConfig.create(:site_id => site.id)
        SmtpConfig.create( :site_id => site.id)
        resp.redirect = "/admin/sites/#{site.id}"
      end
      
      # Create an admin user for the account
      if User.where(:username => 'admin', :site_id => site.id).exists?
        admin_user = User.create(:username => 'admin', :site_id => site.id, :password => Digest::SHA1.hexdigest(Caboose::salt + 'caboose'))
        admin_role = Role.where(:name => 'Admin').first
        if admin_role
          RoleMembership.create(:user_id => admin_user.id, :role_id => admin_role.id)
        else
          Caboose.log("Error: no admin role exists.")
        end
      end
      
      render :json => resp
    end
    
    # PUT /admin/sites/:id
    def admin_update
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master

      resp = StdClass.new     
      site = Site.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'name'                     then site.name                    = value
          when 'description'              then site.description             = value
          when 'under_construction_html'  then site.under_construction_html = value
          when 'use_store'                then site.use_store               = value
    	  end
    	end
    	
    	resp.success = save && site.save
    	render :json => resp
    end
    
    # POST /admin/sites/:id/logo
    def admin_update_logo
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      
      site = Site.find(params[:id])       
      site.logo = params[:logo]
      site.save
      
      resp = StdClass.new
      resp.success = true
      resp.attributes = { :image => { :value => site.logo.url(:thumb) }}
      render :json => resp
    end
      
    # DELETE /admin/sites/:id
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      
      site = Site.find(params[:id])
      site.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/sites'
      })
      render :json => resp
    end
    
    # POST /admin/sites/:id/members
    def admin_add_member
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      
      sm = SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).first
      sm = SiteMembership.create(:site_id => params[:id], :user_id => params[:user_id]) if sm.nil?
      sm.role = params[:role]
      sm.save      
      render :json => true
    end
    
    # DELETE /admin/sites/:id/members/:user_id
    def admin_remove_member
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      
      SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).destroy_all        
      render :json => true
    end
    
    # GET /admin/sites/options
    def options
      return if !user_is_allowed('sites', 'view')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      
      options = Site.reorder('name').all.collect { |s| { 'value' => s.id, 'text' => s.name }}
      render :json => options
    end
    
  end
end
