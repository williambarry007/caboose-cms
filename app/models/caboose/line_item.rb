module Caboose
  class LineItem < ActiveRecord::Base
    self.table_name = 'store_line_items'
    
    belongs_to :variant
    belongs_to :order
    belongs_to :order_package, :class_name => 'OrderPackage'
    belongs_to :parent, :class_name => 'LineItem', :foreign_key => 'parent_id'
    has_many :children, :class_name => 'LineItem', :foreign_key => 'parent_id'
    
    attr_accessible :id      ,
      :order_id              ,
      :order_package_id      ,
      :variant_id            ,
      :unit_price            ,
      :quantity              ,
      :subtotal              ,
      :notes                 ,            
      :status                ,      
      :custom1               ,
      :custom2               ,
      :custom3               ,
      :is_gift               ,
      :include_gift_message  ,
      :gift_message          ,
      :gift_wrap             ,
      :hide_prices
    
    #
    # Scopes
    #
    
    scope :pending, where('status = ?', 'pending')
    scope :fulfilled, where('status = ?', 'shipped')
    scope :unfulfilled, where('status != ?', 'shipped')
    #
    # Validations
    #
    
    validates :status, :inclusion => {
      :in      => ['pending', 'shipped'],
      :message => "%{value} is not a valid status. Must be either 'pending' or 'shipped'"
    }
    
    validates :quantity, :numericality => { :greater_than_or_equal_to => 0 }
    
    validate :quantity_in_stock
    def quantity_in_stock
      errors.add(:base, "There #{self.variant.quantity_in_stock > 1 ? 'are' : 'is'} only #{self.variant.quantity_in_stock} left in stock.") if self.variant.quantity_in_stock - self.quantity < 0
    end
    
    #
    # Callbacks
    #
    
    before_save :update_subtotal
    after_save { self.order.calculate }    
    after_initialize :check_nil_fields
    
    def check_nil_fields      
      self.subtotal = 0.00 if self.subtotal.nil?        
    end
    
    #
    # Methods
    #
    
    def update_subtotal
      if self.unit_price.nil?
        self.unit_price = self.variant.on_sale? ? self.variant.sale_price : self.variant.price        
      end      
      self.subtotal = self.unit_price * self.quantity
    end
    
    def title
      if self.variant.product.variants.count > 1
        "#{self.variant.product.title} - #{self.variant.title}"
      else
        self.variant.product.title
      end
    end
    
    def as_json(options={})
      self.attributes.merge({        
        :variant => self.variant,
        :title   => self.title
      })
    end
    
    def verify_unit_price      
      if self.unit_price.nil?
        self.unit_price = self.variant.clearance && self.variant.clearance_price ? self.variant.clearance_price : (self.variant.on_sale? ? self.variant.sale_price : self.variant.price)
        self.save
      end      
    end
    
    def copy
      LineItem.new(      
        :variant_id      => self.variant_id      ,
        :quantity        => self.quantity        ,
        :unit_price      => self.unit_price      ,
        :subtotal        => self.subtotal        ,
        :notes           => self.notes           ,
        :order_id        => self.order_id        ,
        :status          => self.status          ,        
        :custom1         => self.custom1         ,
        :custom2         => self.custom2         ,
        :custom3         => self.custom3
      )
    end
  end
end

