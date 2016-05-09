
$.ajax_value = function(url) {
  var x = null;
  $.ajax({
    url: url,
    type: 'get',
    success: function(x2) { x = x2; },
    async: false                  
  });
  return x;
};

var StripeCheckoutController = function(params) { this.init(params); };

StripeCheckoutController.prototype = {

  container: 'payment',
  stripe_key: false,
  customer_id: false,
  card_brand: false,
  card_last4: false,
  order_total: false,
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    
    if (that.customer_id)    
      that.print_summary();
    else      
      that.print_form();
  },
  
  print_form: function()
  {
    var that = this;
    var form = $('<form/>')
      .attr('action', '')
      .attr('method', 'post')
      .attr('id', 'stripe_form')
      .addClass('stripe_form')
      .submit(function(e) { e.preventDefault(); that.submit_form(); return false; });
          
    form.append($('<div/>').addClass('card_number_container')                                        
      .append($('<input/>').attr('id', 'card_number').attr('type', 'tel').attr('autocomplete', 'off').attr('autocorrect', 'off').attr('spellcheck', 'off').attr('autocapitalize', 'off').attr('placeholder', 'Card number'))              
      .append($('<div/>').addClass('svg icon').css('width', '30px').css('height', '30px').html('<svg version="1.1" viewBox="0 0 30 30" width="30" height="30" focusable="false"><g fill-rule="evenodd"><path d="M2.00585866,0 C0.898053512,0 0,0.900176167 0,1.99201702 L0,9.00798298 C0,10.1081436 0.897060126,11 2.00585866,11 L11.9941413,11 C13.1019465,11 14,10.0998238 14,9.00798298 L14,1.99201702 C14,0.891856397 13.1029399,0 11.9941413,0 L2.00585866,0 Z M2.00247329,1 C1.44882258,1 1,1.4463114 1,1.99754465 L1,9.00245535 C1,9.55338405 1.45576096,10 2.00247329,10 L11.9975267,10 C12.5511774,10 13,9.5536886 13,9.00245535 L13,1.99754465 C13,1.44661595 12.544239,1 11.9975267,1 L2.00247329,1 Z M1,3 L1,5 L13,5 L13,3 L1,3 Z M11,8 L11,9 L12,9 L12,8 L11,8 Z M9,8 L9,9 L10,9 L10,8 L9,8 Z M9,8" style="fill:#3b6faa" transform="translate(8,10)"></g></svg>')));
    form.append($('<div/>').addClass('card_exp_container')      
      .append($('<input/>').attr('id', 'card_exp').attr('type', 'tel').attr('autocomplete', 'off').attr('autocorrect', 'off').attr('spellcheck', 'off').attr('autocapitalize', 'off').attr('placeholder', 'MM / YY').attr('x-autocompletetype', 'off').attr('autocompletetype', 'off'))      
      .append($('<div/>').addClass('svg icon').css('width', '30px').css('height', '30px').html('<svg version="1.1" viewBox="0 0 30 30" width="30" height="30" focusable="false"><g fill-rule="evenodd"><path d="M2.0085302,1 C0.899249601,1 0,1.90017617 0,2.99201702 L0,10.007983 C0,11.1081436 0.901950359,12 2.0085302,12 L9.9914698,12 C11.1007504,12 12,11.0998238 12,10.007983 L12,2.99201702 C12,1.8918564 11.0980496,1 9.9914698,1 L2.0085302,1 Z M1.99539757,4 C1.44565467,4 1,4.43788135 1,5.00292933 L1,9.99707067 C1,10.5509732 1.4556644,11 1.99539757,11 L10.0046024,11 C10.5543453,11 11,10.5621186 11,9.99707067 L11,5.00292933 C11,4.44902676 10.5443356,4 10.0046024,4 L1.99539757,4 Z M3,1 L3,2 L4,2 L4,1 L3,1 Z M8,1 L8,2 L9,2 L9,1 L8,1 Z M3,0 L3,1 L4,1 L4,0 L3,0 Z M8,0 L8,1 L9,1 L9,0 L8,0 Z M8,0" style="fill:#3b6faa" transform="translate(8,9)"></g></svg>')));
    form.append($('<div/>').addClass('card_cvc_container')
      .append($('<input>').attr('id', 'card_cvc').attr('type', 'tel').attr('autocomplete', 'off').attr('autocorrect', 'off').attr('spellcheck', 'off').attr('autocapitalize', 'off').attr('placeholder', 'CVC').attr('maxlength', '4'))      
      .append($('<div>').addClass('svg icon').css('width', '30px').css('height', '30px').html('<svg version="1.1" viewBox="0 0 30 30" width="30" height="30" focusable="false"><g fill-rule="evenodd"><path d="M8.8,4 C8.8,1.79086089 7.76640339,4.18628304e-07 5.5,0 C3.23359661,-4.1480896e-07 2.2,1.79086089 2.2,4 L3.2,4 C3.2,2.34314567 3.81102123,0.999999681 5.5,1 C7.18897877,1.00000032 7.80000001,2.34314567 7.80000001,4 L8.8,4 Z M1.99201702,4 C0.891856397,4 0,4.88670635 0,5.99810135 L0,10.0018986 C0,11.1054196 0.900176167,12 1.99201702,12 L9.00798298,12 C10.1081436,12 11,11.1132936 11,10.0018986 L11,5.99810135 C11,4.89458045 10.0998238,4 9.00798298,4 L1.99201702,4 Z M1.99754465,5 C1.44661595,5 1,5.45097518 1,5.99077797 L1,10.009222 C1,10.5564136 1.4463114,11 1.99754465,11 L9.00245535,11 C9.55338405,11 10,10.5490248 10,10.009222 L10,5.99077797 C10,5.44358641 9.5536886,5 9.00245535,5 L1.99754465,5 Z M1.99754465,5" style="fill:#3b6faa" transform="translate(9,9)"></g></svg>')));
    form.append($('<div/>').attr('id', 'payment_message'))
    form.append($('<input/>').attr('type', 'submit').attr('id', 'save_payment_btn').val('Save Payment Method'));
      
    $('#'+that.container).empty().append(form);
            
    $('#stripe_form .card_number_container input').payment('formatCardNumber');
    $('#stripe_form .card_exp_container    input').payment('formatCardExpiry');
    $('#stripe_form .card_cvc_container    input').payment('formatCardCVC');
    
    $('#checkout-continue').empty().append($('<a/>').attr('href', '/').html('return to the store'));  
  },
  
  print_summary: function()
  {
    var that = this;
    $('#'+that.container).empty()
      .append($('<p/>').append(that.card_brand + ' ending in ' + that.card_last4))
      .append($('<p/>').append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
        e.preventDefault();
        that.print_form();        
      })));
    $('#checkout-continue').empty()
      .append($('<button/>').addClass('blue').html("Continue to Order Confirmation").click(function(e) { window.location = '/checkout/confirm'; }))
      .append($('<em/>').html('or')).append($('<a/>').attr('href', '/').html('return to the store'));
  },
    
  
  
  submit_form: function() 
  {
    var that = this;                
    var info = {
      number: $('#card_number').val(),
      exp:    $('#card_exp').val(),
      cvc:    $('#card_cvc').val()            
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
            that.print_summary();
          }
        });
      }
    });  
  },
  
  submit_order: function()
  {
    var that = this;
    
    $('#message').html("<p class='loading'>Verifying order total...</p>");
    var t = $.ajax_value('/checkout/total');    
    if (parseFloat(t) != total_is_correct)
    {
      $('#message').html("<p class='note error'>It looks like the order total has changed since this was loaded. Please submit your order again after this page refreshes.");
      setTimeout(function() { window.location.reload(true); }, 3000);
      return;
    }
    
    $('#message').html("<p class='loading'>Processing payment...</p>");
    $.ajax({
      url: '/checkout/stripe-process',
      type: 'post',
      success: function(resp) {
        total_is_correct = parseFloat(x) == that.order_total; 
      },
      async: false                  
    });
    $('form#payment').submit();
    $('#checkout-continue button').hide();    
  }            
};

Caboose.Store.Modules.CheckoutPayment = (function() {

  self = {
    is_confirm: false
  };    
  
  self.initialize = function() {            
    self.bind_event_handlers();
  };
    
  self.bind_event_handlers = function() {        
    $('#checkout-continue button').click(self.continue_handler);    
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
        
  return self
}).call(Caboose.Store);

