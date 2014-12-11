//
// Cart
//

Caboose.Store.Modules.Cart = (function() {
  var self = {
    templates: {
      line_items: JST['caboose/cart/line_items'],
      add_to_cart: JST['caboose/cart/add_to_cart']
    }
  };
  
  //
  // Initialize
  //
  
  self.initialize = function() {
    self.render_add_to_cart();
    self.render_item_count();
    self.$cart = $('#cart');
    if (!self.$cart.length) return false;
    self.$cart.on('click', '#remove-from-cart', self.remove_handler);
    self.$cart.on('keyup', 'input', self.update_handler);
    self.render();
  };
  
  //
  // Set Variant
  //
  
  self.set_variant = function(variant) {
    if (self.$add_to_cart) {
      self.$add_to_cart.find('input[name=variant_id]').val(variant ? variant.id : "");
      self.$add_to_cart.trigger('change');
    }
  };
  
  //
  // Render
  //
  
  self.render = function() {
    $.get('/cart/items', function(response) {
      self.$cart.empty().html(self.templates.line_items({ order: response.order }));
      self.$cart.removeClass('loading');
    });
  };
  
  self.render_add_to_cart = function() {
    self.$add_to_cart = $('#add-to-cart');
    if (!self.$add_to_cart.length) return false;
    self.$add_to_cart.empty().html(self.templates.add_to_cart());
    //$('input[name=quantity]', self.$add_to_cart).on('keyup', self.qty_keyup_handler);
    //$('input[name=quantity,type=hidden,value=1]', self.$add_to_cart);
    $('form', self.$add_to_cart).on('submit', self.add_handler);
  };
  
  self.render_item_count = function(item_count) {
    var $link = $('#cart-link, .cart-link');
    if (!$link.length) return false;
    
    function set_count(count) {
      if      ($link.children('i') && count < 1) { $link.children('i').remove(); }
      else if ($link.children('i').length)       { $link.children('i').empty().text(count); } 
      else                                       { $link.append($('<i/>').text(count)); }
    };
    
    if (item_count) {
      set_count(item_count);
    } else {
      $.get('/cart/item-count', function(response) {
        set_count(response.item_count);
      });
    }
  };
  
  //
  // Event Handlers
  //
  
  self.qty_keyup_handler = function(event) {
    var $quantity = $(event.target);
    $quantity.val($quantity.val().match(/\d*\.?\d+/));
  };
  
  self.add_handler = function(event) {
    event.preventDefault();
    var $form = $(event.target);
    
    if ($form.find('input[name=variant_id]').val().trim() == "") {
      alert('Must select all options');
    } else {
      $.ajax({
        type: $form.attr('method'),
        url: $form.attr('action'),
        data: $form.serialize(),
        success: function(response) {
          if (response.success) {
            self.render_item_count(response.item_count);
            if (self.$add_to_cart.length) self.$add_to_cart.trigger('added');
            
            if (!self.$add_to_cart.find('.message').length) {
              self.$add_to_cart
                .append($('<div/>').hide().addClass('message')
                  .append($('<p/>').text('Successfully added to cart'))
                  .append($('<p/>')
                    .append($('<a/>').attr('href', '/cart').html('View cart')).append(' | ')
                    .append($('<a/>').attr('href', '/checkout').html('Continue to checkout'))
                  )
                );                
              self.$add_to_cart.find('.message').fadeIn();
              Caboose.Store.Modules.Product.$product.trigger('added-to-cart');
              
              //setTimeout(function() {
              //  self.$add_to_cart.find('.message').fadeOut(function() { $(this).remove() });
              //}, 5000);
            }
          } else {
            alert(response.errors[0]);
          }
        }
      });
    }
  };
  
  self.update_handler = function(event) {
    var $quantity = $(event.target)
    var $line_item = $quantity.parents('li').first();
    
    $quantity.val($quantity.val().match(/\d*\.?\d+/));
    if ($quantity.val() == "") return false;
    
    delay(function() {
      $.ajax({
        type: 'put',
        url: '/cart/items/' + $line_item.data('id'),
        data: { quantity: $quantity.val() },
        success: function(response) {
          if (response.success) {
            $line_item.find('.price').empty().text('$' + response.line_item.price);
            if (self.$cart.find('.subtotal').length) self.$cart.find('.subtotal').empty().text('$' + response.order_subtotal);
          } else {
            alert(response.errors[0]);
          }
        }
      });
    }, 1000);
  };
  
  self.remove_handler = function(event) {
    var $line_item = $(event.target).parents('li').first();
    
    $.ajax({
      type: 'delete',
      url: '/cart/items/' + $line_item.data('id'),
      success: function(response) {
        if (response.success) {
          self.render();
          self.render_item_count(response.item_count);
        }
      }
    });
  };
  
  self.redirect_handler = function(event) {
    event.preventDefault();
    window.location = $(event.target).attr('href');
  };
  
  return self;
}).call(Caboose.Store);
