module Caboose
  class MyAccountOrdersController < Caboose::ApplicationController
            
    # GET /my-account/orders
    def index
      return if !logged_in?
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'customer_id'          => @logged_in_user_id.id,         
        'status'               => '',        
        'id'                   => ''
      }, {
        'model'          => 'Caboose::Order',
        'sort'           => 'id',
        'desc'           => 1,
        'base_url'       => '/my-account/orders',
        'use_url_params' => false
      })      
      @orders = @pager.items                  
    end
      
    # GET /my-account/orders/:id
    def edit
      return if !logged_in?
      
      @order = Order.find(params[:id])
      if @order.customer_id != logged_in_user.id
        @error = "The given order does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end      
    end
             
  end
end
