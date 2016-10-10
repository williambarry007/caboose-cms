require 'authorize_net'
  
module Caboose
  class CheckoutController < Caboose::ApplicationController
        
    before_filter :ensure_line_items, :only => [:step_one, :step_two]
    protect_from_forgery
    
    def ensure_line_items
      redirect_to '/checkout/empty' if @invoice.line_items.empty?
    end
        
    # @route GET /checkout/json
    def invoice_json            
      render :json => @invoice.as_json(
        :include => [                          
          :customer,
          :shipping_address,
          :billing_address,
          :invoice_transactions,          
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
          { :invoice_packages => { :include => [:shipping_package, :shipping_method] }},          
          { :discounts => { :include => :gift_card }}
        ]        
      )      
    end
    
    # @route GET /checkout/stripe/json
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
    # @route GET /checkout
    def index            
      if logged_in?
        if @invoice.customer_id.nil?
          @invoice.customer_id = logged_in_user.id
          @invoice.save
        end                        
        #redirect_to '/checkout/addresses'
        #return
        
        @invoice.verify_invoice_packages
        
        # See if any there are any empty invoice packages          
        #@invoice.invoice_packages.each do |op|
        #  count = 0
        #  @invoice.line_items.each do |li|
        #    count = count + 1 if li.invoice_package_id == op.id
        #  end
        #  op.destroy if count == 0
        #end
        #
        ## See if any line items aren't associated with an invoice package
        #line_items_attached = true
        #@invoice.line_items.each do |li|
        #  line_items_attached = false if li.invoice_package_id.nil?
        #end
        #  
        #ops = @invoice.invoice_packages
        #if ops.count == 0 || !line_items_attached
        #  @invoice.calculate
        #  LineItem.where(:invoice_id => @invoice.id).update_all(:invoice_package_id => nil)
        #  InvoicePackage.where(:invoice_id => @invoice.id).destroy_all          
        #  InvoicePackage.create_for_invoice(@invoice)
        #end
      
        #render :file => "caboose/checkout/checkout_#{@site.store_config.pp_name}"
        render :file => "caboose/checkout/checkout"                                                                                                                      
      end
    end
    
    # Step 3 - Shipping method
    # @route GET /checkout/shipping/json
    def shipping_json
      render :json => { :error => 'Not logged in.'          } and return if !logged_in?
      render :json => { :error => 'No shippable items.'     } and return if !@invoice.has_shippable_items?
      render :json => { :error => 'Empty shipping address.' } and return if @invoice.shipping_address.nil?      
      
      @invoice.calculate
      
      #ops = @invoice.invoice_packages      
      #if params[:recalculate_invoice_packages] || ops.count == 0
      #  # Remove any invoice packages      
      #  LineItem.where(:invoice_id => @invoice.id).update_all(:invoice_package_id => nil)
      #  InvoicePackage.where(:invoice_id => @invoice.id).destroy_all      
      #    
      #  # Calculate what shipping packages we'll need            
      #  InvoicePackage.create_for_invoice(@invoice)
      #end

      # Now get the rates for those packages            
      rates = ShippingCalculator.rates(@invoice)      
      render :json => rates                  
    end        
        
    # Step 5 - Update Stripe Details
    # @route PUT /checkout/stripe-details
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
        :success        => true,
        :customer_id    => u.stripe_customer_id,                                                           
        :card_last4     => u.card_last4,     
        :card_brand     => u.card_brand,       
        :card_exp_month => u.card_exp_month, 
        :card_exp_year  => u.card_exp_year
      }      
    end
        
    # @route DELETE /checkout/payment-method
    def remove_payment_method
      render :json => false and return if !logged_in?
      
      resp = Caboose::StdClass.new
      sc = @site.store_config      
      if sc.pp_name == 'stripe'
        Stripe.api_key = sc.stripe_secret_key.strip
        u = logged_in_user        
        if u.stripe_customer_id          
          begin
            c = Stripe::Customer.retrieve(u.stripe_customer_id)
            c.delete
          rescue Exception => ex
            Caboose.log(ex)
            resp.error = ex.message if !ex.message.starts_with?('No such customer')
          end
          if resp.error.nil?            
            u.stripe_customer_id = nil          
            u.card_last4         = nil
            u.card_brand         = nil
            u.card_exp_month     = nil
            u.card_exp_year      = nil
            u.save
          else
            resp.success = true
          end
        end
      end      
      render :json => resp      
    end
            
    # @route POST /checkout/confirm
    def confirm
      render :json => { :error => 'Not logged in.'            } and return if !logged_in?
      #render :json => { :error => 'Invalid billing address.'  } and return if @invoice.billing_address.nil?
      if !@invoice.instore_pickup && @invoice.has_shippable_items?
        render :json => { :error => 'Invalid shipping address.' } and return if @invoice.shipping_address.nil?      
        render :json => { :error => 'Invalid shipping methods.' } and return if @invoice.has_empty_shipping_methods?
      end
      
      resp = Caboose::StdClass.new
      sc = @site.store_config
      
      # Make sure all the variants still exist      
      @invoice.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :json => { :error => 'One or more of the products you are purchasing are no longer available.' }
          return
        end
      end

      error = false      
      requires_payment = @invoice.line_items.count > 0 && @invoice.total > 0 && @invoice.payment_terms == Invoice::PAYMENT_TERMS_PIA       
      if requires_payment
      
        ot = nil
        case sc.pp_name
          when StoreConfig::PAYMENT_PROCESSOR_AUTHNET
                                    
          when StoreConfig::PAYMENT_PROCESSOR_STRIPE
            Stripe.api_key = sc.stripe_secret_key.strip
            begin
              c = Stripe::Charge.create(
                :amount => (@invoice.total * 100).to_i,
                :currency => 'usd',
                :customer => logged_in_user.stripe_customer_id,
                :capture => false,
                :metadata => { :invoice_id => @invoice.id },
                :statement_descriptor => "Invoice ##{@invoice.id}"
              )
            rescue Exception => ex
              render :json => { :error => ex.message }
              return
            end
            ot = Caboose::InvoiceTransaction.create(
              :invoice_id        => @invoice.id,
              :transaction_id    => c.id,
              :transaction_type  => c.captured ? Caboose::InvoiceTransaction::TYPE_AUTHCAP : Caboose::InvoiceTransaction::TYPE_AUTHORIZE,
              :payment_processor => sc.pp_name,
              :amount            => c.amount/100.0,              
              :date_processed    => DateTime.now.utc,              
              :success           => c.status == 'succeeded'
            )
        end
        
        if !ot.success
          render :json => { :error => error }
          return        
        else        
          @invoice.financial_status = Invoice::FINANCIAL_STATUS_AUTHORIZED                                                   
          @invoice.take_gift_card_funds
        end
      end
      
      @invoice.status = Invoice::STATUS_PENDING
      @invoice.invoice_number = @site.store_config.next_invoice_number
      
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
      Caboose.plugin_hook('invoice_authorized', @invoice) if @invoice.total > 0 
      
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
    
    # @route GET /checkout/thanks
    def thanks
      @logged_in_user = logged_in_user
      
      # Find the last invoice for the user
      @last_invoice = Invoice.where(:customer_id => @logged_in_user.id).reorder("id desc").limit(1).first            
      add_ga_event('Ecommerce', 'Checkout', 'Payment', (@last_invoice.total*100).to_i)
    end
    
    #===========================================================================    
    
    # @route GET /checkout/state-options
    def state_options                            
      options = Caboose::States.all.collect { |abbr, state| { 'value' => abbr, 'text' => abbr }}
      render :json => options
    end
        
    # @route GET /checkout/total
    def verify_total
      total = 0.00
      if logged_in?
        @invoice.calculate
        total = @invoice.total
      end
      render :json => total.to_f      
    end
    
    # @route GET /checkout/address
    def address
      render :json => {
        :shipping_address => @invoice.shipping_address,
        :billing_address => @invoice.billing_address
      }
    end
            
    # @route PUT /checkout/addresses
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
    
    # @route PUT /checkout/shipping-address
    def update_shipping_address      
      resp = Caboose::StdClass.new
            
      # Grab or create addresses
      sa = @invoice.shipping_address
      if sa.nil?
        sa = Address.create
        @invoice.shipping_address_id = sa.id
        @invoice.save
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
        @invoice.invoice_packages.each do |op|          
          op.shipping_method_id = nil                         
          op.total = nil
          op.save
        end
      end

      resp.success = save && sa.save      
      render :json => resp            
    end
    
    # @route PUT /checkout/billing-address
    def update_billing_address
      
      # Grab or create addresses
      ba = @invoice.billing_address
      if ba.nil?
        ba = Address.create
        @invoice.billing_address_id = ba.id
        @invoice.save
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
    
    # @route PUT /checkout/invoice
    def update_invoice
      render :json => false and return if !logged_in?      
      resp = Caboose::StdClass.new
      
      params.each do |k,v|
        case k
          when 'instore_pickup'
            @invoice.instore_pickup = v
            @invoice.save
            
            @invoice.invoice_packages.each do |ip|
              ip.instore_pickup = v
              ip.save
            end
        end
      end
      
      resp.success = true
      render :json => resp                  
    end
    
    # @route POST /checkout/attach-user
    def attach_user              
      render :json => { :success => false, :errors => ['User is not logged in'] } and return if !logged_in?
      @invoice.customer_id = logged_in_user.id
      #Caboose.log("Attaching user to invoice: customer_id = #{@invoice.customer_id}")
      render :json => { :success => @invoice.save, :errors => @invoice.errors.full_messages, :logged_in => logged_in? }
    end
    
    # @route POST /checkout/guest
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
    
    # @route PUT /checkout/shipping
    def update_shipping
      op = InvoicePackage.find(params[:invoice_package_id])
      op.shipping_method_id = params[:shipping_method_id]
      op.total = params[:total]
      op.save
      op.invoice.calculate
                                   
      render :json => { :success => true }               
    end
        
  end
end
