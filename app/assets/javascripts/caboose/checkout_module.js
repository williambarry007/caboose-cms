//
// Checkout
//

Caboose.Store.Modules.Checkout = (function() {

  // Steps
  // Step 1: Present non-editable cart and login/register/guest buttons.
  // Step 2: Present shipping address form.
  // Step 3: Present shipping options.
  // Step 4: Present credit card form.
  // Step 5: Thank you.
    
  self = {
    templates: {
      address:    JST['caboose/checkout/address'],
      login:      JST['caboose/checkout/login'],
      payment:    JST['caboose/checkout/payment'],
      lineItems:  JST['caboose/checkout/line_items'],
      shipping:   JST['caboose/checkout/shipping'],
      forms: {
        signin:   JST['caboose/checkout/forms/signin'],
        register: JST['caboose/checkout/forms/register'],
        guest:    JST['caboose/checkout/forms/guest']
      }
    }
  };
  
  //
  // Initialize
  //
  
  self.initialize = function() {    
    switch (window.location.pathname.replace(/\/$/, "")) {
      case '/checkout':
      case '/checkout/step-one': self.step = 1; break;
      case '/checkout/step-two': self.step = 2; break;
    }
    
    self.$checkout = $('#checkout')
    if (!self.$checkout.length) return false;
    self.loggedIn = $('body').data('logged-in');
    
    // TODO refactor this
    if (self.loggedIn) {
      $.post('/checkout/attach-user', function(response) {
        self.fetch(self.render);
      });
    } else {
      self.fetch(self.render);
    }
    
    self.bindEventHandlers();
  };
  
  //
  // Fetch items from the cart
  //
  
  self.fetch = function(callback) {
    $.get('/cart/items', function(response) {
      self.order = response.order
      
      if (self.step == 2) {
        $.get('/checkout/shipping', function(response) {
          self.shippingRates = response.rates;
          self.selectedRate = response.selected_rate;
          callback();
        });
      } else {
        callback();
      }
    });
  };
  
  //
  // Events
  //
  
  self.bindEventHandlers = function() {
    self.$checkout.on('click' , '[data-login-action]', self.loginClickHandler);
    self.$checkout.on('submit', '#checkout-login form', self.loginSubmitHandler);
    self.$checkout.on('change', 'input[type=checkbox][name=use_as_billing]', self.useAsBillingHandler);
    self.$checkout.on('click' , '#checkout-continue button', self.continueHandler);
    self.$checkout.on('click' , '#checkout-complete button', self.completeHandler);
    self.$checkout.on('change', '#checkout-shipping select', self.shippingChangeHandler);
    self.$checkout.on('change', '#checkout-payment form#payment select', self.expirationChangeHandler);
    self.$checkout.on('submit', '#checkout-payment form#payment', self.paymentSubmitHandler);
  };
  
  $('.login-choices button').removeClass('selected');
  self.loginClickHandler = function(event) {
    $section = self.$login.children('section');
    
    switch ($(event.target).data('login-action')) {
      case 'signin'  : $section.slideUp(400, function() { $section.empty().html(self.templates.forms.signin()  ).slideDown() }); $('#signin_button'  ).addClass('selected'); break;
      case 'register': $section.slideUp(400, function() { $section.empty().html(self.templates.forms.register()).slideDown() }); $('#register_button').addClass('selected'); break;
      case 'continue': $section.slideUp(400, function() { $section.empty().html(self.templates.forms.guest()   ).slideDown() }); $('#continue_button').addClass('selected'); break;
    };
  };
  
  self.loginSubmitHandler = function(event) {
    event.preventDefault();
    var $form = $(event.target);
    
    $.ajax({
      type: $form.attr('method'),
      url: $form.attr('action'),
      data: $form.serialize(),
      success: function(response) {
        if (response.error || (response.errors && response.errors.length > 0)) {
          if ($form.find('.message').length) {
            $form.find('.message').empty().addClass('error').text(response.error || response.errors[0]);
          } else {
            $form.append($('<span/>').addClass('message error').text(response.error || response.errors[0]));
          }
        } else {
          if (response.logged_in) {
            self.$login.after($('<p/>').addClass('alert').text('You are now signed in').css('text-align', 'center')).remove();
            $.post('/checkout/attach-user');
          } else {
            self.$login.after($('<p/>').addClass('alert').text('Email successfully saved').css('text-align', 'center')).remove();
          }
        }
        
        self.fetch(self.render);
      }
    });
  };
  
  self.useAsBillingHandler = function(event) {
    if (event.target.checked) {
      self.$address.find('#billing').hide();
    } else {
      self.$address.find('#billing').show();
    }
  };
  
  self.continueHandler = function(event) {
    $form = self.$address.find('form');
    
    if (!self.order.email && !self.order.customer_id) {
      alert('Please sign in, register or choose to continue as a guest');
      return false;
    }
    
    $.ajax({
      type: $form.attr('method'),
      url: $form.attr('action'),
      data: $form.serialize(),
      success: function(response) {
        if (response.success) {
          window.location = '/checkout/step-two';
        } else {
          $form.find('.message').remove();
          $form.find('#' + response.address + ' h3').append($('<span/>').addClass('message error').text(response.errors[0]));
        }
      }
    });
  };
  
  self.shippingChangeHandler = function(event) {
    if (event.target.value == "") return false;
    self.$checkout.addClass('loading');
    
    $.ajax({
      url: '/checkout/shipping',
      type: 'put',
      data: { shipping_method_code: event.target.value },
      success: function(response) {
        if (response.success) {
          self.order = response.order;
          self.selectedRate = response.selected_rate;
          self.render();
        }
      }
    });
  };
  
  self.expirationChangeHandler = function(event) {
    var $form = $('#checkout-payment #payment')
      , month = $form.find('select[name=month]').val()
      , year = $form.find('select[name=year]').val();
    
    $form.find('#expiration').val(month + year);
  };
  
  self.completeHandler = function(event) {
    if (self.$payment.length) self.$payment.find('form').submit();
  };
  
  self.paymentSubmitHandler = function(event) {
    event.preventDefault();
    
    if (!self.order.shipping_method_code) {
      alert('Please choose a shipping method');
    } else {
      self.$checkout.off('submit', '#checkout-payment form#payment').addClass('loading');
      $(event.target).submit();
    }
  };
  
  self.relayHandler = function(event) {
    var $iframe = $(event.target)
      , $form = self.$payment.find('form')
      , $response = $iframe.contents().find('#response');
    
    if (!$response.length || !$form.length) return false;
    var response = JSON.parse($iframe.contents().find('#response').html());
    console.log(response);
    if (response.success == true) {
      window.location = '/checkout/thanks';
    } else {
      alert(response.message);
      self.render();
    }
  };
  
  //
  // Render
  //
  
  self.render = function() {
    var renderFunctions = [];
        
    if (self.step == 1) {      
      renderFunctions.push(self.renderLineItems);
      renderFunctions.push(self.renderLogin);
      renderFunctions.push(self.renderAddress);
    } else {
      renderFunctions.push(self.renderShipping);
      renderFunctions.push(self.renderLineItems);
      renderFunctions.push(self.renderPayment);
    }
    
    _.each(renderFunctions, function(renderFunction, index) {
      var finished = index == (renderFunctions.length - 1)
      
      renderFunction(function() {
        if (finished) self.$checkout.removeClass('loading');
      });
    });
  };
  
  self.renderLineItems = function(callback) {
    self.$lineItems = self.$checkout.find('#checkout-line-items');
    if (!self.$lineItems.length) return false;
    self.$lineItems.empty().html(self.templates.lineItems({ order: self.order }));
    if (callback) callback();
  };
  
  self.renderLogin = function(callback) {
    self.$login = self.$checkout.find('#checkout-login');
    if (self.loggedIn) self.$login.remove();
    if (self.loggedIn || !self.$login.length) return false;
    self.$login.html(self.templates.login());
    //if (!self.order.email) self.$login.find('button[data-login-action="signin"]').click();
    if (callback) callback();
  };
  
  self.renderAddress = function(callback) {
    self.$address = self.$checkout.find('#checkout-address');
    if (!self.$address.length) return false;
    
    self.$address.empty().html(self.templates.address({
      shippingAddress: self.order.shipping_address,
      billingAddress: self.order.billing_address,
      states: window.States
    }));
    
    if (callback) callback();
  };
  
  self.renderShipping = function(callback) {
    self.$shipping = self.$checkout.find('#checkout-shipping');
    if (!self.$shipping.length) return false;
    
    self.$shipping.empty().html(self.templates.shipping({
      rates: self.shippingRates,
      selectedRate: self.selectedRate
    }));
    
    if (callback) callback();
  };
  
  self.renderPayment = function(callback) {
    self.$payment = self.$checkout.find('#checkout-payment');
    if (!self.$payment.length) return false;
    self.$checkout.addClass('loading');
    
    $.get('/checkout/payment', function(response) {
      var serializedForm = self.$payment.find('form').serialize();
      self.$payment.empty().html(self.templates.payment({ form: response }));
      
      if (serializedForm.length > 0) {
        _.each(serializedForm.split('&'), function(serializedField) {
          var name = serializedField.split('=')[0]
            , value = serializedField.split('=')[1];
          
          self.$payment.find('form [name="' + name + '"]').val(value);
        });                               
      }
      
      self.expirationChangeHandler();
      self.$checkout.removeClass('loading');
      self.$payment.find('iframe').on('load', self.relayHandler);
    });
  };
  
  return self
}).call(Caboose.Store);

