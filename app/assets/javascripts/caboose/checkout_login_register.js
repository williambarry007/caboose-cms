//
// Checkout
//

Caboose.Store.Modules.CheckoutLoginRegister = (function() {

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
      case '/checkout': self.step = 1; break;      
    }
    
    $('#signin_form_container'   ).slideUp();
    $('#register_form_container' ).slideUp();    
    
    self.$checkout = $('#checkout')        
    self.bindEventHandlers();
  };
  
  //
  // Events
  //
  
  self.bindEventHandlers = function() {
    self.$checkout.on('click' , '[data-login-action]', self.login_click_handler);    
    $('#signin_form'  ).submit(self.login_form_submit_handler);
    $('#register_form').submit(self.register_form_submit_handler);        
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
              else window.location = '/checkout/addresses';
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
            else window.location = '/checkout/addresses';
          }
        });        
      }
    });
    return false;
  };
      
  return self
}).call(Caboose.Store);
