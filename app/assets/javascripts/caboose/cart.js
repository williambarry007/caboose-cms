
Cart = function(params) { this.init(params); };

Cart.prototype = {
  
  order: false,  
  allow_edit_line_items: true,
  allow_edit_gift_cards: true,
  show_total: true,
  show_shipping: true,
  show_tax: true,
  show_discounts: true,
    
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
        that.order = resp;
        $('#message').empty();
        that.print();
      }        
    });    
  },
  
  print: function()
  {
    var that = this;
    if (!this.order || !this.order.line_items || this.order.line_items.length == 0)
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
                
    $.each(this.order.line_items, function(i, li) {      
      var v = li.variant;
      var p = v.product;      
      var img = v.product_images && v.product_images.length > 0 ? v.product_images[0] : (p.product_images && p.product_images.length > 0 ? p.product_images[0] : false);            
      img = img ? $('<img/>').attr('src', img.urls.tiny) : '&nbsp;';
         
      var item = $('<td/>').attr('valign', 'top').append(p.title + '<br/>' + v.title);
      if (that.allow_edit_line_items == true)
        item.append('<br/>').append($('<a/>').attr('href','#').html('Remove').click(function(e) { e.preventDefault(); that.remove_item(li.id); }));
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
      .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.subtotal).toFixed(2)))
    );
    if (that.show_shipping)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Shipping &amp; Handling'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.shipping + that.order.handling).toFixed(2)))
      );
    }
    if (that.show_tax)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Tax'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.tax).toFixed(2)))
      );
    }
    if (that.show_discounts && that.order.discounts.length > 0)
    {
      $.each(that.order.discounts, function(i, d) {
          
        var gctd = $('<td/>').css('text-align', 'right').attr('colspan', 4);
        if (that.allow_edit_gift_cards)
          gctd.append($('<a/>').data('discount_id', d.id).attr('href', '#').html('(remove)').click(function(e) { e.preventDefault(); that.remove_discount($(this).data('discount_id')); })).append(' ');
        gctd.append('Gift Card (' + d.gift_card.code + ')');
            
        tbody.append($('<tr/>')        
          .append(gctd)
          .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(d.amount).toFixed(2)))
        );          
      });
      if (that.order.custom_discount && that.order.custom_discount > 0)
      {
        tbody.append($('<tr/>')        
          .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Discount'))
          .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.custom_discount).toFixed(2)))
        );
      }
    }
    if (that.show_total)
    {
      tbody.append($('<tr/>')        
        .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Total'))
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.total).toFixed(2)))
      );            
    }            
    $('#cart').empty().append($('<table/>').append(tbody));
          
    if (that.allow_edit_line_items)
    {
      $.each(this.order.line_items, function(i, li) {      
        m = new ModelBinder({
          name: 'LineItem',
          id: li.id,
          update_url: '/cart/' + li.id,
          authenticity_token: that.form_authenticity_token,    
          attributes: [
            { name: 'quantity', nice_name: 'Qty', type: 'text', value: li.quantity, width: 50, fixed_placeholder: false, after_update: function() { that.refresh(); } }                
          ]
        }); 
      });
    }        
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
