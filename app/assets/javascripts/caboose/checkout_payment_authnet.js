
Caboose.Store.Modules.CheckoutPayment = (function() {

  self = {
    is_confirm: false
  };    
  
  self.initialize = function() {
    //$('#checkout-confirm').hide();
    if (!SHOW_RELAY || SHOW_RELAY == false)
      $('#relay').hide();
    $('#checkout-confirm').hide();
    self.bind_event_handlers();    
    self.expiration_change_handler();
  };
    
  self.bind_event_handlers = function() {
    
    $('#payment select').change(self.expiration_change_handler);
    $('#checkout-continue button').click(self.continue_handler);
    $('#checkout-confirm #edit_payment').click(self.edit_payment_handler);                
          
    $(window).on('message', function(event) {
      relay_handler(event.originalEvent.data);
    });
  };
    
  self.expiration_change_handler = function(event) {
    var form = $('#checkout-payment #payment')
    month = form.find('select[name=month]').val()
    year = form.find('select[name=year]').val();    
    $('#expiration').val(month + year);
  };
  
  self.continue_handler = function(event) {    
    if (!self.is_confirm)
    {
      var cc = $('#billing-cc-number').val();
      if (cc.length < 15)
        $('#message').html("<p class='note error'>Please enter a valid credit card number.</p>");
      else
      {          
        $('#message').empty();
        $('#checkout-payment').hide();
        $('#checkout-confirm').show();
        $('#confirm_card_number').html("Card ending in " + cc.substr(-4));                        
        $('#checkout-continue button').html("Confirm order");
        self.is_confirm = true;
      }
    }
    else
    {
      // Verify that the order total is correct before submitting
      $('#message').html("<p class='loading'>Verifying order total...</p>");
      var total_is_correct = true;      
      $.ajax({
        url: '/checkout/total',
        type: 'get',
        success: function(x) {
          if (parseFloat(x) != CABOOSE_ORDER_TOTAL)                      
            total_is_correct = false;           
        },
        async: false                  
      });      
      
      if (total_is_correct == false)
      {
        $('#message').html("<p class='note error'>It looks like the order total has changed since this page has refreshed. Please submit your order again after this page refreshes.");
        setTimeout(function() { window.location.reload(true); }, 3000);                
      }
      else
      {
        $('#message').html("<p class='loading'>Processing payment...</p>");
        $('form#payment').submit();
        $('#checkout-continue button').hide();
      }
    }
  };
  
  self.edit_payment_handler = function(event) {
    $('#checkout-confirm').hide();
    $('#checkout-payment').show();    
    $('#checkout-continue button').html("Continue");    
    self.is_confirm = false;    
  };
  
  //self.relay_handler = function(event) {
  //  alert('Relay handler');
  //  var iframe = $('#relay');
  //  var form   = $('#payment');
  //  var resp   = iframe.contents().find('#response');
  //  
  //  if (!resp.length || form.length)
  //  {
  //    alert('No response found.');
  //    return false;
  //  }
  //  
  //  resp = JSON.parse(resp.html());    
  //  if (resp.error)
  //    $('#message').html("<p class='note error'>" + resp.error + "</p>");
  //  else if (resp.success == true)
  //    window.location = '/checkout/thanks';                
  //};
  
  return self
}).call(Caboose.Store);

function relay_handler(resp)
{
  console.log('RELAY');
  console.log(resp);
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
  {
    $('#message').html("<p class='note error'>There was an error processing your payment.</p>");
    $('#checkout-continue button').show();
  }
}
