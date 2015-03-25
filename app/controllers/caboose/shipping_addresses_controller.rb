module Caboose
  class ShippingAddressesController < Caboose::ApplicationController
            
    # GET /admin/orders/:order_id/shipping-address/json
    def admin_json
      return if !user_is_allowed('orders', 'edit')    
      order = Order.find(params[:order_id])      
      render :json => order.shipping_address      
    end
      
    # PUT /admin/orders/:order_id/shipping-address
    def admin_update
      return if !user_is_allowed('orders', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      order = Order.find(params[:order_id])    
      sa = order.shipping_address
      
      save = true    
      params.each do |name, value|
        case name          
          when 'name'           then sa.name          = value          
          when 'first_name'     then sa.first_name    = value
          when 'last_name'      then sa.last_name     = value
          when 'street'         then sa.street        = value
          when 'address1'       then sa.address1      = value
          when 'address2'       then sa.address2      = value
          when 'company'        then sa.company       = value
          when 'city'           then sa.city          = value
          when 'state'          then sa.state         = value
          when 'province'       then sa.province      = value
          when 'province_code'  then sa.province_code = value
          when 'zip'            then sa.zip           = value
          when 'country'        then sa.country       = value
          when 'country_code'   then sa.country_code  = value
          when 'phone'          then sa.phone         = value
        end
      end                
      resp.success = save && sa.save      
      render :json => resp
    end
    
    #===========================================================================
    
    # GET /my-account/orders/:order_id/shipping-address/json
    def my_account_json
      return if !logged_in?    
      order = Order.find(params[:order_id])      
      if order.customer_id != logged_in_user.id        
        render :json => { :error => "The given order does not belong to you." } 
        return
      end
      render :json => order.shipping_address      
    end
    
    # PUT /my-account/orders/:order_id/shipping-address
    def my_account_update
      return if !logged_in?
      
      resp = Caboose::StdClass.new
      order = Order.find(params[:order_id])
      if order.customer_id != logged_in_user.id        
        render :json => { :error => "The given order does not belong to you." } 
        return
      end

      sa = order.shipping_address      
      save = true    
      params.each do |name, value|
        case name          
          when 'name'           then sa.name          = value          
          when 'first_name'     then sa.first_name    = value
          when 'last_name'      then sa.last_name     = value
          when 'street'         then sa.street        = value
          when 'address1'       then sa.address1      = value
          when 'address2'       then sa.address2      = value
          when 'company'        then sa.company       = value
          when 'city'           then sa.city          = value
          when 'state'          then sa.state         = value
          when 'province'       then sa.province      = value
          when 'province_code'  then sa.province_code = value
          when 'zip'            then sa.zip           = value
          when 'country'        then sa.country       = value
          when 'country_code'   then sa.country_code  = value
          when 'phone'          then sa.phone         = value
        end
      end                
      resp.success = save && sa.save      
      render :json => resp
    end
        
  end
end
