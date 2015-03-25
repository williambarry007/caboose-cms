module Caboose
  class MyAccountOrdersController < Caboose::ApplicationController
            
    helper :authorize_net
    
    # GET /my-account/orders
    def index
      return if !logged_in?
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'customer_id'          => logged_in_user.id,         
        'status'               => [Order::STATUS_PENDING, Order::STATUS_CANCELED, Order::STATUS_READY_TO_SHIP, Order::STATUS_SHIPPED]        
      }, {
        'model'          => 'Caboose::Order',
        'sort'           => 'order_number',
        'desc'           => 1,
        'base_url'       => '/my-account/orders',
        'use_url_params' => false
      })      
      @orders = @pager.all_items
    end
      
    # GET /my-account/orders/:id
    def edit
      return if !logged_in?
      
      @order = Order.find(params[:id])
      if @order.customer_id != logged_in_user.id
        @error = "The given order does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end

      if @order.financial_status == Order::FINANCIAL_STATUS_PENDING
        
        sc = @site.store_config
        case sc.pp_name
          when 'authorize.net'
                        
            @sim_transaction = AuthorizeNet::SIM::Transaction.new(
              sc.pp_username, 
              sc.pp_password, 
              @order.total,                          
              :relay_response => 'TRUE',              
              :relay_url => "#{sc.pp_relay_domain}/my-account/orders/authnet-relay",
              :transaction_type => 'AUTH_ONLY',                        
              :test => sc.pp_testing
            )
            @request = request
            @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
            
          when 'stripe'
            # TODO: Implement manual order payment for stripe
            
        end
      end
      
    end
    
    # GET /my-account/orders/:id/json
    def order_json
      return if !logged_in?
      
      order = Order.find(params[:id])
      if order.customer_id != logged_in_user.id        
        render :json => { :error => "The given order does not belong to you." } 
        return
      end
      
      if order.shipping_address_id.nil?
        sa = Address.create
        order.shipping_address_id = sa.id
        order.save
      end
      render :json => order.as_json(:include => [        
        { :line_items => { :include => { :variant => { :include => :product }}}},
        { :order_packages => { :include => [:shipping_package, :shipping_method] }},
        { :discounts => { :include => :gift_card }},
        :customer,
        :shipping_address,
        :billing_address,
        :order_transactions
      ])
    end
    
    # POST /my-account/orders/authnet-relay
    def authnet_relay
      Caboose.log("Authorize.net relay for my account, order #{params[:x_invoice_id]}")
      
      order = Caboose::Order.find(params[:x_invoice_num])
      ot = Caboose::OrderTransaction.new(
        :order_id => order.id,
        :date_processed => DateTime.now.utc,
        :transaction_type => Caboose::OrderTransaction::TYPE_AUTHORIZE
      )
      ot.success        = params[:x_response_code] && params[:x_response_code] == '1'
      ot.transaction_id = params[:x_trans_id] if params[:x_trans_id]              
      ot.auth_code      = params[:x_auth_code] if params[:x_auth_code]
      ot.response_code  = params[:x_response_code] if params[:x_response_code]
      ot.amount         = order.total
      ot.save
      
      error = nil
      if ot.success
        order.financial_status = Order::FINANCIAL_STATUS_AUTHORIZED
        order.status = Order::STATUS_PENDING if order.status == Order::STATUS_CART
        order.order_number = @site.store_config.next_order_number if order.order_number.nil?
        
        # Send out emails        
        OrdersMailer.configure_for_site(@site.id).customer_new_order(order).deliver                
        
        # Emit order event
        Caboose.plugin_hook('order_authorized', order)        
      else
        order.financial_status = Order::FINANCIAL_STATUS_PENDING        
        error = "There was a problem processing your payment."
      end
            
      order.save
      
      @url = params[:x_after_relay]
      @url << (ot.success ? "?success=1" : "?error=#{error}")             
                  
      render :layout => false
    end
    
    # GET  /my-account/orders/:id/authnet-response
    # POST /my-account/orders/:id/authnet-response    
    def authnet_response
      Caboose.log("Authorize.net response for my account, order #{params[:id]}")
      
      @resp = Caboose::StdClass.new
      @resp.success = true if params[:success]
      @resp.error = params[:error] if params[:error]
      
      # Go ahead and capture funds if the order only contained downloadable items
      @order = Order.find(params[:id])
      if !@order.has_shippable_items?
        capture_resp = @order.capture_funds
        if capture_resp.error
          @resp.success = false
          @resp.error = capture_resp.error
        end        
      end      
      render :layout => false
    end
            
  end
end
