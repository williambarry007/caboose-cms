module Caboose
  class CartController < Caboose::ApplicationController
    
    # GET /cart
    def index
    end
    
    # GET /cart/items
    def list
      render :json => @order.as_json(
        :include => [        
          { 
            :line_items => { 
              :include => { 
                :variant => { 
                  :include => [
                    { :product_images => { :methods => :urls }},
                    { :product => { :include => { :product_images => { :methods => :urls }}}}
                  ],
                  :methods => :title
                }
              }
            }
          },
          { :order_packages => { :include => [:shipping_package, :shipping_method] }},
          :customer,
          :shipping_address,
          :billing_address,
          :order_transactions,
          { :discounts => { :include => :gift_card }}
        ]        
      )
    end
    
    # GET /cart/item-count
    def item_count
      render :json => { :item_count => @order.item_count }
    end
    
    # POST /cart
    def add      
      v = Variant.find(params[:variant_id])
      qty = params[:quantity] ? params[:quantity].to_i : 1
      
      if @order.line_items.exists?(:variant_id => v.id)
        li = @order.line_items.find_by_variant_id(v.id)
        li.quantity += qty
        li.subtotal = li.unit_price * li.quantity
      else
        unit_price = v.on_sale? ? v.sale_price : v.price
        li = LineItem.new(
          :order_id   => @order.id,
          :variant_id => v.id,
          :quantity   => qty,
          :unit_price => unit_price,
          :subtotal   => unit_price * qty,
          :status     => 'pending'
        )
      end       
      render :json => { 
        :success => li.save, 
        :errors => li.errors.full_messages,
        :item_count => @order.item_count 
      }
    end
    
    # PUT /cart/:line_item_id
    def update
      li = LineItem.find(params[:line_item_id])
      li.quantity = params[:quantity].to_i
      li.subtotal = li.unit_price * li.quantity
      li.save
      li.destroy if li.quantity == 0
      @order.calculate_subtotal
      render :json => { :success => true }
    end
    
    # DELETE /cart/:line_item_id
    def remove
      li = LineItem.find(params[:line_item_id]).destroy
      render :json => { :success => true, :item_count => @order.line_items.count }
    end
    
    # POST /cart/gift-cards
    def add_gift_card      
      resp = StdClass.new
      code = params[:code].strip
      gc = GiftCard.where("lower(code) = ?", code.downcase).first
      
      if gc.nil? then resp.error = "Invalid gift card code."                    
      elsif gc.status != GiftCard::STATUS_ACTIVE                                then resp.error = "That gift card is not active."
      elsif gc.date_available && DateTime.now.utc < self.date_available         then resp.error = "That gift card is not active yet."         
      elsif gc.date_expires && DateTime.now.utc > self.date_expires             then resp.error = "That gift card is expired."
      elsif gc.card_type == GiftCard::CARD_TYPE_AMOUNT && gc.balance <= 0       then resp.error = "That gift card has a zero balance." 
      elsif gc.min_order_total && @order.total < gc.min_order_total             then resp.error = "Your order must be at least $#{sprintf('%.2f',gc.min_order_total)} to use this gift card." 
      elsif Discount.where(:order_id => @order.id, :gift_card_id => gc.id).exists? then resp.error = "That gift card has already been applied to this order."
      else
        # Determine how much the discount will be
        d = Discount.new(:order_id => @order.id, :gift_card_id => gc.id, :amount => 0.0)
        case gc.card_type
          when GiftCard::CARD_TYPE_AMOUNT      then d.amount = (@order.total > gc.balance ? gc.balance : @order.total)
          when GiftCard::CARD_TYPE_PERCENTAGE  then d.amount = @order.subtotal * gc.total
          when GiftCard::CARD_TYPE_NO_SHIPPING then d.amount = @order.shipping
          when GiftCard::CARD_TYPE_NO_TAX      then d.amount = @order.tax
        end
        d.save
        @order.calculate
        resp.success = true
        resp.order_total = @order.total
      end
      render :json => resp
    end
    
    # DELETE /cart/discounts/:discount_id
    def remove_discount
      Discount.find(params[:discount_id]).destroy
      @order.calculate
      render :json => { :success => true }
    end
  end
end
