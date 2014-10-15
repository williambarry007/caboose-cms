module Caboose
  class OrdersMailer < ActionMailer::Base
    default :from => Caboose::from_address.nil? ? 'caboose-store.actionmailer@gmail.com' : Caboose::from_address
    
    # Sends a confirmation email to the customer about a new order 
    def customer_new_order(order)
      @order = order
      mail(:to => order.customer.email, :subject => 'Thank you for your order!')
    end
    
    # Sends a notification email to the fulfillment dept about a new order 
    def fulfillment_new_order(order)
      @order = order
      mail(:to => Caboose::fulfillment_email, :subject => 'New Order')
    end
    
    # Sends a notification email to the shipping dept that an order is ready to be shipped
    def shipping_order_ready(order)
      @order = order
      mail(:to => Caboose::shipping_email, :subject => 'Order ready for shipping')
    end
    
    # Sends a notification email to the customer that the status of the order has been changed
    def customer_status_updated(order)
      @order = order
      mail(:to => order.customer.email, :subject => 'Order status update')
    end
  end
end

