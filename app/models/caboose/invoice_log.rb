module Caboose
  class InvoiceLog < ActiveRecord::Base
    self.table_name = 'store_invoice_logs'
        
    belongs_to :invoice  
    belongs_to :user
    attr_accessible :id   ,
      :invoice_id         ,
      :invoice_package_id ,
      :line_item_id       ,      
      :user_id            ,
      :date_logged        ,
      :invoice_action     ,
      :field              ,
      :old_value          ,
      :new_value
      
    ACTION_INVOICE_CREATED         = 'invoice created'
    ACTION_INVOICE_UPDATED         = 'invoice updated'
    ACTION_INVOICE_DELETED         = 'invoice deleted'
    ACTION_INVOICE_PACKAGE_CREATED = 'invoice package created'
    ACTION_INVOICE_PACKAGE_UPDATED = 'invoice package updated'
    ACTION_INVOICE_PACKAGE_DELETED = 'invoice package deleted'
    ACTION_LINE_ITEM_CREATED       = 'line item created'
    ACTION_LINE_ITEM_UPDATED       = 'line item updated'
    ACTION_LINE_ITEM_DELETED       = 'line item deleted'

  end
end
                                          