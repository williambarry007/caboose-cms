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
        :financial_status => Order::FINANCIAL_STATUS_PENDING
      )    
      render :json => { :sucess => true, :redirect => "/admin/orders/#{order.id}" }
    end
      
    # GET /admin/orders/:id
    def admin_edit
      return if !user_is_allowed('orders', 'edit')
      @order = Order.find(params[:id])
      @order.calculate
      render :layout => 'caboose/admin'
    end

    # GET /admin/orders/:id/capture
    def capture_funds
      return if !user_is_allowed('orders', 'edit')
      
      response = Caboose::StdClass.new
      order = Order.find(params[:id])
      t = OrderTransaction.where(:order_id => order.id, :transaction_type => OrderTransaction::TYPE_AUTHORIZE, :success => true).first
      
      if order.financial_status == Order::FINANCIAL_STATUS_CAPTURED
        resp.error = "Funds for this order have already been captured."    
      elsif order.total > t.amount
        resp.error = "The order total exceeds the authorized amount."
      elsif t.nil?
        resp.error = "This order doesn't seem to be authorized."
      else
                        
        sc = @site.store_config
        case sc.pp_name
          when 'authorize.net'
            
            response = AuthorizeNet::SIM::Transaction.new(
              sc.pp_username, 
              sc.pp_password,
              order.total,
              :transaction_type => 'CAPTURE_ONLY',
              :transaction_id => t.transaction_id
            )                
            order.update_attribute(:financial_status, Order::FINANCIAL_STATUS_CAPTURED)
            resp.success = 'Captured funds successfully'
          when 'payscape'
            # TODO: Implement capture funds for payscape

        end
          
        #if (order.discounts.any? && order.total < order.discounts.first.amount_current) || PaymentProcessor.capture(order)
        #  order.financial_status = 'captured'
        #  order.save
        #  
        #  if order.discounts.any?
        #    order.update_attribute(:amount_discounted, order.discounts.first.amount_current)
        #    order.update_gift_cards
        #  end
        #  
        #  response.success = "Captured funds successfully"
        #else
        #  response.error = "Error capturing funds."
        #end
        
      end
      
      render :json => response
    end
    
    # GET /admin/orders/:id/void
    def admin_void
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new      
      order = Order.find(params[:id])
      t = OrderTransaction.where(:order_id => order.id, :transaction_type => OrderTransaction::TYPE_AUTHORIZE, :success => true).first
      
      if order.financial_status == Order::FINANCIAL_STATUS_CAPTURED
        resp.error = "This order has already been captured, you will need to refund instead"
      elsif t.nil?
        resp.error = "This order doesn't seem to be authorized."
      else
                
        sc = @site.store_config
        case sc.pp_name
          when 'authorize.net'        
                    
            response = AuthorizeNet::SIM::Transaction.new(
              sc.pp_username, 
              sc.pp_password,                      
              order.total,
              :transaction_type => OrderTransaction::TYPE_VOID,
              :transaction_id => t.transaction_id
            )                    
            order.update_attributes(
              :financial_status => Order::FINANCIAL_STATUS_VOIDED,
              :status => Order::STATUS_CANCELED
            )
            order.save          
            # TODO: Add the variant quantities ordered back        
            resp.success = "Order voided successfully"
          when 'payscape'
            # TODO: Implement payscape void order
        end
        
      end
    
      render :json => resp
    end
  
    # GET /admin/orders/:id/refund
    def admin_refund
      return if !user_is_allowed('orders', 'edit')
    
      response = Caboose::StdClass.new({
        'refresh' => nil,
        'error' => nil,
        'success' => nil
      })
    
      order = Order.find(params[:id])
    
      if order.financial_status != Order::FINANCIAL_STATUS_CAPTURED
        response.error = "This order hasn't been captured yet, you will need to void instead"
      else
        if PaymentProcessor.refund(order)
          order.update_attributes(
            :financial_status => Order::FINANCIAL_STATUS_REFUNDED,
            :status => Order::STATUS_CANCELED
          )
          
          response.success = 'Order refunded successfully'
        else
          response.error = 'Error refunding order'
        end
        
        #if order.calculate_net < (order.amount_discounted || 0) || PaymentProcessor.refund(order)
        #  order.financial_status = 'refunded'
        #  order.status = 'refunded'
        #  order.save
        #  
        #  if order.discounts.any?
        #    discount = order.discounts.first
        #    amount_to_refund = order.calculate_net < order.amount_discounted ? order.calculate_net : order.amount_discounted
        #    discount.update_attribute(:amount_current, amount_to_refund + discount.amount_current)
        #  end
        #  
        #  response.success = "Order refunded successfully"
        #else
        #  response.error = "Error refunding order."
        #end
      end
    
      render json: response
      
      # return if !user_is_allowed('orders', 'edit')
      #     
      # response = Caboose::StdClass.new({
      #   'refresh' => nil,
      #   'error' => nil,
      #   'success' => nil
      # })
      #     
      # order = Order.find(params[:id])
      #     
      # if order.financial_status != 'captured'
      #   response.error = "This order hasn't been captured yet, you will need to void instead"
      # else
      #   if PaymentProcessor.refund(order)
      #     order.financial_status = 'refunded'
      #     order.status = 'refunded'
      #     order.save
      #     
      #     # Add the variant quantities ordered back
      #     order.cancel
      #     
      #     response.success = "Order refunded successfully"
      #   else
      #     response.error = "Error refunding order."
      #   end
      # end
      #     
      # render :json => response
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
          when 'tax'             then order.tax             = value          
          when 'shipping'        then order.shipping        = value
          when 'handling'        then order.handling        = value
          when 'custom_discount' then order.custom_discount = value        
          when 'status'          then order.status          = value
          when 'customer_id'     then order.customer_id     = value            
        end
      end
      order.calculate
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

    # GET /admin/orders/:id/refund
    # def refund
    #   return if !user_is_allowed('orders', 'edit')
    # 
    #   response = Caboose::StdClass.new({
    #     'refresh' => nil,
    #     'error' => nil,
    #     'success' => nil
    #   })
    # 
    #   order = Order.find(params[:id])
    # 
    #   if order.financial_status != 'captured'
    #     response.error = "This order hasn't been captured yet, you will need to void instead"
    #   else
    #     ap order.total
    #     ap order.amount_discounted
    #     
    #     if order.total < order.amount_discounted || PaymentProcessor.refund(order)
    #       order.financial_status = 'refunded'
    #       order.status = 'refunded'
    #       order.save
    #       
    #       discount = order.discounts.first
    #       ap '==========================='
    #       ap order.amount_discounted + discount.amount_current
    #       ap '==========================='
    #       discount.update_attribute(:amount_current, order.amount_discounted + discount.amount_current) if order.discounts.any?
    #       
    #       response.success = "Order refunded successfully"
    #     else
    #       response.error = "Error refunding order."
    #     end
    #   end
    # 
    #   render json: response
    # end

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
