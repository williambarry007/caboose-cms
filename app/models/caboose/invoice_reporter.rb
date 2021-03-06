module Caboose
  class InvoiceReporter
            
    def InvoiceReporter.summary_report(site_id, d1, d2)
      q = ["select 
          concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized)),
          count(*),          
          sum(subtotal),
          sum(tax),
          sum(shipping),
          sum(handling),
          sum(discount),          
          sum(total),
          sum(cost),
          sum(profit)
        from store_invoices
        where site_id = ?
        and (financial_status = ? or financial_status = ?)
        and date_authorized >= ?
        and date_authorized < ?
        group by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))
        order by concat(date_part('year', date_authorized), '-', date_part('month', date_authorized), '-', date_part('day', date_authorized))",
        site_id, 'authorized', 'captured', d1, d2]
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
      
      days = []
      rows.each do |row|
        arr = row[0].split('-')
        days << Caboose::StdClass.new(
          :date     => Date.new(arr[0].to_i, arr[1].to_i, arr[2].to_i), 
          :count    => row[1].to_i,
          :subtotal => row[2].to_f,
          :tax      => row[3].to_f,
          :shipping => row[4].to_f,
          :handling => row[5].to_f,
          :discount => row[6].to_f,
          :total    => row[7].to_f,
          :cost     => row[8].to_f,
          :profit   => row[9].to_f
        )
      end      
      days.sort_by!{ |h| h.date }
            
      last_day = d1 - 1.day
      days2 = []
      days.each do |h|
        while (h.date - last_day) > 1          
          days2 << Caboose::StdClass.new(
            :date     => last_day + 1.day, 
            :count    => 0,
            :subtotal => 0.0,
            :tax      => 0.0,
            :shipping => 0.0,
            :handling => 0.0,
            :discount => 0.0,
            :total    => 0.0,
            :cost     => 0.0,
            :profit   => 0.0
          )
          last_day = last_day + 1.day
        end
        days2 << h
        last_day = h.date        
      end
      #days2.each do |h|
      #  puts "#{h.date} #{h.count} #{h.total}"
      #end
      return days2            
    end
    
    def InvoiceReporter.city_report(site_id, d1, d2)
      q = ["select 
        count(*),
        sum(O.subtotal),
        sum(O.tax),
        sum(O.shipping),
        sum(O.handling),
        sum(O.discount),          
        sum(O.total),
        SA.city,
        SA.state
        from store_invoices O
        left join store_addresses SA on O.shipping_address_id = SA.id
        where O.site_id = ?
        and (O.financial_status = ? or O.financial_status = ?)
        and O.date_authorized >= ?
        and O.date_authorized < ?
        group by concat(SA.city, ', ', SA.state), SA.state, SA.city
        order by SA.state, SA.city",
        site_id, 'authorized', 'captured', d1, d2]
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
      
      arr = []
      rows.each do |row|        
        arr << Caboose::StdClass.new(           
          :count    => row[0].to_i,
          :subtotal => row[1].to_f,
          :tax      => row[2].to_f,
          :shipping => row[3].to_f,
          :handling => row[4].to_f,
          :discount => row[5].to_f,
          :total    => row[6].to_f,
          :city     => row[7],
          :state    => row[8]
        )
      end
            
      return arr            
    end
    
  end
end