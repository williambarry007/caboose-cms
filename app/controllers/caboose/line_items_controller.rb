module Caboose
  class LineItemsController < Caboose::ApplicationController
    
    # @route GET /admin/invoices/:id/line-items/json
    # @route GET /admin/invoices/:id/packages/json
    def admin_json
      return if !user_is_allowed('invoices', 'edit')    
      invoice = Invoice.find(params[:id])
      render :json => invoice.line_items.as_json(:include => :invoice_package)
    end
    
    # @route GET /admin/invoices/:invoice_id/line-items/new
    def admin_new
      return if !user_is_allowed('invoices', 'edit')      
      render :layout => 'caboose/modal'            
    end
    
    # @route POST /admin/invoices/:invoice_id/line-items
    def admin_add
      return if !user_is_allowed('invoices', 'edit')      
      
      resp = StdClass.new
      v = Variant.find(params[:variant_id])
      li = LineItem.new(
        :invoice_id   => params[:invoice_id],
        :variant_id => params[:variant_id],
        :quantity   => 1,
        :unit_price => v.price,
        :subtotal   => v.price,
        :status     => 'pending'                
      )         
      resp.success = li.save
      render :json => resp
    end
      
    # @route PUT /admin/invoices/:invoice_id/line-items/:id
    def admin_update
      return if !user_is_allowed('invoices', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      li = LineItem.find(params[:id])    
      
      save = true
      send_status_email = false
      params.each do |name,value|        
        case name
          when 'invoice_id'         then li.invoice_id          = value
          when 'invoice_package_id' then li.invoice_package_id  = value
          when 'variant_id'       then li.variant_id        = value
          when 'parent_id'        then li.parent_id         = value          
          #when 'unit_price'       then li.unit_price        = value
          #when 'subtotal'         then li.subtotal          = value
          when 'notes'            then li.notes             = value
          when 'custom1'          then li.custom1           = value
          when 'custom2'          then li.custom2           = value
          when 'custom3'          then li.custom3           = value
          when 'quantity'
            li.quantity = value
            li.subtotal = li.unit_price * li.quantity
            
            li.save
            
            
            li.invoice.subtotal = li.invoice.calculate_subtotal
            li.invoice.total = li.invoice.calculate_total
            
            # Recalculate everything
            #r = ShippingCalculator.rate(li.invoice, li.invoice.shipping_method_code)
            #li.invoice.shipping = r['negotiated_rate'] / 100
            #li.invoice.handling = (r['negotiated_rate'] / 100) * 0.05
            #li.invoice.tax = TaxCalculator.tax(li.invoice)            
            #li.invoice.calculate_total
            #li.invoice.save
            
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
        InvoicesMailer.configure_for_site(@site.id).customer_status_updated(li.invoice).deliver
      end    
      resp.success = save && li.save
      render :json => resp
    end
        
    # @route DELETE /admin/invoices/:invoice_id/line-items/:id
    def admin_delete
      return if !user_is_allowed('invoices', 'delete')
      li = LineItem.find(params[:id])
      invoice = li.invoice
      li.destroy
      invoice.calculate_total
      invoice.save                  
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/invoices'
      })
    end
    
    # @route GET /admin/invoices/:invoice_id/line-items/:id/highlight
    def admin_highlight
      return if !user_is_allowed('invoices', 'view')
      li = LineItem.find(params[:id])
      v = li.variant
      redirect_to "/admin/products/#{v.product_id}/variants?highlight=#{v.id}"
    end
    
    # @route GET /admin/invoices/line-items/status-options
    def admin_status_options
      arr = ['pending', 'ready to ship', 'shipped', 'backinvoiceed', 'canceled']
      options = []
      arr.each do |status|
        options << {
          :value => status,
          :text  => status
        }
      end
      render :json => options
    end
    
    # @route GET /admin/invoices/line-items/product-stubs
    def admin_product_stubs      
      title = params[:title].strip.downcase.split(' ')
      render :json => [] and return if title.length == 0
      
      where = ["site_id = ?"]      
      vars = [@site.id]
      title.each do |str|
        where << 'lower(title) like ?'
        vars << "%#{str}%"
      end      
      where = where.join(' and ')
      query = ["select id, title, option1, option2, option3 from store_products where #{where} invoice by title limit 20"]
      vars.each{ |v| query << v }
      
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      arr = rows.collect do |row|
        has_options = row[2] || row[3] || row[4] ? true : false
        variant_id = nil
        if !has_options
          v = Variant.where(:product_id => row[0].to_i, :status => 'Active').first
          variant_id = v.id if v
        end          
        { :id => row[0], :title => row[1], :variant_id => variant_id }
      end        
      render :json => arr
    end
        
  end
end
