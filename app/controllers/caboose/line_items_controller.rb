module Caboose
  class LineItemsController < Caboose::ApplicationController
    
    # GET /admin/orders/:id/line-items/json
    def admin_json
      return if !user_is_allowed('orders', 'edit')    
      order = Order.find(params[:id])
      render :json => order.line_items.as_json(:include => :order_package)
    end
    
    # GET /admin/orders/:order_id/line-items/new
    def admin_new
      return if !user_is_allowed('orders', 'edit')      
      render :layout => 'caboose/modal'            
    end
    
    # POST /admin/orders/:order_id/line-items
    def admin_add
      return if !user_is_allowed('orders', 'edit')      
      
      resp = StdClass.new
      v = Variant.find(params[:variant_id])
      li = LineItem.new(
        :order_id   => params[:order_id],
        :variant_id => params[:variant_id],
        :quantity   => 1,
        :price      => v.price,
        :status     => 'pending'                
      )         
      resp.success = li.save
      render :json => resp
    end
      
    # PUT /admin/orders/:order_id/line-items/:id
    def admin_update
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      li = LineItem.find(params[:id])    
      
      save = true
      send_status_email = false
      params.each do |name,value|        
        case name
          when 'order_id'         then li.order_id          = value
          when 'order_package_id' then li.order_package_id  = value
          when 'variant_id'       then li.variant_id        = value
          when 'parent_id'        then li.parent_id         = value          
          when 'price'            then li.price             = value
          when 'notes'            then li.notes             = value
          when 'custom1'          then li.custom1           = value
          when 'custom2'          then li.custom2           = value
          when 'custom3'          then li.custom3           = value
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
        OrdersMailer.configure_for_site(@site.id).customer_status_updated(li.order).deliver
      end    
      resp.success = save && li.save
      render :json => resp
    end
        
    # DELETE /admin/orders/:order_id/line-items/:id
    def admin_delete
      return if !user_is_allowed('orders', 'delete')
      li = LineItem.find(params[:id])
      order = li.order
      li.destroy
      order.calculate_total
      order.save                  
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/orders'
      })
    end
    
    # GET /admin/orders/:order_id/line-items/:id/highlight
    def admin_highlight
      return if !user_is_allowed('orders', 'view')
      li = LineItem.find(params[:id])
      v = li.variant
      redirect_to "/admin/products/#{v.product_id}/variants?highlight=#{v.id}"
    end
    
    # GET /admin/orders/line-items/status-options
    def admin_status_options
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
    
    # GET /admin/line-items/product-stubs
    def admin_product_stubs      
      title = params[:title].strip.downcase.split(' ')
      render :json => [] and return if title.length == 0      
      where = []
      query = [""]
      title.each do |str|
        where << 'lower(title) like ?'
        query << "%#{str}%"
      end
      where = where.join(' and ')
      query[0] = "select id, title from store_products where #{where} order by title limit 20"          
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      arr = rows.collect{ |row| { :id => row[0], :title => row[1] }}
      render :json => arr
    end
        
  end
end
