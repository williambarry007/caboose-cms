require 'prawn'

module Caboose
  class OrderPdf < Prawn::Document
    
    attr_accessor :order, :card_type, :card_number
    
    def to_pdf
      
      # Get the type of card and last four digits
      get_card_details
      
      #image open("https://dmwwflw4i3miv.cloudfront.net/logo.png"), :position => :center
      text " "
      customer_info
      text " "
      order_table
      render
    end
    
    def formatted_phone(str)
      return '' if str.nil?
      str = str.gsub(/[^0-9]/i, '')
      return "#{str[0]} (#{str[1..3]}) #{str[4..6]}-#{str[7..10]}" if str.length == 11
      return "(#{str[0..2]}) #{str[3..5]}-#{str[6..9]}"            if str.length == 10
      return "#{str[0..2]}-#{str[3..6]}"                           if str.length == 7
      return str
    end
    
    def get_card_details
            
      sc = self.order.site.store_config
      ot = self.order.order_transactions.where(:transaction_type => OrderTransaction::TYPE_AUTHORIZE, :success => true).first
      
      case sc.pp_name
        when 'authorize.net'
          
          t = AuthorizeNet::Reporting::Transaction.new(sc.pp_username, sc.pp_password)
          resp = t.get_transaction_details(ot.transaction_id)
          t2 = resp.transaction
          self.card_type = t2.payment_method.card_type
          self.card_number = t2.payment_method.card_number.gsub('X', '')
        
      end
            
    end
    
    def customer_info
      
      order_info = "Order ##{order.id}\n"
      order_info << "Status: #{order.status.capitalize}\n"
      order_info << "Received: #{order.date_created.strftime("%m/%d/%Y")}\n"
      if order.status == 'shipped' && order.date_shipped
        order_info << "Shipped: #{order.date_shipped.strftime("%m/%d/%Y")}"
      end
      
      c = order.customer
      billed_to = "#{c.first_name} #{c.last_name}\n#{c.email}\n#{self.formatted_phone(c.phone)}\n#{self.card_type} ending in #{self.card_number}"
      
      sa = order.shipping_address
      shipped_to = "#{sa.name}\n#{sa.address1}\n"
      shipped_to << "#{sa.address2}\n" if sa.address2.strip.length > 0
      shipped_to << "#{sa.city}, #{sa.state} #{sa.zip}"
  
      tbl = []
      tbl << [
        { :content => "Order Info" , :align => :center, :valign => :bottom, :width => 180 },
        { :content => "Billed To"  , :align => :center, :valign => :bottom, :width => 180 },
        { :content => "Shipped To" , :align => :center, :valign => :bottom, :width => 180 }
      ]    
      tbl << [
        { :content => order_info, :valign => :top, :height => 75 },
        { :content => billed_to , :valign => :top, :height => 75 },
        { :content => shipped_to, :valign => :top, :height => 75 }
      ]    
      table tbl
      
    end
    
    def order_table
      
      tbl = []
      tbl << [
        { :content => "Item"            , :align => :center, :valign => :bottom },
        { :content => "Tracking Number" , :align => :center, :valign => :bottom },
        { :content => "Unit Price"      , :align => :center, :valign => :bottom },
        { :content => "Quantity"        , :align => :center, :valign => :bottom },                
        { :content => "Subtotal"        , :align => :center, :valign => :bottom, :width => 60 }
      ]
      
      order.line_items.each do |li|
        tbl << [        
          "#{li.variant.product.title}\n#{li.variant.sku}\n#{li.variant.title}",
          { :content => li.tracking_number },
          { :content => sprintf("%.2f", li.variant.price) , :align => :right },
          { :content => "#{li.quantity}"                  , :align => :right },          
          { :content => sprintf("%.2f", li.subtotal)      , :align => :right }
        ]
      end            
      tbl << [{ :content => "Subtotal"                                      , :colspan => 4, :align => :right }, { :content => sprintf("%.2f", order.subtotal                        ) , :align => :right }]
      tbl << [{ :content => "Tax"                                           , :colspan => 4, :align => :right }, { :content => sprintf("%.2f", order.tax ? order.tax : 0.0           ) , :align => :right }]
      #tbl << [{ :content => "#{order.shipping_method} Shipping & Handling"  , :colspan => 4, :align => :right }, { :content => sprintf("%.2f", order.shipping_and_handling           ) , :align => :right }]    
      tbl << [{ :content => "Discount"                                      , :colspan => 4, :align => :right }, { :content => sprintf("%.2f", order.discount ? order.discount : 0.0 ) , :align => :right }]
      tbl << [{ :content => "Total"                                         , :colspan => 4, :align => :right }, { :content => sprintf("%.2f", order.total                           ) , :align => :right }]
      
      table tbl
    end
  end
end
