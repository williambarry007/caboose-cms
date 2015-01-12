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
      Caboose.log(sa.first_name)
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
      Caboose.log(sa.first_name)
      resp.success = save && sa.save
      Caboose.log(sa.first_name)
      render :json => resp
    end
        
  end
end
