
var OrderController = function(params) { this.init(params); }

OrderController.prototype = {
  
  order_id: false,
  order: false,
  authenticity_token: false,
  
  init: function(params)
  {
    for (var i in params)
      this[i] = params[i];
    
    var that = this;
    $(document).ready(function() { that.refresh(); });
  },
  
  refresh: function()
  {
    var that = this;
    that.refresh_order(function() {
      $('#order_table').html("<p class='loading'>Getting order...</p>");
      that.print();
      that.make_editable(); 
    });    
  },
  
  refresh_order: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/orders/' + that.order_id + '/json',
      success: function(order) {                 
        that.order = order;
        if (after) after(); 
      }
    });
  },
  
  make_editable: function()
  {    
    var that = this;
    $.each(that.order.order_packages, function(i, op) {
      new ModelBinder({
        name: 'OrderPackage',
        id: op.id,
        update_url: '/admin/orders/' + op.order_id + '/packages/' + op.id,
        authenticity_token: that.authenticity_token,
        attributes: [                      
          { name: 'status'          , nice_name: 'Status'          , type: 'select' , value: op.status                                            , width: 300, fixed_placeholder: true , options_url: '/admin/orders/line-items/status-options' },
          { name: 'package_method'  , nice_name: 'Package/Method'  , type: 'select' , value: op.shipping_package_id + '_' + op.shipping_method_id , width: 300, fixed_placeholder: false, options_url: '/admin/shipping-packages/package-method-options' },
          { name: 'tracking_number' , nice_name: 'Tracking Number' , type: 'text'   , value: op.tracking_number                                   , width: 300, fixed_placeholder: true, align: 'right' },
          { name: 'total'           , nice_name: 'Shipping Total'  , type: 'text'   , value: curr(op.total)                                       , width: 300, fixed_placeholder: true, align: 'right' }
        ]
      });              
    });    
    $.each(that.order.line_items, function(i, li) {        
      new ModelBinder({
        name: 'Lineitem',
        id: li.id,
        update_url: '/admin/orders/' + li.order_id + '/line-items/' + li.id,
        authenticity_token: that.authenticity_token,
        attributes: [
          { name: 'status'          , nice_name: 'Status'           , type: 'select'  , align: 'left' , value: li.status          , text: li.status, width: 150, fixed_placeholder: false, options_url: '/admin/orders/line-items/status-options' },
          { name: 'tracking_number' , nice_name: 'Tracking Number'  , type: 'text'    , align: 'left' , value: li.tracking_number , width: 200, fixed_placeholder: false },
          { name: 'quantity'        , nice_name: 'Quantity'         , type: 'text'    , align: 'right', value: li.quantity        , width:  75, fixed_placeholder: false, after_update: function() { that.refresh(); } }
        ]
      });
    });    
    new ModelBinder({
      name: 'Order',
      id: that.order.id,
      update_url: '/admin/orders/' + that.order.id,
      authenticity_token: that.authenticity_token,
      attributes: [
        { name: 'status'         , nice_name: 'Status'   , type: 'select', value: that.order.status                , width: 100, fixed_placeholder: false, options_url: '/admin/orders/status-options' },
        { name: 'tax'            , nice_name: 'Tax'      , type: 'text'  , value: curr(that.order.tax)             , width: 100, fixed_placeholder: false, align: 'right' },
        { name: 'handling'       , nice_name: 'Handling' , type: 'text'  , value: curr(that.order.handling)        , width: 100, fixed_placeholder: false, align: 'right' },
        { name: 'custom_discount', nice_name: 'Discount' , type: 'text'  , value: curr(that.order.custom_discount) , width: 100, fixed_placeholder: false, align: 'right' }
      ]
    });        
  },
  
  assign_to_package_form: function(li_id)
  {
    var that = this;
    if (!that.order.order_packages)
      that.order.order_packages = [];
    if (that.order.order_packages.length == 0)
    {
      that.assign_to_new_package_form(li_id);
      return;
    }
    
    var select = $('<select/>').attr('id', 'order_package_id').css('width', '300px').change(function(e) {
      var order_package_id = $(this).val();
      if (order_package_id == -1)
        that.assign_to_new_package_form(li_id);
      else
        that.assign_to_package(li_id, order_package_id);
    });
    select.append($('<option/>').val(-1).html('-- Select a package --'));
    $.each(that.order.order_packages, function(i, op) {        
      var sp = op.shipping_package;      
      var sm = op.shipping_method;
      var name = []; 
      if (sp.name) name.push(sp.name);
      name.push(sp.outside_length + 'x' + sp.outside_width + 'x' + sp.outside_height);
      name.push(sm.carrier);
      name.push(sm.service_name);
      name = name.join(' - ');                
      select.append($('<option/>').val(op.id).html(name));      
    });        
    select.append($('<option/>').val(-1).html('New Package'));
    var p = $('<p/>').append(select);
    $('#assign_to_package_' + li_id).empty().append(p);              
  },

  assign_to_new_package_form: function(li_id)
  {
    var that = this;
    $('#assign_to_package_' + li_id).html("<p class='loading'>Getting packages...</p>");
    $.ajax({
      url: '/admin/shipping-packages/json',
      type: 'get',
      success: function(resp) {      
        var select = $('<select/>')
          .attr('id', 'package_id')
          .css('width', '400px')
          .change(function(e) { // Create the new order package
            var arr = $(this).val().split('_');            
            $.ajax({
              url: '/admin/orders/' + that.order.id + '/packages',
              type: 'post',
              data: { shipping_package_id: arr[0], shipping_method_id: arr[1] },
              success: function(resp) {
                that.assign_to_package(li_id, resp.new_id);            
              }
            });          
          }
        );  
        select.append($('<option/>').val('').html('-- Select a package and shipping method --'));
        $.each(resp.models, function(i, sp) {        
          var name = []; 
          if (sp.name) name.push(sp.name);
          name.push(sp.outside_length + 'x' + sp.outside_width + 'x' + sp.outside_height);
          name = name.join(' - ');        
          var optgroup = $('<optgroup/>').attr('label', name);                
          $.each(sp.shipping_methods, function(j, sm) {                  
            optgroup.append($('<option/>').val('' + sp.id + '_' + sm.id).html(sm.carrier + ' - ' + sm.service_name));
          });
          select.append(optgroup);
        });
        
        var p = $('<p/>')
          .append(select).append('<br/>')
          .append($('<input/>').attr('type', 'button').val('Cancel').click(function(e) { that.refresh(); }));                      
        $('#assign_to_package_' + li_id).empty().append(p);
      }
    });
  },

  assign_to_package: function(li_id, order_package_id)
  {
    var that = this;    
    $.ajax({
      url: '/admin/orders/' + that.order.id + '/line-items/' + li_id,
      type: 'put',
      data: { order_package_id: order_package_id },
      success: function(resp) {
        if (resp.error) $('#assign_to_package_' + li_id).html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();
      }
    });    
  },
  
  unassign_from_package: function(li_id)
  {
    var that = this;    
    $.ajax({
      url: '/admin/orders/' + that.order.id + '/line-items/' + li_id,
      type: 'put',
      data: { order_package_id: -1 },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();
      }
    });    
  },

/******************************************************************************/

  print_order: function(order_id)
  {
    window.open('/admin/orders/' + order_id + '/print');
  },  
    
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
       
    var table = that.overview_table();
    $('#overview_table').empty().append(table).append($('<br />'));
    
    table = $('<table/>').addClass('data').css('width', '100%');    
    that.order_packages_table(table);
    that.unassigned_line_items_table(table);
    that.summary_table(table);
    $('#order_table').empty().append(table);
  },
  
  overview_table: function()
  {
    var that = this;        
    
    var fstatus = $('<div/>').append(that.order.financial_status);
    if (that.order.order_transactions.length > 0)        
    {
      var transactions_table = $('<table/>').addClass('data');
      $.each(that.order.order_transactions, function(i, ot) {
        var d = new Date(ot.date_processed);
        var h = d.getHours();
        var ampm = 'am';
        if (h >= 12) ampm = 'pm';
        if (h > 12) h = h - 12;                  
        d = '' + (d.getMonth()+1) + '/' + d.getDate() + '/' + d.getYear() + '<br/>' + h + ':' + d.getMinutes() + ' ' + ampm;
        transactions_table.append($('<tr/>')
          .append($('<td/>').html(d   ))        
          .append($('<td/>').html(ot.transaction_type ))
          .append($('<td/>').html(curr(ot.amount)     ))
          .append($('<td/>').html(ot.transaction_id   ))                
          .append($('<td/>').html(ot.success ? 'Success' : 'Fail'))
        );                    
      });
      fstatus.append(transactions_table);
    }
    
    var table = $('<table/>').addClass('data');
    table.append($('<tr/>')  
      .append($('<th/>').html('Customer'))
      .append($('<th/>').html('Shipping Address'))  
      .append($('<th/>').html('Order Status'))
      .append($('<th/>').html('Payment Status'))      
    );    
    table.append($('<tr/>')      
      .append($('<td/>').attr('valign', 'top')
        .append($('<div/>').attr('id', 'customer').append(that.noneditable_customer(true)))
        .append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
          var a = $(this);
          that.refresh_order(function() {
            if (a.html() == 'Edit') { that.edit_customer();        a.html('Finished'); }
            else                    { that.noneditable_customer(); a.html('Edit');     }
          });
        }))
      )
      .append($('<td/>').attr('valign', 'top')
        .append($('<div/>').attr('id', 'shipping_address').append(that.noneditable_shipping_address(true)))
        .append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
          var a = $(this);
          that.refresh_order(function() {
            if (a.html() == 'Edit') { that.edit_shipping_address();        a.html('Finished'); }
            else                    { that.noneditable_shipping_address(); a.html('Edit');     }
          });
        }))
      )
      .append($('<td/>').attr('valign', 'top').append($('<div/>').attr('id', 'order_' + that.order.id + '_status')))
      .append($('<td/>').attr('valign', 'top').attr('align', 'center').append(fstatus))      
    );
    return table;  
  },
  
  noneditable_customer: function(return_element)
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
    if (return_element)
      return str;
    $('#customer').empty().append(str);
  },
    
  edit_customer: function()
  {
    var that = this;    
    var div = $('<div/>').attr('id', 'order_' + that.order.id + '_customer_id');        
    $('#customer').empty().append(div);
            
    new ModelBinder({
      name: 'Order',
      id: that.order.id,
      update_url: '/admin/orders/' + that.order.id,
      authenticity_token: that.authenticity_token,
      attributes: [        
        { name: 'customer_id', nice_name: 'Customer', type: 'select', value: that.order.customer_id, width: 150, fixed_placeholder: false, options_url: '/admin/users/options' }        
      ]
    });
  },
  
  noneditable_shipping_address: function(return_element)
  {
    var that = this;
    var sa = that.order.shipping_address;
    var str = '';
    str += (sa.first_name ? sa.first_name : '[Empty first name]') + ' ';
    str += (sa.last_name  ? sa.last_name  : '[Empty last name]');        
    str += '<br />' + (sa.address1 ? sa.address1 : '[Empty address]');
    if (sa.address2) str += "<br />" + sa.address2;             
    str += '<br/>' + (sa.city ? sa.city : '[Empty city]') + ", " + (sa.state ? sa.state : '[Empty state]') + " " + (sa.zip ? sa.zip : '[Empty zip]');
    if (return_element)
      return str;
    $('#shipping_address').empty().append(str);
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
    $('#shipping_address').empty().append(table);
            
    new ModelBinder({
      name: 'ShippingAddress',
      id: sa.id,
      update_url: '/admin/orders/' + that.order.id + '/shipping-address',
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
  order_packages_table: function(table)
  {
    var that = this;    
    $.each(that.order.order_packages, function(i, op) {
      var line_items = that.line_items_for_order_package(op.id);      
      if (line_items && line_items.length > 0)
      {
        table.append($('<tr/>')      
          .append($('<th/>').html('Package'    ))
          .append($('<th/>').html('Item'       ))
          .append($('<th/>').html('Status'     ))    
          .append($('<th/>').html('Unit Price' ))
          .append($('<th/>').html('Quantity'   ))
          .append($('<th/>').html('Subtotal'   ))
        );
        $.each(line_items, function(j, li) {          
          var tr = $('<tr/>');
          if (j == 0)
          {
            tr.append($('<td/>').attr('rowspan', line_items.length)
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_package_method'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_status'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_tracking_number'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_total'))
            );
          }
          var v = li.variant;
          tr.append($('<td/>').append(that.line_item_link(li)).append($('<div/>').attr('id', 'line_item_' + li.id + '_message')));
          tr.append($('<td/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_status')))      
          tr.append($('<td/>').attr('align', 'right').html(curr(v.price)));    
          tr.append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity')));
          tr.append($('<td/>').attr('align', 'right').attr('id', 'li_' + li.id + '_subtotal').html(curr(li.price)));        
          table.append(tr);
        });
      }
      else
      {
        table
          .append($('<tr/>')      
            .append($('<th/>').html('Package'    ))
            .append($('<th/>').attr('colspan', '5').html('&nbsp;'))            
          )
          .append($('<tr/>')
            .append($('<td/>')
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_package_method'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_status'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_tracking_number'))
              .append($('<div/>').attr('id', 'orderpackage_' + op.id + '_total'))
            )
            .append($('<td/>').attr('colspan', '5')
              .append($('<p>')
                .append("This package is empty. ")
                .append($('<a/>').attr('href', '#').html('Delete Package').data('op_id', op.id).click(function(e) { e.preventDefault(); that.delete_order_package($(this).data('op_id')); }))
              )
            )
          );
      }
    });
  },
  
  line_item_link: function(li)
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
    var link = $('<a/>').attr('href', '#').html(name)
      .data('li_id', li.id)
      .data('order_package_id', li.order_package_id)
      .click(function(e) {
        e.preventDefault();
        that.line_item_options($(this).data('li_id'), $(this).data('order_package_id'));
      });
    return link;    
  },
  
  line_item_options: function(li_id, order_package_id)
  {
    var that = this;
    var ul = $('<ul/>').addClass('line_item_controls');
    ul.append($('<li/>').append($('<a/>')
      .html('View Product')
      .attr('href', '/admin/orders/' + that.order.id + '/line-items/' + li_id + '/highlight')
    ))
    if (order_package_id && order_package_id != -1)
    {
      ul.append($('<li/>').append($('<a/>')
        .html('Remove from Package')
        .attr('href', '#')
        .data('li_id', li_id)
        .click(function(e) { e.preventDefault(); that.unassign_from_package($(this).data('li_id')); })
      ));
    }    
    ul.append($('<li/>').append($('<a/>')
      .html('Remove from Order')
      .attr('href', '#')
      .data('li_id', li_id)        
      .click(function(e) { e.preventDefault(); that.delete_line_item($(this).data('li_id')); })
    ));
    var el = $('#line_item_' + li_id + '_message');    
    if (el.is(':empty'))
      el.hide().empty().append(ul).slideDown();
    else
      el.slideUp(function() { $(this).empty(); });
  },
  
  // Show all the line items not assigned to a package
  unassigned_line_items_table: function(table)
  {
    var that = this;
    
    var has_unassigned_line_items = false
    $.each(that.order.line_items, function(i, li) {
      if (!li.order_package_id || li.order_package_id == -1)
      {
        has_unassigned_line_items = true;
        return false;
      }
    });
    if (!has_unassigned_line_items)
      return;
      
    table.append($('<tr/>')      
      .append($('<th/>').html('Package'    ))
      .append($('<th/>').html('Item'       ))
      .append($('<th/>').html('Status'     ))    
      .append($('<th/>').html('Unit Price1' ))
      .append($('<th/>').html('Quantity'   ))
      .append($('<th/>').html('Subtotal'   ))
    );
    
    $.each(that.order.line_items, function(i, li) {
      if (li.order_package_id && li.order_package_id != -1) return true;
      var v = li.variant;
      
      var div = $('<div/>').attr('id', 'assign_to_package_' + li.id)
        .append('Unpackaged! ')
        .append($('<a/>').data('line_item_id', li.id).attr('href', '#').html('Assign to package').click(function(e) {
          e.preventDefault();
          e.stopPropagation();
          that.assign_to_package_form($(this).data('line_item_id'));
        }));
                                     
      var tr = $('<tr/>');
      tr.append($('<td/>').append(div));
      tr.append($('<td/>').append(that.line_item_link(li)).append($('<div/>').attr('id', 'line_item_' + li.id + '_message')));            
      tr.append($('<td/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_status')))      
      tr.append($('<td/>').attr('align', 'right').html(curr(v.price)));    
      tr.append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity')));
      tr.append($('<td/>').attr('align', 'right').attr('id', 'li_' + li.id + '_subtotal').html(curr(li.price)));
      table.append(tr);
    });
  },
  
  // Show the order summary
  summary_table: function(table)
  {    
    var that = this;
    if (that.order.line_items.length > 0 || that.order.order_packages.length > 0)
    {
      table.append($('<tr/>').append($('<th/>').attr('colspan', '6').html('&nbsp;')));
    }
    
    if (that.order.line_items.length > 0)
    {
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Subtotal' )).append($('<td/>').attr('align', 'right').attr('id', 'subtotal').html(curr(that.order.subtotal))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Tax'      )).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'order_' + that.order.id + '_tax'))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Shipping' )).append($('<td/>').attr('align', 'right').attr('id', 'shipping').html(curr(that.order.shipping))));    
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Handling' )).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'order_' + that.order.id + '_handling'))));
      if (that.order.discounts)
      {
        $.each(that.order.discounts, function(i, d) {
          table.append($('<tr/>')
            .append($('<td/>').attr('colspan', '5').attr('align', 'right')
              .append($('<a/>').attr('href', '#').html('Remove').click(function(e) { that.remove_discount(d.id); }))
              .append(' ' + d.name + ' Discount')
            )
            .append($('<td/>').attr('align', 'right').html(curr(d.amount)))
          );
        });
      }    
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Discount')).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'order_' + that.order.id + '_custom_discount'))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Total' )).append($('<td/>').attr('align', 'right').attr('id', 'total').html(curr(that.order.total))));
    }    
    else
    {
      table.append($('<tr/>').append($('<td/>').attr('colspan', '6')
        .append($('<p/>')
          .append('There are no items in this order. ')
          .append($('<a/>').attr('href','#').html('Add one!').click(function(e) {
            e.preventDefault();
            that.add_variant();              
          }))
        )
      ));            
    }
  },
  
  add_variant: function(variant_id)
  {
    var that = this;
    if (!variant_id)
    {
      caboose_modal_url('/admin/orders/' + this.order.id + '/line-items/new');
      return;
    }
    $.ajax({
      url: '/admin/orders/' + that.order.id + '/line-items',
      type: 'post',
      data: { variant_id: variant_id },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();        
      }
    });
  },
  
  delete_order_package: function(order_package_id)
  {
    var that = this;
    $.ajax({
      url: '/admin/orders/' + that.order.id + '/packages/' + order_package_id,
      type: 'delete',      
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();        
      }
    });    
  },
  
  delete_line_item: function(li_id)
  {
    var that = this;
    $.ajax({
      url: '/admin/orders/' + that.order.id + '/line-items/' + li_id,
      type: 'delete',      
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();        
      }
    });    
  },
  
  void_order: function(confirm)
  {
    var that = this;
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to void this order? ")
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.void_order(true); }))
        .append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }
    $('#message').html("<p class='loading'>Voiding...</p>");
    $.ajax({
      url: '/admin/orders/' + order_id + '/void',
      success: function(resp) {
        if (resp.error)   $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) $('#message').html("<p class='note success'>" + resp.success + "</p>");
        if (resp.refresh) window.location.reload(true);
      }
    });
  }
                              
  //resend_confirmation: function(order_id)
  //{
  //  modal.autosize("<p class='loading'>Resending confirmation..</p>");
  //  $.ajax({
  //    type: 'post',
  //    url: '/admin/orders/' + order_id + '/resend-confirmation',
  //    success: function(resp) {
  //      if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
  //      if (resp.success) modal.autosize("<p class='note success'>" + resp.success + "</p>");
  //    }
  //  });
  //},
  //
  //capture_funds: function(order_id, confirm)
  //{
  //  total = $('#total').html();
  //  if (!confirm)
  //  {    
  //    var p = $('<p/>').addClass('note confirm')
  //      .append("Are you sure you want to charge " + total + " to the customer? ")
  //      .append($('<input/>').attr('type','button').val('Yes').click(function() { capture_funds(order_id, true); }))
  //      .append(' ')
  //      .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); modal.autosize(); }));
  //    modal.autosize(p);
  //    return;
  //  }
  //  modal.autosize("<p class='loading'>Capturing funds...</p>");
  //  $.ajax({
  //    url: '/admin/orders/' + order_id + '/capture',
  //    success: function(resp) {
  //      if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
  //      if (resp.success) modal.autosize("<p class='note success'>" + resp.success + "</p>");
  //      if (resp.refresh) window.location.reload(true);
  //    }
  //  });
  //},    
  //
  //refund_order: function(order_id, confirm)
  //{
  //  if (!confirm)
  //  {    
  //    var p = $('<p/>').addClass('note confirm')
  //      .append("Are you sure you want to refund this order? ")
  //      .append($('<input/>').attr('type','button').val('Yes').click(function() { refund_order(order_id, true); }))
  //      .append(' ')
  //      .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); modal.autosize(); }));
  //    modal.autosize(p);
  //    return;
  //  }
  //  modal.autosize("<p class='loading'>Refunding...</p>");
  //  $.ajax({
  //    url: '/admin/orders/' + order_id + '/refund',
  //    success: function(resp) {
  //      if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
  //      if (resp.success) modal.autosize("<p class='note success'>" + resp.success + "</p>");
  //      if (resp.refresh) window.location.reload(true);
  //    }
  //  });
  //},
  
};
  
  
  
  