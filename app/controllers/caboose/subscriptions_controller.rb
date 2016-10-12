
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
    
    # @route GET /admin/users/:user_id/subscriptions
    def admin_user_index
      return if !user_is_allowed('subscriptions', 'view')
      @edituser = User.find(params[:user_id])
      render :layout => 'caboose/admin'      
    end
    
    # @route GET /admin/subscriptions/json
    # @route GET /admin/users/:user_id/subscriptions/json
    def admin_json
      return if !user_is_allowed('subscriptions', 'view')
      
      pager = PageBarGenerator.new(params, {
          'variant_id'            => '',
          'user_id'               => params[:user_id] ? params[:user_id] : '',
          'date_started_gte'      => '',
          'date_started_lte'      => '',
          'date_started_full_gte' => '',
          'date_started_full_lte' => '',
          'status'                => ''                                
    		},{
    		  'model'          => 'Caboose::Subscription',
    	    'sort'			     => 'date_started',
    		  'desc'			     => false,
    		  'base_url'		   => params[:user_id] ? "/admin/users/#{params[:user_id]}/subscriptions" : '/admin/subscriptions',
    		  'use_url_params' => false
    	})
    	render :json => {
    	  :pager => pager,
    	  :models => pager.items.as_json(:include => [:user, :subscription])
    	}
    end

    # @route GET /admin/subscriptions/:id
    # @route GET /admin/users/:user_id/subscriptions/:id
    def admin_edit
      return if !user_is_allowed('subscriptions', 'edit')    
      @subscription = Subscription.find(params[:id])      
      @edituser = @subscription.user
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/users/:user_id/subscriptions/:id/json
    def admin_json_single
      return if !user_is_allowed('subscriptions', 'view')    
      s = Subscription.find(params[:id])      
      render :json => s
    end

    # @route POST /admin/users/:user_id/subscriptions
    def admin_add
      return unless user_is_allowed('subscriptions', 'add')

      resp = Caboose::StdClass.new            
      v = params[:variant_id] ? Variant.where(:id => params[:variant_id]).first : nil      

      if params[:variant_id].nil? || v.nil? || v.product.site_id != @site.id || !v.is_subscription 
        resp.error = "A valid subscription variant is required."      
      else
        s = Subscription.create(
          :variant_id        => v.id,
          :user_id           => params[:user_id],
          :date_started      => Date.today,
          :date_started_full => Date.today,
          :status            => UserSubcription::STATUS_ACTIVE
        )                                    
        resp.redirect = "/admin/users/#{params[:user_id]}/subscriptions/#{s.id}"
        resp.success = true
      end                  
      render :json => resp
    end
    
    # @route PUT /admin/users/:user_id/subscriptions/:id
    def admin_update
      return unless user_is_allowed('subscriptions', 'edit')
      
      resp = StdClass.new
      models = params[:id] == 'bulk' ? params[:model_ids].collect{ |model_id| Subscription.find(model_id) } : [Subscription.find(params[:id])]
            
      params.each do |k, v|        
        case k
          when 'variant_id'        then models.each{ |s| s.variant_id        = v }
          when 'user_id'           then models.each{ |s| s.user_id           = v }
          when 'date_started'      then models.each{ |s| s.date_started      = v }
          when 'date_started_full' then models.each{ |s| s.date_started_full = v }
          when 'status'            then models.each{ |s| s.status            = v }                
        end
      end
      models.each{ |s| s.save }
      resp.success = true      
      render :json => resp
    end
       
    # @route POST /admin/users/:user_id/subscriptions/:id/invoices
    def admin_create_invoices
      return if !user_is_allowed('subscriptions', 'edit')    
      s = Subscription.find(params[:id])
      s.create_invoices
      render :json => { :success => true }      
    end
    
    # @route DELETE /admin/users/:user_id/subscriptions/:id
    def admin_delete
      return unless user_is_allowed('subscriptions', 'delete')
      
      model_ids = params[:id] == 'bulk' ? params[:model_ids] : [params[:id]]      
      model_ids.each do |model_id|
        Subscription.where(:id => model_id).destroy_all        
      end
      
      render :json => { :sucess => true }
    end
        
    # @route_priority 1
    # @route GET /admin/subscriptions/:field-options
    # @route GET /admin/users/:user_id/subscriptions/:field-options        
    def admin_options
      if !user_is_allowed('subscriptions', 'edit')
        render :json => false
        return
      end
      
      options = []
      case params[:field]                
        when 'variant'
          arr = Variant.join(:product.where("store_products.site_id = ? and is_subscription = ?", @site.id, true).reorder("store_products.title").all          
          options = arr.collect{ |v| { 'value' => v.id, 'text' => v.product.title }}
        when 'status'
          options = [
            { 'value' => Subscription::STATUS_ACTIVE   , 'text' => 'Active'   },
            { 'value' => Subscription::STATUS_INACTIVE , 'text' => 'Inactive' }
          ]          
        when 'user'
          arr = User.where(:site_id => @site.id).reorder('last_name, first_name').all          
          options = arr.collect{ |u| { 'value' => u.id, 'text' => "#{u.first_name} #{u.last_name}" }}
      end              
      render :json => options 		
    end
    
  end
end
