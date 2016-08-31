
module Caboose        
  class UserSubscription < ActiveRecord::Base
    self.table_name  = 'store_user_subscriptions'
    self.primary_key = 'id'

    belongs_to :subscription
    belongs_to :user
    has_many :line_items
    attr_accessible :id  ,
      :subscription_id   ,
      :user_id           ,
      :date_started      ,
      :date_started_full ,
      :status
      
    STATUS_ACTIVE   = 'active'
    STATUS_INACTIVE = 'inactive'

    def calculate_date_started_full
      
      s = self.subscription
      if !s.start_on_day
        self.date_started_full = self.date_started
        self.save
      end
      
      s = self.subscription
      d = nil
      if s.interval == Subscription::INTERVAL_YEARLY        
        d = Date.new(self.date_started.year, s.start_month, s.start_day)
        d = d + 1.year if d < self.date_started        
      elsif s.interval == Subscription::INTERVAL_MONTHLY        
        d = Date.new(self.date_started.year, s.start_month, s.start_day)
        d = d + 1.month if d < self.date_started                
      end
      self.date_started_full = d
      self.save
      
    end
    
    def custom_prorate          
      return eval(self.subscription.prorate_function)    
    end
              
    # Verify invoices exist for the entire subscription period up until today
    def create_invoices
      
      self.calculate_date_started_full if self.date_started_full.nil?
              
      interval = case self.subscription.interval
        when Subscription::INTERVAL_MONTHLY then 1.month
        when Subscription::INTERVAL_YEARLY  then 1.year
      end
      sc = self.subscription.site.store_config
      v  = self.subscription.variant
      unit_price = v.clearance && v.clearance_price ? v.clearance_price : (v.on_sale? ? v.sale_price : v.price)
      
      # Special case if the subscription starts on specific day
      if self.subscription.start_on_day && (Date.today > self.date_started_full)
        li = self.line_items.where("date_starts = ? date_ends = ?", self.date_started, self.date_started_full - 1.day).first
        if li.nil?
          prorated_unit_price = unit_price + 0.00          
          if self.subscription.prorate             
            prorated_unit_price = case self.subscription.prorate_method
              when Subscription::PRORATE_METHOD_FLAT       then self.subscription.prorate_flat_amount
              when Subscription::PRORATE_METHOD_PERCENTAGE then unit_price * ((self.date_started_full - self.date_started).to_f / ((self.date_started_full + interval) - self.date_started_full).to_f)
              when Subscription::PRORATE_METHOD_CUSTOM     then self.subscription.custom_prorate(self)                                            
            end
          end            
          invoice = Caboose::Invoice.create(        
            :site_id          => self.subscription.site_id,
            :status           => Caboose::Invoice::STATUS_PENDING,
            :financial_status => Caboose::Invoice::STATUS_PENDING,
            :date_created     => DateTime.now,                                    
            :payment_terms    => sc.default_payment_terms,
            :invoice_number   => sc.next_invoice_number
          )          
          LineItem.create(
            :invoice_id            => invoice.id,
            :variant_id            => v.id,
            :quantity              => 1,
            :unit_price            => prorated_unit_price,
            :subtotal              => prorated_unit_price,
            :status                => 'pending',
            :user_subscription_id  => self.id,            
            :date_starts           => d,
            :date_ends             => d + interval - 1.day
          )
          invoice.calculate
          invoice.save                    
        end
      end        

      d2 = self.date_started_full + 1.day - 1.day
      while d2 <= Date.today do
        d2 = d2 + interval
      end
      d  = self.date_started + 1.day - 1.day
      while d <= d2 do
        # See if an invoice has already been created for today      
        li = self.line_items.where("date_starts = ? AND date_ends = ?", d, d + interval - 1.day).first
        if li.nil?
          invoice = Caboose::Invoice.create(        
            :site_id          => self.subscription.site_id,
            :customer_id      => self.user_id,
            :status           => Caboose::Invoice::STATUS_PENDING,
            :financial_status => Caboose::Invoice::STATUS_PENDING,
            :date_created     => DateTime.now,                                    
            :payment_terms    => sc.default_payment_terms,
            :invoice_number   => sc.next_invoice_number
          )          
          LineItem.create(
            :invoice_id            => invoice.id,
            :variant_id            => v.id,
            :quantity              => 1,
            :unit_price            => unit_price,
            :subtotal              => unit_price,
            :status                => 'pending',
            :user_subscription_id  => self.id,            
            :date_starts           => d,
            :date_ends             => d + interval - 1.day
          )
          invoice.calculate
          invoice.save                    
        end
        d = d + interval
      end        
      return true      
    end
    
    #===========================================================================
    # Static methods
    #===========================================================================
    
    def UserSubscription.create_invoices
      UserSubscription.where(:status => UserSubscription::STATUS_ACTIVE).all.each do |us|
        us.create_invoices
      end
    end

  end
end

