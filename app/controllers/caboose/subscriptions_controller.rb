
module Caboose
  class SubscriptionsController < ApplicationController
            
    #===========================================================================
    # Admin actions
    #===========================================================================
    
    # @route GET /admin/subscriptions
    def admin_index
      return if !user_is_allowed('subscriptions', 'view')
      render :layout => 'caboose/admin'      
    end
    
    # @route GET /admin/subscriptions/json
    def admin_json
      return if !user_is_allowed('subscriptions', 'view')
      
      pager = PageBarGenerator.new(params, {
          'site_id'             => @site.id,          
          'name_like'           => '',
          'description_like'    => '',
          'variant_id'          => '',
          'interval'            => '',
          'prorate'             => '',
          'prorate_method'      => '',
          'prorate_flat_amount' => '',
          'start_on_day'        => '',
          'start_day'           => '',
          'start_month'         => ''                
    		},{
    		  'model'          => 'Caboose::Subscription',
    	    'sort'			     => 'name',
    		  'desc'			     => false,
    		  'base_url'		   => "/admin/subscriptions",
    		  'use_url_params' => false
    	})
    	render :json => {
    	  :pager => pager,
    	  :models => pager.items
    	}
    end

    # @route GET /admin/subscriptions/:id
    def admin_edit
      return if !user_is_allowed('subscriptions', 'edit')    
      @subscription = Subscription.find(params[:id])            
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/subscriptions/:id/json
    def admin_json_single
      return if !user_is_allowed('subscriptions', 'view')    
      s = Subscription.find(params[:id])      
      render :json => s
    end

    # @route POST /admin/subscriptions
    def admin_add
      return unless user_is_allowed('subscriptions', 'add')

      resp = Caboose::StdClass.new            
      name = params[:name]      

      if name.nil? || name.strip.length == 0
        resp.error = "A name is required."
      elsif Subscription.where(:site_id => @site.id, :name => params[:name]).exists?                 
        resp.error = "A subscription with that name already exists."
      else
        s = Subscription.create(
          :site_id             => @site.id,
          :name                => params[:name].strip,                
          :interval            => Subscription::INTERVAL_MONTHLY,
          :prorate             => false,        
          :start_on_day        => false
        )                                    
        resp.redirect = "/admin/subscriptions/#{s.id}"
        resp.success = true
      end                  
      render :json => resp
    end
    
    # @route PUT /admin/subscriptions/:id
    def admin_update
      return unless user_is_allowed('subscriptions', 'edit')
      
      resp = StdClass.new
      models = params[:id] == 'bulk' ? params[:model_ids].collect{ |model_id| Subscription.find(model_id) } : [Subscription.find(params[:id])]
            
      params.each do |k, v|        
        case k
          when 'name'                then models.each{ |s| s.name                = v }
          when 'description'         then models.each{ |s| s.description         = v }
          when 'variant_id'          then models.each{ |s| s.variant_id          = v }
          when 'interval'            then models.each{ |s| s.interval            = v }
          when 'prorate'             then models.each{ |s| s.prorate             = v }
          when 'prorate_method'      then models.each{ |s| s.prorate_method      = v }
          when 'prorate_flat_amount' then models.each{ |s| s.prorate_flat_amount = v }
          when 'prorate_function'    then models.each{ |s| s.prorate_function    = v }
          when 'start_on_day'        then models.each{ |s| s.start_on_day        = v }
          when 'start_day'           then models.each{ |s| s.start_day           = v }
          when 'start_month'         then models.each{ |s| s.start_month         = v }
        end
      end
      models.each{ |s| s.save }
      resp.success = true      
      render :json => resp
    end
    
    # @route DELETE /admin/subscriptions/:id
    def admin_delete
      return unless user_is_allowed('subscriptions', 'delete')
      
      model_ids = params[:id] == 'bulk' ? params[:model_ids] : [params[:id]]      
      model_ids.each do |model_id|
        UserSubscription.where(:subscription_id => model_id).destroy_all
        Subscription.where(:id => model_id).destroy_all
      end
      
      render :json => { :sucess => true }
    end
        
    # @route_priority 1
    # @route GET /admin/subscriptions/:field-options        
    def admin_options
      if !user_is_allowed('subscriptions', 'edit')
        render :json => false
        return
      end
      
      options = []
      case params[:field]                
        when 'interval'
          options = [
            { 'value' => Subscription::INTERVAL_MONTHLY , 'text' => 'Monthly' },
            { 'value' => Subscription::INTERVAL_YEARLY  , 'text' => 'Yearly'  }
          ]                      
        when 'prorate-method'
          options = [
            { 'value' => Subscription::PRORATE_METHOD_FLAT       , 'text' => 'Flat Amount'            },
            { 'value' => Subscription::PRORATE_METHOD_PERCENTAGE , 'text' => 'Percentage of Interval' },
            { 'value' => Subscription::PRORATE_METHOD_CUSTOM     , 'text' => 'Custom'                 }
          ]
        when 'start-day'
          options = (1..31).collect{ |i| { 'value' => i, 'text' => i }}            
        when 'start-month'    
          options = (1..12).collect{ |i| { 'value' => i, 'text' => Date.new(2000, i, 1).strftime('%B') }}
      end              
      render :json => options 		
    end
    
  end
end
