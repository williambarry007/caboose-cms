module Caboose
  class CartController < Caboose::ApplicationController
    
    # GET /cart
    def index
    end
    
    # GET /cart/items
    def list
      render :json => { :order => @order }
    end
    
    # GET /cart/item-count
    def item_count
      render :json => { :item_count => @order.line_items.count }
    end
    
    # POST /cart
    def add
      variant_id = params[:variant_id]
      qty = params[:quantity] ? params[:quantity].to_i : 1
      
      if @order.line_items.exists?(:variant_id => variant_id)
        li = @order.line_items.find_by_variant_id(variant_id)
        li.quantity += qty
      else
        li = LineItem.new(
          :order_id   => @order.id,
          :variant_id => variant_id,
          :quantity   => qty,
          :status     => 'pending'
        )
      end            
      render :json => { 
        :success => li.save, 
        :errors => li.errors.full_messages,
        :item_count => @order.line_items.count 
      }
    end
    
    # PUT /cart/:line_item_id
    def update
      li = LineItem.find(params[:line_item_id])
      li.quantity = params[:quantity].to_i
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
  end
end

