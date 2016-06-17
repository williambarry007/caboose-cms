require 'authorize_net'
  
module Caboose
  class TheCheckoutController < Caboose::ApplicationController
    
    helper :authorize_net
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery :except => :authnet_relay
    
    def ensure_line_items
      redirect_to '/checkout/empty' if @order.line_items.empty?
    end
        
    # GET /checkout/json
    def order_json            
      render :json => @order.as_json(
        :include => [                          
          :customer,
          :shipping_address,
          :billing_address,
          :order_transactions,          
          { 
            :line_items => { 
              :include => { 
                :variant => { 
                  :include => [
                    { :product_images => { :methods => :urls }},
                    { :product => { :include => { :product_images => { :methods => :urls }}}}
                  ],
                  :methods => :title
                }
              }
            }
          },
          { :order_packages => { :include => [:shipping_package, :shipping_method] }},          
          { :discounts => { :include => :gift_card }}
        ]        
      )      
    end
    
    # Step 1 - Login or register
    # GET /checkout
    def index        
      if logged_in?
        if @order.customer_id.nil?
          @order.customer_id = logged_in_user.id
          @order.save
        end                        
        #redirect_to '/checkout/addresses'
        #return
        render :file => "caboose/checkout/checkout_#{@site.store_config.pp_name}"
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
      Caboose.log(@rates)
      
      #Caboose.log(@rates.inspect)
      @logged_in_user = logged_in_user

      add_ga_event('Ecommerce', 'Checkout', 'Shipping')            
    end
    
    # Step 3 - Shipping method
    # GET /checkout/shipping/json
    def shipping_json
      render :json => { :error => 'Not logged in.'          } and return if !logged_in?
      render :json => { :error => 'No shippable items.'     } and return if !@order.has_shippable_items?
      render :json => { :error => 'Empty shipping address.' } and return if @order.shipping_address.nil?      
      
      @order.calculate
      
      # Remove any order packages      
      LineItem.where(:order_id => @order.id).update_all(:order_package_id => nil)
      OrderPackage.where(:order_id => @order.id).destroy_all      
        
      # Calculate what shipping packages we'll need            
      OrderPackage.create_for_order(@order)

      # Now get the rates for those packages            
      rates = ShippingCalculator.rates(@order)      
      render :json => rates                  
    end
    
    # Step 4 - Gift cards
    # GET /checkout/gift-cards
    def gift_cards
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @order.billing_address.nil? || (@order.has_shippable_items? && @order.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?
      @logged_in_user = logged_in_user      
      add_ga_event('Ecommerce', 'Checkout', 'Gift Cards')
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
            
      sc = @site.store_config
      case sc.pp_name
        when StoreConfig::PAYMENT_PROCESSOR_AUTHNET
                    
          @sim_transaction = AuthorizeNet::SIM::Transaction.new(
            sc.authnet_api_login_id, 
            sc.authnet_api_transaction_key, 
            @order.total,
            :relay_response => 'TRUE',
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay/#{@order.id}",
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay",
            :relay_url => "#{sc.authnet_relay_domain}/checkout/authnet-relay",
            :transaction_type => 'AUTH_ONLY',                        
            :test => sc.pp_testing
          )
          @request = request
          @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
          render :file => 'caboose/checkout/payment_authnet'
                  
        when StoreConfig::PAYMENT_PROCESSOR_STRIPE                                 
          render :file => 'caboose/checkout/payment_stripe'
          
      end
      @logged_in_user = logged_in_user      
      add_ga_event('Ecommerce', 'Checkout', 'Payment Form')
    end
        
    # Step 5 - Update Stripe Details
    # PUT /checkout/stripe-details
    def update_stripe_details
      render :json => false and return if !logged_in?
      
      sc = @site.store_config      
      Stripe.api_key = sc.stripe_secret_key.strip

      u = logged_in_user      
      
      c = nil
      if u.stripe_customer_id
        c = Stripe::Customer.retrieve(u.stripe_customer_id)
        begin          
          c.source = params[:token]
          c.save
        rescue          
          c = nil
        end
      end
      
      if c.nil?
        c = Stripe::Customer.create(
          :source => params[:token],
          :email => u.email,
          :metadata => { :user_id => u.id }          
        )
      end
      
      u.stripe_customer_id = c.id
      u.card_last4     = params[:card][:last4]
      u.card_brand     = params[:card][:brand]  
      u.card_exp_month = params[:card][:exp_month]
      u.card_exp_year  = params[:card][:exp_year]
      u.save
      
      render :json => true
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
      add_ga_event('Ecommerce', 'Checkout', 'Confirm Without Payment')
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
      begin
        OrdersMailer.configure_for_site(@site.id).customer_new_order(@order).deliver
        OrdersMailer.configure_for_site(@site.id).fulfillment_new_order(@order).deliver
      rescue
        puts "=================================================================="
        puts "Error sending out order confirmation emails for order ID #{@order.id}"
        puts "=================================================================="
      end
        
      # Emit order event
      Caboose.plugin_hook('order_authorized', @order)
      
      # Save the order
      @order.save
      
      # Decrement quantities of variants
      @order.decrement_quantities
      
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
      add_ga_event('Ecommerce', 'Checkout', 'Payment', (@last_order.total*100).to_i)
    end
    
    #===========================================================================
        
    # GET /checkout/total
    def verify_total
      total = 0.00
      if logged_in?
        @order.calculate
        total = @order.total
      end
      render :json => total.to_f      
    end
    
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
    
    # PUT /checkout/shipping-address
    def update_shipping_address
      
      # Grab or create addresses
      sa = @order.shipping_address
      if sa.nil?
        sa = Address.create
        @order.shipping_address_id = sa.id
        @order.save
      end
                                                        
      sa.first_name = params[:first_name]
      sa.last_name  = params[:last_name]
      sa.company    = params[:company]
      sa.address1   = params[:address1]
      sa.address2   = params[:address2]
      sa.city       = params[:city]
      sa.state      = params[:state]
      sa.zip        = params[:zip]
      sa.save
                        
      render :json => { :success => true }
    end
    
    # PUT /checkout/billing-address
    def update_billing_address
      
      # Grab or create addresses
      ba = @order.billing_address
      if ba.nil?
        ba = Address.create
        @order.billing_address_id = ba.id
        @order.save
      end
                                                        
      ba.first_name = params[:first_name]
      ba.last_name  = params[:last_name]
      ba.company    = params[:company]
      ba.address1   = params[:address1]
      ba.address2   = params[:address2]
      ba.city       = params[:city]
      ba.state      = params[:state]
      ba.zip        = params[:zip]
      ba.save
                        
      render :json => { :success => true }
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
    #    when StoreConfig::PAYMENT_PROCESSOR_AUTHNET                             
    #      @sim_transaction = AuthorizeNet::SIM::Transaction.new(
    #        Caboose::authorize_net_login_id,
    #        Caboose::authorize_net_transaction_key,
    #        @order.total,
    #        :relay_url => "#{Caboose::root_url}/checkout/relay/#{@order.id}",
    #        :transaction_type => 'AUTH_ONLY',
    #        :test => true
    #      )
    #    when StoreConfig::PAYMENT_PROCESSOR_STRIPE
    #
    #  end      
    #  render :layout => false
    #end
        
    # POST /checkout/authnet-relay
    def authnet_relay
      Caboose.log("Authorize.net relay, order #{params[:x_invoice_id]}")
      
      if params[:x_invoice_num].nil? || params[:x_invoice_num].strip.length == 0
        Caboose.log("Error: no x_invoice_id in given parameters.")
        render :json => { :error => "Invalid x_invoice_id." }
        return
      end
      
      order = Caboose::Order.where(:id => params[:x_invoice_num].to_i).first
      if order.nil?
        Caboose.log("Error: can't find order for x_invoice_num #{params[:x_invoice_num]}.")
        render :json => { :error => "Invalid x_invoice_id." }
        return
      end
            
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
        order.date_authorized = DateTime.now.utc
        
        # Tell taxcloud the order was authorized
        #Caboose::TaxCalculator.authorized(order)
         
        # Take funds from any gift cards that were used on the order
        order.take_gift_card_funds
        
        # Send out emails 
        begin
          OrdersMailer.configure_for_site(@site.id).customer_new_order(order).deliver
          OrdersMailer.configure_for_site(@site.id).fulfillment_new_order(order).deliver        
        rescue
          puts "=================================================================="
          puts "Error sending out order confirmation emails for order ID #{@order.id}"
          puts "=================================================================="
        end
                              
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
      
      # Go ahead and capture funds if the order only contained downloadable items
      @order = Order.find(params[:order_id])
      
      if @resp.success
        if !@order.has_shippable_items?
          capture_resp = @order.capture_funds
          if capture_resp.error
            @resp.success = false
            @resp.error = capture_resp.error
          end        
        end
        
        # Decrement quantities of variants
        @order.decrement_quantities
    
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
