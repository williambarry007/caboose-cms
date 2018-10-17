
module Caboose
  class LoginLogsController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end

    # @route GET /admin/login-logs/user/:userid
    def admin_index_for_user
      return if !user_is_allowed_to 'view', 'loginlogs'
      @pager = self.login_logs_pager
      @edituser = Caboose::User.find(params[:userid]) if !params[:userid].blank?
      render :layout => 'caboose/admin'    
    end
    
    # @route GET /admin/login-logs
    def admin_index
      return if !user_is_allowed_to 'view', 'loginlogs'
      @pager = self.login_logs_pager
      render :layout => 'caboose/admin'    
    end
    
    # @route GET /admin/login-logs/json
    def admin_json
      return if !user_is_allowed_to 'view', 'loginlogs'
      pager = self.login_logs_pager        
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
    end
    
    def login_logs_pager
      return Caboose::Pager.new(params, {
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
    		  'items_per_page' => 100,
    		  'base_url'		   => '/admin/login-logs',
    		  'use_url_params' => false
    	})    	
    end
    
    # @route GET /admin/login-logs/:id/json
    def admin_json_single
      return if !user_is_allowed_to 'view', 'loginlogs'
      login_log = LoginLog.find(params[:id])      
      render :json => login_log
    end
    
    # @route GET /admin/login-logs/:id
    def admin_edit
      return if !user_is_allowed_to 'edit', 'loginlogs'
      @login_log = LoginLog.find(params[:id])
	    render :layout => 'caboose/admin'
    end
    
  end
end

