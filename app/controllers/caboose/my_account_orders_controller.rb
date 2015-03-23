module Caboose
  class MyAccountOrdersController < Caboose::ApplicationController
            
    # GET /my-account/orders
    def index
      return if !logged_in?
      
      @pager = Caboose::PageBarGenerator.new(params, {
        'customer_id'          => logged_in_user.id,         
        'status'               => [Order::STATUS_PENDING, Order::STATUS_CANCELED, Order::STATUS_READY_TO_SHIP, Order::STATUS_SHIPPED]        
      }, {
        'model'          => 'Caboose::Order',
        'sort'           => 'order_number',
        'desc'           => 1,
        'base_url'       => '/my-account/orders',
        'use_url_params' => false
      })      
      @orders = @pager.all_items
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
     # GET /my-account
    def my_account
      return if !logged_in?
      @user = logged_in_user
      render :layout => 'caboose/modal'
    end
    
    # PUT /my-account
    def update_my_account  
      return if !logged_in?
      
      resp = StdClass.new     
      user = logged_in_user
    
      save = true
      params.each do |name,value|
        case name
    	  	when "first_name", "last_name", "username", "email", "phone"
    	  	  user[name.to_sym] = value
    	  	when "password"			  
    	  	  confirm = params[:confirm]
    	  		if (value != confirm)			
    	  		  resp.error = "Passwords do not match.";
    	  		  save = false
    	  		elsif (value.length < 8)
    	  		  resp.error = "Passwords must be at least 8 characters.";
    	  		  save = false
    	  		else
    	  		  user.password = Digest::SHA1.hexdigest(Caboose::salt + value)
    	  		end    	  	    		  
    	  end
    	end
    	
    	resp.success = save && user.save
    	render json: resp
    end        
  end
end
