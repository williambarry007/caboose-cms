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
      li = LineItem.create(
        :invoice_id => params[:invoice_id],
        :variant_id => params[:variant_id],
        :quantity   => 1,
        :unit_price => v.price,
        :subtotal   => v.price,
        :status     => LineItem::STATUS_PENDING                
      )
      resp.success = true
      resp.new_id = li.id
            
      InvoiceLog.create(
        :invoice_id     => params[:invoice_id],
        :line_item_id   => li.id,
        :user_id        => logged_in_user.id,
        :date_logged    => DateTime.now.utc,
        :invoice_action => InvoiceLog::ACTION_LINE_ITEM_CREATED                                                                          
      )      
      render :json => resp
    end
      
    # @route PUT /admin/invoices/:invoice_id/line-items/:id
    def admin_update
      return if !user_is_allowed('invoices', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      li = LineItem.find(params[:id])    
      
      save = true
      send_status_email = false
      fields_to_log = ['invoice_id','invoice_package_id','variant_id','parent_id','notes','custom1','custom2','custom3','unit_price','quantity','tracking_number','status']
      params.each do |name,value|
        if fields_to_log.include?(name)                
          InvoiceLog.create(
            :invoice_id     => params[:invoice_id],
            :line_item_id   => li.id,
            :user_id        => logged_in_user.id,
            :date_logged    => DateTime.now.utc,
            :invoice_action => InvoiceLog::ACTION_LINE_ITEM_UPDATED,
            :field          => name,
            :old_value      => li[name.to_sym],
            :new_value      => value
          )
        end                
        case name
          when 'invoice_id'         then li.invoice_id          = value
          when 'invoice_package_id' then li.invoice_package_id  = value
          when 'variant_id'         then li.variant_id          = value
          when 'parent_id'          then li.parent_id           = value                    
          #when 'subtotal'          then li.subtotal            = value
          when 'notes'              then li.notes               = value
          when 'custom1'            then li.custom1             = value
          when 'custom2'            then li.custom2             = value
          when 'custom3'            then li.custom3             = value
          when 'unit_price'            
            li.unit_price = value
            li.save            
            li.subtotal = li.unit_price * li.quantity
            li.save
            li.invoice.subtotal = li.invoice.calculate_subtotal
            li.invoice.total = li.invoice.calculate_total
            
          when 'quantity'
            li.quantity = value
            li.subtotal = li.unit_price * li.quantity            
            li.save                        
            li.invoice.subtotal = li.invoice.calculate_subtotal
            li.invoice.total = li.invoice.calculate_total
            
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
      li.destroy
      
      invoice = Invoice.find(params[:invoice_id])
      invoice.subtotal = invoice.calculate_subtotal      
      invoice.total    = invoice.calculate_total
      invoice.save
      
      InvoiceLog.create(
        :invoice_id     => params[:invoice_id],
        :line_item_id   => params[:id],
        :user_id        => logged_in_user.id,
        :date_logged    => DateTime.now.utc,
        :invoice_action => InvoiceLog::ACTION_LINE_ITEM_DELETED                                                                          
      )
      
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
      options = [
        { :value => LineItem::STATUS_PENDING       , :text => 'Pending'       },        
        { :value => LineItem::STATUS_BACKORDERED   , :text => 'Backordered'   },
        { :value => LineItem::STATUS_CANCELED      , :text => 'Canceled'      },
        { :value => LineItem::STATUS_PROCESSED     , :text => 'Processed'     }
      ]          
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
      query = ["select id, title, option1, option2, option3 from store_products where #{where} order by title limit 20"]
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
