require 'authorize_net'
  
module Caboose
  class CheckoutController < Caboose::ApplicationController
    
    helper :authorize_net
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery :except => :authnet_relay
    
    def ensure_line_items
      redirect_to '/checkout/empty' if @invoice.line_items.empty?
    end
    
    # Step 1 - Login or register
    # GET /checkout
    def index        
      if logged_in?
        if @invoice.customer_id.nil?
          @invoice.customer_id = logged_in_user.id
          @invoice.save
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
      redirect_to '/checkout/addresses' and return if @invoice.billing_address.nil? || (@invoice.has_shippable_items? && @invoice.shipping_address.nil?)
      
      @invoice.calculate
                  
      if !@invoice.has_shippable_items?
        redirect_to '/checkout/gift-cards'
        return
      end
      
      # Remove any invoice packages      
      LineItem.where(:invoice_id => @invoice.id).update_all(:invoice_package_id => nil)
      InvoicePackage.where(:invoice_id => @invoice.id).destroy_all      
        
      # Calculate what shipping packages we'll need            
      InvoicePackage.create_for_invoice(@invoice)

      # Now get the rates for those packages            
      @rates = ShippingCalculator.rates(@invoice)
      Caboose.log(@rates)
      
      #Caboose.log(@rates.inspect)
      @logged_in_user = logged_in_user

      add_ga_event('Ecommerce', 'Checkout', 'Shipping')            
    end
    
    # Step 4 - Gift cards
    # GET /checkout/gift-cards
    def gift_cards
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @invoice.billing_address.nil? || (@invoice.has_shippable_items? && @invoice.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @invoice.has_shippable_items? && @invoice.has_empty_shipping_methods?
      @logged_in_user = logged_in_user      
      add_ga_event('Ecommerce', 'Checkout', 'Gift Cards')
    end
    
    # Step 5 - Payment
    # GET /checkout/payment
    def payment
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @invoice.billing_address.nil? || (@invoice.has_shippable_items? && @invoice.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @invoice.has_shippable_items? && @invoice.has_empty_shipping_methods?
      redirect_to '/checkout/confirm'   and return if @invoice.total == 0.00      
      
      # Make sure all the variants still exist      
      @invoice.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :file => 'caboose/checkout/deleted_variant'
          return
        end
      end
            
      sc = @site.store_config
      case sc.pp_name
        when 'authorize.net'
                    
          @sim_transaction = AuthorizeNet::SIM::Transaction.new(
            sc.authnet_api_login_id, 
            sc.authnet_api_transaction_key, 
            @invoice.total,
            :relay_response => 'TRUE',
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay/#{@invoice.id}",
            #:relay_url => "#{request.protocol}#{request.host_with_port}/checkout/authnet-relay",
            :relay_url => "#{sc.authnet_relay_domain}/checkout/authnet-relay",
            :transaction_type => 'AUTH_ONLY',                        
            :test => sc.pp_testing
          )
          @request = request
          @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
                  
        when 'stripe'
                    
          Stripe.api_key = sc.stripe_secret_key
          token = params[:stripeToken]
          
      end
      @logged_in_user = logged_in_user      
      add_ga_event('Ecommerce', 'Checkout', 'Payment Form')
    end
        
    # Step 5 - Stripe Payment Form
    # POST /checkout/stripe-payment
    #def stripe_payment
    #end
      
    # GET /checkout/confirm
    def confirm_without_payment
      redirect_to '/checkout'           and return if !logged_in?
      redirect_to '/checkout/addresses' and return if @invoice.billing_address.nil? || (@invoice.has_shippable_items? && @invoice.shipping_address.nil?)
      redirect_to '/checkout/shipping'  and return if @invoice.has_shippable_items? && @invoice.has_empty_shipping_methods?
      redirect_to '/checkout/payment'   and return if @invoice.total > 0.00      
      
      # Make sure all the variants still exist      
      @invoice.line_items.each do |li|
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
      render :json => { :error => 'Invalid addresses.'        } and return if @invoice.billing_address.nil? || (@invoice.has_shippable_items? && @invoice.shipping_address.nil?)
      render :json => { :error => 'Invalid shipping methods.' } and return if @invoice.has_shippable_items? && @invoice.has_empty_shipping_methods?
      render :json => { :error => 'Invoice requires payment.'   } and return if @invoice.total > 0.00
      
      resp = Caboose::StdClass.new
                  
      @invoice.financial_status = Invoice::FINANCIAL_STATUS_AUTHORIZED
      @invoice.status = Invoice::STATUS_PENDING
      @invoice.invoice_number = @site.store_config.next_invoice_number
         
      # Take funds from any gift cards that were used on the invoice
      @invoice.take_gift_card_funds
        
      # Send out emails
      begin
        InvoicesMailer.configure_for_site(@site.id).customer_new_invoice(@invoice).deliver
        InvoicesMailer.configure_for_site(@site.id).fulfillment_new_invoice(@invoice).deliver
      rescue
        puts "=================================================================="
        puts "Error sending out invoice confirmation emails for invoice ID #{@invoice.id}"
        puts "=================================================================="
      end
        
      # Emit invoice event
      Caboose.plugin_hook('invoice_authorized', @invoice)
      
      # Save the invoice
      @invoice.save
      
      # Decrement quantities of variants
      @invoice.decrement_quantities
      
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
      
      # Find the last invoice for the user
      @last_invoice = Invoice.where(:customer_id => @logged_in_user.id).invoice("id desc").limit(1).first            
      add_ga_event('Ecommerce', 'Checkout', 'Payment', (@last_invoice.total*100).to_i)
    end
    
    #===========================================================================
        
    # GET /checkout/total
    def verify_total
      total = 0.00
      if logged_in?
        @invoice.calculate
        total = @invoice.total
      end
      render :json => total.to_f      
    end
    
    # GET /checkout/address
    def address
      render :json => {
        :shipping_address => @invoice.shipping_address,
        :billing_address => @invoice.billing_address
      }
    end
    
    # PUT /checkout/addresses
    def update_addresses
      
      # Grab or create addresses
      shipping_address = if @invoice.shipping_address then @invoice.shipping_address else Address.new end
      billing_address  = if @invoice.billing_address  then @invoice.billing_address  else Address.new end
            
      has_shippable_items = @invoice.has_shippable_items?
        
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
      
      # Associate address info with invoice
      @invoice.shipping_address_id = shipping_address.id
      @invoice.billing_address_id  = billing_address.id
      
      #render :json => { :redirect => 'checkout/shipping' }
      render :json => { :success => @invoice.save, :errors => @invoice.errors.full_messages }
    end
    
    # POST /checkout/attach-user
    def attach_user              
      render :json => { :success => false, :errors => ['User is not logged in'] } and return if !logged_in?
      @invoice.customer_id = logged_in_user.id
      #Caboose.log("Attaching user to invoice: customer_id = #{@invoice.customer_id}")
      render :json => { :success => @invoice.save, :errors => @invoice.errors.full_messages, :logged_in => logged_in? }
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
        @invoice.customer_id = user.id
        login_user(user)
        
        if !@invoice.valid?        
          resp.errors = @invoice.errors.full_messages
        else
          @invoice.save
          resp.redirect = '/checkout/addresses'
        end
      end
      render :json => resp            
    end
    
    # PUT /checkout/shipping
    def update_shipping
      op = InvoicePackage.find(params[:invoice_package_id])
      op.shipping_method_id = params[:shipping_method_id]
      op.total = params[:total]
      op.save
      op.invoice.calculate
                                   
      render :json => { :success => true }               
    end
    
    # GET /checkout/payment
    #def payment
    #  case Caboose::payment_processor
    #    when 'authorize.net'                             
    #      @sim_transaction = AuthorizeNet::SIM::Transaction.new(
    #        Caboose::authorize_net_login_id,
    #        Caboose::authorize_net_transaction_key,
    #        @invoice.total,
    #        :relay_url => "#{Caboose::root_url}/checkout/relay/#{@invoice.id}",
    #        :transaction_type => 'AUTH_ONLY',
    #        :test => true
    #      )
    #    when 'payscape'
    #      @form_url = Caboose::PaymentProcessor.form_url(@invoice)
    #  end      
    #  render :layout => false
    #end
        
    # POST /checkout/authnet-relay
    def authnet_relay
      Caboose.log("Authorize.net relay, invoice #{params[:x_invoice_id]}")
      
      if params[:x_invoice_num].nil? || params[:x_invoice_num].strip.length == 0
        Caboose.log("Error: no x_invoice_id in given parameters.")
        render :json => { :error => "Invalid x_invoice_id." }
        return
      end
      
      invoice = Caboose::Invoice.where(:id => params[:x_invoice_num].to_i).first
      if invoice.nil?
        Caboose.log("Error: can't find invoice for x_invoice_num #{params[:x_invoice_num]}.")
        render :json => { :error => "Invalid x_invoice_id." }
        return
      end
            
      ot = Caboose::InvoiceTransaction.new(
        :invoice_id => invoice.id,
        :date_processed => DateTime.now.utc,
        :transaction_type => Caboose::InvoiceTransaction::TYPE_AUTHORIZE
      )
      ot.success        = params[:x_response_code] && params[:x_response_code] == '1'
      ot.transaction_id = params[:x_trans_id] if params[:x_trans_id]              
      ot.auth_code      = params[:x_auth_code] if params[:x_auth_code]
      ot.response_code  = params[:x_response_code] if params[:x_response_code]
      ot.amount         = invoice.total
      ot.save
      
      error = nil
      if ot.success
        invoice.financial_status = Invoice::FINANCIAL_STATUS_AUTHORIZED
        invoice.status = Invoice::STATUS_PENDING
        invoice.invoice_number = @site.store_config.next_invoice_number
        invoice.date_authorized = DateTime.now.utc
        
        # Tell taxcloud the invoice was authorized
        #Caboose::TaxCalculator.authorized(invoice)
         
        # Take funds from any gift cards that were used on the invoice
        invoice.take_gift_card_funds
        
        # Send out emails 
        begin
          InvoicesMailer.configure_for_site(@site.id).customer_new_invoice(invoice).deliver
          InvoicesMailer.configure_for_site(@site.id).fulfillment_new_invoice(invoice).deliver        
        rescue
          puts "=================================================================="
          puts "Error sending out invoice confirmation emails for invoice ID #{@invoice.id}"
          puts "=================================================================="
        end
                              
        # Emit invoice event
        Caboose.plugin_hook('invoice_authorized', invoice)        
      else
        invoice.financial_status = 'unauthorized'        
        error = "There was a problem processing your payment."
      end
            
      invoice.save
      
      @url = params[:x_after_relay]
      @url << (ot.success ? "?success=1" : "?error=#{error}")             
                  
      render :layout => false
    end
    
    # GET  /checkout/authnet-response/:invoice_id
    # POST /checkout/authnet-response/:invoice_id    
    def authnet_response
      Caboose.log("Authorize.net response, invoice #{params[:invoice_id]}")
      
      @resp = Caboose::StdClass.new
      @resp.success = true if params[:success]
      @resp.error = params[:error] if params[:error]
      
      # Go ahead and capture funds if the invoice only contained downloadable items
      @invoice = Invoice.find(params[:invoice_id])
      
      if @resp.success
        if !@invoice.has_shippable_items?
          capture_resp = @invoice.capture_funds
          if capture_resp.error
            @resp.success = false
            @resp.error = capture_resp.error
          end        
        end
        
        # Decrement quantities of variants
        @invoice.decrement_quantities
    
        session[:cart_id] = nil
        init_cart
      end
      
      render :layout => false
    end
    
    #def relay
    #  
    #  # Check to see that the invoice has a valid total and was authorized
    #  if @invoice.total > 0 && PaymentProcessor.authorize(@invoice, params)
    #    
    #    # Update invoice
    #    @invoice.date_authorized  = DateTime.now
    #    @invoice.auth_amount      = @invoice.total
    #    @invoice.financial_status = 'authorized'
    #    @invoice.status           = if @invoice.test? then 'testing' else 'pending' end
    #    
    #    # Send out notifications
    #    InvoicesMailer.customer_new_invoice(@invoice).deliver
    #    InvoicesMailer.fulfillment_new_invoice(@invoice).deliver
    #    
    #    # Clear everything
    #    session[:cart_id] = nil
    #    
    #    # Emit invoice event
    #    Caboose.plugin_hook('invoice_authorized', @invoice)
    #    
    #    # Decrement quantities of variants
    #    @invoice.decrement_quantities
    #  else
    #    @invoice.financial_status = 'unauthorized'
    #  end
    #  
    #  @invoice.save
    #end
    
    # GET /checkout/authorize-by-gift-card
    #def authorize_by_gift_card
    #  if @invoice.total < @invoice.discounts.first.amount_current
    #    
    #    # Update invoice
    #    @invoice.date_authorized  = DateTime.now
    #    @invoice.auth_amount      = @invoice.total
    #    @invoice.financial_status = 'authorized'
    #    @invoice.status           = if @invoice.test? then 'testing' else 'pending' end
    #    
    #    # Send out notifications
    #    InvoicesMailer.customer_new_invoice(@invoice).deliver
    #    InvoicesMailer.fulfillment_new_invoice(@invoice).deliver
    #    
    #    # Clear everything
    #    session[:cart_id] = nil
    #    
    #    # Emit invoice event
    #    Caboose.plugin_hook('invoice_authorized', @invoice)
    #    
    #    # Decrement quantities of variants
    #    @invoice.decrement_quantities
    #    
    #    @invoice.save
    #    
    #    redirect_to '/checkout/thanks'
    #  else
    #    redirect_to '/checkout/error'
    #  end
    #end
    
  end
end
