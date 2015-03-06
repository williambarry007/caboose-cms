require 'prawn'

module Caboose
  class PendingOrdersPdf < Prawn::Document
    
    attr_accessor :orders
    attr_accessor :order
    
    def to_pdf
      #image open("https://dmwwflw4i3miv.cloudfront.net/logo.png"), :position => :center
      text " "
      self.orders.each_with_index do |o, i|
        start_new_page if i > 0
        self.order = o        
        customer_info
        text " "
        order_table
      end      
      render
    end
    
    def customer_info
      
      order_info = "Order ##{self.order.id}\n"
      order_info << "Status: #{self.order.status.capitalize}\n"
      order_info << "Received: #{self.order.date_created ? self.order.date_created.strftime("%m/%d/%Y") : ''}\n"
      if order.status == 'shipped' && self.order.date_shipped
        order_info << "Shipped: #{self.order.date_shipped.strftime("%m/%d/%Y")}"
      end
      
      c = self.order.customer
      billed_to = c ? "#{c.first_name} #{c.last_name}\n#{c.email}\n#{c.phone}" : ''
      
      sa = self.order.shipping_address
      shipped_to = "#{sa.name}\n#{sa.address1}\n"
      shipped_to << "#{sa.address2}\n" if sa.address2 && sa.address2.strip.length > 0
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
          { :content => sprintf("%.2f", li.unit_price) , :align => :right },
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
