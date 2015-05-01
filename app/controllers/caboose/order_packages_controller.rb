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
    
    # GET /admin/orders/:order_id/packages/:id/calculate-shipping
    def calculate_shipping
      return if !user_is_allowed('orders', 'edit')

      op = OrderPackage.find(params[:id])
      order = op.order
      
      render :json => { :error => "Empty order" } and return if order.nil?
      render :json => { :error => "No shippable items in order package" } and return if !order.has_shippable_items?
      render :json => { :error => "Empty shipping address" } and return if order.shipping_address.nil?

      rate = ShippingCalculator.calculate_rate(op)
      render :json => { :error => "No rate found for given shipping package and method" } and return if rate.nil?

      op.total = rate
      op.save
      
      order.calculate_shipping
      order.calculate_total
      order.save
      
      render :json => { :error => "No rate found for shipping method" } and return if rate.nil?                   
      render :json => { :success => true, :rate => rate }            
    end
    
    # GET /admin/orders/:order_id/packages/:id/shipping-rates
    def shipping_rates
      return if !user_is_allowed('orders', 'edit')

      op = OrderPackage.find(params[:id])
      order = op.order
      
      render :json => { :error => "Empty order" } and return if order.nil?
      render :json => { :error => "No shippable items in order package" } and return if !order.has_shippable_items?
      render :json => { :error => "Empty shipping address" } and return if order.shipping_address.nil?
                                                        
      rates = ShippingCalculator.order_package_rates(op)      
      render :json => rates            
    end
            
  end
end
