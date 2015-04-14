require 'cgi'
require 'open-uri'
require 'httparty'

module Caboose
  class RetargetingController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
    
    # GET /admin/sites/:site_id/retargeting
    def admin_edit
      return if !user_is_allowed('sites', 'edit')       
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end      
      @site = Site.find(params[:site_id])
    end
        
    # PUT /admin/sites/:id/retargeting
    def admin_update
      render :json => { :error => "You are not allowed to manage sites." } and return if !user_is_allowed('sites', 'edit') || !@site.is_master
      
      resp = StdClass.new     
      site = Site.find(params[:site_id])
      rc = site.retargeting_config
    
      params.each do |name,value|
        case name          
          when 'google_conversion_id'   then rc.google_conversion_id   = value    
          when 'google_labels_function' then rc.google_labels_function = value
          when 'fb_pixel_id'            then rc.fb_pixel_id            = value
          when 'fb_vars_function'       then rc.fb_vars_function       = value
    	  end
    	end
    	
    	resp.success = rc.save
    	render :json => resp
    end
    
    ## GET /admin/sites/:id/retargeting/fb-auth
    #def admin_fb_auth      
    #  if params[:code]                     
    #    domain = "#{request.protocol}#{request.host}"
    #    domain << ":#{request.port}" if request.port != 80
    #    h = {
    #      :client_id     => "664751370321086",
    #      :redirect_uri  => "#{domain}/admin/sites/#{params[:site_id]}/retargeting/fb-auth/",
    #      :client_secret => "7724cd8006af75d5ab89aa1157057e71",
    #      :code          => params[:code]
    #    }
    #    h = h.collect{ |k,v| "#{k}=#{URI::encode(v)}" }.join('&')
    #    resp = HTTParty.get("https://graph.facebook.com/oauth/access_token?#{h}")        
    #    h = CGI::parse(resp.body)
    #    
    #    site = Site.find(params[:site_id])
    #    rc = site.retargeting_config
    #    rc.fb_access_token = h['access_token'].first         
    #    rc.fb_access_token_expires = DateTime.now.utc + h['expires'].first.to_i.seconds
    #    rc.save                
    #    redirect_to "/admin/sites/#{site.id}/retargeting"
    #    
    #  else
    #    domain = "#{request.protocol}#{request.host}"
    #    domain << ":#{request.port}" if request.port != 80
    #    h = {        
    #      :client_id     => "664751370321086",
    #      :redirect_uri => "#{domain}/admin/sites/#{params[:site_id]}/retargeting/fb-auth/",
    #      :scope        => "ads_management"
    #    }
    #    h = h.collect{ |k,v| "#{k}=#{URI::encode(v)}" }.join('&')
    #    redirect_to "https://www.facebook.com/dialog/oauth?#{h}"                    
    #  end        
    #end
    #
    ## GET /admin/sites/:site_id/retargeting/fb-audiences
    #def admin_fb_audiences
    #  site = Site.find(params[:site_id])
    #  rc = site.retargeting_config
    #  
    #  resp = HTTParty.get("https://graph.facebook.com/v2.3/act_279723427/customaudiences", :query => {
    #    :access_token => rc.fb_access_token,
    #    :fields => "id,name,subtype,approximate_count"
    #  })
    #  render :json => resp.body      
    #end
    #
    ## GET /admin/sites/:site_id/retargeting/fb-audiences/:custom_audience_id
    #def admin_fb_audience_members
    #  site = Site.find(params[:site_id])
    #  rc = site.retargeting_config
    #  
    #  resp = HTTParty.get("https://graph.facebook.com/v2.3/#{params[:custom_audience_id]}", :query => {
    #    :access_token => rc.fb_access_token,
    #    :fields => "id,name,subtype,approximate_count"
    #  })
    #  render :json => resp.body
    #end
            
  end
end
 