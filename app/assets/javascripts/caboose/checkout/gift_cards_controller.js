
var GiftCardsController = function(params) { this.init(params); };

GiftCardsController.prototype = {

  cc: false,  
      
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
  },
    
  print: function()
  {
    var that = this;
    $('#gift_cards_container').empty();
  },
  
  edit: function()
  {    
    var that = this;
    var div = $('<div/>')
      .append($('<form/>')
        .attr('method', 'post')
        .submit(function(e) { that.apply_code($('#gift_card_code').val()); return false; })        
        .append($('<p/>')
          .append($('<input/>').attr('type', 'submit').attr('id', 'redeem_code_btn').val('Redeem Code'))
          .append($('<input/>').attr('type', 'text'  ).attr('id', 'gift_card_code').attr('placeholder', 'Gift card code'))          
        )
        .append($('<div/>').attr('id', 'gift_card_message'))
        .append($('<div/>').attr('id', 'gift_card_spacer'))
      );
    $('#gift_cards_container').empty().append(div);
  },
  
  apply_code: function(code)
  {
    var that = this;
    $('#gift_card_message').html("<p class='loading'>...</p>");    
    $.ajax({
      url: '/cart/gift-cards',
      type: 'post',
      data: { code: code },
      success: function(resp) {
        if (resp.error) $('#gift_card_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success)
        {          
          that.cc.invoice.total = parseFloat(resp.invoice_total);
          that.cc.refresh_cart();
          that.cc.payment_method_controller.print();                      
          $('#gift_card_code').val('');
          $('#gift_card_message').empty();
        }
      }        
    });    
  }
};
