module Caboose
  class OrdersMailer < ActionMailer::Base
    default :from => 'lockerroombiz@gmail.com'
    
    #before_action :configure            
    #def configure(site_id)      
    #  settings = Caboose::SmtpConfig.where(:site_id => site_id).first            
    #  delivery_options = {
    #    :user_name            => settings.user_name, 
    #    :password             => settings.password,
    #    :address              => settings.address,
    #    :port                 => settings.port,
    #    :domain               => settings.domain,
    #    :authentication       => settings.authentication,
    #    :enable_starttls_auto => settings.enable_starttls_auto
    #  }
    #  default_options[:from] = delivery_options[:user_name]
    #  delivery_method.settings.merge!(delivery_options)
    #end
    
    def test_email            
      mail(:to => 'william@nine.is', :subject => "Test #{DateTime.now.strftime('%H:%M:%S')}")
    end
    
    # Sends a confirmation email to the customer about a new order 
    def customer_new_order(order)      
      @order = order
      mail(:to => order.customer.email, :subject => 'Thank you for your order!')
    end
    
    # Sends a notification email to the fulfillment dept about a new order 
    def fulfillment_new_order(order)      
      @order = order
      sc = order.site.store_config
      mail(:to => sc.fulfillment_email, :subject => 'New Order')
    end
    
    # Sends a notification email to the shipping dept that an order is ready to be shipped
    def shipping_order_ready(order)      
      @order = order
      sc = order.site.store_config
      mail(:to => sc.shipping_email, :subject => 'Order ready for shipping')
    end
    
    # Sends a notification email to the customer that the status of the order has been changed
    def customer_status_updated(order)      
      @order = order
      mail(:to => order.customer.email, :subject => 'Order status update')
    end
  end
end

