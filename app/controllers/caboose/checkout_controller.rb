
module Caboose
  class CheckoutController < Caboose::ApplicationController
    
    helper :authorize_net
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery :except => :authnet_relay
    
    def ensure_line_items
      redirect_to '/checkout/empty' if @order.line_items.empty?
    end
    
    # Step 1 - Login or register
    # GET /checkout
    def index        
      if logged_in?
        if @order.customer_id.nil?
          @order.customer_id = logged_in_user.id
          @order.save
        end
        redirect_to '/checkout/addresses'
        return        
      end
    end
    
    # Step 2 - Shipping and billing addresses
    # GET /checkout/addresses
    def addresses      
      redirect_to '/checkout' if !logged_in?      
      @logged_in_user = logged_in_user      
    end
    
    # Step 3 - Shipping method
    # GET /checkout/shipping
    def shipping
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      
      @order.calculate
                  
      if !@order.has_shippable_items?
        redirect_to '/checkout/gift-cards'
        return
      end
      
      # Remove any order packages      
      LineItem.where(:order_id => @order.id).update_all(:order_package_id => nil)
      OrderPackage.where(:order_id => @order.id).destroy_all      
        
      # Calculate what shipping packages we'll need            
      OrderPackage.create_for_order(@order)

      # Now get the rates for those packages            
      @rates = ShippingCalculator.rates(@order)
      
      #Caboose.log(@rates.inspect)
      @logged_in_user = logged_in_user      
    end
    
    # Step 4 - Gift cards
    # GET /checkout/gift-cards
    def gift_cards
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?
      @logged_in_user = logged_in_user
    end
    
    # Step 5 - Payment
    # GET /checkout/payment
    def payment
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?
      redirect_to '/checkout/confirm'   and return if @order.total == 0.00      
      
      # Make sure all the variants still exist      
      @order.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :file => 'caboose/checkout/deleted_variant'
          return
        end
      end
      
      store_config = @site.store_config
      case store_config.pp_name
        when 'authorize.net'
          
          sc = @site.store_config
          @sim_transaction = AuthorizeNet::SIM::Transaction.new(
            sc.pp_username, 
            sc.pp_password, 
            @order.total,            
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay/#{@order.id}",
            :relay_response => 'TRUE',
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay",
            :relay_url => "#{sc.pp_relay_domain}/checkout/authnet-relay",
            :transaction_type => 'AUTH_ONLY',                        
            :test => sc.pp_testing
          )
          @request = request
          @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
          
        when 'payscape'
          @form_url = Caboose::PaymentProcessor.form_url(@order)
      end
      @logged_in_user = logged_in_user
    end
        
    # GET /checkout/confirm
    def confirm_without_payment
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?
      redirect_to '/checkout/payment'   and return if @order.total > 0.00      
      
      # Make sure all the variants still exist      
      @order.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :file => 'caboose/checkout/deleted_variant'
          return
        end
      end
      @logged_in_user = logged_in_user
    end
    
    # POST /checkout/confirm
    def confirm
      render :json => { :error => 'Not logged in.'            } and return if !logged_in?
      render :json => { :error => 'Invalid addresses.'        } and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      render :json => { :error => 'Invalid shipping methods.' } and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?
      render :json => { :error => 'Order requires payment.'   } and return if @order.total > 0.00
      
      resp = Caboose::StdClass.new
                  
      @order.financial_status = Order::FINANCIAL_STATUS_AUTHORIZED
      @order.status = Order::STATUS_PENDING
      @order.order_number = @site.store_config.next_order_number
         
      # Take funds from any gift cards that were used on the order
      @order.take_gift_card_funds
        
      # Send out emails        
      OrdersMailer.configure_for_site(@site.id).customer_new_order(@order).deliver
      OrdersMailer.configure_for_site(@site.id).fulfillment_new_order(@order).deliver        
        
      # Emit order event
      Caboose.plugin_hook('order_authorized', @order)
      
      # Save the order
      @order.save
      
      # Clear the cart and re-initialize                    
      session[:cart_id] = nil
      init_cart
      
      resp.success = true
      resp.redirect = '/checkout/thanks'      
      render :json => resp
    end
    
    # GET /checkout/thanks
    def thanks
      @logged_in_user = logged_in_user
      
      # Find the last order for the user
      @last_order = Order.where(:customer_id => @logged_in_user.id).order("id desc").limit(1).first
            
    end
    
    #===========================================================================
    
    # GET /checkout/address
    def address
      render :json => {
        :shipping_address => @order.shipping_address,
        :billing_address => @order.billing_address
      }
    end
    
    # PUT /checkout/addresses
    def update_addresses
      
      # Grab or create addresses
      shipping_address = if @order.shipping_address then @order.shipping_address else Address.new end
      billing_address  = if @order.billing_address  then @order.billing_address  else Address.new end
            
      has_shippable_items = @order.has_shippable_items?
        
      # Shipping address
      if has_shippable_items
        shipping_address.first_name = params[:shipping][:first_name]
        shipping_address.last_name  = params[:shipping][:last_name]
        shipping_address.company    = params[:shipping][:company]
        shipping_address.address1   = params[:shipping][:address1]
        shipping_address.address2   = params[:shipping][:address2]
        shipping_address.city       = params[:shipping][:city]
        shipping_address.state      = params[:shipping][:state]
        shipping_address.zip        = params[:shipping][:zip]
      end
      
      # Billing address
      if has_shippable_items && params[:use_as_billing]
        billing_address.update_attributes(shipping_address.attributes)
      else
        billing_address.first_name = params[:billing][:first_name]
        billing_address.last_name  = params[:billing][:last_name]
        billing_address.company    = params[:billing][:company]
        billing_address.address1   = params[:billing][:address1]
        billing_address.address2   = params[:billing][:address2]
        billing_address.city       = params[:billing][:city]
        billing_address.state      = params[:billing][:state]
        billing_address.zip        = params[:billing][:zip]
      end
      
      # Save address info; generate ids      
      render :json => { :success => false, :errors => shipping_address.errors.full_messages, :address => 'shipping' } and return if has_shippable_items && !shipping_address.save
      render :json => { :success => false, :errors => billing_address.errors.full_messages, :address => 'billing' } and return if !billing_address.save
      
      # Associate address info with order
      @order.shipping_address_id = shipping_address.id
      @order.billing_address_id  = billing_address.id
      
      #render :json => { :redirect => 'checkout/shipping' }
      render :json => { :success => @order.save, :errors => @order.errors.full_messages }
    end
    
    # POST /checkout/attach-user
    def attach_user              
      render :json => { :success => false, :errors => ['User is not logged in'] } and return if !logged_in?
      @order.customer_id = logged_in_user.id
      #Caboose.log("Attaching user to order: customer_id = #{@order.customer_id}")
      render :json => { :success => @order.save, :errors => @order.errors.full_messages, :logged_in => logged_in? }
    end
    
    # POST /checkout/guest
    def attach_guest
      resp = Caboose::StdClass.new      
      email = params[:email]      
      
      if email != params[:confirm_email]
        resp.error = "Emails do not match."
      elsif Caboose::User.where(:email => email, :is_guest => false).exists?
        resp.error = "A user with that email address already exists."
      else
        user = Caboose::User.where(:email => email, :is_guest => true).first
        if user.nil?        
          user = Caboose::User.create(:email => email)
          user.is_guest = true
          user.save
          user = Caboose::User.where(:email => email).first
        end                   
        @order.customer_id = user.id
        login_user(user)
        
        if !@order.valid?        
          resp.errors = @order.errors.full_messages
        else
          @order.save
          resp.redirect = '/checkout/addresses'
        end
      end
      render :json => resp            
    end
    
    # PUT /checkout/shipping
    def update_shipping
      op = OrderPackage.find(params[:order_package_id])
      op.shipping_method_id = params[:shipping_method_id]
      op.total = params[:total]
      op.save
      op.order.calculate
                                   
      render :json => { :success => true }               
    end
    
    # GET /checkout/payment
    #def payment
    #  case Caboose::payment_processor
    #    when 'authorize.net'                             
    #      @sim_transaction = AuthorizeNet::SIM::Transaction.new(
    #        Caboose::authorize_net_login_id,
    #        Caboose::authorize_net_transaction_key,
    #        @order.total,
    #        :relay_url => "#{Caboose::root_url}/checkout/relay/#{@order.id}",
    #        :transaction_type => 'AUTH_ONLY',
    #        :test => true
    #      )
    #    when 'payscape'
    #      @form_url = Caboose::PaymentProcessor.form_url(@order)
    #  end      
    #  render :layout => false
    #end
        
    # POST /checkout/authnet-relay
    def authnet_relay
      Caboose.log("Authorize.net relay, order #{params[:x_invoice_id]}")
      
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
        order.status = Order::STATUS_PENDING
        order.order_number = @site.store_config.next_order_number
         
        # Take funds from any gift cards that were used on the order
        order.take_gift_card_funds
        
        # Send out emails        
        OrdersMailer.configure_for_site(@site.id).customer_new_order(order).deliver
        OrdersMailer.configure_for_site(@site.id).fulfillment_new_order(order).deliver        
        
        # Emit order event
        Caboose.plugin_hook('order_authorized', order)
      else
        order.financial_status = 'unauthorized'        
        error = "There was a problem processing your payment."
      end
            
      order.save
      
      @url = params[:x_after_relay]
      @url << (ot.success ? "?success=1" : "?error=#{error}")             
                  
      render :layout => false
    end
    
    # GET  /checkout/authnet-response/:order_id
    # POST /checkout/authnet-response/:order_id    
    def authnet_response
      Caboose.log("Authorize.net response, order #{params[:order_id]}")
      
      @resp = Caboose::StdClass.new
      @resp.success = true if params[:success]
      @resp.error = params[:error] if params[:error]
      
      if @resp.success        
        session[:cart_id] = nil
        init_cart
      end
      
      render :layout => false
    end
    
    #def relay
    #  
    #  # Check to see that the order has a valid total and was authorized
    #  if @order.total > 0 && PaymentProcessor.authorize(@order, params)
    #    
    #    # Update order
    #    @order.date_authorized  = DateTime.now
    #    @order.auth_amount      = @order.total
    #    @order.financial_status = 'authorized'
    #    @order.status           = if @order.test? then 'testing' else 'pending' end
    #    
    #    # Send out notifications
    #    OrdersMailer.customer_new_order(@order).deliver
    #    OrdersMailer.fulfillment_new_order(@order).deliver
    #    
    #    # Clear everything
    #    session[:cart_id] = nil
    #    
    #    # Emit order event
    #    Caboose.plugin_hook('order_authorized', @order)
    #    
    #    # Decrement quantities of variants
    #    @order.decrement_quantities
    #  else
    #    @order.financial_status = 'unauthorized'
    #  end
    #  
    #  @order.save
    #end
    
    # GET /checkout/authorize-by-gift-card
    #def authorize_by_gift_card
    #  if @order.total < @order.discounts.first.amount_current
    #    
    #    # Update order
    #    @order.date_authorized  = DateTime.now
    #    @order.auth_amount      = @order.total
    #    @order.financial_status = 'authorized'
    #    @order.status           = if @order.test? then 'testing' else 'pending' end
    #    
    #    # Send out notifications
    #    OrdersMailer.customer_new_order(@order).deliver
    #    OrdersMailer.fulfillment_new_order(@order).deliver
    #    
    #    # Clear everything
    #    session[:cart_id] = nil
    #    
    #    # Emit order event
    #    Caboose.plugin_hook('order_authorized', @order)
    #    
    #    # Decrement quantities of variants
    #    @order.decrement_quantities
    #    
    #    @order.save
    #    
    #    redirect_to '/checkout/thanks'
    #  else
    #    redirect_to '/checkout/error'
    #  end
    #end
    
  end
end
