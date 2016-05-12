require 'authorize_net'
  
module Caboose
  class CheckoutController < Caboose::ApplicationController
        
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery
    
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
    
    # GET /checkout/stripe/json
    def stripe_json
      sc = @site.store_config
      u = logged_in_user
      render :json => {
        :stripe_key     => sc.stripe_publishable_key.strip,        
        :customer_id    => u.stripe_customer_id,                   
        :card_last4     => u.card_last4,     
        :card_brand     => u.card_brand,       
        :card_exp_month => u.card_exp_month, 
        :card_exp_year  => u.card_exp_year
      }          
    end
    
    #===========================================================================
    
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
        
        # See if any there are any empty order packages          
        @order.order_packages.each do |op|
          count = 0
          @order.line_items.each do |li|
            count = count + 1 if li.order_package_id == op.id
          end
          op.destroy if count == 0
        end
        
        # See if any line items aren't associated with an order package
        line_items_attached = true
        @order.line_items.each do |li|
          line_items_attached = false if li.order_package_id.nil?
        end
          
        ops = @order.order_packages
        if ops.count == 0 || !line_items_attached
          @order.calculate
          LineItem.where(:order_id => @order.id).update_all(:order_package_id => nil)
          OrderPackage.where(:order_id => @order.id).destroy_all          
          OrderPackage.create_for_order(@order)
        end
      
        #render :file => "caboose/checkout/checkout_#{@site.store_config.pp_name}"
        render :file => "caboose/checkout/checkout"
      end
    end
    
    # Step 3 - Shipping method
    # GET /checkout/shipping/json
    def shipping_json
      render :json => { :error => 'Not logged in.'          } and return if !logged_in?
      render :json => { :error => 'No shippable items.'     } and return if !@order.has_shippable_items?
      render :json => { :error => 'Empty shipping address.' } and return if @order.shipping_address.nil?      
      
      @order.calculate            
      ops = @order.order_packages
      
      if params[:recalculate_order_packages] || ops.count == 0
        # Remove any order packages      
        LineItem.where(:order_id => @order.id).update_all(:order_package_id => nil)
        OrderPackage.where(:order_id => @order.id).destroy_all      
          
        # Calculate what shipping packages we'll need            
        OrderPackage.create_for_order(@order)
      end

      # Now get the rates for those packages            
      rates = ShippingCalculator.rates(@order)      
      render :json => rates                  
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
      
      render :json => {
        :success => true,
        :customer_id => u.stripe_customer_id
      }      
    end
    
    # POST /checkout/confirm
    def confirm
      render :json => { :error => 'Not logged in.'            } and return if !logged_in?
      #render :json => { :error => 'Invalid billing address.'  } and return if @order.billing_address.nil?
      render :json => { :error => 'Invalid shipping address.' } and return if @order.has_shippable_items? && @order.shipping_address.nil?      
      render :json => { :error => 'Invalid shipping methods.' } and return if @order.has_shippable_items? && @order.has_empty_shipping_methods?      
      
      resp = Caboose::StdClass.new
      sc = @site.store_config
      
      # Make sure all the variants still exist      
      @order.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :json => { :error => 'One or more of the products you are purchasing are no longer available.' }
          return
        end
      end
            
      ot = nil
      error = false
      if @order.total > 0
        case sc.pp_name
          when StoreConfig::PAYMENT_PROCESSOR_AUTHNET
                                    
          when StoreConfig::PAYMENT_PROCESSOR_STRIPE
            Stripe.api_key = sc.stripe_secret_key.strip
            begin
              c = Stripe::Charge.create(
                :amount => (@order.total * 100).to_i,
                :currency => 'usd',
                :customer => logged_in_user.stripe_customer_id,
                :capture => false,
                :metadata => { :order_id => @order.id },
                :statement_descriptor => "#{@site.name.length > (14 - @order.id.to_s.length) ? @site.name[0,22 - @order.id.to_s.length] : @site.name} Order ##{@order.id}"
              )
            rescue Exception => ex
              render :json => { :error => ex.message }
              return
            end
            ot = Caboose::OrderTransaction.create(
              :order_id         => @order.id,
              :transaction_id   => c.id,
              :transaction_type => c.captured ? Caboose::OrderTransaction::TYPE_AUTHORIZE : Caboose::OrderTransaction::TYPE_AUTHCAP,     
              :amount           => c.amount/100.0,              
              :date_processed   => DateTime.now.utc,              
              :success          => c.status == 'succeeded'
            )            
        end
      elsif @order.line_items.count > 0
        # Then the order didn't require payment
        
      end

      if @order.total > 0 && ot && !ot.success
        render :json => { :error => error }
        return
      end
                    
      @order.financial_status = Order::FINANCIAL_STATUS_AUTHORIZED if @order.total > 0
      @order.status = Order::STATUS_PENDING
      @order.order_number = @site.store_config.next_order_number                           
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
      Caboose.plugin_hook('order_authorized', @order) if @order.total > 0 
      
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
    
    # GET /checkout/state-options
    def state_options                            
      options = Caboose::States.all.collect { |abbr, state| { 'value' => abbr, 'text' => abbr }}
      render :json => options
    end
        
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
      resp = Caboose::StdClass.new
            
      # Grab or create addresses
      sa = @order.shipping_address
      if sa.nil?
        sa = Address.create
        @order.shipping_address_id = sa.id
        @order.save
      end
            
      save = true
      recalc_shipping = false
      params.each do |name, value|
        case name                              
          when 'address1' then recalc_shipping = true if sa.address1 != value
          when 'address2' then recalc_shipping = true if sa.address2 != value          
          when 'city'     then recalc_shipping = true if sa.city     != value
          when 'state'    then recalc_shipping = true if sa.state    != value          
          when 'zip'      then recalc_shipping = true if sa.zip      != value          
        end        
        case name          
          when 'name'           then sa.name          = value          
          when 'first_name'     then sa.first_name    = value
          when 'last_name'      then sa.last_name     = value
          when 'street'         then sa.street        = value
          when 'address1'       then sa.address1      = value
          when 'address2'       then sa.address2      = value
          when 'company'        then sa.company       = value
          when 'city'           then sa.city          = value
          when 'state'          then sa.state         = value
          when 'province'       then sa.province      = value
          when 'province_code'  then sa.province_code = value
          when 'zip'            then sa.zip           = value
          when 'country'        then sa.country       = value
          when 'country_code'   then sa.country_code  = value
          when 'phone'          then sa.phone         = value
        end                 
      end      
      if recalc_shipping
        @order.order_packages.each do |op|          
          op.shipping_method_id = nil
          op.shipping_package_id = nil               
          op.total = nil
          op.save
        end
      end

      resp.success = save && sa.save      
      render :json => resp            
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
        
  end
end
