module Caboose
  class CartController < Caboose::ApplicationController
    before_filter :get_line_item, :only => [:update, :remove]
    
    def get_line_item
      @line_item = @order.line_items.find(params[:id])
    end
    
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
    
    # POST /cart/add
    def add
      if @order.line_items.exists?(:variant_id => params[:variant_id])
        @line_item = @order.line_items.find_by_variant_id(params[:variant_id])
        @line_item.quantity += params[:quantity] ? params[:quantity].to_i : 1
      else
        @line_item = LineItem.new
        @line_item.variant_id = params[:variant_id]
        @line_item.order_id = @order.id
        @line_item.status = 'pending'
        @line_item.quantity = params[:quantity] ? params[:quantity].to_i : 1
      end
      
      render :json => { :success => @line_item.save, :errors => @line_item.errors.full_messages, :item_count => @order.line_items.count }
    end
    
    # PUT cart/update
    def update
      @line_item.quantity = params[:quantity].to_i
      render :json => { :success => @line_item.save, :errors => @line_item.errors.full_messages, :line_item => @line_item, :order_subtotal => @order.calculate_subtotal }
    end
    
    # DELETE cart/delete
    def remove
      render :json => { :success => !!@order.line_items.delete(@line_item), :item_count => @order.line_items.count }
    end
  end
end

