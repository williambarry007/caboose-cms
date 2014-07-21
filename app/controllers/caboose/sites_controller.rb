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
      @site = Site.new
    end
    
    # GET /admin/sites/1/edit
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      @site = Site.find(params[:id])
    end
        
    # POST /admin/sites
    def admin_add
      return if !user_is_allowed('sites', 'add')
      
      resp = StdClass.new      
      site = Site.new
      site.name = params[:name].strip
      
      if site.name.length == 0
        resp.error = "Please enter a valid domain."      
      else
        site.save
        resp.redirect = "/admin/sites/#{site.id}"
      end
      
      render :json => resp
    end
    
    # PUT /admin/sites/:id
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      site = Site.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'name'         then site.name          = value
          when 'description'  then site.description   = value               		  
    	  end
    	end
    	
    	resp.success = save && site.save
    	render :json => resp
    end        
      
    # DELETE /admin/sites/1
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
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
      sm = SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).first
      sm = SiteMembership.create(:site_id => params[:id], :user_id => params[:user_id]) if sm.nil?
      sm.role = params[:role]
      sm.save      
      render :json => true
    end
    
    # DELETE /admin/sites/:id/members/:user_id
    def admin_remove_member
      return if !user_is_allowed('sites', 'edit')
      SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).destroy_all        
      render :json => true
    end
    
    # POST /admin/sites/:id/domains
    def admin_add_domain
      return if !user_is_allowed('sites', 'edit')
      
      resp = Caboose::StdClass.new      
      d = Domain.where(:domain => params[:domain]).first
            
      if d && d.site_id != params[:id]
        resp.error = "That domain is already associated with another site."
      elsif d && d.site_id == params[:id]
        resp.refresh = true
      elsif d.nil?
        primary = Domain.where(:site_id => params[:id]).count == 0        
        d = Domain.create(:site_id => params[:id], :domain => params[:domain], :primary => primary)
        resp.refresh = true
      end
      render :json => resp
    end
    
    # PUT /admin/sites/:id/domains/:domain_id/set-primary
    def admin_set_primary_domain
      return if !user_is_allowed('sites', 'edit')
      
      domain_id = params[:domain_id].to_i
      Domain.where(:site_id => params[:id]).all.each do |d|
        d.primary = d.id == domain_id ? true : false
        d.save
      end       
      render :json => true
    end
    
    # DELETE /admin/sites/:id/domains/:domain_id
    def admin_remove_domain
      return if !user_is_allowed('sites', 'edit')
      Domain.find(params[:domain_id]).destroy
      if Domain.where(:site_id => params[:id]).count == 1
        d = Domain.where(:site_id => params[:id]).first
        d.primary = true
        d.save
      end
      render :json => { 'refresh' => true }
    end        
    
    # GET /admin/sites/options
    def options
      return if !user_is_allowed('sites', 'view')
      options = Site.reorder('name').all.collect { |s| { 'value' => s.id, 'text' => s.name }}
      render :json => options
    end
    
  end
end
