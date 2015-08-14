module Caboose
  class OrdersController < Caboose::ApplicationController
    
    # GET /admin/orders/weird-test
    def admin_weird_test
      Caboose.log("Before the admin_weird_test")
      x = Order.new
      Caboose.log("After the admin_weird_test")
      render :json => x      
    end
    
    # GET /admin/orders
    def admin_index
      return if !user_is_allowed('orders', 'view')
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'site_id'              => @site.id,
        'customer_id'          => '', 
        'status'               => Order::STATUS_PENDING,
        'shipping_method_code' => '',
        'id'                   => ''
      }, {
        'model'          => 'Caboose::Order',
        'sort'           => 'id',
        'desc'           => 1,
        'base_url'       => '/admin/orders',
        'use_url_params' => false
      })
      
      @orders    = @pager.items
      @customers = Caboose::User.reorder('last_name, first_name').all
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/orders/new
    def admin_new
      return if !user_is_allowed('orders', 'add')      
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/orders
    def admin_add
      return if !user_is_allowed('orders', 'add')
      order = Order.create(
        :site_id => @site.id,
        :status => Order::STATUS_PENDING,                          
        :financial_status => Order::FINANCIAL_STATUS_PENDING,
        :order_number => @site.store_config.next_order_number
      )    
      render :json => { :sucess => true, :redirect => "/admin/orders/#{order.id}" }
    end
      
    # GET /admin/orders/:id
    def admin_edit
      return if !user_is_allowed('orders', 'edit')
      @order = Order.find(params[:id])
      #@order.calculate
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/orders/:id/calculate-tax
    def admin_calculate_tax
      return if !user_is_allowed('orders', 'edit')
      order = Order.find(params[:id])
      order.tax = order.calculate_tax
      order.total = order.calculate_total
      order.save
      render :json => { :success => true }      
    end
    
    # GET /admin/orders/:id/calculate-handling
    def admin_calculate_handling
      return if !user_is_allowed('orders', 'edit')
      order = Order.find(params[:id])
      order.handling = order.calculate_handling
      order.total = order.calculate_total
      order.save
      render :json => { :success => true }      
    end

    # GET /admin/orders/:id/capture
    def capture_funds
      return if !user_is_allowed('orders', 'edit')
           
      order = Order.find(params[:id])
      resp = order.capture_funds      
      
      render :json => resp
    end
    
    # GET /admin/orders/:id/void
    def admin_void
      return if !user_is_allowed('orders', 'edit')
            
      order = Order.find(params[:id])
      resp = order.void
    
      render :json => resp
    end
  
    # GET /admin/orders/:id/refund
    def admin_refund
      return if !user_is_allowed('orders', 'edit')
    
      order = Order.find(params[:id])
      resp = order.refund 
      
      render :json => resp            
    end
    
    # POST /admin/orders/:id/resend-confirmation
    def admin_resend_confirmation
      if Order.find(params[:id]).resend_confirmation
        render :json => { success: "Confirmation re-sent successfully." }
      else
        render :json => { error: "There was an error re-sending the email." }
      end
    end
    
    # GET /admin/orders/:id/json
    def admin_json
      return if !user_is_allowed('orders', 'edit')    
      order = Order.find(params[:id])
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
  
    # GET /admin/orders/:id/print.pdf
    def admin_print
      return if !user_is_allowed('orders', 'edit')           
      
      pdf = OrderPdf.new
      pdf.order = Order.find(params[:id])             
      send_data pdf.to_pdf, :filename => "order_#{pdf.order.id}.pdf", :type => "application/pdf", :disposition => "inline"   
    end
    
    # GET /admin/orders/print-pending
    def admin_print_pending
      return if !user_is_allowed('orders', 'edit')    
      
      pdf = PendingOrdersPdf.new
      pdf.orders = Order.where(:site_id => @site.id, :status => Order::STATUS_PENDING).all      
      send_data pdf.to_pdf, :filename => "pending_orders.pdf", :type => "application/pdf", :disposition => "inline"            
    end
      
    # PUT /admin/orders/:id
    def admin_update
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      order = Order.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'tax'             then 
            order.tax = value
            order.total = order.calculate_total          
          when 'handling'        then
            order.handling = value
            order.total = order.calculate_total
          when 'custom_discount' then 
            order.custom_discount = value
            order.discount = order.calculate_discount
            order.total = order.calculate_total
          when 'status'          then
            order.status = value
            if value == 'Shipped'
              order.date_shipped = DateTime.now.utc
            end            
          when 'customer_id'     then order.customer_id     = value            
        end
      end

      #order.calculate
      #order.calculate_total
      #resp.attributes['total'] = { 'value' => order.total }
      
      resp.success = save && order.save
      render :json => resp
    end
    
    # DELETE /admin/orders/:id
    def admin_delete
      return if !user_is_allowed('orders', 'delete')
      Order.find(params[:id]).destroy
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/orders'
      })
    end

    # GET /admin/orders/:id/send-for-authorization
    def admin_send_for_authorization
      return if !user_is_allowed('orders', 'edit')
      order = Order.find(params[:id])
      order.delay.send_payment_authorization_email      
      render :json => { :success => true }
    end

    # GET /admin/orders/status-options
    def admin_status_options
      return if !user_is_allowed('orders', 'view')
      statuses = [
        Order::STATUS_CART, 
        Order::STATUS_PENDING, 
        Order::STATUS_READY_TO_SHIP, 
        Order::STATUS_SHIPPED, 
        Order::STATUS_CANCELED
      ]
      options = statuses.collect{ |s| { 'text' => s.capitalize, 'value' => s }}       
      render :json => options    
    end
    
    # GET /admin/orders/test-info
    def admin_mail_test_info
      TestMailer.test_info.deliver
      render :text => "Sent email to info@tuskwearcollection.com on #{DateTime.now.strftime("%F %T")}"
    end
    
    # GET /admin/orders/test-gmail
    def admin_mail_test_gmail
      TestMailer.test_gmail.deliver
      render :text => "Sent email to william@nine.is on #{DateTime.now.strftime("%F %T")}"
    end
    
    # GET /admin/orders/google-feed
    def admin_google_feed
      d2 = DateTime.now
      d1 = DateTime.now
      if Caboose::Setting.exists?(:name => 'google_feed_date_last_submitted')                  
        d1 = Caboose::Setting.where(:name => 'google_feed_date_last_submitted').first.value      
        d1 = DateTime.parse(d1)
      elsif Order.exists?("status = ? and date_authorized is not null", Order::STATUS_SHIPPED)
        d1 = Order.where("status = ? and date_authorized is not null", Order::STATUS_SHIPPED).reorder("date_authorized DESC").limit(1).pluck('date_authorized')
        d1 = DateTime.parse(d1)
      end
      
      # Google Feed Docs
      # https://support.google.com/trustedstoresmerchant/answer/3272612?hl=en&ref_topic=3272286?hl=en
      tsv = ["merchant order id\ttracking number\tcarrier code\tother carrier name\tship date"]            
      if Order.exists?("status = ? and date_authorized > '#{d1.strftime("%F %T")}'", Order::STATUS_SHIPPED)
        Order.where("status = ? and date_authorized > ?", Order::STATUS_SHIPPED, d1).reorder(:id).all.each do |order|
          tracking_numbers = order.line_items.collect{ |li| li.tracking_number }.compact.uniq
          tn = tracking_numbers && tracking_numbers.count >= 1 ? tracking_numbers[0] : ""
          tsv << "#{order.id}\t#{tn}\tUPS\t\t#{order.date_shipped.strftime("%F")}"                              
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
