
Cart = function(params) { this.init(params); };

Cart.prototype = {
  
  order: false,
  
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
        .append($('<th/>').html('&nbsp'))
        .append($('<th/>').html('Item'))
        .append($('<th/>').html('Unit Price'))
        .append($('<th/>').html('Quantity'))        
        .append($('<th/>').html('Subtotal'))
      );
                
    $.each(this.order.line_items, function(i, li) {      
      var v = li.variant;
      var p = v.product;      
      var img = v.images ? v.images[0] : (p.featured_image ? p.featured_image : false);      
      img = img ? $('<img/>').attr('src', img.urls.tiny) : '&nbsp;';
            
      tbody.append($('<tr/>')
        .append($('<td/>').attr('valign', 'top').append(img))
        .append($('<td/>').attr('valign', 'top')
          .append(v.title).append('<br/>')
          .append($('<a/>').attr('href','#').html('Remove').click(function(e) { e.preventDefault(); that.remove_item(li.id); }))          
        )                                  
        .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(v.price).toFixed(2)))
        .append($('<td/>').css('text-align', 'right').append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity')))
        .append($('<td/>').css('text-align', 'right').html('$' + (v.price * li.quantity).toFixed(2)))
      );
    });
    tbody.append($('<tr/>')
      .append($('<td/>').css('text-align', 'right').attr('colspan', 4).html('Subtotal'))
      .append($('<td/>').css('text-align', 'right').html('$' + parseFloat(that.order.subtotal).toFixed(2)))
    );
    $('#cart').empty()
      .append($('<table/>').append(tbody))
      .append($('<p/>').addClass('controls')
        .append($('<input/>').attr('type', 'button').val('Continue Shopping').click(function() { window.location = '/products'; }))        
        .append(' ')
        .append($('<input/>').attr('type', 'button').val('Checkout').click(function() { window.location = '/checkout'; }))        
      );
      
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
  },
  
  remove_item: function(li_id)
  {
    var that = this;
    $.ajax({
     url: '/cart/' + li_id,
     type: 'delete',
     success: function(resp) { that.refresh(); }
    });    
  }
  
};
