module Caboose
  class OrdersController < Caboose::ApplicationController
     
    # GET /admin/orders/summary-report
    def admin_summary_report
      return if !user_is_allowed('orders', 'view')
      
      q = ["select 
          concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized)),
          count(*), 
          sum(total)
        from store_orders
        where site_id = ?
        and (financial_status = ? or financial_status = ?)
        and date_authorized >= ?
        and date_authorized < ?
        group by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))
        order by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))",
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
    
    
    
  end
end
