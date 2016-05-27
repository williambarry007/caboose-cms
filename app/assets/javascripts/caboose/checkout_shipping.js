
Caboose.Store.Modules.CheckoutShipping = (function() {
    
  self = {};
   
  self.initialize = function() {                
    self.bind_event_handlers();
  };
  
  self.bind_event_handlers = function() {
    $('a.shipping_rate').click(self.shipping_click_handler);    
  };

  self.shipping_click_handler = function(event) {
    event.preventDefault();
    $('#message').html("<p class='loading'>Saving information...</p>");            
    $.ajax({
      url: '/checkout/shipping',
      type: 'put',      
      data: { 
        invoice_package_id: $(event.target).data('invoice_package_id'),
        shipping_method_id: $(event.target).data('shipping_method_id'),
        total:              $(event.target).data('total')
      },
      success: function(resp) {
        if (resp.errors && resp.errors.length > 0)
          $('#message').html("<p class='note error'>" + resp.errors[0] + "</p>");
        else if (resp.success)
          window.location = '/checkout/gift-cards';        
      }
    });
    return false;
  };
    
  return self
}).call(Caboose.Store);
