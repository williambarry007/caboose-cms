require 'prawn'
require 'prawn/table'

module Caboose
  class PendingInvoicesPdf < Prawn::Document
    
    attr_accessor :invoices, :card_type, :card_number, :print_card_details
    
    def to_pdf
      
      # Get the type of card and last four digits

      invoices.each_with_index do |o,index|
        get_card_details(o)
        font_size 9
        move_down 10
        invoice_info(o)
        move_down 15
        invoice_table(o)
        move_down 15
        customer_info(o)
        move_down 15
        payment_info(o)
        if index + 1 < invoices.count then start_new_page end
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
    
    def get_card_details(invoice)
      return if self.print_card_details && self.print_card_details == false
      
      if invoice.customer.card_brand
        self.card_type   = invoice.customer.card_brand
        self.card_number = invoice.customer.card_last4
        return
      end
      
      sc = invoice.site.store_config
      ot = invoice.invoice_transactions.where(:transaction_type => InvoiceTransaction::TYPE_AUTHORIZE, :success => true).first
      return if ot.nil?        
      case ot.payment_processor
        when StoreConfig::PAYMENT_PROCESSOR_AUTHNET
          t = AuthorizeNet::Reporting::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)
          resp = t.get_transaction_details(ot.transaction_id)
          t2 = resp.transaction
          if t2
            self.card_type = t2.payment_method.card_type.upcase
            self.card_number = t2.payment_method.card_number.gsub('X', '')
          end
        when StoreConfig::PAYMENT_PROCESSOR_STRIPE
          self.card_type   = invoice.customer.card_brand
          self.card_number = invoice.customer.card_last4
      end
    end

    def invoice_info(invoice)
      invoice_info = "Invoice Number: #{invoice.invoice_number}\n"
      invoice_info << "Invoice Date: #{invoice.date_created ? invoice.date_created.strftime('%d %b %Y %H:%M:%S %p') : ''}\n"
      invoice_info << "Status: #{invoice.status.capitalize}\n"
      tbl = []
      tbl << [
        { :content => invoice_info }
      ]
      move_down 4
      table tbl, :position => 7, :width => 530
    end

    
    def customer_info(invoice)
      c = invoice.customer
      ba = invoice.billing_address
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
              
      sa = invoice.shipping_address
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
    
    def invoice_table(invoice)
      
      hide_prices = invoice.hide_prices_for_any_line_item?
      
      tbl = []
      tbl << [
        { :content => "Package"    , :align => :left  , :valign => :bottom },
        { :content => "Product"    , :align => :left  , :valign => :bottom , :colspan => 2 },
        { :content => "Attributes" , :align => :left  , :valign => :bottom },
        { :content => "Quantity"   , :align => :right , :valign => :bottom }
      ]
      if !hide_prices
        tbl[0] << { :content => "Price"      , :align => :right , :valign => :bottom }
        tbl[0] << { :content => "Amount"     , :align => :right , :valign => :bottom }
      end
      
      #invoice.calculate
      
      invoice.invoice_packages.all.each do |pk|

        carrier = pk.shipping_method ? pk.shipping_method.carrier : nil
        service = pk.shipping_method ? pk.shipping_method.service_name : nil
        package = pl.shipping_package ? pk.shipping_package.name : nil

        pk.line_items.each_with_index do |li, index|
          options = ''
          if li.variant.product.option1 && li.variant.option1 then options += li.variant.product.option1 + ": " + li.variant.option1 + "\n" end
          if li.variant.product.option2 && li.variant.option2 then options += li.variant.product.option2 + ": " + li.variant.option2 + "\n" end
          if li.variant.product.option3 && li.variant.option3 then options += li.variant.product.option3 + ": " + li.variant.option3 + "\n" end
          if li.variant.product.product_images.count > 0 && li.variant.product.product_images.first.url(:tiny)
          #  Caboose.log("image path: #{li.variant.product.product_images.first.url(:tiny)}")
          #  image = ""
            url = li.variant.product.product_images.first.url(:tiny)
            url = "http:#{url}" if url.starts_with?('//')
            image = open(url)
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
          if !hide_prices
            arr << { :content => "$" + sprintf("%.2f", li.unit_price) , :align => :right }
            arr << { :content => "$" + sprintf("%.2f", li.subtotal)   , :align => :right }
          end

          tbl << arr
          
        end
      end

      unassigned = invoice.line_items.where("invoice_package_id IS NULL OR invoice_package_id = ?",-1)
      unassigned.each_with_index do |li, index|
        options = ''
        if li.variant.product.option1 && li.variant.option1 then options += li.variant.product.option1 + ": " + li.variant.option1 + "\n" end
        if li.variant.product.option2 && li.variant.option2 then options += li.variant.product.option2 + ": " + li.variant.option2 + "\n" end
        if li.variant.product.option3 && li.variant.option3 then options += li.variant.product.option3 + ": " + li.variant.option3 + "\n" end
        if li.variant.product.product_images.count > 0 && li.variant.product.product_images.first.url(:tiny)
       #   Caboose.log("image path: #{li.variant.product.product_images.first.url(:tiny)}")
       #   image = ""          
          url = li.variant.product.product_images.first.url(:tiny)          
          url = "http:#{url}" if url.starts_with?('//')
          image = open(url)
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
        if !hide_prices
          if li.unit_price
            arr << { :content => "$" + sprintf("%.2f", li.unit_price) , :align => :right }
          else
            arr << { :content => "" }
          end
          arr << { :content => "$" + sprintf("%.2f", li.subtotal)   , :align => :right }
        end
        tbl << arr
      end
      invoice.calculate
      if !hide_prices
        tbl << [{ :content => "Subtotal"                       , :colspan => 6, :align => :right                       }, { :content => "$"     + sprintf("%.2f", invoice.subtotal                        ) , :align => :right }]
        tbl << [{ :content => "Discount"                       , :colspan => 6, :align => :right                       }, { :content => "(-) $" + sprintf("%.2f", invoice.discount ? invoice.discount : 0.0 ) , :align => :right }]
        tbl << [{ :content => "Shipping and Handling Charges"  , :colspan => 6, :align => :right                       }, { :content => "(+) $" + sprintf("%.2f", invoice.shipping_and_handling           ) , :align => :right }]    
        tbl << [{ :content => "Sales Tax"                      , :colspan => 6, :align => :right                       }, { :content => "(+) $" + sprintf("%.2f", invoice.tax ? invoice.tax : 0.0           ) , :align => :right }]
        tbl << [{ :content => "Grand Total"                    , :colspan => 6, :align => :right, :font_style => :bold }, { :content => "$"     + sprintf("%.2f", invoice.total                           ) , :align => :right, :font_style => :bold }]
      end
      
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

    def payment_info(invoice)

      trans = invoice.invoice_transactions.where(:transaction_type => InvoiceTransaction::TYPE_AUTHORIZE, :success => true).first
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
