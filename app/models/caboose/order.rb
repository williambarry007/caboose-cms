#
# Order
#

module Caboose        
  class Order < ActiveRecord::Base
    self.table_name  = 'store_orders'
    self.primary_key = 'id'

    belongs_to :site    
    belongs_to :customer, :class_name => 'Caboose::User'
    belongs_to :shipping_address, :class_name => 'Address'
    belongs_to :billing_address, :class_name => 'Address'
    has_many :discounts    
    has_many :line_items, :after_add => :line_item_added, :after_remove => :line_item_removed, :order => :id
    has_many :order_packages, :class_name => 'Caboose::OrderPackage'
    has_many :order_transactions
    
    attr_accessible :id,
      :site_id,
      :alternate_id,      
      :subtotal,
      :tax,            
      :shipping,
      :handling,
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
      
      # :payment_status,
      # :cancel_reason,      
      # :date_authorized,
      # :date_captured,
      # :date_cancelled,
      # :email,      
      # :payment_id,
      # :gateway_id,      
      # :transaction_d,
      # :auth_code,      
      # :amount_discounted,
      # :shipping_carrier,
      # :shipping_service_code,
      # :order_number,            
      # :date_shipped,
      # :transaction_service,
      # :transaction_id
    
    STATUS_CART      = 'cart'
    STATUS_PENDING   = 'pending'    
    STATUS_CANCELED  = 'canceled'
    STATUS_SHIPPED   = 'shipped'
    STATUS_TESTING   = 'testing'
    
    #
    # Scopes
    #
    
    scope :test       , where('status = ?', 'testing')
    scope :cancelled  , where('status = ?', 'cancelled')
    scope :pending    , where('status = ?', 'pending')
    #TODO scope :fulfilled
    #TODO scope :unfulfilled
    scope :authorized , where('financial_status = ?', 'authorized')
    scope :captured   , where('financial_status = ?', 'captured')
    scope :refunded   , where('financial_status = ?', 'refunded')
    scope :voided     , where('financial_status = ?', 'voided')        
    
    #
    # Validations
    #
    
    validates :status, :inclusion => {
      :in      => ['cart', 'pending', 'cancelled', 'shipped', 'testing'],
      :message => "%{value} is not a valid status. Must be either 'pending' or 'shipped'"
    }
    
    validates :financial_status, :inclusion => {
      :in      => ['pending', 'authorized', 'captured', 'refunded', 'voided'],
      :message => "%{value} is not a valid financial status. Must be 'authorized', 'captured', 'refunded' or 'voided'"
    }
    
    #
    # Callbacks
    #
    
    after_update :calculate
    
    #
    # Methods
    #
    
    def packages
      self.order_packages
    end
    
    #def as_json(options={})
    #  self.attributes.merge({
    #    :line_items => self.line_items,
    #    :shipping_address => self.shipping_address,
    #    :billing_address => self.billing_address
    #  })
    #end
    
    def decrement_quantities
      return false if self.decremented
      
      self.line_items.each do |line_item|
        line_item.variant.update_attribute(:quantity, line_item.variant.quantity_in_stock - line_item.quantity)
      end
      
      self.update_attribute(:decremented, true)
    end
    
    def increment_quantities
      return false if !self.decremented
      
      self.line_items.each do |line_item|
        line_item.variant.update_attribute(:quantity, line_item.variant.quantity_in_stock - line_item.quantity)
      end
      
      self.update_attribute(:decremented, false)
    end
    
    def resend_confirmation
      OrdersMailer.configure_for_site(self.site_id).customer_new_order(self).deliver
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
    
    def refuned
      PaymentProcessor.refund(self)
    end
    
    def void
      PaymentProcessor.void(self)
    end
    
    def line_item_added(line_item)
      self.calculate
    end
    
    def line_item_removed(line_item)
      self.calculate
    end
    
    def calculate
      self.update_column(:subtotal , self.calculate_subtotal )
      self.update_column(:tax      , self.calculate_tax      )
      self.update_column(:shipping , self.calculate_shipping )
      self.update_column(:handling , self.calculate_handling )
      self.update_column(:discount , self.calculate_discount )
      self.update_column(:total    , self.calculate_total    )
    end
    
    def calculate_subtotal
      return 0.0 if self.line_items.empty?
      x = 0.0      
      self.line_items.each{ |li| x = x + li.variant.price }
      return x
    end
    
    def calculate_tax
      return 0.0 if !self.shipping_address
      self.subtotal * TaxCalculator.tax_rate(self.shipping_address)
    end
    
    def calculate_shipping      
      return 0.0 if self.order_packages.nil? || self.order_packages.count == 0
      x = 0.0
      self.order_packages.each{ |op| x = x + op.total }
      return x
    end
    
    def calculate_handling
      return 0.0 if self.site.nil? || self.site.store_config.nil?      
      self.subtotal * self.site.store_config.handling_percentage.to_f
    end
    
    def calculate_discount      
      return 0.0 if self.discounts.nil? || self.discounts.count == 0
      x = 0.0
      self.discounts.each{ |d| x = x + d.amount }
      x = x + self.custom_discount if self.custom_discount
      return x
    end
    
    def calculate_total
      return (self.subtotal + self.tax + self.shipping + self.handling) - self.discount
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
      return true if self.order_packages.nil?
      return true if self.order_packages.count == 0
      self.order_packages.each do |op|
        return true if op.shipping_method_id.nil?
      end
      return false
    end
  end
end

