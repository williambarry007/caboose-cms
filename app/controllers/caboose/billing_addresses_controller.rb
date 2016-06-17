module Caboose
  class BillingAddressesController < Caboose::ApplicationController
            
    # @route GET /admin/invoices/:invoice_id/billing-address/json
    def admin_json
      return if !user_is_allowed('invoices', 'edit')    
      invoice = Invoice.find(params[:invoice_id])      
      render :json => invoice.billing_address      
    end
      
    # @route PUT /admin/invoices/:invoice_id/billing-address
    def admin_update
      return if !user_is_allowed('invoices', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      invoice = Invoice.find(params[:invoice_id])    
      sa = invoice.billing_address
      
      if sa.nil?
        sa = Address.create
        invoice.billing_address_id = sa.id
        invoice.save
      end
      
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
    
    # @route GET /my-account/invoices/:invoice_id/billing-address/json
    def my_account_json
      return if !logged_in?    
      invoice = Invoice.find(params[:invoice_id])      
      if invoice.customer_id != logged_in_user.id        
        render :json => { :error => "The given invoice does not belong to you." } 
        return
      end
      render :json => invoice.billing_address      
    end
    
    # @route PUT /my-account/invoices/:invoice_id/billing-address
    def my_account_update
      return if !logged_in?
      
      resp = Caboose::StdClass.new
      invoice = Invoice.find(params[:invoice_id])
      if invoice.customer_id != logged_in_user.id        
        render :json => { :error => "The given invoice does not belong to you." } 
        return
      end                
      
      sa = invoice.billing_address      
      if sa.nil?
        sa = Address.create
        invoice.billing_address_id = sa.id
        invoice.save
      end
      
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
