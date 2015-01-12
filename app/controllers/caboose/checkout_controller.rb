
module Caboose
  class CheckoutController < Caboose::ApplicationController
    
    helper :authorize_net
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery :except => :authnet_relay
    
    def ensure_line_items
      redirect_to '/checkout/empty' if @order.line_items.empty?
    end
    
    # GET /checkout
    def index
      redirect_to '/checkout/step-one'
    end
    
    # GET /checkout/step-one
    def step_one
      if logged_in?
        if @order.customer_id.nil?
          @order.customer_id = logged_in_user.id
          @order.save
        end
        redirect_to '/checkout/step-two'
        return        
      end
    end
    
    # GET /checkout/step-two
    def step_two
      #redirect_to '/checkout/step-one' if !@order.shipping_address || !@order.billing_address
      redirect_to '/checkout/step-one' if !logged_in?      
    end
    
    # GET /checkout/step-three
    def step_three
      redirect_to '/checkout/step-one' and return if !logged_in?
      redirect_to '/checkout/step-two' and return if @order.shipping_address.nil? || @order.billing_address.nil?

      # Remove any order packages      
      LineItem.where(:order_id => @order.id).update_all(:order_package_id => nil)
      OrderPackage.where(:order_id => @order.id).destroy_all      
      
      # Calculate what shipping packages we'll need            
      OrderPackage.create_for_order(@order)
      
      # Now get the rates for those packages
      Caboose.log("Getting rates...")      
      @rates = ShippingCalculator.rates(@order)      
      Caboose.log(@rates.inspect)      
    end
    
    # GET /checkout/step-four
    def step_four
      redirect_to '/checkout/step-one'   and return if !logged_in?
      redirect_to '/checkout/step-two'   and return if @order.shipping_address.nil? || @order.billing_address.nil?
      redirect_to '/checkout/step-three' and return if @order.shipping_service_code.nil?
      
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
            :relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay",
            :transaction_type => 'AUTH_ONLY',            
            :test => true
          )
          @request = request
          @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
          
        when 'payscape'
          @form_url = Caboose::PaymentProcessor.form_url(@order)
      end
    end
    
    # GET /checkout/thanks
    def thanks
    end
    
    #===========================================================================
    
    # GET /checkout/address
    def address
      render :json => {
        :shipping_address => @order.shipping_address,
        :billing_address => @order.billing_address
      }
    end
    
    # PUT /checkout/address
    def update_address
      
      # Grab or create addresses
      shipping_address = if @order.shipping_address then @order.shipping_address else Address.new end
      billing_address  = if @order.billing_address  then @order.billing_address  else Address.new end
      
      # Shipping address
      shipping_address.first_name = params[:shipping][:first_name]
      shipping_address.last_name  = params[:shipping][:last_name]
      shipping_address.company    = params[:shipping][:company]
      shipping_address.address1   = params[:shipping][:address1]
      shipping_address.address2   = params[:shipping][:address2]
      shipping_address.city       = params[:shipping][:city]
      shipping_address.state      = params[:shipping][:state]
      shipping_address.zip        = params[:shipping][:zip]
      
      # Billing address
      if params[:use_as_billing]
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
      render :json => { :success => false, :errors => shipping_address.errors.full_messages, :address => 'shipping' } and return if !shipping_address.save
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
          resp.redirect = '/checkout/step-two'
        end
      end
      render :json => resp            
    end
    
    ## GET /checkout/shipping
    #def shipping
    #  render :json => { :rates => ShippingCalculator.rates(@order), :selected_rate => ShippingCalculator.rate(@order) }
    #end
    
    # PUT /checkout/shipping
    def update_shipping

      rates = ShippingCalculator.rates(@order)
        
      if @site.store_config.calculate_packages
        # TODO: Add the separate shipping costs for each package
      else
        @order.shipping_carrier      = params[:carrier]
        @order.shipping_service_code = params[:service_code]
        @order.shipping_service_name = params[:service_name]
        
        rates[0][:rates].each do |rate|
          if rate[:carrier] == params[:carrier] && rate[:service_code] == params[:service_code]
            @order.shipping = rate[:total_price]
            break
          end
        end                 
      end                       
      render :json => { 
        :success => @order.save, 
        :errors => @order.errors.full_messages 
        #:order => @order, 
        #:selected_rate => ShippingCalculator.rate(@order) 
      }
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
        order.financial_status = 'authorized'
        order.status = 'pending'
        
        # Send out emails        
        OrdersMailer.customer_new_order(order).deliver
        OrdersMailer.fulfillment_new_order(order).deliver        
        
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
    
    # GET /checkout/discount
    #def discount
    #  # TODO make it possible to use multiple discounts
    #  
    #  @gift_card = @order.discounts.first
    #end
    
    # POST /checkout/update-discount
    #def add_discount
    #  gift_card = Discount.find_by_code(params[:gift_card_number])
    #  
    #  render :json => { :error => true, :message => 'Gift card not found.' } and return if gift_card.nil?
    #  render :json => { :error => true, :message => 'Gift card has no remaining funds.' } and return if gift_card.amount_current <= 0
    #  
    #  @order.discounts.delete_all if @order.discounts.any?
    #  @order.discounts << gift_card
    #  @order.calculate_total
    #  
    #  render :json => { :success => true, :message => 'Gift card added successfully.' }
    #end
    
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
