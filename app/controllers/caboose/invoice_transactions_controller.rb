module Caboose
  class InvoiceTransactionsController < Caboose::ApplicationController
    
    # @route GET /admin/invoices/:invoice_id/transactions/:id/capture
    def admin_capture
      return if !user_is_allowed('invoices', 'edit')
    
      it = InvoiceTransaction.find(params[:id])
      resp = params[:amount] ? it.capture(params[:amount]) : it.capture 
      
      render :json => resp            
    end
        
    # @route GET /admin/invoices/:invoice_id/transactions/:id/refund
    def admin_refund
      return if !user_is_allowed('invoices', 'edit')
    
      it = InvoiceTransaction.find(params[:id])
      resp = it.refund 
      
      render :json => resp            
    end
    
    # @route GET /admin/invoices/:invoice_id/transactions/:id/void
    def admin_void
      return if !user_is_allowed('invoices', 'edit')
    
      it = InvoiceTransaction.find(params[:id])
      resp = it.void 
      
      render :json => resp            
    end
    
  end
end
