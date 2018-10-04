module Caboose
  class InvoicesMailer < ActionMailer::Base
    #default :from => 'lockerroombiz@gmail.com'
    
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
    
    # Sends a confirmation email to the customer about a new invoice 
    def customer_new_invoice(invoice)
      @invoice = invoice
      mail(:to => invoice.customer.email, :subject => 'Thank you for your order!')
    end
    
    # Sends a notification email to the fulfillment dept about a new invoice 
    def fulfillment_new_invoice(invoice)      
      @invoice = invoice
      sc = invoice.site.store_config
      mail(:to => sc.fulfillment_email, :subject => 'New Order')
    end
    
    # Sends a notification email to the shipping dept that an invoice is ready to be shipped
    def shipping_invoice_ready(invoice)      
      @invoice = invoice
      sc = invoice.site.store_config
      mail(:to => sc.shipping_email, :subject => 'Order ready for shipping')
    end
    
    # Sends a notification email to the customer that the status of the invoice has been changed
    def customer_status_updated(invoice)      
      @invoice = invoice
      mail(:to => invoice.customer.email, :subject => 'Order status update')
    end
    
    # Sends an email to the customer telling them they need to authorize payment on an invoice 
    def customer_payment_authorization(invoice)      
      @invoice = invoice
      mail(:to => invoice.customer.email, :subject => "Invoice #{@invoice.invoice_number} ready for payment")
    end
    
    # Sends an email to the customer telling them they need to authorize payment on an invoice 
    def customer_receipt(invoice)      
      @invoice = invoice
      mail(:to => invoice.customer.email, :subject => "Invoice #{@invoice.invoice_number} receipt")
    end
  end
end

