
var MyAccountOrderController = function(params) { this.init(params); }

MyAccountOrderController.prototype = {
  
  order_id: false,
  order: false,
  authenticity_token: false,
  
  init: function(params)
  {
    for (var i in params)
      this[i] = params[i];
    
    var that = this;
    $('#payment_form').hide();
    $(document).ready(function() { that.refresh(); });
  },
  
  refresh: function()
  {
    var that = this;
    that.refresh_order(function() {
      $('#order_table').html("<p class='loading'>Getting order...</p>");
      that.print();       
    });    
  },
  
  refresh_order: function(after)
  {
    var that = this;
    $.ajax({
      url: '/my-account/orders/' + that.order_id + '/json',
      success: function(order) {                 
        that.order = order;
        if (after) after(); 
      }
    });
  },

/******************************************************************************/
      
  line_items_for_order_package: function(order_package_id)
  {
    var that = this;
    var line_items = [];
    $.each(that.order.line_items, function(i, li) {
      if (li.order_package_id == order_package_id)
        line_items.push(li);
    });
    return line_items;
  },
  
  print: function()
  {    
    var that = this;

    if (that.order.line_items && that.order.line_items.length > 0)
    {      
      var count_packaged     = 0;
      var count_unpackaged   = 0;
      var count_downloadable = 0;
      $.each(that.order.line_items, function(i, li) {  
        if (li.order_package_id)
          count_packaged++;
        else if (li.variant.downloadable == true)
          count_downloadable++;
        else
          count_unpackaged++;
      });
      
      var table = that.overview_table();
      $('#overview_table').empty().append(table).append($('<br />'));
      
      table = $('<table/>').addClass('order').css('width', '100%');
      if (count_packaged     > 0) that.packaged_line_items_table(table);
      if (count_unpackaged   > 0) that.unpackaged_line_items_table(table);
      if (count_downloadable > 0) that.downloadable_line_items_table(table);    
      that.summary_table(table);
      $('#order_table').empty().append(table);
    }
    else
    {
      $('#overview_table').empty();
      $('#order_table').empty();
      $('#message').empty().html("This order is empty.");
    }                  
  },
  
  overview_table: function()
  {
    var that = this;        
    
    var fstatus = $('<div/>').append($('<p/>').html(capitalize_first_letter(that.order.financial_status)));    
    if (that.order.financial_status == 'pending')        
    {      
      fstatus.append($('<p/>').append($('<input/>').attr('type', 'button').addClass('btn').val('Pay now').click(function(e) { e.preventDefault(); that.payment_form(); })));            
    }            

    var table = $('<table/>').addClass('order');
    table.append($('<tr/>')  
      .append($('<th/>').html('Customer'))
      .append($('<th/>').html('Shipping Address'))
      .append($('<th/>').html('Billing Address'))
      .append($('<th/>').html('Order Status'))
      .append($('<th/>').html('Payment Status'))      
    );    
    table.append($('<tr/>')      
      .append($('<td/>').attr('valign', 'top').attr('id', 'customer'         ).append(that.noneditable_customer()))
      .append($('<td/>').attr('valign', 'top').attr('id', 'shipping_address' ).append(that.noneditable_shipping_address()))      
      .append($('<td/>').attr('valign', 'top').attr('id', 'billing_address'  ).append(that.noneditable_billing_address()))        
      .append($('<td/>').attr('valign', 'top').attr('align', 'center').append($('<p/>').html(capitalize_first_letter(that.order.status))))
      .append($('<td/>').attr('valign', 'top').attr('align', 'center').append(fstatus))      
    );
    return table;  
  },
  
  noneditable_customer: function()
  {
    var that = this;
    c = that.order.customer;    
    str = '';
    if (c)                                                                  
    {
      str = c.first_name + ' ' + c.last_name;
      if (c.email) str += '<br /><a href="mailto:' + c.email + '">' + c.email + '</a>';
      if (c.phone) str += '<br />' + c.phone;
    }
    else
      str = '[Empty]';    
    return str;    
  },
  
  noneditable_shipping_address: function()
  {
    var that = this;
    var div = $('<div/>');
    if (that.has_shippable_items())
    {
      var sa = that.order.shipping_address;
      str = '';                  
      str += (sa.first_name ? sa.first_name : '[Empty first name]') + ' ';
      str += (sa.last_name  ? sa.last_name  : '[Empty last name]');
      str += '<br />' + (sa.address1 ? sa.address1 : '[Empty address]');
      if (sa.address2) str += "<br />" + sa.address2;
      str += '<br/>' + (sa.city ? sa.city : '[Empty city]') + ", " + (sa.state ? sa.state : '[Empty state]') + " " + (sa.zip ? sa.zip : '[Empty zip]');
      
      div.append($('<div/>').attr('id', 'shipping_address').append(str));
      div.append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
        var a = $(this);
        that.refresh_order(function() { that.edit_shipping_address(); });
      }));      
    }
    else
    {
      div.append("This order does not require shipping.");
    }    
    return div;    
  },
  
  edit_shipping_address: function()
  {
    var that = this;
    var sa = that.order.shipping_address;
    var table = $('<table/>').addClass('shipping_address')
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_first_name')))
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_last_name')))
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_address1')))                                
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')        
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_address2')))                        
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_city')))
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_state')))        
        .append($('<td/>').append($('<div/>').attr('id', 'shippingaddress_' + sa.id + '_zip')))        
      ))));
    $('#shipping_address').empty()          
      .append(table)
      .append($('<a/>').attr('href', '#').html('Finished').click(function(e) {
        var a = $(this);
        that.refresh_order(function() { $('#shipping_address').empty().append(that.noneditable_shipping_address()); });
      }));
            
    new ModelBinder({
      name: 'ShippingAddress',
      id: sa.id,
      update_url: '/my-account/orders/' + that.order.id + '/shipping-address',
      authenticity_token: that.authenticity_token,
      attributes: [        
        { name: 'first_name'  , nice_name: 'First Name' , type: 'text'  , value: sa.first_name , width: 150, fixed_placeholder: false },
        { name: 'last_name'   , nice_name: 'Last Name'  , type: 'text'  , value: sa.last_name  , width: 150, fixed_placeholder: false },
        { name: 'address1'    , nice_name: 'Address 1'  , type: 'text'  , value: sa.address1   , width: 320, fixed_placeholder: false },
        { name: 'address2'    , nice_name: 'Address 2'  , type: 'text'  , value: sa.address2   , width: 320, fixed_placeholder: false },
        { name: 'city'        , nice_name: 'City'       , type: 'text'  , value: sa.city       , width: 180, fixed_placeholder: false },
        { name: 'state'       , nice_name: 'State'      , type: 'text'  , value: sa.state      , width: 40, fixed_placeholder: false },
        { name: 'zip'         , nice_name: 'Zip'        , type: 'text'  , value: sa.zip        , width: 60, fixed_placeholder: false }
      ]
    });
  },
  
  noneditable_billing_address: function()
  {
    var that = this;
    
    var sa = that.order.billing_address;
    if (!sa) sa = {};
    var str = '';
    str += (sa.first_name ? sa.first_name : '[Empty first name]') + ' ';
    str += (sa.last_name  ? sa.last_name  : '[Empty last name]');        
    str += '<br />' + (sa.address1 ? sa.address1 : '[Empty address]');
    if (sa.address2) str += "<br />" + sa.address2;             
    str += '<br/>' + (sa.city ? sa.city : '[Empty city]') + ", " + (sa.state ? sa.state : '[Empty state]') + " " + (sa.zip ? sa.zip : '[Empty zip]');
    
    var div = $('<div/>')
      .append(str)      
      .append("<br />")
      .append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
        var a = $(this);
        that.refresh_order(function() { that.edit_billing_address(); });
      }));
    return div;    
  },
  
  edit_billing_address: function()
  {
    var that = this;
    var sa = that.order.billing_address;
    if (!sa) sa = { id: 1 };
    var table = $('<table/>').addClass('billing_address')
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_first_name')))
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_last_name')))
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_address1')))                                
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')        
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_address2')))                        
      ))))
      .append($('<tr/>').append($('<td/>').append($('<table/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_city')))
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_state')))        
        .append($('<td/>').append($('<div/>').attr('id', 'billingaddress_' + sa.id + '_zip')))        
      ))));
    $('#billing_address').empty()
      .append(table)
      .append($('<a/>').attr('href', '#').html('Finished').click(function(e) {
        var a = $(this);
        that.refresh_order(function() { $('#billing_address').empty().append(that.noneditable_billing_address()); });
      }));      
            
    new ModelBinder({
      name: 'BillingAddress',
      id: sa.id,
      update_url: '/my-account/orders/' + that.order.id + '/billing-address',
      authenticity_token: that.authenticity_token,
      attributes: [        
        { name: 'first_name'  , nice_name: 'First Name' , type: 'text'  , value: sa.first_name , width: 150, fixed_placeholder: false },
        { name: 'last_name'   , nice_name: 'Last Name'  , type: 'text'  , value: sa.last_name  , width: 150, fixed_placeholder: false },
        { name: 'address1'    , nice_name: 'Address 1'  , type: 'text'  , value: sa.address1   , width: 320, fixed_placeholder: false },
        { name: 'address2'    , nice_name: 'Address 2'  , type: 'text'  , value: sa.address2   , width: 320, fixed_placeholder: false },
        { name: 'city'        , nice_name: 'City'       , type: 'text'  , value: sa.city       , width: 180, fixed_placeholder: false },
        { name: 'state'       , nice_name: 'State'      , type: 'text'  , value: sa.state      , width: 40, fixed_placeholder: false },
        { name: 'zip'         , nice_name: 'Zip'        , type: 'text'  , value: sa.zip        , width: 60, fixed_placeholder: false }
      ]
    });
  },
  
  // Show all the packages and the line items in each package
  packaged_line_items_table: function(table)
  {
    var that = this;           
    $.each(that.order.order_packages, function(i, op) {
      var line_items = that.line_items_for_order_package(op.id);      
      if (line_items && line_items.length > 0)
      {        
        table.append($('<tr/>').append($('<th/>').attr('colspan', '5').addClass('package_header').html("Package " + (i+1) + ": " + op.shipping_method.service_name + "<br />" + op.status)));
        table.append($('<tr/>')                
          .append($('<th/>').html('Item'))
          .append($('<th/>').html('Status'))    
          .append($('<th/>').html('Unit Price'))
          .append($('<th/>').html('Quantity'))
          .append($('<th/>').html('Subtotal'))
        );                          
        $.each(line_items, function(j, li) {          
          var tr = $('<tr/>');                                 
          tr.append($('<td/>').addClass('line_item_details'   ).append(that.line_item_details(li)));
          tr.append($('<td/>').addClass('line_item_status'    ).attr('align', 'center').html(li.status));      
          tr.append($('<td/>').addClass('line_item_unit_price').attr('align', 'right' ).html(curr(li.unit_price)));    
          tr.append($('<td/>').addClass('line_item_quantity'  ).attr('align', 'right' ).html(li.quantity));
          tr.append($('<td/>').addClass('line_item_subtotal'  ).attr('align', 'right' ).html(curr(li.subtotal)));        
          table.append(tr);
        });      
      }
    });
  },
  
  // Show all the packages and the line items in each package
  unpackaged_line_items_table: function(table)
  {
    var that = this;           
    $.each(that.order.order_packages, function(i, op) {
      var line_items = that.line_items_for_order_package(op.id);      
      if (line_items && line_items.length > 0)
      {        
        table.append($('<tr/>').append($('<th/>').attr('colspan', '5').addClass('package_header').html("Unpackaged Items")));
        table.append($('<tr/>')                
          .append($('<th/>').html('Item'))
          .append($('<th/>').html('Status'))    
          .append($('<th/>').html('Unit Price'))
          .append($('<th/>').html('Quantity'))
          .append($('<th/>').html('Subtotal'))
        );                          
        $.each(line_items, function(j, li) {          
          var tr = $('<tr/>');                                 
          tr.append($('<td/>').addClass('line_item_details'   ).append(that.line_item_details(li)));
          tr.append($('<td/>').addClass('line_item_status'    ).attr('align', 'center').html(li.status));      
          tr.append($('<td/>').addClass('line_item_unit_price').attr('align', 'right' ).html(curr(li.unit_price)));    
          tr.append($('<td/>').addClass('line_item_quantity'  ).attr('align', 'right' ).html(li.quantity));
          tr.append($('<td/>').addClass('line_item_subtotal'  ).attr('align', 'right' ).html(curr(li.subtotal)));        
          table.append(tr);
        });      
      }
    });
  },
   
  downloadable_line_items_table: function(table)
  {
    var that = this;           
    $.each(that.order.order_packages, function(i, op) {
      var line_items = that.line_items_for_order_package(op.id);      
      if (line_items && line_items.length > 0)
      {        
        table.append($('<tr/>').append($('<th/>').attr('colspan', '5').addClass('package_header').html("Downloadable Items")));
        table.append($('<tr/>')                
          .append($('<th/>').html('Item'))
          .append($('<th/>').html('Status'))    
          .append($('<th/>').html('Unit Price'))
          .append($('<th/>').html('Quantity'))
          .append($('<th/>').html('Subtotal'))
        );                          
        $.each(line_items, function(j, li) {          
          var tr = $('<tr/>');                                 
          tr.append($('<td/>').addClass('line_item_details'   ).append(that.line_item_details(li)));
          tr.append($('<td/>').addClass('line_item_status'    ).attr('align', 'center').html(li.status));      
          tr.append($('<td/>').addClass('line_item_unit_price').attr('align', 'right' ).html(curr(li.unit_price)));    
          tr.append($('<td/>').addClass('line_item_quantity'  ).attr('align', 'right' ).html(li.quantity));
          tr.append($('<td/>').addClass('line_item_subtotal'  ).attr('align', 'right' ).html(curr(li.subtotal)));        
          table.append(tr);
        });      
      }
    });
  },
  
  line_item_details: function(li)
  {
    var that = this;    
    var v = li.variant;
    var name = ''
    if (!v || !v.product)
      name = v ? v.sku : 'Unknown variant';                      
    else
    {
      name = v.product.title;
      if (v.sku   && v.sku.length   > 0) name += '<br />' + v.sku;
      if (v.title && v.title.length > 0) name += '<br />' + v.title;
    }       
    
    var div = $('<div/>').append($('<p/>').append($('<a/>').attr('href', '/products/' + li.variant.product_id).html(name)));
    if (li.is_gift)
    {      
      div.append($('<ul/>').addClass('gift_options')
        .append($('<li/>').html("This item is a gift."))
        .append($('<li/>').html("Gift wrap? " + (li.gift_wrap ? 'Yes' : 'No')))
        .append($('<li/>').html("Hide prices? " + (li.hide_prices ? 'Yes' : 'No')))
        .append($('<li/>').html("Gift message: " + (li.gift_message && li.gift_message.length > 0 ? li.gift_message : '[Empty]')))
      );            
    }
    else
    {
      div.append($('<p/>').html("This item is not a gift."));
    } 
    if (li.variant.downloadable)
    {
      div.append($('<p/>').append($('<a/>').attr('href', '/my-account/orders/' + that.order.id + '/line-items/' + li.id + '/download').html('Download')));
    }
    
    return div;    
  },
      
  // Show the order summary
  summary_table: function(table)
  {    
    var that = this;
    table.append($('<tr/>').append($('<th/>').attr('colspan', '5').addClass('totals_header').html('Totals')));        
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Subtotal' )).append($('<td/>').attr('align', 'right').attr('id', 'subtotal').html(curr(that.order.subtotal ))));
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Tax'      )).append($('<td/>').attr('align', 'right').attr('id', 'tax'     ).html(curr(that.order.tax      ))));
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Shipping' )).append($('<td/>').attr('align', 'right').attr('id', 'shipping').html(curr(that.order.shipping ))));
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Handling' )).append($('<td/>').attr('align', 'right').attr('id', 'handling').html(curr(that.order.handling ))));
    if (that.order.discounts)
    {
      $.each(that.order.discounts, function(i, d) {
        table.append($('<tr/>').addClass('totals_row')
          .append($('<td/>').attr('colspan', '4').attr('align', 'right').append(' "' + d.gift_card.code + '" Discount'))
          .append($('<td/>').attr('align', 'right').html(curr(d.amount)))
        );
      });
    }    
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Discount')).append($('<td/>').attr('align', 'right').attr('id', 'custom_discount').html(curr(that.order.custom_discount))));
    table.append($('<tr/>').addClass('totals_row').append($('<td/>').attr('colspan', '4').attr('align', 'right').html('Total'   )).append($('<td/>').attr('align', 'right').attr('id', 'total'          ).html(curr(that.order.total))));            
  },

  /****************************************************************************/
  
  payment_form: function()
  {
    var that = this;
    var form = $('#payment_form');
    if (form.is(':visible'))
    {      
      form.slideUp(function() { form.empty(); });
      $('#payment_message').empty();
      return; 
    }
    
    $('#payment_message').empty().html("<p class='loading'>Getting payment form...</p>");
    $.ajax({
      url: '/my-account/orders/' + that.order.id + '/payment-form',
      type: 'get',
      success: function(html) {        
        form.empty().append(html);
        form.slideDown();
        $('#payment_message').empty();        
      }
    });                  
  },
  
  submit_payment: function() 
  {
    $('input[name=billing-cc-exp]').val($('#billing-expiration-month').val() + $('#billing-expiration-year').val());      
    $('#payment_message').empty().html("<p class='loading'>Processing payment...</p>");
    $('#payment_form').slideUp();
    $('#payment').submit();    
  },
  
  payment_relay_handler: function(resp)
  {
    console.log('RELAY');
    console.log(resp);
    if (resp.success == true)
      controller.refresh();
    else if (resp.error)  
      $('#payment_message').html("<p class='note error'>" + resp.error + "</p>");
    else
      $('#payment_message').html("<p class='note error'>There was an error processing your payment.</p>");    
  },

  has_shippable_items: function()
  {
    var that = this;
    var needs_shipping = false;
    $.each(that.order.line_items, function(i, li) {      
      if (li.variant.downloadable == false)
        needs_shipping = true;
    });
    return needs_shipping;    
  },
  
};
  
function relay_handler(resp)
{
  controller.payment_relay_handler(resp);  
}
