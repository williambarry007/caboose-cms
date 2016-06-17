
Cart = function(params) { this.init(params); };

Cart.prototype = {
  
  invoice: false,  
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
    for (var i in params)
      this[i] = params[i];
    this.refresh();    
  },
  
  refresh: function()
  {
    var that = this;
    $('#message').html("<p class='loading'>Getting cart...</p>");
    $.ajax({
      url: '/cart/items',
      success: function(resp) {
        that.invoice = resp;
        $('#message').empty();
        that.print();
      }        
    });    
  },
  
  print: function()
  {
    var that = this;
    if (!this.invoice || !this.invoice.line_items || this.invoice.line_items.length == 0)
    {
      $('#cart').html("<p class='note'>You don't have any items in your shopping cart.  <a href='/products'>Continue shopping.</a></p>");
      return;
    }

    var tbody = $('<tbody/>')
      .append($('<tr/>')              
        .append($('<th/>').attr('colspan', '2').html('Item'))        
        .append($('<th/>').html('Unit Price'))
        .append($('<th/>').html('Quantity'))        
        .append($('<th/>').html('Subtotal'))
      );
                
    $.each(this.invoice.line_items, function(i, li) {      
      var v = li.variant;
      var p = v.product;      
      var img = v.product_images && v.product_images.length > 0 ? v.product_images[0] : (p.product_images && p.product_images.length > 0 ? p.product_images[0] : false);            
      img = img ? $('<img/>').attr('src', img.urls.tiny) : '&nbsp;';
         
      var item = $('<td/>').attr('valign', 'top').append(p.title + '<br/>' + v.title);
      if (that.allow_edit_line_items == true)
        item.append($('<div/>').append($('<a/>').attr('href','#').html('Remove').click(function(e) { e.preventDefault(); that.remove_item(li.id); })));
      if (that.show_gift_options)
      {
        if (that.allow_edit_line_items == true)
        {
          var gift_options_tbody = $('<tbody/>');
          if (li.variant.product.allow_gift_wrap == true)
            gift_options_tbody.append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_gift_wrap'  ))).append($('<td/>').append("Gift wrap ($" + parseFloat(li.variant.product.gift_wrap_price).toFixed(2) + ')')));
          gift_options_tbody.append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_hide_prices'))).append($('<td/>').append("Hide prices in receipt")));
          gift_options_tbody.append($('<tr/>').append($('<td/>').attr('colspan', '2').append('Gift message<br/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_gift_message'))));
                          
          item
            .append($('<div/>').addClass('gift_options_checkbox')
              .append($('<table/>')
                .append($('<tbody/>')
                  .append($('<tr/>').append($('<td/>').addClass('checkbox').append($('<div/>').attr('id', 'lineitem_' + li.id + '_is_gift'  ))).append($('<td/>').append("This item is a gift")))              
                )
              )
            )
            .append($('<div/>').attr('id', 'gift_options_' + li.id).addClass('gift_options').css('display', li.is_gift ? 'block' : 'none')
              .append($('<table/>').append(gift_options_tbody))
            );
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
            item.append("This item is not a gift.")                              
        }
      }
      
      var qty = $('<td/>').css('text-align', 'right');
      if (that.allow_edit_line_items == true)
        qty.append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity'));
      else
        qty.append(li.quantity);
              
      tbody.append($('<tr/>').data('id', li.id)            
        .append($('<td/>').attr('valign', 'top').append(img))
        .append(item)                                                                        
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(li.unit_price).toFixed(2)))
        .append(qty)
        .append($('<td/>').css('text-align', 'right').html('$' + (li.unit_price * li.quantity).toFixed(2)))
      );      
    });
    tbody.append($('<tr/>')        
      .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Subtotal'))
      .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.invoice.subtotal).toFixed(2)))
    );
    if (that.show_tax)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Tax'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.invoice.tax).toFixed(2)))
      );
    }
    if (that.show_shipping)
    {
      var x = parseFloat(that.invoice.shipping) + parseFloat(that.invoice.handling);
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Shipping &amp; Handling'))
        .append($('<td/>').css('text-align', 'right').html('$' + x.toFixed(2)))
      );
    }
    if (that.show_gift_wrap && that.invoice.gift_wrap > 0)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Gift Wrapping'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.invoice.gift_wrap).toFixed(2)))
      );
    }    
    if (that.show_discounts && that.invoice.discounts.length > 0)
    {
      $.each(that.invoice.discounts, function(i, d) {
          
        var gctd = $('<td/>').css('text-align', 'right').attr('colspan', 4);
        if (that.allow_edit_gift_cards)
          gctd.append($('<a/>').data('discount_id', d.id).attr('href', '#').html('(remove)').click(function(e) { e.preventDefault(); that.remove_discount($(this).data('discount_id')); })).append(' ');
        gctd.append('Gift Card (' + d.gift_card.code + ')');
            
        tbody.append($('<tr/>')        
          .append(gctd)
          .append($('<td/>').css('text-align', 'right').html('-$' + parseFloat(d.amount).toFixed(2)))
        );          
      });
      if (that.invoice.custom_discount && that.invoice.custom_discount > 0)
      {
        tbody.append($('<tr/>')
          .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Discount'))
          .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.invoice.custom_discount).toFixed(2)))
        );
      }
    }
    if (that.show_total)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Total'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.invoice.total).toFixed(2)))
      );            
    }            
    $('#cart').empty().append($('<table/>').append(tbody));
     
    // Make anything editable that needs to be
    if (that.allow_edit_line_items)
    {
      $.each(this.invoice.line_items, function(i, li) {
        var p = li.variant.product;
        var attribs = [];        
        attribs.push({ name: 'quantity', nice_name: 'Qty', type: 'text', value: li.quantity, width: 50, fixed_placeholder: false, after_update: function() { that.refresh(); } });
        if (that.show_gift_options)
        {
          attribs.push({ name: 'is_gift'      , nice_name: 'This item is a gift'  , type: 'checkbox' , value: li.is_gift      , width: 40 ,               fixed_placeholder: false, after_update: function() { that.toggle_gift_options(this.li_id); }, li_id: li.id });
          attribs.push({ name: 'hide_prices'  , nice_name: 'Hide prices'          , type: 'checkbox' , value: li.hide_prices  , width: 40 ,               fixed_placeholder: false, after_update: function() { } });
          if (p.allow_gift_wrap == true)
            attribs.push({ name: 'gift_wrap'  , nice_name: 'Gift wrap'            , type: 'checkbox' , value: li.gift_wrap    , width: 40 ,               fixed_placeholder: false, after_update: function() { that.refresh(); } });        
          attribs.push({ name: 'gift_message' , nice_name: 'Gift message'         , type: 'textarea' , value: li.gift_message , width: 400 , height: 75 , fixed_placeholder: false, after_update: function() { } });                        
        }        
        m = new ModelBinder({
          name: 'LineItem',
          id: li.id,
          update_url: '/cart/' + li.id,
          authenticity_token: that.form_authenticity_token,    
          attributes: attribs
        });
      });
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
     success: function(resp) { that.refresh(); }
    });    
  },
  
  remove_discount: function(discount_id)
  {
    var that = this;
    $.ajax({
     url: '/cart/discounts/' + discount_id,
     type: 'delete',
     success: function(resp) { that.refresh(); }
    });    
  }
  
};
