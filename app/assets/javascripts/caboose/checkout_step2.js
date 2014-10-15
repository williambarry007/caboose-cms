
Caboose.Store.Modules.CheckoutStep2 = (function() {
    
  self = {};
  
  self.initialize = function() {                
    self.bind_event_handlers();
  };
  
  self.bind_event_handlers = function() {
    $('input[type=checkbox][name=use_as_billing]').on('change', self.use_as_billing_handler);
    $('#address_form').submit(self.continue_handler);
  };

  self.use_as_billing_handler = function(event) {    
    if (event.target.checked)
      $('#billing').hide();
    else
      $('#billing').show();    
  };
  
  self.continue_handler = function(event) {    
    $('#message').html("<p class='loading'>Saving information...</p>");
    $.ajax({
      url: '/checkout/address',
      type: 'put',      
      data: $('#address_form').serialize(),
      success: function(resp) {
        if (resp.errors && resp.errors.length > 0)
          $('#message').html("<p class='note error'>" + resp.errors[0] + "</p>");
        else if (resp.success)
          window.location = '/checkout/step-three';
      }
    });
    return false;
  };
    
  return self
}).call(Caboose.Store);
