module Caboose
  class LineItem < ActiveRecord::Base
    self.table_name = 'store_line_items'
    
    belongs_to :variant
    belongs_to :order, :dependent => :destroy
    belongs_to :parent, :class_name => 'LineItem', :foreign_key => 'parent_id'
    has_many :children, :class_name => 'LineItem', :foreign_key => 'parent_id'
    
    attr_accessible :id,
      :variant_id,
      :quantity,
      :price,
      :notes,
      :order_id,
      :status,
      :tracking_number,
      :custom1,
      :custom2,
      :custom3
    
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
    
    before_save :update_price
    after_save { self.order.calculate }
    
    #
    # Methods
    #
    
    def update_price
      self.price = self.variant.price * self.quantity
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
        :title => self.title,
        :product => { :images => self.variant.product.product_images }
      })
    end
    
    def subtotal
      return self.quantity * self.price
    end
  end
end

