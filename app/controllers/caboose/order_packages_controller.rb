module Caboose
  class OrderPackagesController < Caboose::ApplicationController
    
    # GET /admin/orders/:order_id/packages/json
    def admin_json      
      return if !user_is_allowed('orders', 'view')
      order = Order.find(params[:order_id])
      render :json => order.order_packages.as_json(
        :include => { :shipping_package => { :include => :shipping_methods} }
      )
    end     

    # POST /admin/orders/:order_id/packages
    def admin_add
      return if !user_is_allowed('orders', 'add')
      
      resp = StdClass.new
                              
      if    params[:shipping_package_id].strip.length  == 0 then resp.error = "Please select a shipping package."
      elsif params[:shipping_method_id].strip.length   == 0 then resp.error = "Please select a shipping method."      
      else

        op = OrderPackage.new(
          :order_id            => params[:order_id],
          :shipping_package_id => params[:shipping_package_id],
          :shipping_method_id  => params[:shipping_method_id],
          :status              => OrderPackage::STATUS_PENDING          
        )        
        op.save        
        resp.new_id = op.id
        resp.redirect = "/admin/orders/#{params[:order_id]}/packages/#{op.id}"
        
      end
      
      render :json => resp
    end
    
    # PUT /admin/orders/:order_id/packages/:id
    def admin_update
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new
      op = OrderPackage.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'order_id'            then op.order_id              = value
          when 'shipping_method_id'  then op.shipping_method_id    = value
          when 'shipping_package_id' then op.shipping_package_id   = value
          when 'status'              then op.status                = value
          when 'tracking_number'     then op.tracking_number       = value
          when 'total'               then op.total                 = value
          when 'package_method'      then
            arr = value.split('_')
            op.shipping_package_id = arr[0]
            op.shipping_method_id = arr[1]                      
        end
      end
      
      op.save
      op.order.shipping = op.order.calculate_shipping
      op.order.total = op.order.calculate_total
      op.order.save
      
      resp.success = true
      render :json => resp
    end
    
    # PUT /admin/orders/:order_id/line-items/:id
    def admin_update_line_item
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      li = LineItem.find(params[:id])    
      
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
            li.order.tax = TaxCalculator.tax(li.order)            
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
        OrdersMailer.configure_for_site(@site.id).customer_status_updated(li.order).deliver
      end
      resp.success = save && li.save
      render :json => resp
    end 
    
    # DELETE /admin/orders/:order_id/packages/:id
    def admin_delete
      return if !user_is_allowed('orders', 'delete')
      resp = StdClass.new
      op = OrderPackage.find(params[:id])
      if op.line_items.nil? || op.line_items.count == 0
        op.destroy
        resp.redirect = "/admin/orders/#{params[:order_id]}"
      else
        resp.error = "Only empty packages can be deleted."
      end
      render :json => resp
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
