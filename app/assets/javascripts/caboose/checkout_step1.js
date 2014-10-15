//
// Checkout
//

Caboose.Store.Modules.CheckoutStep1 = (function() {

  // Steps
  // Step 1: Present non-editable cart and login/register/guest buttons.
  // Step 2: Present shipping address form.
  // Step 3: Present shipping options.
  // Step 4: Present credit card form.
  // Step 5: Thank you.
    
  self = {};
  
  //
  // Initialize
  //
  
  self.initialize = function() {
    switch (window.location.pathname.replace(/\/$/, "")) {
      case '/checkout':
      case '/checkout/step-one': self.step = 1; break;      
    }
    
    $('#signin_form_container'   ).slideUp();
    $('#register_form_container' ).slideUp();
    $('#guest_form_container'    ).slideUp();
    
    self.$checkout = $('#checkout')        
    self.bindEventHandlers();
  };
  
  //
  // Events
  //
  
  self.bindEventHandlers = function() {
    self.$checkout.on('click' , '[data-login-action]', self.login_click_handler);
    //self.$checkout.on('submit', '#checkout-login form', self.login_submit_handler);    
    //self.$checkout.on('click' , '#checkout-continue button', self.continue_handler);
    $('#signin_form'  ).submit(self.login_form_submit_handler);
    $('#register_form').submit(self.register_form_submit_handler);
    $('#guest_form'   ).submit(self.guest_form_submit_handler);    
  };
  
  self.login_click_handler = function(event) {    
    var form = $(event.target).data('login-action');    
    if (self.current_form && form == self.current_form)
      return;
    if (self.current_form)
    {
      $('#' + self.current_form + '_form_container').slideUp(400, function() {
        $('#' + form + '_form_container').slideDown();        
      });
      $('#' + self.current_form + '_button').removeClass('selected');
    }    
    else
    {
      $('#' + form + '_form_container').slideDown();      
    }
    $('#' + form + '_button').addClass('selected');
    $('#message').empty();
    
    $('html, body').animate({
      scrollTop: $('#checkout-login').offset().top
    }, 600);
    
    self.current_form = form;         
  };
  
  //self.login_submit_handler = function(event) {
  //  event.preventDefault();
  //  var $form = $(event.target);
  //  
  //  $.ajax({
  //    type: $form.attr('method'),
  //    url: $form.attr('action'),
  //    data: $form.serialize(),
  //    success: function(response) {
  //      if (response.error || (response.errors && response.errors.length > 0)) {
  //        if ($form.find('.message').length) {
  //          $form.find('.message').empty().addClass('error').text(response.error || response.errors[0]);
  //        } else {
  //          $form.append($('<span/>').addClass('message error').text(response.error || response.errors[0]));
  //        }
  //      } else {
  //        if (response.logged_in) {
  //          self.$login.after($('<p/>').addClass('alert').text('You are now signed in').css('text-align', 'center')).remove();
  //          $.post('/checkout/attach-user');
  //        } else {
  //          self.$login.after($('<p/>').addClass('alert').text('Email successfully saved').css('text-align', 'center')).remove();
  //        }
  //      }
  //      
  //      self.fetch(self.render);
  //    }
  //  });
  //};
  
  //self.continueHandler = function(event) {
  //  $form = self.$address.find('form');
  //  
  //  $.ajax({
  //    type: $form.attr('method'),
  //    url: $form.attr('action'),
  //    data: $form.serialize(),
  //    success: function(response) {
  //      if (response.success) {
  //        window.location = '/checkout/step-two';
  //      } else {
  //        $form.find('.message').remove();
  //        $form.find('#' + response.address + ' h3').append($('<span/>').addClass('message error').text(response.errors[0]));
  //      }
  //    }
  //  });
  //};
  
  self.login_form_submit_handler = function(event) {    
    $('#message').html("<p class='loading'>Logging in...</p>");
    $.ajax({
      url: '/login',
      type: 'post',
      data: $('#signin_form').serialize(),
      success: function(resp) {        
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else
        {
          $.ajax({
            url: '/checkout/attach-user',
            type: 'post',            
            success: function(resp2) {
              if (resp2.error) $('#message').html("<p class='note error'>" + resp2.error + "</p>");
              else window.location = '/checkout/step-two';
            }
          });          
        }
      }
    });
    return false;
  };
  
  self.register_form_submit_handler = function(event) {    
    $('#message').html("<p class='loading'>Registering...</p>");
    $.ajax({
      url: '/register',
      type: 'post',
      data: $('#register_form').serialize(),
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        $.ajax({
          url: '/checkout/attach-user',
          type: 'post',            
          success: function(resp2) {
            if (resp2.error) $('#message').html("<p class='note error'>" + resp2.error + "</p>");
            else window.location = '/checkout/step-two';
          }
        });        
      }
    });
    return false;
  };
  
  self.guest_form_submit_handler = function(event) {    
    $('#message').html("<p class='loading'>Submitting...</p>");
    $.ajax({
      url: '/checkout/attach-guest',
      type: 'post',
      data: $('#guest_form').serialize(),
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else window.location = '/checkout/step-two';
      }
    });
    return false;
  };
      
  return self
}).call(Caboose.Store);
