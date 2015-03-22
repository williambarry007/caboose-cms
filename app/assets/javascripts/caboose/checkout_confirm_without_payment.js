
Caboose.Store.Modules.CheckoutPayment = (function() {

  self = {
    is_confirm: false
  };    
  
  self.initialize = function() {        
    $('#checkout-continue button').click(self.continue_handler);
  };

  self.continue_handler = function(event) {    
    $('#message').html("<p class='loading'>Processing...</p>");
    $.ajax({
      url: '/checkout/confirm',
      type: 'post',
      success: function(resp)
      {
        if (resp.success == true)
        {
          if (resp.redirect)
            window.location = resp.redirect;
          else
            window.location = '/checkout/thanks';          
        }
        else if (resp.error)  
          $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else
          $('#message').html("<p class='note error'>There was an error processing your payment.</p>");
      } 
    });
  };
  
  return self
}).call(Caboose.Store);

