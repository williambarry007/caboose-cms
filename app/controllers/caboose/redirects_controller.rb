
module Caboose
  class RedirectsController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end    
    
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # GET /admin/redirects
    def admin_index
      return if !user_is_allowed('redirects', 'view')            
      @domain = Domain.where(:domain => request.host_with_port).first      
      @redirects = @domain ? PermanentRedirect.where(:site_id => @domain.site_id).reorder(:priority).all : []            
      render :layout => 'caboose/admin'      
    end

    # GET /admin/redirects/new
    def admin_new
      return unless user_is_allowed('redirects', 'add')            
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/redirects/:id
    def admin_edit
      return unless user_is_allowed('redirects', 'edit')
      @permanent_redirect = PermanentRedirect.find(params[:id])
      render :layout => 'caboose/admin'
    end
                
    # PUT /admin/redirects/priority
    def admin_update_priority
      return unless user_is_allowed('redirects', 'edit')      
      @page = Page.find(params[:id])
      ids = params[:ids]
      i = 0
      ids.each do |prid|
        pr = PermanentRedirect.find(prid)
        pr.priority = i
        pr.save
        i = i + 1
      end
      render :json => true
    end
    
    # POST /admin/redirects
    def admin_add
      return unless user_is_allowed('redirects', 'add')

      resp = Caboose::StdClass.new

      pr = PermanentRedirect.new
      pr.site_id = Site.id_for_domain(request.host_with_port)
      pr.is_regex = false
      pr.old_url  = params[:old_url]
      pr.new_url  = params[:new_url]
      pr.priority = 0

      if !pr.valid?        
        resp.error = pr.errors.first[1]
      else
        pr.save
        resp.redirect = "/admin/redirects/#{pr.id}"
      end

      render :json => resp
    end
    
    # PUT /admin/redirects/:id
    def admin_update
      return unless user_is_allowed('redirects', 'edit')
      
      resp = StdClass.new
      pr = PermanentRedirect.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'is_regex'  then pr.is_regex = value
          when 'old_url'   then pr.old_url  = value
          when 'new_url'   then pr.new_url  = value
          when 'priority'  then pr.priority = value        
        end
      end
    
      resp.success = save && pr.save
      render :json => resp
    end
    
    # DELETE /admin/redirects/:id
    def admin_delete
      return unless user_is_allowed('redirects', 'delete')
      pr = PermanentRedirect.find(params[:id])
      pr.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/redirects'
      })
      render :json => resp
    end
		
  end
end
