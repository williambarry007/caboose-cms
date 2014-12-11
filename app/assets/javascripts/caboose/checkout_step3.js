
Caboose.Store.Modules.CheckoutStep3 = (function() {
    
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
        carrier:      $(event.target).data('carrier'),
        service_code: $(event.target).data('service-code'),
        service_name: $(event.target).data('service-name')         
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
