
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

var CheckoutController = function(params) { this.init(params); };

CheckoutController.prototype = {

  container: 'checkout',
  authenticity_token: false,
  pp_name: 'stripe',
  
  gift_cards_controller: false,
  shipping_address_controller: false,
  shipping_method_controller: false,  
  payment_method_controller: false,
  cart_controller: false,
    
  // Cart options
  allow_edit_line_items: true,
  allow_edit_gift_cards: true,
  show_total: true,
  show_shipping: true,
  show_tax: true,
  show_gift_wrap: true,
  show_discounts: true,
  show_gift_options: true,
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
        
    that.gift_cards_controller       = new GiftCardsController({           cc: that });
    that.shipping_address_controller = new ShippingAddressController({     cc: that });
    if (that.pp_name == 'stripe')       that.payment_method_controller = new StripePaymentMethodController({ cc: that });
    //else if (that.pp_name == 'authnet') that.payment_method_controller = new AuthnetPaymentMethodController({ cc: that });
    else alert("Payment process \"" + that.pp_name + "\" is not supported.");
    that.cart_controller             = new CartController({                cc: that });

    that.refresh_and_print();    
  },
  
  refresh_and_print: function()
  {
    var that = this;
    that.refresh(function() { that.print(); });
  },
  
  refresh_totals: function()
  {
    var that = this;
    that.refresh(function() { that.cart_controller.update_totals(); });
  },
  
  refresh_cart: function()
  {
    var that = this;
    that.refresh(function() { that.cart_controller.print(); });
  },
      
  refresh: function(after)
  {
    var that = this;
    $.ajax({
      url: '/checkout/json',
      type: 'get',          
      success: function(resp) {
        that.invoice = resp;        
        $.each(that.invoice.invoice_packages, function(i, op) {
          that.invoice.invoice_packages[i].shipping_method_controller = new ShippingMethodController({ cc: that, invoice_package_id: op.id });
        });                
        if (!that.invoice.shipping_address) that.invoice.shipping_address = that.empty_address();
        //if (!that.invoice.billing_address)  that.invoice.billing_address  = that.empty_address();
        if (after) after();            
      }
    });    
  },
  
  empty_address: function()
  {
    return {
      first_name: '',
      last_name: '',      
      address1: '',
      address2: '',
      company: '',
      city: '',
      state: '',      
      zip: ''
    };
  },
  
  is_empty_address: function(a)
  {    
    if (!a || a == null) return true;
    return 
         (a.first_name == null || a.first_name.length == 0)
      && (a.last_name  == null || a.last_name.length  == 0)      
      && (a.address1   == null || a.address1.length   == 0)
      && (a.address2   == null || a.address2.length   == 0)
      && (a.company    == null || a.company.length    == 0)
      && (a.city       == null || a.city.length       == 0)
      && (a.state      == null || a.state.length      == 0)      
      && (a.zip        == null || a.zip.length        == 0);
  },
  
  /*****************************************************************************
  General print
  *****************************************************************************/
    
  print: function(confirm)
  {
    var that = this;
    var div = $('<div/>')            
      .append($('<h2/>').html(confirm ? 'Confirm Invoice' : 'Checkout'))
      .append($('<section/>').attr('id', 'shipping_address_container'))
      .append($('<section/>').attr('id', 'cart'))
      .append($('<section/>').attr('id', 'gift_cards_container'))      
      .append($('<section/>').attr('id', 'payment_method_container'))      
      .append($('<div/>').attr('id', 'message'));      
    $('#'+that.container).empty().append(div);
    
    if (confirm)
    {      
      that.gift_cards_controller.print();
      that.shipping_address_controller.print();    
      that.payment_method_controller.print();      
      that.cart_controller.print(confirm);
      that.print_confirm_message();
    }
    else
    {
      that.gift_cards_controller.edit();
      that.shipping_address_controller.edit();    
      that.payment_method_controller.print();                
      that.cart_controller.print();      
      that.print_ready_message();
    }
  },
  
  print_ready_message: function()
  {
    var that = this;
    var ready = true;
    if (!that.shipping_address_controller.ready()) ready = false;            
    if (!that.payment_method_controller.ready())   ready = false;

    if (ready)
    {
      $('#message').empty().append($('<p/>').append($('<input/>').attr('type', 'button').val('Continue to Confirmation').click(function(e) {
        that.print(true);          
      })));
    }
    else
    {
      $('#message').empty().append($('<p/>').addClass('note warning').append("Please complete all the fields."));
    }
  },
  
  print_confirm_message: function()
  {
    var that = this;
    var ready = true;
    if (!that.shipping_address_controller.ready()) ready = false;            
    if (!that.payment_method_controller.ready())   ready = false;

    if (!ready)
    {
      that.refresh_and_print();      
      return;
    }
    
    $('#message').empty().append($('<p/>')
      .append($('<input/>').attr('type', 'button').val('Make Changes' ).click(function(e) { that.print(); })).append(' ')
      .append($('<input/>').attr('type', 'button').val('Confirm Invoice').click(function(e) { that.confirm_invoice(); }))
    );    
  },

  /*****************************************************************************
  Invoice confirmation
  *****************************************************************************/    
  
  confirm_invoice: function(t)
  {
    var that = this;
    
    $('#message').html("<p class='loading'>Verifying invoice total...</p>");    
    var t = $.ajax_value('/checkout/total');    
    if (parseFloat(t) != that.invoice.total)
    {
      $('#message').html("<p class='note error'>It looks like the invoice total has changed since this was loaded. Please submit your invoice again after this page refreshes.</p>");
      setTimeout(function() { window.location.reload(true); }, 3000);
      return;
    }
    
    $('#message').html("<p class='loading'>Processing payment...</p>");
    $.ajax({
      url: '/checkout/confirm',
      type: 'post',
      success: function(resp) {
        if (resp.success) window.location = '/checkout/thanks';
        if (resp.error)
        {        
          $('#message').empty()
            .append($('<p/>').addClass('note error').append(resp.error))
            .append($('<p/>')
              .append($('<input/>').attr('type', 'button').val('Make Changes' ).click(function(e) { that.print(); })).append(' ')
              .append($('<input/>').attr('type', 'button').val('Confirm Invoice').click(function(e) { that.confirm_invoice(); }))
            );
        }
      }                        
    });        
  },
    
  /*****************************************************************************
  Utility methods
  *****************************************************************************/
  
  invoice_package_for_id: function(invoice_package_id)
  {
    var that = this;
    var op = false;
    $.each(that.invoice.invoice_packages, function(i, op2) {
      if (op2.id == invoice_package_id)
      {
        op = op2;
        return false;
      }
    });
    return op;
  },
  
  line_item_for_id: function(li_id)
  {
    var that = this;
    var li = false;
    $.each(that.invoice.line_items, function(i, li2) {
      if (li2.id == li_id)
      {
        li = li2;
        return false;
      }
    });
    return li;
  },
};
