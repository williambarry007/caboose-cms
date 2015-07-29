
module Caboose
  class LoginLogsController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end
            
    # GET /admin/login-logs
    def index
      return if !user_is_allowed('users', 'view')
      
      @gen = PageBarGenerator.new(params, {
          'site_id'            => @site.id,
          'username_like'      => '',
          'user_id'            => '',
          'date_attempted_lte' => '',
          'date_attempted_gte' => '',
          'ip_like'            => '',        
          'success'            => ''              
    		},{
    		  'model'          => 'Caboose::LoginLog',
    	    'sort'			     => 'date_attempted',
    		  'desc'			     => false,
    		  'base_url'		   => '/admin/login-logs',
    		  'use_url_params' => false
    	})
    	@logs = @gen.items
    end       
    
  end
end

