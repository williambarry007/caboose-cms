require 'prawn'

module Caboose
  class PendingOrdersPdf < Prawn::Document
    
    attr_accessor :orders, :card_type, :card_number
    
    def to_pdf
      
      # Get the type of card and last four digits

      orders.each_with_index do |o,index|
        get_card_details(o)
        font_size 9
        move_down 10
        order_info(o)
        move_down 15
        order_table(o)
        move_down 15
        customer_info(o)
        move_down 15
        payment_info(o)
        if index + 1 < orders.count then start_new_page end
      end
      
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
    
    def get_card_details(order)      
      sc = order.site.store_config
      ot = order.order_transactions.where(:transaction_type => OrderTransaction::TYPE_AUTHORIZE, :success => true).first
      return if ot.nil?        
      case sc.pp_name
        when 'authorize.net'
          t = AuthorizeNet::Reporting::Transaction.new(sc.pp_username, sc.pp_password)
          resp = t.get_transaction_details(ot.transaction_id)
          t2 = resp.transaction
          if t2
            self.card_type = t2.payment_method.card_type.upcase
            self.card_number = t2.payment_method.card_number.gsub('X', '')
          end
      end
    end

    def order_info(order)
      order_info = "Order Number: #{order.id}\n"
      order_info << "Order Date: #{order.date_created ? order.date_created.strftime('%d %b %Y %H:%M:%S %p') : ''}\n"
      order_info << "Status: #{order.status.capitalize}\n"
      tbl = []
      tbl << [
        { :content => order_info }
      ]
      move_down 4
      table tbl, :position => 7, :width => 530
    end

    
    def customer_info(order)
      c = order.customer
      ba = order.billing_address
      billed_to = []
      if ba
        ba_address = "#{ba.address1}" + (ba.address2.blank? ? '' : "\n#{ba.address2}") + "\n#{ba.city}, #{ba.state} #{ba.zip}"
        billed_to << [{ :content => "Name"    , :border_width => 0, :width => 55 },{ :content => "#{ba.first_name} #{ba.last_name}" , :border_width => 0, :width => 200 }]
        billed_to << [{ :content => "Address" , :border_width => 0, :width => 55 },{ :content => ba_address                         , :border_width => 0, :width => 200 }]
        billed_to << [{ :content => "Email"   , :border_width => 0, :width => 55 },{ :content => "#{c.email}"                       , :border_width => 0, :width => 200 }]
        billed_to << [{ :content => "Phone"   , :border_width => 0, :width => 55 },{ :content => "#{self.formatted_phone(c.phone)}" , :border_width => 0, :width => 200 }]
      else
        billed_to << [{ :content => "Name"    , :border_width => 0 }]
        billed_to << [{ :content => "Address" , :border_width => 0 }]
        billed_to << [{ :content => "Email"   , :border_width => 0 }]
        billed_to << [{ :content => "Phone"   , :border_width => 0 }]
      end
              
      sa = order.shipping_address
      shipped_to = []
      if sa
        sa_address = "#{sa.address1}" + (sa.address2.blank? ? '' : "\n#{sa.address2}") + "\n#{sa.city}, #{sa.state} #{sa.zip}"
        shipped_to << [{ :content => "Name"    , :border_width => 0, :width => 55 },{ :content => "#{sa.first_name} #{sa.last_name}" , :border_width => 0, :width => 200 }]
        shipped_to << [{ :content => "Address" , :border_width => 0, :width => 55 },{ :content => sa_address                         , :border_width => 0, :width => 200 }]
        shipped_to << [{ :content => "Email"   , :border_width => 0, :width => 55 },{ :content => "#{c.email}"                       , :border_width => 0, :width => 200 }]
        shipped_to << [{ :content => "Phone"   , :border_width => 0, :width => 55 },{ :content => "#{self.formatted_phone(c.phone)}" , :border_width => 0, :width => 200 }]
      else
        shipped_to << [{ :content => "Name"    , :border_width => 0 }]
        shipped_to << [{ :content => "Address" , :border_width => 0 }]
        shipped_to << [{ :content => "Email"   , :border_width => 0 }]
        shipped_to << [{ :content => "Phone"   , :border_width => 0 }]
      end

      tbl = []
      tbl << [
        { :content => "Shipping Information" , :align => :left, :width => 255, :font_style => :bold },
        { :content => "Billing Information"  , :align => :left, :width => 255, :font_style => :bold }
      ]    
      tbl << [
        { :content => shipped_to },
        { :content => billed_to  }
      ]
      move_down 4
      table tbl, :position => 7, :width => 530
      
    end
    
    def order_table(order)
      
      tbl = []
      tbl << [
        { :content => "Package"    , :align => :left  , :valign => :bottom },
        { :content => "Product"    , :align => :left  , :valign => :bottom , :colspan => 2 },
        { :content => "Attributes" , :align => :left  , :valign => :bottom },
        { :content => "Quantity"   , :align => :right , :valign => :bottom },        
        { :content => "Price"      , :align => :right , :valign => :bottom },
        { :content => "Amount"     , :align => :right , :valign => :bottom }
      ]

      #order.calculate
      
      order.order_packages.all.each do |pk|

        carrier = pk.shipping_method.carrier
        service = pk.shipping_method.service_name
        package = pk.shipping_package.name

        pk.line_items.each_with_index do |li, index|
          options = ''
          if li.variant.product.option1 && li.variant.option1 then options += li.variant.product.option1 + ": " + li.variant.option1 + "\n" end
          if li.variant.product.option2 && li.variant.option2 then options += li.variant.product.option2 + ": " + li.variant.option2 + "\n" end
          if li.variant.product.option3 && li.variant.option3 then options += li.variant.product.option3 + ": " + li.variant.option3 + "\n" end
          if li.variant.product.product_images.count > 0 && li.variant.product.product_images.first.url(:tiny)
          #  Caboose.log("image path: #{li.variant.product.product_images.first.url(:tiny)}")
          #  image = ""
            image = open("#{li.variant.product.product_images.first.url(:tiny)}")
          else
            image = ""
          end
          arr = []
          if index == 0
            arr << { :content => package + "\n" + carrier + "\n" + service, :width => 115, :rowspan => (index == 0 ? pk.line_items.count : 1) }
          end
         
          if !image.blank?
            arr << { :image => image, :fit => [40, 40], :borders => [:top, :bottom, :left], :width => 50 }
          else
            arr << { :content => "No Image" }
          end          
          arr << { :content => "#{li.variant.product.title}\n#{li.variant.sku}\n#{self.gift_options(li)}", :borders => [:top, :right, :bottom], :width => 100 }
          arr << { :content => options }
          arr << { :content => "#{li.quantity}"                     , :align => :right }
          arr << { :content => "$" + sprintf("%.2f", li.unit_price) , :align => :right }
          arr << { :content => "$" + sprintf("%.2f", li.subtotal)   , :align => :right }

          tbl << arr
          
        end
      end

      unassigned = order.line_items.where("order_package_id IS NULL OR order_package_id = ?",-1)
      unassigned.each_with_index do |li, index|
        options = ''
        if li.variant.product.option1 && li.variant.option1 then options += li.variant.product.option1 + ": " + li.variant.option1 + "\n" end
        if li.variant.product.option2 && li.variant.option2 then options += li.variant.product.option2 + ": " + li.variant.option2 + "\n" end
        if li.variant.product.option3 && li.variant.option3 then options += li.variant.product.option3 + ": " + li.variant.option3 + "\n" end
        if li.variant.product.product_images.count > 0 && li.variant.product.product_images.first.url(:tiny)
       #   Caboose.log("image path: #{li.variant.product.product_images.first.url(:tiny)}")
       #   image = ""
          image = open("#{li.variant.product.product_images.first.url(:tiny)}")
        else
          image = ""
        end
        arr = []
        if index == 0
          arr << { :content => "Unassigned", :width => 115, :rowspan => (index == 0 ? unassigned.count : 1) }
        end
        if !image.blank?
          arr << { :image => image, :fit => [40, 40], :borders => [:top, :bottom, :left], :width => 50 }
        else
          arr << { :content => "No Image" }
        end        
        arr << { :content => "#{li.variant.product.title}\n#{li.variant.sku}\n#{self.gift_options(li)}", :borders => [:top, :right, :bottom], :width => 100 }
        arr << { :content => options }
        arr << { :content => "#{li.quantity}"               , :align => :right }
        if li.unit_price
          arr << { :content => "$" + sprintf("%.2f", li.unit_price) , :align => :right }
        else
          arr << { :content => "" }
        end
        arr << { :content => "$" + sprintf("%.2f", li.subtotal)   , :align => :right }
        tbl << arr
      end
      order.calculate
      tbl << [{ :content => "Subtotal"                       , :colspan => 6, :align => :right                       }, { :content => "$"     + sprintf("%.2f", order.subtotal                        ) , :align => :right }]
      tbl << [{ :content => "Discount"                       , :colspan => 6, :align => :right                       }, { :content => "(-) $" + sprintf("%.2f", order.discount ? order.discount : 0.0 ) , :align => :right }]
      tbl << [{ :content => "Shipping and Handling Charges"  , :colspan => 6, :align => :right                       }, { :content => "(+) $" + sprintf("%.2f", order.shipping_and_handling           ) , :align => :right }]    
      tbl << [{ :content => "Sales Tax"                      , :colspan => 6, :align => :right                       }, { :content => "(+) $" + sprintf("%.2f", order.tax ? order.tax : 0.0           ) , :align => :right }]
      tbl << [{ :content => "Grand Total"                    , :colspan => 6, :align => :right, :font_style => :bold }, { :content => "$"     + sprintf("%.2f", order.total                           ) , :align => :right, :font_style => :bold }]
      
      table tbl , :position => 7, :width => 530
    end
    
    def gift_options(li)          
      return "This item is not a gift." if !li.is_gift                  
      str = "This item is a gift.\n"
      str << "- Gift wrap: #{li.gift_wrap ? 'Yes' : 'No'}\n"
      str << "- Hide prices: #{li.hide_prices ? 'Yes' : 'No'}\n"
      str << "- Gift message:\n #{li.gift_message && li.gift_message.length > 0 ? li.gift_message : '[Empty]'}"
      return str        
    end

    def payment_info(order)

      trans = order.order_transactions.where(:transaction_type => OrderTransaction::TYPE_AUTHORIZE, :success => true).first
      tbl = []
      tbl2 = []
      tbl3 = []

      if trans
        tbl2 << [
          { :content => "Card Type", :width => 127, :border_width => 0 },
          { :content => self.card_type.blank? ? "N/A" : self.card_type, :width => 128, :border_width => 0 }
        ]
        tbl2 << [
          { :content => "Transaction ID", :width => 127, :border_width => 0 },
          { :content => trans.transaction_id.to_s, :width => 128, :border_width => 0 }
        ]
        tbl2 << [
          { :content => "Gateway Response", :width => 127, :border_width => 0},
          { :content => trans.response_code.to_s, :width => 128, :border_width => 0  }
        ]
        tbl3 << [
          { :content => "Card Number", :width => 127, :border_width => 0},
          { :content => self.card_number ? ("XXXX XXXX XXXX " + self.card_number) : "N/A", :width => 128, :border_width => 0 }
        ]
        tbl3 << [
          { :content => "Transaction Time", :width => 127, :border_width => 0},
          { :content => trans.date_processed.strftime("%d %b %Y %H:%M:%S %p"), :width => 128, :border_width => 0  }
        ]
        tbl3 << [
          { :content => "Payment Process", :width => 127, :border_width => 0},
          { :content => trans.success ? "Successful" : "Failed", :width => 128, :border_width => 0  }
        ]
      else
        tbl2 << [{ :content => "Card Type"        , :width => 127, :border_width => 0}]          
        tbl2 << [{ :content => "Transaction ID"   , :width => 127, :border_width => 0}]          
        tbl2 << [{ :content => "Gateway Response" , :width => 127, :border_width => 0}]          
        tbl3 << [{ :content => "Card Number"      , :width => 127, :border_width => 0}]          
        tbl3 << [{ :content => "Transaction Time" , :width => 127, :border_width => 0}]          
        tbl3 << [{ :content => "Payment Process"  , :width => 127, :border_width => 0}]                  
      end
      
      tbl << [
        { :content => "Authorization Details", :colspan => 2, :font_style => :bold }
      ]
      tbl << [
        { :content => tbl2, :width => 255 },
        { :content => tbl3, :width => 255 }
      ]

      table tbl, :position => 7, :width => 530

    end

  end
end
