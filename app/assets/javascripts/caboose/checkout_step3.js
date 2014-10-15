
Caboose.Store.Modules.CheckoutStep3 = (function() {
    
  self = {};
   
  self.initialize = function() {                
    self.bind_event_handlers();
  };
  
  self.bind_event_handlers = function() {
    $('#checkout button').click(self.shipping_click_handler);    
  };

  self.shipping_click_handler = function(event) {
    $('#message').html("<p class='loading'>Saving information...</p>");            
    $.ajax({
      url: '/checkout/shipping',
      type: 'put',      
      data: { 
        shipping_method:      $(event.target).data('shipping-method'),
        shipping_method_code: $(event.target).data('shipping-code') 
      },
      success: function(resp) {
        if (resp.errors && resp.errors.length > 0)
          $('#message').html("<p class='note error'>" + resp.errors[0] + "</p>");
        else if (resp.success)
          window.location = '/checkout/step-four';        
      }
    });
    return false;
  };
    
  return self
}).call(Caboose.Store);
