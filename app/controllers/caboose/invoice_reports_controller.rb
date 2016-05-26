module Caboose
  class InvoicesController < Caboose::ApplicationController
     
    # GET /admin/invoices/summary-report
    def admin_summary_report
      return if !user_is_allowed('invoices', 'view')
      
      q = ["select 
          concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized)),
          count(*), 
          sum(total)
        from store_invoices
        where site_id = ?
        and (financial_status = ? or financial_status = ?)
        and date_authorized >= ?
        and date_authorized < ?
        group by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))
        invoice by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))",
        @site.id, 'authorized', 'captured', @d1, @d2]
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
      return rows.collect { |row|
        {
          'user_id'          => row[0],
          'facility_id'      => row[1],
          'amount'           => row[2],
          'first_name'       => row[3],
          'last_name'        => row[4],
          'facility_name'    => row[5],
          'vendor_type_name' => row[6],
          'anniversary_date' => row[7]        
        }
      }
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'site_id'              => @site.id,
        'customer_id'          => '', 
        'status'               => Invoice::STATUS_PENDING,
        'shipping_method_code' => '',
        'id'                   => ''
      }, {
        'model'          => 'Caboose::Invoice',
        'sort'           => 'id',
        'desc'           => 1,
        'base_url'       => '/admin/invoices',
        'use_url_params' => false
      })
      
      @invoices  = @pager.items
      @customers = Caboose::User.reorder('last_name, first_name').all
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/invoices/new
    def admin_new
      return if !user_is_allowed('invoices', 'add')      
      render :layout => 'caboose/admin'
    end
    
  end
end
