
var ShippingMethodController = function(params) { this.init(params); };

ShippingMethodController.prototype = {

  cc: false, // CheckoutController
  order_package_id: false,
    
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
  },
    
  print: function()
  {    
    var that = this;
    var div = $('<div/>');
    
    var sa = that.cc.order.shipping_address;
    var op = that.cc.order_package_for_id(that.order_package_id);
    console.log(op);
    var sm = op && op.shipping_method ? op.shipping_method : false;     
    
    if (!op)
    {
      //div.append($('<p/>').append("Please enter your shipping address first."));
      div.append($('<p/>').append($('<a/>').attr('href','#').html("Please enter your shipping address first.")
        .click(function() { $('html, body').animate({ scrollTop: $("#shipping_address_container").offset().top }, 2000); })
      ));
    }
    else if (!sm)
    {
      div.append($('<p/>').append("No shipping method selected."));
    }
    else if (that.cc.is_empty_address(sa))
    {
      div.append($('<p/>').append($('<a/>').attr('href','#').html("Please enter your shipping address first.")
        .click(function() { $('html, body').animate({ scrollTop: $("#shipping_address_container").offset().top }, 2000); })
      ));          
    }
    else
    {      
      div.append($('<p/>').append(sm.service_name + ' - $' + op.total))      
    }
            
    $('#order_package_' + that.order_package_id + '_shipping_method').empty().append(div);
  },
  
  edit: function()
  {
    var that = this;
    var div = $('<div/>').append($('<p/>').addClass('loading').html("Getting rates..."));
    var op = that.cc.order_package_for_id(that.order_package_id);
    
    $('#order_package_' + that.order_package_id + '_shipping_method').empty().append(div);
      
    var all_rates = false;
    $.ajax({
      url: '/checkout/shipping/json',
      type: 'get',          
      success: function(resp) { all_rates = resp; },
      async: false
    });
    
    var select = false;        
    if (all_rates.error)
    {
      //select = $('<p/>').append('Enter your shipping address to get shipping rates');
      select = $('<p/>').append($('<a/>').attr('href','#').html("Enter your shipping address to get shipping rates")
        .click(function() { $('html, body').animate({ scrollTop: $("#shipping_address_container").offset().top }, 2000); })
      );
    }
    else
    {
      select = $('<select/>').attr('id', 'order_package_' + that.order_package_id + '_shipping_method_id');
      select.append($('<option/>').val('').html('-- Shipping method --'));
      $.each(all_rates, function(i, h) {       
        if (h.order_package.id == that.order_package_id)
        {
          $.each(h.rates, function(j, h2) {
            var sm = h2.shipping_method;          
            var opt = $('<option/>').data('total', h2.total_price).val(sm.id).html(sm.service_name + ' - $' + h2.total_price);
            if (op.shipping_method_id == sm.id) opt.attr('selected', 'true');
            select.append(opt);
          });
        }
      });
      select.change(function(e) {
        var opt = $(this).find('option').filter(':selected');      
        that.update(opt.val(), opt.data('total')); 
      });
    }
    div = $('<div/>')
      .append($('<p/>').append(select))
      .append($('<div/>').attr('id', 'order_package_' + that.order_package_id + '_message'));                
    $('#order_package_' + that.order_package_id + '_shipping_method').empty().append(div);
  },
  
  update: function(shipping_method_id, total)
  {
    //console.log('shipping_method_id = ' + shipping_method_id);
    //console.log('total = ' + total);
    var that = this;
    $.ajax({
      url: '/checkout/shipping',
      type: 'put',
      data: {
        order_package_id: that.order_package_id,
        shipping_method_id: shipping_method_id,
        total: total
      },
      success: function(resp) {
        if (resp.error) $('#order_package_' + that.order_package_id + '_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) that.cc.refresh_and_print();        
      }
    });        
  }  
};
