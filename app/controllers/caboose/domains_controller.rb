require 'csv'

module Caboose
  class DomainsController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # @route POST /admin/sites/:site_id/domains
    def admin_add
      return if !user_is_allowed('domains', 'edit')
      
      resp = Caboose::StdClass.new      
      d = Domain.where(:domain => params[:domain]).first
            
      if d && d.site_id != params[:site_id]
        resp.error = "That domain is already associated with another site."
      elsif d && d.site_id == params[:site_id]
        resp.refresh = true
      elsif d.nil?
        primary = Domain.where(:site_id => params[:site_id]).count == 0        
        d = Domain.create(:site_id => params[:site_id], :domain => params[:domain], :primary => primary)
        resp.refresh = true
      end
      render :json => resp
    end
    
    # @route PUT /admin/sites/:site_id/domains/:id
    def admin_update
      return if !user_is_allowed('domains', 'edit')

      resp = StdClass.new     
      d = Domain.find(params[:id])
    
      save = true
      params.each do |name,value|
        case name
          when 'site_id'            then d.site_id            = value
          when 'domain'             then d.domain             = value
          when 'under_construction' then d.under_construction = value
          when 'forward_to_primary' then d.forward_to_primary = value
          when 'forward_to_uri'     then d.forward_to_uri     = value
          when 'force_ssl'     then d.force_ssl     = value
          when 'primary'            then
            d.primary = value
            Domain.where(:site_id => params[:site_id]).all.each do |d2|
              d2.primary = d2.id == d.id ? true : false
              d2.save
            end
    	  end
    	end
    	
    	resp.success = save && d.save
    	render :json => resp
    end        
      
    # @route DELETE /admin/sites/:site_id/domains/:id
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
      Domain.find(params[:id]).destroy
      render :json => { 'refresh' => "/admin/sites/#{params[:site_id]}" }
    end

    # @route PUT /admin/sites/:site_id/domains/:id/set-primary
    def admin_set_primary
      return if !user_is_allowed('domains', 'edit')
      resp = StdClass.new     
      d = Domain.find(params[:id])
      save = true
      #d.primary = value
      Domain.where(:site_id => params[:site_id]).all.each do |d2|
        d2.primary = d2.id == d.id ? true : false
        d2.save
      end      
      resp.success = save && d.save
      render :json => resp
    end 
            
  end
end
