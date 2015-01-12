require 'csv'

module Caboose
  class SmtpController < ApplicationController
    layout 'caboose/admin'
    
    # GET /admin/smtp
    def admin_edit
      return if !user_is_allowed('smtp', 'edit')            
      @smtp_config = @site.smtp_config
      @smtp_config = SmtpConfig.create(:site_id => @site.id) if @smtp_config.nil?
    end
    
    # PUT /admin/smtp
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sc = @site.smtp_config
      sc = SmtpConfig.create(:site_id => @site.id) if sc.nil?
          
      save = true
      params.each do |name,value|
        case name
          when 'site_id'              then sc.site_id              = value
          when 'address'              then sc.address              = value
          when 'port'                 then sc.port                 = value
          when 'domain'               then sc.domain               = value
          when 'user_name'            then sc.user_name            = value
          when 'password'             then sc.password             = value
          when 'authentication'       then sc.authentication       = value
          when 'enable_starttls_auto' then sc.enable_starttls_auto = value          
    	  end
    	end
    	
    	resp.success = save && sc.save
    	render :json => resp
    end        
    
    # GET /admin/smtp/auth-options
    def auth_options
      return if !user_is_allowed('smtp', 'view')
      options = [
        { 'value' => SmtpConfig::AUTH_PLAIN , 'text' => SmtpConfig::AUTH_PLAIN },
        { 'value' => SmtpConfig::AUTH_LOGIN , 'text' => SmtpConfig::AUTH_LOGIN },
        { 'value' => SmtpConfig::AUTH_MD5   , 'text' => SmtpConfig::AUTH_MD5   }                  
      ]
      render :json => options
    end
    
  end
end
