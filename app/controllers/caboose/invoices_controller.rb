module Caboose
  class InvoicesController < Caboose::ApplicationController
    
    # @route GET /admin/invoices/weird-test
    def admin_weird_test
      Caboose.log("Before the admin_weird_test")
      x = Invoice.new
      Caboose.log("After the admin_weird_test")
      render :json => x      
    end
    
    # @route GET /admin/invoices
    def admin_index
      return if !user_is_allowed('invoices', 'view')
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'site_id'              => @site.id,
        'customer_id'          => '', 
        'status'               => Invoice::STATUS_PENDING,
        'shipping_method_code' => '',
        'id'                   => '',
        'invoice_number'       => ''
      }, {
        'model'          => 'Caboose::Invoice',
        'sort'           => 'id',
        'desc'           => 1,
        'base_url'       => '/admin/invoices',
        'use_url_params' => false,
        'items_per_page' => 100
      })
      
      @invoices  = @pager.items
      @customers = Caboose::User.where(:site_id => @site.id).reorder('last_name, first_name').all
      
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/invoices/:id/refresh-transactions
    def refresh_transactions      
      return if !user_is_allowed('invoices', 'add')
      
      resp = Caboose::StdClass.new
                  
      invoice = Invoice.find(params[:id])
      invoice.refresh_transactions            
      resp.financial_status = invoice.financial_status
      resp.invoice_transactions = invoice.invoice_transactions.reorder(:date_processed).all
      
      render :json => resp
    end
    
    # @route GET /admin/invoices/new
    def admin_new
      return if !user_is_allowed('invoices', 'add')      
      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/invoices
    def admin_add
      return if !user_is_allowed('invoices', 'add')
      invoice = Invoice.create(
        :site_id => @site.id,
        :status => Invoice::STATUS_PENDING,                          
        :financial_status => Invoice::FINANCIAL_STATUS_PENDING,
        :invoice_number => @site.store_config.next_invoice_number
      )    
      render :json => { :sucess => true, :redirect => "/admin/invoices/#{invoice.id}" }
    end
      
    # @route_priority 50
    # @route GET /admin/invoices/:id
    def admin_edit
      return if !user_is_allowed('invoices', 'edit')
      @invoice = Invoice.where(:id => params[:id]).first

      if params[:id].nil? || @invoice.nil?
        render :file => 'caboose/invoices/admin_invalid_invoice', :layout => 'caboose/admin'
        return
      end            
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/invoices/:id/calculate-tax
    def admin_calculate_tax
      return if !user_is_allowed('invoices', 'edit')
      invoice = Invoice.find(params[:id])
      invoice.tax = invoice.calculate_tax
      invoice.total = invoice.calculate_total
      invoice.save
      render :json => { :success => true }      
    end
    
    # @route GET /admin/invoices/:id/calculate-handling
    def admin_calculate_handling
      return if !user_is_allowed('invoices', 'edit')
      invoice = Invoice.find(params[:id])
      invoice.handling = invoice.calculate_handling
      invoice.total = invoice.calculate_total
      invoice.save
      render :json => { :success => true }      
    end

    # @route GET /admin/invoices/:id/capture
    def capture_funds
      return if !user_is_allowed('invoices', 'edit')
           
      invoice = Invoice.find(params[:id])
      resp = invoice.capture_funds   
      
      # Tell taxcloud the invoice was captured
      #Caboose::TaxCalculator.captured(invoice)
      
      render :json => resp
    end
    
    # @route GET /admin/invoices/:id/void
    def admin_void
      return if !user_is_allowed('invoices', 'edit')
            
      invoice = Invoice.find(params[:id])
      resp = invoice.void
    
      render :json => resp
    end
  
    # @route GET /admin/invoices/:id/refund
    def admin_refund
      return if !user_is_allowed('invoices', 'edit')
    
      invoice = Invoice.find(params[:id])
      resp = invoice.refund 
      
      render :json => resp            
    end
    
    # @route POST /admin/invoices/:id/resend-confirmation
    def admin_resend_confirmation
      if Invoice.find(params[:id]).resend_confirmation
        render :json => { success: "Confirmation re-sent successfully." }
      else
        render :json => { error: "There was an error re-sending the email." }
      end
    end
    
    # @route GET /admin/invoices/:id/json
    def admin_json
      return if !user_is_allowed('invoices', 'edit')    
      invoice = Invoice.find(params[:id])
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
  
    # @route GET /admin/invoices/:id/print
    def admin_print
      return if !user_is_allowed('invoices', 'edit')           
      
      pdf = InvoicePdf.new
      pdf.invoice = Invoice.find(params[:id])             
      send_data pdf.to_pdf, :filename => "invoice_#{pdf.invoice.id}.pdf", :type => "application/pdf", :disposition => "inline"   
    end
    
    # @route GET /admin/invoices/print-pending
    def admin_print_pending
      return if !user_is_allowed('invoices', 'edit')    
      
      pdf = PendingInvoicesPdf.new
      if params[:print_card_details]
        pdf.print_card_details = params[:print_card_details].to_i == 1
      end
      pdf.invoices = Invoice.where(:site_id => @site.id, :status => Invoice::STATUS_PENDING).all      
      send_data pdf.to_pdf, :filename => "pending_invoices.pdf", :type => "application/pdf", :disposition => "inline"            
    end
      
    # @route PUT /admin/invoices/:id
    def admin_update
      return if !user_is_allowed('invoices', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      invoice = Invoice.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'tax'             then 
            invoice.tax = value
            invoice.total = invoice.calculate_total          
          when 'handling'        then
            invoice.handling = value
            invoice.total = invoice.calculate_total
          when 'custom_discount' then 
            invoice.custom_discount = value
            invoice.discount = invoice.calculate_discount
            invoice.total = invoice.calculate_total
          when 'status'          then
            invoice.status = value
            if value == 'Shipped'
              invoice.date_shipped = DateTime.now.utc
            end            
          when 'customer_id'     then invoice.customer_id     = value            
        end
      end

      #invoice.calculate
      #invoice.calculate_total
      #resp.attributes['total'] = { 'value' => invoice.total }
      
      resp.success = save && invoice.save
      render :json => resp
    end
    
    # @route DELETE /admin/invoices/:id
    def admin_delete
      return if !user_is_allowed('invoices', 'delete')
      Invoice.find(params[:id]).destroy
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/invoices'
      })
    end

    # @route GET /admin/invoices/:id/send-for-authorization
    def admin_send_for_authorization
      return if !user_is_allowed('invoices', 'edit')
      invoice = Invoice.find(params[:id])
      invoice.delay(:queue => 'caboose_store').send_payment_authorization_email      
      render :json => { :success => true }
    end
    
    # @route GET /admin/invoices/city-report
    def admin_city_report
      return if !user_is_allowed('invoices', 'view')

      @d1 = params[:d1] ? DateTime.strptime("#{params[:d1]} 00:00:00", '%Y-%m-%d %H:%M:%S') : DateTime.strptime(DateTime.now.strftime("%Y-%m-01 00:00:00"), '%Y-%m-%d %H:%M:%S')
      @d2 = params[:d2] ? DateTime.strptime("#{params[:d2]} 00:00:00", '%Y-%m-%d %H:%M:%S') : @d1 + 1.month      
      @rows = InvoiceReporter.city_report(@site.id, @d1, @d2)
      
      render :layout => 'caboose/admin'    
    end
    
    # @route GET /admin/invoices/summary-report
    def admin_summary_report
      return if !user_is_allowed('invoices', 'view')

      @d1 = params[:d1] ? DateTime.strptime("#{params[:d1]} 00:00:00", '%Y-%m-%d %H:%M:%S') : DateTime.strptime(DateTime.now.strftime("%Y-%m-01 00:00:00"), '%Y-%m-%d %H:%M:%S')
      @d2 = params[:d2] ? DateTime.strptime("#{params[:d2]} 00:00:00", '%Y-%m-%d %H:%M:%S') : @d1 + 1.month      
      @rows = InvoiceReporter.summary_report(@site.id, @d1, @d2)
      
      render :layout => 'caboose/admin'    
    end

    # @route GET /admin/invoices/:field-options    
    def admin_options
      return if !user_is_allowed('invoices', 'view')
      
      options = []
      case params[:field]
        when 'status'
          statuses = [
            Invoice::STATUS_CART, 
            Invoice::STATUS_PENDING, 
            Invoice::STATUS_READY_TO_SHIP, 
            Invoice::STATUS_SHIPPED, 
            Invoice::STATUS_CANCELED
          ]
          options = statuses.collect{ |s| { 'text' => s.capitalize, 'value' => s }}              
        when 'payment-terms'
          options = [
            { 'value' => Invoice::PAYMENT_TERMS_PIA   , 'text' => 'Pay In Advance' },
            { 'value' => Invoice::PAYMENT_TERMS_NET7  , 'text' => 'Net 7'          },
            { 'value' => Invoice::PAYMENT_TERMS_NET10 , 'text' => 'Net 10'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET30 , 'text' => 'Net 30'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET60 , 'text' => 'Net 60'         },
            { 'value' => Invoice::PAYMENT_TERMS_NET90 , 'text' => 'Net 90'         },
            { 'value' => Invoice::PAYMENT_TERMS_EOM   , 'text' => 'End of Month'   }            
          ]
      end          
      render :json => options    
    end
    
    # @route GET /admin/invoices/google-feed
    def admin_google_feed
      d2 = DateTime.now
      d1 = DateTime.now
      if Caboose::Setting.exists?(:name => 'google_feed_date_last_submitted')                  
        d1 = Caboose::Setting.where(:name => 'google_feed_date_last_submitted').first.value      
        d1 = DateTime.parse(d1)
      elsif Invoice.exists?("status = ? and date_authorized is not null", Invoice::STATUS_SHIPPED)
        d1 = Invoice.where("status = ? and date_authorized is not null", Invoice::STATUS_SHIPPED).reorder("date_authorized DESC").limit(1).pluck('date_authorized')
        d1 = DateTime.parse(d1)
      end
      
      # Google Feed Docs
      # https://support.google.com/trustedstoresmerchant/answer/3272612?hl=en&ref_topic=3272286?hl=en
      tsv = ["merchant invoice id\ttracking number\tcarrier code\tother carrier name\tship date"]            
      if Invoice.exists?("status = ? and date_authorized > '#{d1.strftime("%F %T")}'", Invoice::STATUS_SHIPPED)
        Invoice.where("status = ? and date_authorized > ?", Invoice::STATUS_SHIPPED, d1).reorder(:id).all.each do |invoice|
          tracking_numbers = invoice.line_items.collect{ |li| li.tracking_number }.compact.uniq
          tn = tracking_numbers && tracking_numbers.count >= 1 ? tracking_numbers[0] : ""
          tsv << "#{invoice.id}\t#{tn}\tUPS\t\t#{invoice.date_shipped.strftime("%F")}"                              
        end
      end
      
      # Save when we made the last call
      setting = if Caboose::Setting.exists?(:name => 'google_feed_date_last_submitted')
        Caboose::Setting.where(:name => 'google_feed_date_last_submitted').first
      else
        Caboose::Setting.new(:name => 'google_feed_date_last_submitted')
      end
      
      setting.value = d2.strftime("%F %T")
      setting.save            
                   
      # Print out the lines
      render :text => tsv.join("\n")
    end
  end
end
