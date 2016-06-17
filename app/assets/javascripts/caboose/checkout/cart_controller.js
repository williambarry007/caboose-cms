
var CartController = function(params) { this.init(params); };

CartController.prototype = {

  cc: false, // CheckoutController
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];    
  },
  
  update_totals: function()
  {
    var that = this;
    var x = parseFloat(that.cc.invoice.shipping) + parseFloat(that.cc.invoice.handling);
            
    $('#totals_subtotal').html('$' + parseFloat(that.cc.invoice.subtotal).toFixed(2));    
    $('#totals_tax').html('$' + parseFloat(that.cc.invoice.tax).toFixed(2));
    $('#totals_shipping').html('$' + x.toFixed(2));    
    $('#totals_gift_wrap').html('$' + parseFloat(that.cc.invoice.gift_wrap).toFixed(2));      
    $('#totals_custom_discount').html('$' + parseFloat(that.cc.invoice.custom_discount).toFixed(2));    
    $('#totals_total').html('$' + parseFloat(that.cc.invoice.total).toFixed(2));
    
    $.each(that.cc.invoice.discounts, function(i, d) {                        
      $('#totals_discount_' + i).html('-$' + parseFloat(d.amount).toFixed(2));                
    });                                
  },
    
  print: function(confirm)
  {
    var that = this;
    if (!that.cc.invoice || !that.cc.invoice.line_items || that.cc.invoice.line_items.length == 0)
    {
      $('#cart').html("<p class='note'>You don't have any items in your shopping cart.  <a href='/products'>Continue shopping.</a></p>");
      return;
    }

    var tbody = $('<tbody/>');                      
    $.each(that.cc.invoice.invoice_packages, function(j, op) {      
      that.cart_line_items(tbody, op, j, confirm);      
    });
    that.cart_line_items(tbody, false);    
    that.cart_totals(tbody, confirm);
    $('#cart').empty().append($('<table/>').append(tbody));
     
    // Make anything editable that needs to be
    if (!confirm)
    {
      $.each(that.cc.invoice.line_items, function(i, li) {
        var p = li.variant.product;
        var attribs = [];        
        attribs.push({ name: 'quantity', nice_name: 'Qty', type: 'text', value: li.quantity, width: 50, fixed_placeholder: false, after_update: function() { that.cc.refresh_cart(); }});
        if (that.cc.show_gift_options)
        {
          attribs.push({ name: 'is_gift'      , nice_name: 'This item is a gift'  , type: 'checkbox' , value: li.is_gift      , width: 40 ,               fixed_placeholder: false, after_update: function() { that.toggle_gift_options(this.li_id); }, li_id: li.id });
          attribs.push({ name: 'hide_prices'  , nice_name: 'Hide prices'          , type: 'checkbox' , value: li.hide_prices  , width: 40 ,               fixed_placeholder: false, after_update: function() { } });
          if (p.allow_gift_wrap == true)
            attribs.push({ name: 'gift_wrap'  , nice_name: 'Gift wrap'            , type: 'checkbox' , value: li.gift_wrap    , width: 40 ,               fixed_placeholder: false, after_update: function() { that.cc.refresh_cart(); } });
          attribs.push({ name: 'gift_message' , nice_name: 'Gift message'         , type: 'textarea' , value: li.gift_message , width: 400 , height: 75 , fixed_placeholder: false, after_update: function() { } });
        }        
        m = new ModelBinder({
          name: 'LineItem',
          id: li.id,
          update_url: '/cart/' + li.id,
          authenticity_token: that.cc.authenticity_token,    
          attributes: attribs
        });
      });            
    }
    
    $.each(that.cc.invoice.invoice_packages, function(i, op) {
      if (confirm)
        op.shipping_method_controller.print();
      else
        op.shipping_method_controller.edit();
    });    
  },
  
  cart_line_items: function(tbody, op, j, confirm)
  {    
    var that = this;
    
    line_items = [];              
    $.each(that.cc.invoice.line_items, function(i, li) {
      if ((op && li.invoice_package_id == op.id) || (!op && !li.invoice_package_id))          
        line_items[line_items.length] = li;
    });
    
    if (line_items.length > 0)
    {      
      tbody
        .append($('<tr/>').addClass('invoice_package_header')
          .append($('<td/>')            
            .attr('colspan', '4')
            .append('<h3>Package ' + (j+1) + '</h3>')
            .append($('<div/>').attr('id', 'invoice_package_' + op.id + '_shipping_method'))
          )
        )
        .append($('<tr/>')
          .append($('<th/>').html('Item'))        
          .append($('<th/>').html('Price'))
          .append($('<th/>').html('Quantity'))        
          .append($('<th/>').html('Subtotal'))
        );
    }
    
    $.each(line_items, function(i, li) {      
      var v = li.variant;
      var p = v.product;      
      var img = v.product_images && v.product_images.length > 0 ? v.product_images[0] : (p.product_images && p.product_images.length > 0 ? p.product_images[0] : false);            
      img = img ? $('<img/>').attr('src', img.urls.tiny) : '&nbsp;';                     
      var item = $('<td/>').attr('valign', 'top')
        .append(img)
        .append('<br/>' + p.title + '<br/>' + v.title);        
              
      if (that.cc.show_gift_options)
      {
        if (!confirm)
        {
          var gift_options_tbody = $('<tbody/>');
          if (li.variant.product.allow_gift_wrap == true)
            gift_options_tbody.append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_gift_wrap'  ))).append($('<td/>').append("Gift wrap ($" + parseFloat(li.variant.product.gift_wrap_price).toFixed(2) + ')')));
          gift_options_tbody.append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_hide_prices'))).append($('<td/>').append("Hide prices in receipt")));
          gift_options_tbody.append($('<tr/>').append($('<td/>').attr('colspan', '2').append('Gift message<br/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_gift_message'))));
                          
          item.append($('<div/>').addClass('gift_options_checkbox')
            .append($('<table/>').append($('<tbody/>').append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_is_gift'  ))).append($('<td/>').append("This item is a gift"))))))
            .append($('<div/>').attr('id', 'gift_options_' + li.id).addClass('gift_options').css('display', li.is_gift ? 'block' : 'none').append($('<table/>').append(gift_options_tbody)));
        }
        else
        {
          if (li.is_gift)
          {
            item.append($('<ul/>').addClass('gift_options')
              .append($('<li/>').html("This item is a gift."))
              .append($('<li/>').html("Gift wrap? " + (li.gift_wrap ? 'Yes' : 'No')))
              .append($('<li/>').html("Hide prices? " + (li.hide_prices ? 'Yes' : 'No')))
              .append($('<li/>').html("Gift message: " + (li.gift_message.length > 0 ? li.gift_message : '[Empty]')))
            );
          }
          else 
            item.append($('<p/>').append("This item is not a gift."));                              
        }
      }
      
      var qty = $('<td/>').css('text-align', 'right');
      if (!confirm) qty.append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity'));
      else          qty.append(li.quantity);
      if (!confirm) qty.append($('<div/>').append($('<a/>').attr('href','#').html('Remove').click(function(e) { e.preventDefault(); that.remove_item(li.id); })));
      
      var tr = $('<tr/>').data('id', li.id);
      //if (i == 0)     
      //  tr.append($('<td/>').attr('valign', 'top').attr('rowspan', line_items.length).attr('id', 'invoice_package_' + op.id + '_shipping_method'));
      
      tr.append(item)                                                                        
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(li.unit_price).toFixed(2)))
        .append(qty)
        .append($('<td/>').css('text-align', 'right').html('$' + (li.unit_price * li.quantity).toFixed(2)));      
      tbody.append(tr);                    
    });                                                                                                                    
  },
  
  cart_totals: function(tbody, confirm)
  {
    var that = this;
    
    tbody.append($('<tr/>')
      .append($('<th/>').addClass('invoice_totals_header').attr('colspan', '4').html('<h3>Invoice Totals</h3>')));
    tbody.append($('<tr/>')        
      .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Subtotal'))
      .append($('<td/>').css('text-align', 'right').attr('id', 'totals_subtotal').html('$' + parseFloat(that.cc.invoice.subtotal).toFixed(2)))
    );
    if (that.cc.show_tax)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Tax'))
        .append($('<td/>').css('text-align', 'right').attr('id', 'totals_tax').html('$' + parseFloat(that.cc.invoice.tax).toFixed(2)))
      );
    }
    if (that.cc.show_shipping)
    {
      var x = parseFloat(that.cc.invoice.shipping) + parseFloat(that.cc.invoice.handling);
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Shipping &amp; Handling'))
        .append($('<td/>').css('text-align', 'right').attr('id', 'totals_shipping').html('$' + x.toFixed(2)))
      );
    }
    if (that.cc.show_gift_wrap && that.cc.invoice.gift_wrap > 0)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Gift Wrapping'))
        .append($('<td/>').css('text-align', 'right').attr('id', 'totals_gift_wrap').html('$' + parseFloat(that.cc.invoice.gift_wrap).toFixed(2)))
      );
    }    
    if (that.cc.show_discounts && that.cc.invoice.discounts.length > 0)
    {
      $.each(that.cc.invoice.discounts, function(i, d) {
          
        var gctd = $('<td/>').css('text-align', 'right').attr('colspan', 3);
        if (!confirm)
          gctd.append($('<a/>').data('discount_id', d.id).attr('href', '#').html('(remove)').click(function(e) { e.preventDefault(); that.remove_discount($(this).data('discount_id')); })).append(' ');
        gctd.append('Gift Card (' + d.gift_card.code + ')');
            
        tbody.append($('<tr/>')        
          .append(gctd)
          .append($('<td/>').css('text-align', 'right').attr('id', 'totals_discount_' + i).html('-$' + parseFloat(d.amount).toFixed(2)))
        );          
      });
      if (that.cc.invoice.custom_discount && that.cc.invoice.custom_discount > 0)
      {
        tbody.append($('<tr/>')
          .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Discount'))
          .append($('<td/>').css('text-align', 'right').attr('id', 'totals_custom_discount').html('$' + parseFloat(that.cc.invoice.custom_discount).toFixed(2)))
        );
      }
    }
    if (that.cc.show_total)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 3).html('Total'))
        .append($('<td/>').css('text-align', 'right').attr('id', 'totals_total').html('$' + parseFloat(that.cc.invoice.total).toFixed(2)))
      );            
    }
  },
          
  toggle_gift_options: function(li_id)
  {
    var el = $('#gift_options_' + li_id);
    if (el.is(':visible'))
      el.slideUp();
    else
      el.slideDown();    
  },
  
  remove_item: function(li_id)
  {
    var that = this;
    $.ajax({
     url: '/cart/' + li_id,
     type: 'delete',
     success: function(resp) { that.cc.refresh_and_print(); }
    });    
  },
  
  remove_discount: function(discount_id)
  {
    var that = this;
    $.ajax({
     url: '/cart/discounts/' + discount_id,
     type: 'delete',
     success: function(resp) { that.cc.refresh_and_print(); }
    });    
  }    
};
