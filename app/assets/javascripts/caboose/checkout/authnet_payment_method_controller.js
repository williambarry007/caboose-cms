
var AuthnetPaymentMethodController = function(params) { this.init(params); };

AuthnetPaymentMethodController.prototype = {

  container: 'payment_method_container',
  customer_profile_id: false,
  payment_profile_id: false,  
  card_brand: false,
  card_last4: false,
  card_name: false,
  card_zip: false,
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];        
  },
  
  refresh: function(after)
  {
    var that = this;
    $.ajax({
      url: '/checkout/authnet/json',
      type: 'get',          
      success: function(resp) {        
        that.stripe_key   = resp.stripe_key;
        that.customer_id  = resp.customer_id;
        that.card_brand   = resp.card_brand;
        that.card_last4   = resp.card_last4;
        that.cc.print_ready_message();
        if (after) after();            
      }
    });    
  },
  
  print: function()
  {
    var that = this;
    //if (!that.stripe_key)
    //{
    //  that.refresh(function() { that.print(); });
    //  return;
    //}    
    var msg = that.card_brand && that.card_last4 ? that.card_brand + ' ending in ' + that.card_last4 : 'You have no card on file.';    
    var div = $('<div/>')
      .append($('<h3/>').html('Payment Method'))
      .append($('<p/>')
        .append(msg).append(' ')
        .append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
          e.preventDefault();
          that.edit();        
        })
      ));      
    $('#'+that.container).empty().append(div);    
  },

  edit: function()
  {
    caboose_modal_url('/checkout/authnet');          
  },
  
  update: function() 
  {
    var that = this;                
    var info = {
      number:      $('#card_number').val(),
      exp:         $('#card_exp').val(),
      cvc:         $('#card_cvc').val(),
      name:        $('card_name').val(),
      address_zip: $('card_zip').val()
    };
    var exp = info.exp.split('/');
    var m = exp.length > 0 ? exp[0] : '';
    var y = exp.length > 1 ? exp[1] : '';        
    var error = false;
    if (!$.payment.validateCardNumber(info.number)) error = "Invalid card number.";
    if (!$.payment.validateCardExpiry(m, y))        error = "Invalid expiration date.";
    if (!$.payment.validateCardCVC(info.cvc))       error = "Invalid CVC.";
    if (error) { $('#payment_message').html("<p class='note error'>" + error + "</p>"); return; }
        
    $('#save_payment_btn').attr('disabled', 'true').val('Saving card...');    
    Stripe.setPublishableKey(that.stripe_key);    
    Stripe.card.createToken(info, function(status, resp) {
      if (resp.error)
      {
        $('#save_payment_btn').attr('disabled', 'false').val('Save Payment Method');    
        $('#payment_message').html("<p class='note error'>" + resp.error.message + "</p>");
      }      
      else
      {
        that.card_brand = resp.card.brand;
        that.card_last4 = resp.card.last4;                                
        $.ajax({
          url: '/checkout/stripe-details',
          type: 'put',
          data: { token: resp.id, card: resp.card },
          success: function(resp2) {
            if (resp2.success)
            {
              that.customer_id = resp.customer_id;
              that.print();
            }
            if (resp2.error) $('#payment_message').html("<p class='note error'>" + resp2.error + "</p>");
          }
        });
      }
    });  
  },
  
  ready: function()
  {
    var that = this;
    if (!that.customer_id ) return false;
    if (!that.card_brand  ) return false;
    if (!that.card_last4  ) return false;
    return true;
  }
};
