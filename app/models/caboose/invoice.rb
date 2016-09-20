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
      :site_id               ,
      :invoice_number        ,
      :alternate_id          ,
      :subtotal              ,
      :tax                   ,
      :tax_rate              ,
      :shipping              ,
      :handling              ,
      :gift_wrap             ,
      :custom_discount       ,
      :discount              ,
      :total                 ,
      :cost                  ,
      :profit                ,
      :customer_id           ,
      :financial_status      ,
      :shipping_address_id   ,
      :billing_address_id    ,
      :notes                 ,
      :status                ,
      :payment_terms         ,
      :date_created          ,
      :date_authorized       ,
      :date_captured         ,
      :date_shipped          ,
      :date_due              ,
      :referring_site        ,
      :landing_page          ,
      :landing_page_ref      ,
      :auth_amount           ,
      :gift_message          ,
      :include_receipt               
          
    STATUS_CART          = 'cart'
    STATUS_PENDING       = 'pending'    
    STATUS_CANCELED      = 'canceled'
    STATUS_READY_TO_SHIP = 'ready to ship'
    STATUS_SHIPPED       = 'shipped'    
    STATUS_PAID          = 'paid'
    STATUS_TESTING       = 'testing'
    
    # New
    #STATUS_PENDING        = 'Pending'
    #STATUS_OVERDUE        = 'Overdue'
    #STATUS_UNDER_REVIEW   = 'Under Review'
    #STATUS_PAID           = 'Paid'
    #STATUS_PAID_BY_CHECK  = 'Paid By Check'
    #STATUS_CANCELED       = 'Canceled'
    #STATUS_WAIVED         = 'Waived'
             
    FINANCIAL_STATUS_PENDING             = 'pending'
    FINANCIAL_STATUS_AUTHORIZED          = 'authorized'
    FINANCIAL_STATUS_CAPTURED            = 'captured'
    FINANCIAL_STATUS_REFUNDED            = 'refunded'
    FINANCIAL_STATUS_VOIDED              = 'voided'
    FINANCIAL_STATUS_PAID_BY_CHECK       = 'paid by check'
    FINANCIAL_STATUS_PAID_BY_OTHER_MEANS = 'paid by other means'
        
    PAYMENT_TERMS_PIA   = 'pia'
    PAYMENT_TERMS_NET7  = 'net7'
    PAYMENT_TERMS_NET10 = 'net10'
    PAYMENT_TERMS_NET30 = 'net30'
    PAYMENT_TERMS_NET60 = 'net60'
    PAYMENT_TERMS_NET90 = 'net90'
    PAYMENT_TERMS_EOM   = 'eom'
        
    #
    # Scopes
    #    
    scope :cart       , where('status = ?', 'cart')
    scope :pending    , where('status = ?', 'pending')    
    scope :canceled   , where('status = ?', 'canceled')
    scope :shipped    , where('status = ?', 'shipped')
    scope :paid       , where('status = ?', 'paid')
    scope :test       , where('status = ?', 'testing')
    
    scope :authorized , where('financial_status = ?', 'authorized')
    scope :captured   , where('financial_status = ?', 'captured')
    scope :refunded   , where('financial_status = ?', 'refunded')
    scope :voided     , where('financial_status = ?', 'voided')        
    
    #
    # Validations
    #
    
    validates :status, :inclusion => {
      :in      => ['cart', 'pending', 'canceled', 'ready to ship', 'shipped', 'paid', 'testing'],
      :message => "%{value} is not a valid status. Must be either 'pending' or 'shipped'"
    }
    
    validates :financial_status, :inclusion => {
      :in      => ['pending', 'authorized', 'captured', 'refunded', 'voided', 'paid by check', 'paid by other means'],
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
    
    #def refund
    #  PaymentProcessor.refund(self)
    #end
    #
    #def void
    #  PaymentProcessor.void(self)
    #end
    
    def calculate        
      self.update_column(:subtotal  , self.calculate_subtotal  )
      self.update_column(:tax       , self.calculate_tax       )
      self.update_column(:shipping  , self.calculate_shipping  )
      self.update_column(:handling  , self.calculate_handling  )
      self.update_column(:gift_wrap , self.calculate_gift_wrap )
      
      # Calculate the total without the discounts first       
      self.discounts.each{ |d| d.update_column(:amount, 0.0) } if self.discounts
      self.update_column(:discount  , 0.00)
      self.update_column(:total     , self.calculate_total     )
            
      # Now calculate the discounts and re-calculate the total
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
    
    # Authorize and capture funds
    def authorize_and_capture
      
      resp = StdClass.new                        
      if self.financial_status == Invoice::FINANCIAL_STATUS_CAPTURED
        resp.error = "Funds for this invoice have already been captured."
      else
                        
        sc = self.site.store_config                
        case sc.pp_name                                    
          when StoreConfig::PAYMENT_PROCESSOR_STRIPE
                                                                              
            Stripe.api_key = sc.stripe_secret_key.strip
            bt = nil
            begin
              c = Stripe::Charge.create(
                :amount => (self.total * 100).to_i,
                :currency => 'usd',
                :customer => self.customer.stripe_customer_id,
                :capture => true,
                :metadata => { :invoice_id => self.id },
                :statement_descriptor => "Invoice ##{self.id}"
              )                        
            rescue Exception => ex
              resp.error = "Error during capture process\n#{ex.message}"                
            end            
            if resp.error.nil?
              InvoiceTransaction.create(
                :invoice_id => self.id,
                :transaction_id => c.id,
                :transaction_type => InvoiceTransaction::TYPE_AUTHCAP,
                :payment_processor => sc.pp_name,
                :amount => c.amount / 100.0,
                :captured => true,
                :date_processed => DateTime.now.utc,
                :success => c.status == 'succeeded'
              )
              if c.status == 'succeeded'
                self.financial_status = Invoice::FINANCIAL_STATUS_CAPTURED
                self.save
                resp.success = true
              else
                resp.error = "Error capturing funds."
              end
            end
                      
        end        
      end      
      return resp
    end

    # Capture funds from a previously authorized transaction
    def capture_funds
      
      resp = StdClass.new      
      it = InvoiceTransaction.where(:invoice_id => self.id, :success => true).first
            
      if self.financial_status == Invoice::FINANCIAL_STATUS_CAPTURED
        resp.error = "Funds for this invoice have already been captured."    
      elsif self.total > it.amount
        resp.error = "The invoice total exceeds the authorized amount."
      elsif it.nil?
        resp.error = "This invoice doesn't seem to be authorized."
      else
                        
        sc = self.site.store_config                
        case sc.pp_name
          
          #when 'authorize.net'
          #  transaction = AuthorizeNet::AIM::Transaction.new(sc.authnet_api_login_id, sc.authnet_api_transaction_key)
          #  response = transaction.prior_auth_capture(t.transaction_id, self.total)
          #  
          #  ot = Caboose::InvoiceTransaction.create(
          #    :invoice_id        => self.id,
          #    :date_processed    => DateTime.now.utc,
          #    :transaction_type  => InvoiceTransaction::TYPE_CAPTURE,
          #    :payment_processor => sc.pp_name,
          #    :amount            => self.total,        
          #    :success           => response.response_code && response.response_code == '1',            
          #    :transaction_id    => response.transaction_id,
          #    :auth_code         => response.authorization_code,
          #    :response_code     => response.response_code
          #  )
          #  if ot.success
          #    self.date_captured = DateTime.now.utc
          #    self.save              
          #  end                                    
          #  self.update_attribute(:financial_status, Invoice::FINANCIAL_STATUS_CAPTURED)
          #  resp.success = 'Captured funds successfully'
                                    
          when StoreConfig::PAYMENT_PROCESSOR_STRIPE
                                          
            it = Caboose::InvoiceTransaction.where(:invoice_id => self.id, :success => true).first
            if it.nil?
              resp.error = "Error capturing funds for invoice #{self.id}. No previous successful authorization for this invoice exists."
              return false
            else                        
              Stripe.api_key = sc.stripe_secret_key.strip
              bt = nil
              begin
                c = Stripe::Charge.retrieve(it.transaction_id)
                c = c.capture
                bt = Stripe::BalanceTransaction.retrieve(c.balance_transaction)
              rescue Exception => ex
                resp.error = "Error during capture process\n#{ex.message}"                
              end
              
              if resp.error.nil?
                InvoiceTransaction.create(
                  :invoice_id => self.id,
                  :transaction_id => bt.id,
                  :transaction_type => InvoiceTransaction::TYPE_CAPTURE,
                  :payment_processor => sc.pp_name,
                  :amount => bt.amount / 100,                
                  :date_processed => DateTime.strptime(bt.created.to_s, '%s'),
                  :success => bt.status == 'succeeded' || bt.status == 'pending'
                )
                if bt.status == 'succeeded' || bt.status == 'pending'
                  self.financial_status = Invoice::FINANCIAL_STATUS_CAPTURED
                  self.save
                  resp.success = true
                else
                  resp.error = "Error capturing funds."
                end
              end
            end
          
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
          :payment_processor => sc.pp_name,
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
      
    # Refund an order
    def refund(amount = nil)
      
      resp = StdClass.new      
      it = InvoiceTransaction.where(:invoice_id => self.id, :success => true).first
      amount = self.total - self.amount_refunded if amount.nil?
            
      if self.financial_status == Invoice::FINANCIAL_STATUS_REFUNDED
        resp.error = "Funds for this invoice have already been refunded."    
      elsif amount > self.amount_refunded
        resp.error = "The amount to refund exceeds the amount available to refund."
      elsif it.nil?
        resp.error = "This invoice doesn't seem to be authorized."
      else
                        
        sc = self.site.store_config                
        case sc.pp_name
                                    
          when StoreConfig::PAYMENT_PROCESSOR_STRIPE
                                          
            it = Caboose::InvoiceTransaction.where(:invoice_id => self.id, :success => true).first
            if it.nil?
              resp.error = "Error capturing funds for invoice #{self.id}. No previous successful authorization for this invoice exists."
              return false
            else                        
              Stripe.api_key = sc.stripe_secret_key.strip
              bt = nil
              begin
                c = Stripe::Charge.retrieve(it.transaction_id)
                c = c.capture
                bt = Stripe::BalanceTransaction.retrieve(c.balance_transaction)
              rescue Exception => ex
                resp.error = "Error during capture process\n#{ex.message}"                
              end
              
              if resp.error.nil?
                InvoiceTransaction.create(
                  :invoice_id => self.id,
                  :transaction_id => bt.id,
                  :transaction_type => InvoiceTransaction::TYPE_CAPTURE,
                  :payment_processor => sc.pp_name,
                  :amount => bt.amount / 100,                
                  :date_processed => DateTime.strptime(bt.created.to_s, '%s'),
                  :success => bt.status == 'succeeded' || bt.status == 'pending'
                )
                if bt.status == 'succeeded' || bt.status == 'pending'
                  self.financial_status = Invoice::FINANCIAL_STATUS_CAPTURED
                  self.save
                  resp.success = true
                else
                  resp.error = "Error capturing funds."
                end
              end
            end
          
        end        
      end      
      return resp
    end
    
    def send_payment_authorization_email
      InvoicesMailer.configure_for_site(self.site_id).customer_payment_authorization(self).deliver
    end
    
    def send_receipt_email
      InvoicesMailer.configure_for_site(self.site_id).customer_receipt(self).deliver
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
    
    #===========================================================================
    
    def verify_invoice_packages
      
      Caboose.log("Verifying invoice packages....")
      
      # See if any there are any empty invoice packages          
      self.invoice_packages.each do |ip|
        count = 0
        self.line_items.each do |li|
          count = count + 1 if li.invoice_package_id == ip.id
        end
        ip.destroy if count == 0
      end
      
      # See if any line items aren't associated with an invoice package
      line_items_attached = true      
      self.line_items.each do |li|
        line_items_attached = false if li.invoice_package_id.nil?
      end
      shipping_packages_attached = true
      self.invoice_packages.each do |ip|    
        shipping_packages_attached = false if ip.shipping_package_id.nil?                          
      end
      ips = self.invoice_packages
      if ips.count == 0 || !line_items_attached || !shipping_packages_attached        
        self.calculate
        LineItem.where(:invoice_id => self.id).update_all(:invoice_package_id => nil)
        InvoicePackage.where(:invoice_id => self.id).destroy_all          
        self.create_invoice_packages
      end
                  
    end
    
    # Calculates the shipping packages required for all the items in the invoice
    def create_invoice_packages
      
      Caboose.log("Creating invoice packages...")
      
      store_config = self.site.store_config            
      if !store_config.auto_calculate_packages                        
        InvoicePackage.custom_invoice_packages(store_config, self)
        return
      end
                  
      # Make sure all the line items in the invoice have a quantity of 1
      extra_line_items = []
      self.line_items.each do |li|        
        if li.quantity > 1          
          (1..li.quantity).each{ |i|            
            extra_line_items << li.copy 
          }
          li.quantity = 1
          li.save
        end        
      end
      extra_line_items.each do |li|         
        li.quantity = 1                        
        li.save 
      end 
      
      # Make sure all the items in the invoice have attributes set
      self.line_items.each do |li|              
        v = li.variant
        next if v.downloadable
        Caboose.log("Error: variant #{v.id} has a zero weight") and return false if v.weight.nil? || v.weight == 0
        next if v.volume && v.volume > 0
        Caboose.log("Error: variant #{v.id} has a zero length") and return false if v.length.nil? || v.length == 0
        Caboose.log("Error: variant #{v.id} has a zero width" ) and return false if v.width.nil?  || v.width  == 0
        Caboose.log("Error: variant #{v.id} has a zero height") and return false if v.height.nil? || v.height == 0        
        v.volume = v.length * v.width * v.height
        v.save
      end
            
      # Reorder the items in the invoice by volume
      line_items = self.line_items.sort_by{ |li| li.quantity * (li.variant.volume ? li.variant.volume : 0.00) * -1 }
                      
      # Get all the packages we're going to use      
      all_packages = ShippingPackage.where(:site_id => self.site_id).reorder(:flat_rate_price).all      
      
      # Now go through each variant and fit it in a new or existing package            
      line_items.each do |li|        
        next if li.variant.downloadable
        
        # See if the item will fit in any of the existing packages
        it_fits = false
        self.invoice_packages.all.each do |op|
          it_fits = op.fits(li)
          if it_fits            
            li.invoice_package_id = op.id
            li.save            
            break
          end
        end        
        next if it_fits
        
        # Otherwise find the cheapest package the item will fit into
        it_fits = false
        all_packages.each do |sp|
          it_fits = sp.fits(li.variant)          
          if it_fits            
            op = InvoicePackage.create(:invoice_id => self.id, :shipping_package_id => sp.id)
            li.invoice_package_id = op.id
            li.save                          
            break
          end
        end
        next if it_fits
        
        Caboose.log("Error: line item #{li.id} (#{li.variant.product.title}) does not fit into any package.")               
      end      
    end
    
    def refresh_transactions  
      InvoiceTransaction.where(:invoice_id => self.id).destroy_all        
      sc = self.site.store_config
      case sc.pp_name          
        when StoreConfig::PAYMENT_PROCESSOR_STRIPE
          
          if sc.stripe_secret_key && sc.stripe_secret_key.strip.length > 0            
            Stripe.api_key = sc.stripe_secret_key.strip
            charges = Stripe::Charge.list(:limit => 100, :customer => self.customer.stripe_customer_id)
            
            self.financial_status = Invoice::FINANCIAL_STATUS_PENDING                      
            charges.each do |c|            
              invoice_id = c.metadata && c.metadata['invoice_id'] ? c.metadata['invoice_id'].to_i : nil            
              next if invoice_id.nil? || invoice_id != self.id
              
              if c.refunded                               then self.financial_status = Invoice::FINANCIAL_STATUS_REFUNDED
              elsif c.status == 'succeeded' && c.captured then self.financial_status = Invoice::FINANCIAL_STATUS_CAPTURED
              elsif c.status == 'succeeded'               then self.financial_status = Invoice::FINANCIAL_STATUS_AUTHORIZED            
              end                                    
                          
              auth_trans = InvoiceTransaction.create(
                :invoice_id => self.id,
                :transaction_id => c.id,
                :transaction_type => c.captured ? InvoiceTransaction::TYPE_AUTHCAP : InvoiceTransaction::TYPE_AUTHORIZE,
                :payment_processor => sc.pp_name,
                :amount => c.amount / 100.0,
                :amount_refunded => c.amount_refunded,
                :date_processed => DateTime.strptime(c.created.to_s, '%s'),              
                :success => c.status == 'succeeded',
                :captured => c.captured,
                :refunded => c.refunded              
              )
              if c.balance_transaction
                bt = Stripe::BalanceTransaction.retrieve(c.balance_transaction)
                capture_trans = InvoiceTransaction.create(
                  :invoice_id => self.id,
                  :parent_id => auth_trans.id, 
                  :transaction_id => bt.id,
                  :transaction_type => InvoiceTransaction::TYPE_CAPTURE,
                  :payment_processor => sc.pp_name,
                  :amount => bt.amount / 100.0,                
                  :date_processed => DateTime.strptime(bt.created.to_s, '%s'),
                  :success => bt.status == 'succeeded' || bt.status == 'pending'
                )                            
              end
              if c.refunds && c.refunds['total_count'] > 0
                total = 0
                c.refunds['data'].each do |r|
                  total = total + r.amount
                  InvoiceTransaction.create(
                    :invoice_id => self.id,
                    :parent_id => auth_trans.id,
                    :transaction_id => r.id,
                    :transaction_type => InvoiceTransaction::TYPE_REFUND,
                    :payment_processor => sc.pp_name,
                    :amount => r.amount / 100.0,                
                    :date_processed => DateTime.strptime(r.created.to_s, '%s'),
                    :success => r.status == 'succeeded' || r.status == 'pending'
                  )
                end
                total = total.to_f / 100
                if total >= auth_trans.amount
                  auth_trans.refunded = true
                  auth_trans.save
                end
              end
            end
            self.save
          end
      end
    end
    
  end
end

