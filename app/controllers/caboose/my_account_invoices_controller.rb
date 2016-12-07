module Caboose
  class MyAccountInvoicesController < Caboose::ApplicationController
            
    helper :authorize_net
    protect_from_forgery :except => :authnet_relay
    
    # @route GET /my-account/invoices
    def index
      return if !verify_logged_in
            
      @pager = Caboose::PageBarGenerator.new(params, {
        'customer_id'          => logged_in_user.id,         
        'status'               => [          
          Invoice::STATUS_PENDING       ,    
          Invoice::STATUS_CANCELED      ,
          Invoice::STATUS_READY_TO_SHIP ,
          Invoice::STATUS_PROCESSED          
        ]
      }, {
        'model'          => 'Caboose::Invoice',
        'sort'           => 'id',
        'desc'           => 1,
        'base_url'       => '/my-account/invoices',
        'use_url_params' => false
      })      
      @invoices = @pager.all_items
    end
    
    # @route GET /my-account/invoices/:id/payment-form
    def payment_form
      return if !logged_in?
      
      @invoice = Invoice.find(params[:id])
      if @invoice.customer_id != logged_in_user.id
        @error = "The given invoice does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end
  
      if @invoice.financial_status != Invoice::FINANCIAL_STATUS_PENDING        
        @error = "This invoice does not require payment at this time."
        render :file => 'caboose/extras/error'
        return
      end
        
      sc = @site.store_config
      case sc.pp_name
        when 'authorize.net'
                      
          @sim_transaction = AuthorizeNet::SIM::Transaction.new(
            sc.authnet_api_login_id, 
            sc.authnet_api_transaction_key, 
            @invoice.total,                          
            :relay_response => 'TRUE',              
            :relay_url => "#{sc.authnet_relay_domain}/my-account/invoices/authnet-relay",
            :transaction_type => 'AUTH_ONLY',                        
            :test => sc.pp_testing
          )
          @request = request
          @show_relay = params[:show_relay] && params[:show_relay].to_i == 1
          
        when 'stripe'
          # TODO: Implement manual invoice payment for stripe
      end      
      render :layout => false      
    end

    # @route POST /my-account/confirm
    def confirm      
      sc = @site.store_config
      @invoice = Invoice.find(params[:id])

      # Make sure all the variants still exist      
      @invoice.line_items.each do |li|
        v = Variant.where(:id => li.variant_id).first
        if v.nil? || v.status == 'Deleted'
          render :json => { :error => 'One or more of the products you are purchasing are no longer available.' }
          return
        end
      end

      error = false      
      requires_payment = @invoice.line_items.count > 0 && @invoice.total > 0
      if requires_payment
        ot = nil

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

        if !ot.success
          render :json => { :error => error }
          return
        else
          capture_resp = @invoice.capture_funds
          if capture_resp.success == true
            @invoice.take_gift_card_funds
            @invoice.status = Caboose::Invoice::STATUS_PROCESSED
          end
        end
      end
      
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

      # Save the invoice
      @invoice.save

      # Decrement quantities of variants
      @invoice.decrement_quantities

      render :json => {
        :success => true,
        :message => "Thank you for your payment!"
      }
      return
    end
    
    # @route GET /my-account/invoices/:id/json
    def invoice_json
      return if !logged_in?
      
      invoice = Invoice.find(params[:id])
      if invoice.customer_id != logged_in_user.id        
        render :json => { :error => "The given invoice does not belong to you." } 
        return
      end
      
      if invoice.shipping_address_id.nil?
        sa = Address.create
        invoice.shipping_address_id = sa.id
        invoice.save
      end
      render :json => invoice.as_json(:include => [        
        { :line_items => { :include => { :variant => { :include => :product }}}},
        { :invoice_packages => { :include => [:shipping_package, :shipping_method] }},
        { :discounts => { :include => :gift_card }},
        :customer,
        :shipping_address,
        :billing_address,
        :invoice_transactions
      ])
    end

    # @route GET /my-account/invoices/:id/print
    def invoice_pdf
      invoice = Invoice.find(params[:id])

      if invoice.customer_id != logged_in_user.id
        @error = "The given invoice does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end

      pdf = @site.store_config.custom_invoice_pdf
      pdf = "InvoicePdf" if pdf.nil? || pdf.strip.length == 0                              
      eval("pdf = #{pdf}.new")
      pdf.invoice = Invoice.find(params[:id])             
      send_data pdf.to_pdf, :filename => "invoice_#{pdf.invoice.id}.pdf", :type => "application/pdf", :disposition => "inline"   
    end
    
    # @route GET  /my-account/invoices/authnet-relay
    # @route POST /my-account/invoices/authnet-relay
    def authnet_relay
      Caboose.log("Authorize.net relay for my account, invoice #{params[:x_invoice_id]}")
      
      invoice = Caboose::Invoice.find(params[:x_invoice_num])
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
        invoice.status = Invoice::STATUS_PENDING if invoice.status == Invoice::STATUS_CART
        invoice.invoice_number = @site.store_config.next_invoice_number if invoice.invoice_number.nil?
        
        # Send out emails        
        InvoicesMailer.configure_for_site(@site.id).customer_new_invoice(invoice).deliver                
        
        # Emit invoice event
        Caboose.plugin_hook('invoice_authorized', invoice)        
      else
        invoice.financial_status = Invoice::FINANCIAL_STATUS_PENDING        
        error = "There was a problem processing your payment."
      end
            
      invoice.save
      
      @url = params[:x_after_relay]
      @url << (ot.success ? "?success=1" : "?error=#{error}")             
                  
      render :layout => false
    end
    
    # @route GET  /my-account/invoices/:id/authnet-response
    # @route POST /my-account/invoices/:id/authnet-response    
    def authnet_response
      Caboose.log("Authorize.net response for my account, invoice #{params[:id]}")
      
      @resp = Caboose::StdClass.new
      @resp.success = true if params[:success]
      @resp.error = params[:error] if params[:error]
      
      # Go ahead and capture funds if the invoice only contained downloadable items
      @invoice = Invoice.find(params[:id])
      if !@invoice.has_shippable_items?
        capture_resp = @invoice.capture_funds
        if capture_resp.error
          @resp.success = false
          @resp.error = capture_resp.error
        end        
      end      
      render :layout => false
    end
    
    # @route GET /my-account/invoices/:id
    def edit
      return if !verify_logged_in
      
      @invoice = Invoice.find(params[:id])
      if @invoice.customer_id != logged_in_user.id
        @error = "The given invoice does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end
    end
            
  end
end
