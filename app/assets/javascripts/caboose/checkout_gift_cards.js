
Caboose.Store.Modules.CheckoutGiftCards = (function() {
    
  self = {};
   
  self.initialize = function() {                
    self.bind_event_handlers();
  };
  
  self.bind_event_handlers = function() {
    $("#checkout-continue button").click(self.continue_click_handler);
    $('#redeem_code_btn').click(self.redeem_gift_card_handler);    
  };

  self.redeem_gift_card_handler = function(event) 
  {
    event.preventDefault();
    self.redeem_gift_card();
  };
  
  self.redeem_gift_card = function()
  {
    var code = $('#code').val();    
    $('#message').html("<p class'loading'>Redeeming code...</p>");
    $.ajax({
      url: '/cart/gift-cards',
      type: 'post',
      data: { code: code },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success)
        {
          $('#code').val('');
          cart.refresh();
        }        
      }        
    });    
  };
  
  self.continue_click_handler = function(event) {
    event.preventDefault();    
    window.location = '/checkout/payment';
    return false;
  };
    
  return self
}).call(Caboose.Store);
