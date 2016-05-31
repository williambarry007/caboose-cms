#
# Invoice
#

module Caboose        
  class Invoice < ActiveRecord::Base
    self.table_name  = 'store_invoices'
    self.primary_key = 'id'

    belongs_to :site    
    belongs_to :customer, :class_name => 'Caboose::User'
    belongs_to :shipping_address, :class_name => 'Caboose::Address'
    belongs_to :billing_address, :class_name => 'Caboose::Address'
    has_many :discounts    
    has_many :line_items, :order => :id
    has_many :invoice_packages, :class_name => 'Caboose::InvoicePackage'
    has_many :invoice_transactions
    
    attr_accessible :id,
      :site_id,
      :alternate_id,
      :invoice_number,      
      :subtotal,
      :tax,            
      :shipping,
      :handling,
      :gift_wrap,
      :custom_discount,
      :discount,      
      :total,
      :customer_id,      
      :shipping_address_id,
      :billing_address_id,
      :status,      
      :financial_status,
      :referring_site,
      :landing_page,
      :landing_page_ref,                        
      :auth_amount,
      :date_created,
      :notes
          
    STATUS_CART          = 'cart'
    STATUS_PENDING       = 'pending'    
    STATUS_CANCELED      = 'canceled'
    STATUS_READY_TO_SHIP = 'ready to ship'
    STATUS_SHIPPED       = 'shipped'    
    STATUS_TESTING       = 'testing'
    
    # New
    #STATUS_PENDING        = 'Pending'
    #STATUS_OVERDUE        = 'Overdue'
    #STATUS_UNDER_REVIEW   = 'Under Review'
    #STATUS_PAID           = 'Paid'
    #STATUS_PAID_BY_CHECK  = 'Paid By Check'
    #STATUS_CANCELED       = 'Canceled'
    #STATUS_WAIVED         = 'Waived'

    FINANCIAL_STATUS_PENDING    = 'pending'
    FINANCIAL_STATUS_AUTHORIZED = 'authorized'
    FINANCIAL_STATUS_CAPTURED   = 'captured'
    FINANCIAL_STATUS_REFUNDED   = 'refunded'
    FINANCIAL_STATUS_VOIDED     = 'voided'
    
    #
    # Scopes
    #    
    scope :cart       , where('status = ?', 'cart')
    scope :pending    , where('status = ?', 'pending')    
    scope :canceled   , where('status = ?', 'canceled')
    scope :shipped    , where('status = ?', 'shipped')
    scope :test       , where('status = ?', 'testing')
    
    scope :authorized , where('financial_status = ?', 'authorized')
    scope :captured   , where('financial_status = ?', 'captured')
    scope :refunded   , where('financial_status = ?', 'refunded')
    scope :voided     , where('financial_status = ?', 'voided')        
    
    #
    # Validations
    #
    
    validates :status, :inclusion => {
      :in      => ['cart', 'pending', 'canceled', 'ready to ship', 'shipped', 'testing'],
      :message => "%{value} is not a valid status. Must be either 'pending' or 'shipped'"
    }
    
    validates :financial_status, :inclusion => {
      :in      => ['pending', 'authorized', 'captured', 'refunded', 'voided'],
      :message => "%{value} is not a valid financial status. Must be 'authorized', 'captured', 'refunded' or 'voided'"
    }
    
    after_initialize :check_nil_fields
    
    def check_nil_fields
      self.subtotal        = 0.00 if self.subtotal.nil?       
      self.tax             = 0.00 if self.tax.nil?
      self.shipping        = 0.00 if self.shipping.nil?
      self.handling        = 0.00 if self.handling.nil?
      self.custom_discount = 0.00 if self.custom_discount.nil?
      self.discount        = 0.00 if self.discount.nil?
      self.total           = 0.00 if self.total.nil?
    end
           
    def decrement_quantities            
      self.line_items.each do |line_item|
        line_item.variant.update_attribute(:quantity_in_stock, line_item.variant.quantity_in_stock - line_item.quantity)
      end            
    end
    
    def increment_quantities            
      self.line_items.each do |line_item|
        line_item.variant.update_attribute(:quantity_in_stock, line_item.variant.quantity_in_stock - line_item.quantity)
      end            
    end
    
    def resend_confirmation
      InvoicesMailer.configure_for_site(self.site_id).customer_new_invoice(self).deliver
    end
    
    def test?
      self.status == 'testing'
    end
    
    def authorized?
      self.financial_status == 'authorized'
    end
    
    def capture
      PaymentProcessor.capture(self)
    end
    
    def refund
      PaymentProcessor.refund(self)
    end
    
    def void
      PaymentProcessor.void(self)
    end
    
    def calculate        
      self.update_column(:subtotal  , self.calculate_subtotal  )
      self.update_column(:tax       , self.calculate_tax       )
      self.update_column(:shipping  , self.calculate_shipping  )
      self.update_column(:handling  , self.calculate_handling  )
      self.update_column(:gift_wrap , self.calculate_gift_wrap )
      
      # Calculate the total without the discounts first       
      self.discounts.each{ |d| d.update_column(:amount, 0.0) } if self.discounts      
      self.update_column(:total     , self.calculate_total     )
      
      self.update_column(:discount  , self.calculate_discount  )
      self.update_column(:total     , self.calculate_total     )      
      self.update_column(:cost      , self.calculate_cost      )
      self.update_column(:profit    , self.calculate_profit    )              
    end
    
    def calculate_subtotal
      return 0.0 if self.line_items.empty?
      self.line_items.each{ |li| li.verify_unit_price } # Make sure the unit prices are populated        
      x = 0.0      
      self.line_items.each{ |li| x = x + (li.unit_price * li.quantity) } # Fixed issue with quantity 
      return x
    end
    
    def calculate_tax      
      return TaxCalculator.tax(self)
    end
    
    def calculate_shipping      
      return 0.0 if self.invoice_packages.nil? || self.invoice_packages.count == 0
      x = 0.0
      self.invoice_packages.all.each{ |op| x = x + op.total }
      return x
    end
    
    def calculate_handling
      return 0.0 if self.site.nil? || self.site.store_config.nil?      
      self.subtotal * self.site.store_config.handling_percentage.to_f
    end
    
    def calculate_gift_wrap      
      x = 0.0
      self.line_items.each do |li|
        next if !li.gift_wrap
        next if !li.variant.product.allow_gift_wrap
        x = x + li.variant.product.gift_wrap_price * li.quantity
      end
      return x
    end
    
    def calculate_discount              
      x = 0.0
      if self.discounts && self.discounts.count > 0                              
        self.discounts.each do |d|
          d.calculate_amount                    
          x = x + d.amount
        end
      end
      x = x + self.custom_discount if self.custom_discount
      return x
    end
    
    def calculate_total
      return (self.subtotal + self.tax + self.shipping + self.handling + self.gift_wrap) - self.discount
    end
    
    def calculate_cost      
      x = 0.0
      invalid_cost = false
      self.line_items.each do |li|
        invalid_cost = true if li.variant.nil? || li.variant.cost.nil?
        x = x + (li.variant.cost * li.quantity)
      end
      return 0.00 if invalid_cost
      return x            
    end
    
    def calculate_profit
      return 0.00 if self.cost.nil?
      return (self.total - (self.tax ? self.tax : 0.00) - (self.shipping ? self.shipping : 0.00) - (self.handling ? self.handling : 0.00) - (self.gift_wrap ? self.gift_wrap : 0.00)) - self.cost
    end
    
    def shipping_and_handling
      (self.shipping ? self.shipping : 0.0) + (self.handling ? self.handling : 0.0)      
    end
    
    def item_count
      count = 0
      self.line_items.each{ |li| count = count + li.quantity } if self.line_items
      return count
    end
    
    def take_gift_card_funds
      return if self.discounts.nil? || self.discounts.count == 0
      self.discounts.each do |d|        
        gc = d.gift_card
        gc.balance = gc.balance - d.amount
        gc.save
      end
    end
    
    def has_empty_shipping_methods?
      return true if self.invoice_packages.nil?
      return true if self.invoice_packages.count == 0
      self.invoice_packages.all.each do |op|
        return true if op.shipping_method_id.nil?
      end
      return false
    end
    
    def has_downloadable_items?
      self.line_items.each do |li|
        return true if li.variant.downloadable
      end
      return false
    end
    
    def has_shippable_items?
      self.line_items.each do |li|
        return true if !li.variant.downloadable
      end
      return false
    end
    
    def has_taxable_items?
      self.line_items.each do |li|
        return true if li.variant.taxable && li.variant.taxable == true
      end
      return false
    end        

    # Capture funds from a previously authorized transaction
    def capture_funds
      
      resp = StdClass.new      
      t = InvoiceTransaction.where(:invoice_id => self.id, :transaction_type => InvoiceTransaction::TYPE_AUTHORIZE, :success => true).first
            
      if self.financial_status == Invoice::FINANCIAL_STATUS_CAPTURED
        resp.error = "Funds for this invoice have already been captured."    
      elsif self.total > t.amount
        resp.error = "The invoice total exceeds the authorized amount."
      elsif t.nil?
        resp.error = "This invoice doesn't seem to be authorized."
      else
                        
        sc = self.site.store_config
        ot = Caboose::InvoiceTransaction.new(
          :invoice_id => self.id,
          :date_processed => DateTime.now.utc,
          :transaction_type => InvoiceTransaction::TYPE_CAPTURE,
          :amount => self.total
        )
        
        case sc.pp_name
          when 'authorize.net'
            transaction = AuthorizeNet::AIM::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)
            response = transaction.prior_auth_capture(t.transaction_id, self.total)
            
            ot.success        = response.response_code && response.response_code == '1'            
            ot.transaction_id = response.transaction_id
            ot.auth_code      = response.authorization_code
            ot.response_code  = response.response_code            
            ot.save
            
            if ot.success
              self.date_captured = DateTime.now.utc
              self.save              
            end
                                    
            self.update_attribute(:financial_status, Invoice::FINANCIAL_STATUS_CAPTURED)
            resp.success = 'Captured funds successfully'
                                    
          when 'stripe'
            # TODO: Implement capture funds for stripe
            
          when 'payscape'
            # TODO: Implement capture funds for payscape

        end
        
      end
      
      return resp
    end
        
    # Void an authorized invoice
    def void
            
      resp = StdClass.new
      t = InvoiceTransaction.where(:invoice_id => self.id, :transaction_type => InvoiceTransaction::TYPE_AUTHORIZE, :success => true).first
      
      if self.financial_status == Invoice::FINANCIAL_STATUS_CAPTURED
        resp.error = "This invoice has already been captured, you will need to refund instead"
      elsif t.nil?
        resp.error = "This invoice doesn't seem to be authorized."
      else
                
        sc = self.site.store_config
        ot = Caboose::InvoiceTransaction.new(
          :invoice_id => self.id,
          :date_processed => DateTime.now.utc,
          :transaction_type => InvoiceTransaction::TYPE_VOID,
          :amount => self.total
        )
        
        case sc.pp_name
          when 'authorize.net'            
            response = AuthorizeNet::SIM::Transaction.new(
              sc.authnet_api_login_id, 
              sc.authnet_api_transaction_key,                      
              self.total,
              :transaction_type => InvoiceTransaction::TYPE_VOID,
              :transaction_id => t.transaction_id,
              :test => sc.pp_testing
            )                    
            self.update_attributes(
              :financial_status => Invoice::FINANCIAL_STATUS_VOIDED,
              :status => Invoice::STATUS_CANCELED
            )
            self.save          
            # TODO: Add the variant quantities invoiceed back        
            resp.success = "Invoice voided successfully"
                        
            ot.success        = response.response_code && response.response_code == '1'            
            ot.transaction_id = response.transaction_id
            #ot.auth_code      = response.authorization_code
            ot.response_code  = response.response_code            
            ot.save
          
          when 'stripe'
            # TODO: Implement void invoice for strip
            
          when 'payscape'
            # TODO: Implement void invoice for payscape
            
        end
        
      end
      return resp      
    end        
      
    #def refund
    #      
    #  resp = StdClass.new
    #  t = InvoiceTransaction.where(:invoice_id => self.id, :transaction_type => InvoiceTransaction::TYPE_CAPTURE, :success => true).first
    #      
    #  if self.financial_status != Invoice::FINANCIAL_STATUS_CAPTURED
    #    resp.error = "This invoice hasn't been captured yet, you will need to void instead"
    #  else
    #    
    #    sc = self.site.store_config
    #    case sc.pp_name
    #      when 'authorize.net'
    #      
    #    if PaymentProcessor.refund(invoice)
    #      invoice.update_attributes(
    #        :financial_status => Invoice::FINANCIAL_STATUS_REFUNDED,
    #        :status => Invoice::STATUS_CANCELED
    #      )
    #      
    #      response.success = 'Invoice refunded successfully'
    #    else
    #      response.error = 'Error refunding invoice'
    #    end
    #    
    #    #if invoice.calculate_net < (invoice.amount_discounted || 0) || PaymentProcessor.refund(invoice)
    #    #  invoice.financial_status = 'refunded'
    #    #  invoice.status = 'refunded'
    #    #  invoice.save
    #    #  
    #    #  if invoice.discounts.any?
    #    #    discount = invoice.discounts.first
    #    #    amount_to_refund = invoice.calculate_net < invoice.amount_discounted ? invoice.calculate_net : invoice.amount_discounted
    #    #    discount.update_attribute(:amount_current, amount_to_refund + discount.amount_current)
    #    #  end
    #    #  
    #    #  response.success = "Invoice refunded successfully"
    #    #else
    #    #  response.error = "Error refunding invoice."
    #    #end
    #  end
    #
    #  render json: response
    #  
    #  # return if !user_is_allowed('invoices', 'edit')
    #  #     
    #  # response = Caboose::StdClass.new({
    #  #   'refresh' => nil,
    #  #   'error' => nil,
    #  #   'success' => nil
    #  # })
    #  #     
    #  # invoice = Invoice.find(params[:id])
    #  #     
    #  # if invoice.financial_status != 'captured'
    #  #   response.error = "This invoice hasn't been captured yet, you will need to void instead"
    #  # else
    #  #   if PaymentProcessor.refund(invoice)
    #  #     invoice.financial_status = 'refunded'
    #  #     invoice.status = 'refunded'
    #  #     invoice.save
    #  #     
    #  #     # Add the variant quantities invoiceed back
    #  #     invoice.cancel
    #  #     
    #  #     response.success = "Invoice refunded successfully"
    #  #   else
    #  #     response.error = "Error refunding invoice."
    #  #   end
    #  # end
    #  #     
    #  # render :json => response
    #end
    
    def send_payment_authorization_email
      InvoicesMailer.configure_for_site(self.site_id).customer_payment_authorization(self).deliver
    end
    
    def determine_statuses
      
      auth    = false
      capture = false
      void    = false
      refund  = false
      
      self.invoice_transactions.each do |it|
        auth    = true if it.transaction_type == InvoiceTransaction::TYPE_AUTHORIZE && it.success == true
        capture = true if it.transaction_type == InvoiceTransaction::TYPE_CAPTURE   && it.success == true
        void    = true if it.transaction_type == InvoiceTransaction::TYPE_VOID      && it.success == true
        refund  = true if it.transaction_type == InvoiceTransaction::TYPE_REFUND    && it.success == true
      end
      
      if    refund  then self.financial_status = Invoice::FINANCIAL_STATUS_REFUNDED
      elsif void    then self.financial_status = Invoice::FINANCIAL_STATUS_VOIDED
      elsif capture then self.financial_status = Invoice::FINANCIAL_STATUS_CAPTURED
      elsif auth    then self.financial_status = Invoice::FINANCIAL_STATUS_AUTHORIZED
      else               self.financial_status = Invoice::FINANCIAL_STATUS_PENDING
      end
    
      self.status = Invoice::STATUS_PENDING if self.status == Invoice::STATUS_CART && (refund || void || capture || auth) 
      
      self.save

    end
    
    def hide_prices_for_any_line_item?
      self.line_items.each do |li|
        return true if li.hide_prices
      end
      return false
    end  
    
    def amount_not_paid
      amount = self.vendor_transactions.where(:success => true).all.collect{ |vt| vt.amount }.sum
      return self.total - amount
    end
    
  end
end

