class Caboose::PaymentProcessors::Base
  
  # Gets a transaction object that obfuscates transaction info.  
  # Included in this info is the relay URL, which should be set to /checkout/payment-relay.  
  def get_authorize_transaction(order)
    return {}
  end
    
  # Gets the hidden form and hidden iframe to which the form will be submitted.  
  # Both are shown on the /checkout/billing page.                                                                                  
  def get_authorize_form(transaction)
    return ""
  end
  
  # Handles the relay during an authorize transaction.                                          
  # Should save the transaction information if a successful authorize.
  # Returns the response required to make the processor to redirect to /checkout/payment-receipt.
  def authorize_relay(params)
    return ""
  end
     
  # Called during the receipt of an authorize transaction.
  # Returns true of false indicating whether the authorize transaction was successful.
  def authorized?(params)
    return false
  end
  
  # Called if authorized? returns false.
  # Returns the error given by the processor.
  def authorize_error(params)
    return ""
  end
  
  # Captures funds for the given order.
  # Returns true or false indicating the success of the transaction.
  def capture(order)
    return false
  end
end
