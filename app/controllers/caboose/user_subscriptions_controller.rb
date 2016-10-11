#
#module Caboose
#  class UserSubscriptionsController < ApplicationController
#            
#    #===========================================================================
#    # Admin actions
#    #===========================================================================
#    
#    # @route GET /admin/users/:user_id/subscriptions
#    def admin_index
#      return if !user_is_allowed('usersubscriptions', 'view')
#      render :layout => 'caboose/admin'      
#    end
#    
#    # @route GET /admin/users/:user_id/subscriptions/json
#    def admin_json
#      return if !user_is_allowed('usersubscriptions', 'view')
#      
#      pager = PageBarGenerator.new(params, {
#          'subscription_id'       => '',
#          'user_id'               => params[:user_id],
#          'date_started_gte'      => '',
#          'date_started_lte'      => '',
#          'date_started_full_gte' => '',
#          'date_started_full_lte' => '',
#          'status'                => ''                                
#    		},{
#    		  'model'          => 'Caboose::UserSubscription',
#    	    'sort'			     => 'date_started',
#    		  'desc'			     => false,
#    		  'base_url'		   => "/admin/users/#{params[:user_id]}/subscriptions",
#    		  'use_url_params' => false
#    	})
#    	render :json => {
#    	  :pager => pager,
#    	  :models => pager.items
#    	}
#    end
#
#    # @route GET /admin/users/:user_id/subscriptions/:id
#    def admin_edit
#      return if !user_is_allowed('usersubscriptions', 'edit')    
#      @user_subscription = UserSubscription.find(params[:id])            
#      render :layout => 'caboose/admin'
#    end
#    
#    # @route GET /admin/users/:user_id/subscriptions/:id/json
#    def admin_json_single
#      return if !user_is_allowed('usersubscriptions', 'view')    
#      us = UserSubscription.find(params[:id])      
#      render :json => us
#    end
#
#    # @route POST /admin/users/:user_id/subscriptions
#    def admin_add
#      return unless user_is_allowed('usersubscriptions', 'add')
#
#      resp = Caboose::StdClass.new            
#      s = params[:subscription_id] ? Subscription.where(:id => params[:subscription_id]).first : nil      
#
#      if subscription_id.nil? || s.nil? || s.site_id != @site.id 
#        resp.error = "A valid subscription is required."      
#      else
#        us = UserSubscription.create(
#          :subscription_id   => s.id,
#          :user_id           => params[:user_id],
#          :date_started      => Date.today,
#          :date_started_full => Date.today,
#          :status            => UserSubcription::STATUS_ACTIVE
#        )                                    
#        resp.redirect = "/admin/users/#{params[:user_id]}/subscriptions/#{us.id}"
#        resp.success = true
#      end                  
#      render :json => resp
#    end
#    
#    # @route PUT /admin/users/:user_id/subscriptions/:id
#    def admin_update
#      return unless user_is_allowed('usersubscriptions', 'edit')
#      
#      resp = StdClass.new
#      models = params[:id] == 'bulk' ? params[:model_ids].collect{ |model_id| UserSubscription.find(model_id) } : [UserSubscription.find(params[:id])]
#            
#      params.each do |k, v|        
#        case k
#          when 'subscription_id'   then models.each{ |us| us.subscription_id   = v }
#          when 'user_id'           then models.each{ |us| us.user_id           = v }
#          when 'date_started'      then models.each{ |us| us.date_started      = v }
#          when 'date_started_full' then models.each{ |us| us.date_started_full = v }
#          when 'status'            then models.each{ |us| us.status            = v }                
#        end
#      end
#      models.each{ |us| us.save }
#      resp.success = true      
#      render :json => resp
#    end
#    
#    # @route DELETE /admin/users/:user_id/subscriptions/:id
#    def admin_delete
#      return unless user_is_allowed('usersubscriptions', 'delete')
#      
#      model_ids = params[:id] == 'bulk' ? params[:model_ids] : [params[:id]]      
#      model_ids.each do |model_id|
#        UserSubscription.where(:id => model_id).destroy_all        
#      end
#      
#      render :json => { :sucess => true }
#    end
#        
#    # @route_priority 1
#    # @route GET /admin/user-subscriptions/:field-options
#    # @route GET /admin/users/:user_id/subscriptions/:field-options        
#    def admin_options
#      if !user_is_allowed('subscriptions', 'edit')
#        render :json => false
#        return
#      end
#      
#      options = []
##      case params[:field]                
##        when 'subscription'
##          options = Subcription.where(:site_id => @site.id).reorder(:name).
##      :status
##      
##    STATUS_ACTIVE   = 'active'
##    STATUS_INACTIVE = 'inactive'
##    
##        when 'interval'
##          options = [
##            { 'value' => Subscription::INTERVAL_MONTHLY , 'text' => 'Monthly' },
##            { 'value' => Subscription::INTERVAL_YEARLY  , 'text' => 'Yearly'  }
##          ]                      
##        when 'prorate-method'
##          options = [
##            { 'value' => Subscription::PRORATE_METHOD_FLAT       , 'text' => 'Flat Amount'            },
##            { 'value' => Subscription::PRORATE_METHOD_PERCENTAGE , 'text' => 'Percentage of Interval' },
##            { 'value' => Subscription::PRORATE_METHOD_CUSTOM     , 'text' => 'Custom'                 }
##          ]
##        when 'start-day'
##          options = (1..31).collect{ |i| { 'value' => i, 'text' => i }}            
##        when 'start-month'    
##          options = (1..12).collect{ |i| { 'value' => i, 'text' => Date.new(2000, i, 1).strftime('%B') }}
##      end              
#      render :json => options 		
#    end
#    
#  end
#end
