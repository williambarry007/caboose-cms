module Caboose
  class InvoicePackagesController < Caboose::ApplicationController
    
    # @route GET /admin/invoices/:invoice_id/packages/json
    def admin_json      
      return if !user_is_allowed('invoices', 'view')
      invoice = Invoice.find(params[:invoice_id])
      render :json => invoice.invoice_packages.as_json(
        :include => { :shipping_package => { :include => :shipping_methods} }
      )
    end     

    # @route POST /admin/invoices/:invoice_id/packages
    def admin_add
      return if !user_is_allowed('invoices', 'add')
      
      resp = StdClass.new
                              
      if    params[:shipping_package_id].strip.length  == 0 then resp.error = "Please select a shipping package."
      elsif params[:shipping_method_id].strip.length   == 0 then resp.error = "Please select a shipping method."      
      else

        op = InvoicePackage.new(
          :invoice_id          => params[:invoice_id],
          :shipping_package_id => params[:shipping_package_id],
          :shipping_method_id  => params[:shipping_method_id],
          :status              => InvoicePackage::STATUS_PENDING          
        )        
        op.save        
        resp.new_id = op.id
        resp.redirect = "/admin/invoices/#{params[:invoice_id]}/packages/#{op.id}"
        
      end
      
      render :json => resp
    end
    
    # @route PUT /admin/invoices/:invoice_id/packages/:id
    def admin_update
      return if !user_is_allowed('invoices', 'edit')
      
      resp = Caboose::StdClass.new
      op = InvoicePackage.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'invoice_id'          then op.invoice_id              = value
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
      op.invoice.shipping = op.invoice.calculate_shipping
      op.invoice.total = op.invoice.calculate_total
      op.invoice.save
      
      resp.success = true
      render :json => resp
    end
    
    # @route PUT /admin/invoices/:invoice_id/line-items/:id
    def admin_update_line_item
      return if !user_is_allowed('invoices', 'edit')
      
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
            r = ShippingCalculator.rate(li.invoice, li.invoice.shipping_method_code)
            li.invoice.shipping = r['negotiated_rate'] / 100
            li.invoice.handling = (r['negotiated_rate'] / 100) * 0.05
            li.invoice.tax = TaxCalculator.tax(li.invoice)            
            li.invoice.calculate_total
            li.invoice.save
            
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
    
    # @route DELETE /admin/invoices/:invoice_id/packages/:id
    def admin_delete
      return if !user_is_allowed('invoices', 'delete')
      resp = StdClass.new
      op = InvoicePackage.find(params[:id])
      if op.line_items.nil? || op.line_items.count == 0
        op.destroy
        resp.redirect = "/admin/invoices/#{params[:invoice_id]}"
      else
        resp.error = "Only empty packages can be deleted."
      end
      render :json => resp
    end
    
    # @route GET /admin/invoices/:invoice_id/packages/:id/calculate-shipping
    def calculate_shipping
      return if !user_is_allowed('invoices', 'edit')

      op = InvoicePackage.find(params[:id])
      invoice = op.invoice
      
      render :json => { :error => "Empty invoice" } and return if invoice.nil?
      render :json => { :error => "No shippable items in invoice package" } and return if !invoice.has_shippable_items?
      render :json => { :error => "Empty shipping address" } and return if invoice.shipping_address.nil?

      rate = ShippingCalculator.calculate_rate(op)
      render :json => { :error => "No rate found for given shipping package and method" } and return if rate.nil?

      op.total = rate
      op.save
      
      invoice.calculate_shipping
      invoice.calculate_total
      invoice.save
      
      render :json => { :error => "No rate found for shipping method" } and return if rate.nil?                   
      render :json => { :success => true, :rate => rate }            
    end
    
    # @route GET /admin/invoices/:invoice_id/packages/:id/shipping-rates
    def shipping_rates
      return if !user_is_allowed('invoices', 'edit')

      op = InvoicePackage.find(params[:id])
      invoice = op.invoice
      
      render :json => { :error => "Empty invoice" } and return if invoice.nil?
      render :json => { :error => "No shippable items in invoice package" } and return if !invoice.has_shippable_items?
      render :json => { :error => "Empty shipping address" } and return if invoice.shipping_address.nil?
                                                        
      rates = ShippingCalculator.invoice_package_rates(op)      
      render :json => rates            
    end
            
  end
end
