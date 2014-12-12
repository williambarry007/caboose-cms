module Caboose
  class OrdersController < Caboose::ApplicationController
    
    # GET /admin/orders
    def admin_index
      return if !user_is_allowed('orders', 'view')
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'site_id'              => @site.id,
        'customer_id'          => '', 
        'status'               => 'pending',
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
      @products = Product.by_title
      render :layout => 'caboose/admin'
    end
      
    # GET /admin/orders/:id
    def admin_edit
      return if !user_is_allowed('orders', 'edit')
      @order = Order.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/orders/:id/void
    def admin_void
      return if !user_is_allowed('orders', 'edit')
      
      response = Caboose::StdClass.new({
        'refresh' => nil,
        'error' => nil,
        'success' => nil
      })
      
      order = Order.find(params[:id])
      
      if order.financial_status == 'captured'
        response.error = "This order has already been captured, you will need to refund instead"
      else
        if PaymentProcessor.void(order)
          order.update_attributes(
            :financial_status => 'voided',
            :status => 'cancelled'
          )
          
          # Add the variant quantities ordered back
          #order.cancel
          
          response.success = "Order voided successfully"
        else
          response.error = "Error voiding order."
        end
      end
    
      render :json => response
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
    
      if order.financial_status != 'captured'
        response.error = "This order hasn't been captured yet, you will need to void instead"
      else
        if PaymentProcessor.refund(order)
          order.update_attributes(
            :financial_status => 'refunded',
            :status => 'cancelled'
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
      render :json => order, :include => { :order_line_items => { :include => :variant }}
    end
  
    # GET /admin/orders/:id/print
    def admin_print
      return if !user_is_allowed('orders', 'edit')    
       
      pdf = OrderPdf.new
      pdf.order = Order.find(params[:id])             
      send_data pdf.to_pdf, :filename => "order_#{pdf.order.id}.pdf", :type => "application/pdf", :disposition => "inline"
      
      #@order = Order.find(params[:id])
      #render :layout => 'caboose/admin'
    end
      
    # PUT /admin/orders/:id
    def admin_update
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      order = Order.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'tax'
            order.tax = value          
          when 'shipping'
            order.shipping = value
          when 'handling'
            order.handling = value
          when 'discount'
            order.discount = value        
          when 'status'
            order.status = value
            resp.attributes['status'] = {'text' => value}
        end
      end
      order.calculate_total    
      resp.success = save && order.save
      render :json => resp
    end
    
    # PUT /admin/orders/:order_id/line-items/:id
    def admin_update_line_item
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      li = OrderLineItem.find(params[:id])    
      
      save = true
      send_status_email = false    
      params.each do |name,value|
        case name
          when 'quantity'
            li.quantity = value
            li.save
                      	  
            # Recalculate everything
            r = ShippingCalculator.rate(li.order, li.order.shipping_method_code)
            li.order.shipping = r['negotiated_rate'] / 100
            li.order.handling = (r['negotiated_rate'] / 100) * 0.05
            tax_rate = TaxCalculator.tax_rate(li.order.shipping_address)
            li.order.tax = li.order.subtotal * tax_rate
            li.order.calculate_total
            li.order.save
            
          when 'tracking_number'
            li.tracking_number = value
            send_status_email = true
          when 'status'
            li.status = value
            resp.attributes['status'] = {'text' => value}
            send_status_email = true
        end
      end
      if send_status_email       
        OrdersMailer.customer_status_updated(li.order).deliver
      end
      resp.success = save && li.save
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
    
    # GET /admin/orders/line-item-status-options
    def admin_line_item_status_options
      arr = ['pending', 'ready to ship', 'shipped', 'backordered', 'canceled']
      options = []
      arr.each do |status|
        options << {
          :value => status,
          :text  => status
        }
      end
      render :json => options
    end
    
    # GET /admin/orders/:id/capture
    def capture_funds
      return if !user_is_allowed('orders', 'edit')
      
      response = Caboose::StdClass.new({
        'refresh' => nil,
        'error'   => nil,
        'success' => nil
      })
      
      order = Order.find(params[:id])
      
      if order.financial_status == 'captured'
        resp.error = "Funds for this order have already been captured."    
      elsif order.total > order.auth_amount
        resp.error = "The order total exceeds the authorized amount."
      else
        if PaymentProcessor.capture(order)
          order.update_attribute(:financial_status, 'captured')
          response.success = 'Captured funds successfully'
        else
          response.error = 'Error capturing funds'
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
    #def void
    #  return if !user_is_allowed('orders', 'edit')
    #
    #  response = Caboose::StdClass.new({
    #    'refresh' => nil,
    #    'error' => nil,
    #    'success' => nil
    #  })
    #
    #  order = Order.find(params[:id])
    #
    #  if order.financial_status == 'captured'
    #    response.error = "This order has already been captured, you will need to refund instead"
    #  else
    #    if order.total < order.amount_discounted || PaymentProcessor.void(order)
    #      order.financial_status = 'cancelled'
    #      order.status = 'voided'
    #      order.save
    #    
    #      response.success = "Order voided successfully"
    #    else
    #      response.error = "Error voiding order."
    #    end
    #  end
    #
    #  render json: response
    #end
  
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
      return if !user_is_allowed('categories', 'view')
      statuses = ['cart', 'pending', 'ready to ship', 'shipped', 'canceled']
      options = []
      statuses.each do |s|
        options << {
          'text' => s,
          'value' => s
        }
      end       
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
      elsif Order.exists?("status = 'shipped' and date_authorized is not null")
        d1 = Order.where("status = ? and date_authorized is not null", 'shipped').reorder("date_authorized DESC").limit(1).pluck('date_authorized')
        d1 = DateTime.parse(d1)
      end
      
      # Google Feed Docs
      # https://support.google.com/trustedstoresmerchant/answer/3272612?hl=en&ref_topic=3272286?hl=en
      tsv = ["merchant order id\ttracking number\tcarrier code\tother carrier name\tship date"]            
      if Order.exists?("status = 'shipped' and date_authorized > '#{d1.strftime("%F %T")}'")
        Order.where("status = ? and date_authorized > ?", 'shipped', d1).reorder(:id).all.each do |order|
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
