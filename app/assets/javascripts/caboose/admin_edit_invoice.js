
var InvoiceController = function(params) { this.init(params); }

InvoiceController.prototype = {
  
  invoice_id: false,
  invoice: false,
  authenticity_token: false,
  store_config: false,
  
  init: function(params)
  {
    for (var i in params)
      this[i] = params[i];
    
    var that = this;            
    $(document).ready(function() {
      that.get_store_config();
      that.refresh(); 
    });
  },
  
  get_store_config: function()
  {
    var that = this;
    $.ajax({
      url: '/admin/store/json',
      success: function(sc) { that.store_config = sc; },
      async: false
    });    
  },
  
  refresh: function(after)
  {
    var that = this;
    that.refresh_invoice(function() {
      $('#invoice_table').html("<p class='loading'>Getting invoice...</p>");
      that.print();
      that.make_editable();
      if (after) after();
    });    
  },
  
  refresh_invoice: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/invoices/' + that.invoice_id + '/json',
      success: function(invoice) {                 
        that.invoice = invoice;
        that.refresh_numbers();
        if (after) after();                      
      }
    });
  },
  
  refresh_numbers: function()
  {    
    var that = this;        
    $('#subtotal').html(curr(that.invoice.subtotal));        
    $('#shipping').html(curr(that.invoice.shipping));                    
    $('#total'   ).html(curr(that.invoice.total   ));        
    $.each(that.invoice.line_items, function(i, li) {
      $('#li_' + li.id + '_subtotal').html(curr(li.subtotal));
    }); 
  },  
  
  make_editable: function()
  {    
    var that = this;
    $.each(that.invoice.invoice_packages, function(i, op) {
      new ModelBinder({
        name: 'InvoicePackage',
        id: op.id,
        update_url: '/admin/invoices/' + op.invoice_id + '/packages/' + op.id,
        authenticity_token: that.authenticity_token,
        attributes: [                      
          { name: 'status'          , nice_name: 'Status'          , type: 'select' , value: op.status                                            , width: 300, fixed_placeholder: true , options_url: '/admin/invoices/line-items/status-options' },
          { name: 'package_method'  , nice_name: 'Package/Method'  , type: 'select' , value: op.shipping_package_id + '_' + op.shipping_method_id , width: 300, fixed_placeholder: false, options_url: '/admin/shipping-packages/package-method-options' },
          { name: 'tracking_number' , nice_name: 'Tracking Number' , type: 'text'   , value: op.tracking_number                                   , width: 300, fixed_placeholder: true, align: 'right' },
          { name: 'total'           , nice_name: 'Shipping Total'  , type: 'text'   , value: curr(op.total)                                       , width: 300, fixed_placeholder: true, align: 'right' , after_update: function() { that.refresh_invoice(); }}
        ]
      });              
    });    
    $.each(that.invoice.line_items, function(i, li) {        
      new ModelBinder({
        name: 'Lineitem',
        id: li.id,
        update_url: '/admin/invoices/' + li.invoice_id + '/line-items/' + li.id,
        authenticity_token: that.authenticity_token,
        attributes: [
          { name: 'status'          , nice_name: 'Status'           , type: 'select'  , align: 'left' , value: li.status          , text: li.status, width: 150, fixed_placeholder: false, options_url: '/admin/invoices/line-items/status-options' },
          { name: 'tracking_number' , nice_name: 'Tracking Number'  , type: 'text'    , align: 'left' , value: li.tracking_number , width: 200, fixed_placeholder: false },
          { name: 'quantity'        , nice_name: 'Quantity'         , type: 'text'    , align: 'right', value: li.quantity        , width:  75, fixed_placeholder: false, after_update: function() { that.refresh_invoice(); } }
        ]
      });
    });    
    new ModelBinder({
      name: 'Invoice',
      id: that.invoice.id,
      update_url: '/admin/invoices/' + that.invoice.id,
      authenticity_token: that.authenticity_token,
      attributes: [
        { name: 'status'         , nice_name: 'Status'   , type: 'select', value: that.invoice.status                , width: 100, fixed_placeholder: false, options_url: '/admin/invoices/status-options' },
        { name: 'tax'            , nice_name: 'Tax'      , type: 'text'  , value: curr(that.invoice.tax)             , width: 100, fixed_placeholder: false, align: 'right' , after_update: function() { that.refresh_invoice(); }},
        { name: 'handling'       , nice_name: 'Handling' , type: 'text'  , value: curr(that.invoice.handling)        , width: 100, fixed_placeholder: false, align: 'right' , after_update: function() { that.refresh_invoice(); }},
        { name: 'custom_discount', nice_name: 'Discount' , type: 'text'  , value: curr(that.invoice.custom_discount) , width: 100, fixed_placeholder: false, align: 'right' , after_update: function() { that.refresh_invoice(); }}
      ]
    });        
  },
  
  assign_to_package_form: function(li_id)
  {
    var that = this;
    if (!that.invoice.invoice_packages)
      that.invoice.invoice_packages = [];
    if (that.invoice.invoice_packages.length == 0)
    {
      that.assign_to_new_package_form(li_id);
      return;
    }
    
    var select = $('<select/>').attr('id', 'invoice_package_id').css('width', '300px').change(function(e) {
      var invoice_package_id = $(this).val();
      if (invoice_package_id == -1)
        that.assign_to_new_package_form(li_id);
      else
        that.assign_to_package(li_id, invoice_package_id);
    });
    select.append($('<option/>').val(-1).html('-- Select a package --'));
    $.each(that.invoice.invoice_packages, function(i, op) {        
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
          .change(function(e) { // Create the new invoice package
            var arr = $(this).val().split('_');            
            $.ajax({
              url: '/admin/invoices/' + that.invoice.id + '/packages',
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

  assign_to_package: function(li_id, invoice_package_id)
  {
    var that = this;    
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/line-items/' + li_id,
      type: 'put',
      data: { invoice_package_id: invoice_package_id },
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
      url: '/admin/invoices/' + that.invoice.id + '/line-items/' + li_id,
      type: 'put',
      data: { invoice_package_id: -1 },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();
      }
    });    
  },

/******************************************************************************/

  print_invoice: function()
  {
    var that = this;
    window.open('/admin/invoices/' + that.invoice.id + '/print');
  },  
    
  line_items_for_invoice_package: function(invoice_package_id)
  {
    var that = this;
    var line_items = [];
    $.each(that.invoice.line_items, function(i, li) {
      if (li.invoice_package_id == invoice_package_id)
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
    that.invoice_packages_table(table);
    that.unassigned_line_items_table(table);
    that.summary_table(table);    
    $('#invoice_table').empty().append(table);
    
    that.button_controls();
  },
  
  overview_table: function()
  {
    var that = this;        
    
    var transactions = that.transactions_table();                
    var table = $('<table/>').addClass('data');
    table.append($('<tr/>')  
      .append($('<th/>').html('Customer'))
      .append($('<th/>').html('Shipping Address'))
      .append($('<th/>').html('Billing Address'))
      .append($('<th/>').html('Invoice Status'))
      .append($('<th/>').html('Payment Status'))      
    );    
    table.append($('<tr/>')      
      .append($('<td/>').attr('valign', 'top')
        .append($('<div/>').attr('id', 'customer').append(that.noneditable_customer(true)))
        .append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
          var a = $(this);
          that.refresh_invoice(function() {
            if (a.html() == 'Edit') { that.edit_customer();        a.html('Finished'); }
            else                    { that.noneditable_customer(); a.html('Edit');     }
          });
        }))
      )      
      .append($('<td/>').attr('valign', 'top').attr('id', 'shipping_address' ).append(that.noneditable_shipping_address()))      
      .append($('<td/>').attr('valign', 'top').attr('id', 'billing_address'  ).append(that.noneditable_billing_address()))        
      .append($('<td/>').attr('valign', 'top').append($('<div/>').attr('id', 'invoice_' + that.invoice.id + '_status')))
      .append($('<td/>').attr('valign', 'top').attr('id', 'transactions').attr('align', 'center').append(transactions))      
    );
    return table;  
  },
  
  transactions_table: function()
  {    
    var that = this;
    var div = $('<div/>')
      .append($('<span/>').attr('id', 'financial_status').append(that.invoice.financial_status)).append(' ')
      .append($('<a/>').attr('href', '#').html('refresh').click(function(e) { e.preventDefault(); that.refresh_transactions(); }));    
    if (that.invoice.invoice_transactions.length > 0)        
    {
      var transactions_table = $('<table/>').addClass('data');
      $.each(that.invoice.invoice_transactions, function(i, ot) {
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
      div.append(transactions_table);
    }
    return div;    
  },
    
  refresh_transactions: function()
  {
    var that = this;
    $('#transactions').html("<p class='loading'>Refreshing transactions...</p>");
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/refresh-transactions',
      type: 'get',
      success: function(resp) {
        if (resp.error) $('#financial_status').html("Error: " + resp.error);
        else
        {
          that.invoice.financial_status = resp.financial_status;
          that.invoice.invoice_transactions = resp.invoice_transactions;
          $('#transactions').empty().append(that.transactions_table());          
        }
      }
    });          
  },
  
  noneditable_customer: function(return_element)
  {
    var that = this;
    c = that.invoice.customer;    
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
    var div = $('<div/>').attr('id', 'invoice_' + that.invoice.id + '_customer_id');        
    $('#customer').empty().append(div);
            
    new ModelBinder({
      name: 'Invoice',
      id: that.invoice.id,
      update_url: '/admin/invoices/' + that.invoice.id,
      authenticity_token: that.authenticity_token,
      attributes: [        
        { name: 'customer_id', nice_name: 'Customer', type: 'select', value: that.invoice.customer_id, width: 150, fixed_placeholder: false, options_url: '/admin/users/options' }        
      ]
    });
  },
  
  noneditable_shipping_address: function()
  {
    var that = this;
    var div = $('<div/>');
    if (that.has_shippable_items())
    {
      var sa = that.invoice.shipping_address;
      str = '';                  
      str += (sa.first_name ? sa.first_name : '[Empty first name]') + ' ';
      str += (sa.last_name  ? sa.last_name  : '[Empty last name]');
      str += '<br />' + (sa.address1 ? sa.address1 : '[Empty address]');
      if (sa.address2) str += "<br />" + sa.address2;
      str += '<br/>' + (sa.city ? sa.city : '[Empty city]') + ", " + (sa.state ? sa.state : '[Empty state]') + " " + (sa.zip ? sa.zip : '[Empty zip]');
      
      div.append($('<div/>').attr('id', 'shipping_address').append(str));
      div.append($('<a/>').attr('href', '#').html('Edit').click(function(e) {
        var a = $(this);
        that.refresh_invoice(function() { that.edit_shipping_address(); });
      }));      
    }
    else
    {
      div.append("This invoice does not require shipping.");
    }    
    return div;    
  },
  
  edit_shipping_address: function()
  {
    var that = this;
    var sa = that.invoice.shipping_address;
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
        that.refresh_invoice(function() { $('#shipping_address').empty().append(that.noneditable_shipping_address()); });
      }));
            
    new ModelBinder({
      name: 'ShippingAddress',
      id: sa.id,
      update_url: '/admin/invoices/' + that.invoice.id + '/shipping-address',
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
    
    var sa = that.invoice.billing_address;
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
        that.refresh_invoice(function() { that.edit_billing_address(); });
      }));
    return div;    
  },
  
  edit_billing_address: function()
  {
    var that = this;
    var sa = that.invoice.billing_address;
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
        that.refresh_invoice(function() { $('#billing_address').empty().append(that.noneditable_billing_address()); });
      }));      
            
    new ModelBinder({
      name: 'BillingAddress',
      id: sa.id,
      update_url: '/admin/invoices/' + that.invoice.id + '/billing-address',
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
  invoice_packages_table: function(table)
  {
    var that = this;    
    $.each(that.invoice.invoice_packages, function(i, op) {
      var line_items = that.line_items_for_invoice_package(op.id);      
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
            tr.append($('<td/>').attr('rowspan', line_items.length).attr('valign', 'top').append(that.package_summary(op, line_items)));
          }                       
          tr.append($('<td/>')
            .append(that.line_item_link(li))
            .append(that.line_item_weight(li))
            .append(that.gift_options(li))
            .append($('<div/>').attr('id', 'line_item_' + li.id + '_message'))
          );
          tr.append($('<td/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_status')))      
          tr.append($('<td/>').attr('align', 'right').html(curr(li.unit_price)));    
          tr.append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity')));
          tr.append($('<td/>').attr('align', 'right').attr('id', 'li_' + li.id + '_subtotal').html(curr(li.subtotal)));        
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
              .append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_package_method'))
              .append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_status'))
              .append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_tracking_number'))
              .append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_total'))
            )
            .append($('<td/>').attr('colspan', '5')
              .append($('<p>')
                .append("This package is empty. ")
                .append($('<a/>').attr('href', '#').html('Delete Package').data('op_id', op.id).click(function(e) { e.preventDefault(); that.delete_invoice_package($(this).data('op_id')); }))
              )
            )
          );
      }
    });
  },
  
  package_summary: function(op, line_items)
  {
    var that = this;
    
    var total_weight = 0.0;
    $.each(line_items, function(i, li) {      
      total_weight += li.variant.weight * li.quantity;
    });
    
    var div = $('<div/>');                
    div.append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_package_method'));
    div.append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_status'));
    div.append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_tracking_number'));
    div.append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_total'));    
    div.append($('<div/>').attr('id', 'invoicepackage_' + op.id + '_total_weight').html("Total weight: " + total_weight + " " + that.store_config.weight_unit));
    div.append($('<a/>').attr('href','#').data('invoice_package_id', op.id).html('Recalculate').click(function(e) { e.preventDefault(); that.calculate_shipping($(this).data('invoice_package_id')); }));            
    div.append($('<div/>').attr('id', 'invoice_package_' + op.id + '_message'));            
    return div;
  },
  
  gift_options: function(li)
  {
    var div = $('<div/>');
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
    return div;
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
      .data('invoice_package_id', li.invoice_package_id)
      .click(function(e) {
        e.preventDefault();
        that.line_item_options($(this).data('li_id'), $(this).data('invoice_package_id'));
      });
    return link;    
  },
  
  line_item_weight: function(li)
  {
    var that = this;
    var v = li.variant;
    div = $('<div/>');
    div.append("Unit Weight: " + Math.floor(v.weight) + " " + that.store_config.weight_unit + "<br />");
    div.append("Total Weight: " + Math.floor(v.weight * li.quantity) + " " + that.store_config.weight_unit);
    return div;        
  },
  
  line_item_options: function(li_id, invoice_package_id)
  {
    var that = this;
    var ul = $('<ul/>').addClass('line_item_controls');
    ul.append($('<li/>').append($('<a/>')
      .html('View Product')
      .attr('href', '/admin/invoices/' + that.invoice.id + '/line-items/' + li_id + '/highlight')
    ))
    if (invoice_package_id && invoice_package_id != -1)
    {
      ul.append($('<li/>').append($('<a/>')
        .html('Remove from Package')
        .attr('href', '#')
        .data('li_id', li_id)
        .click(function(e) { e.preventDefault(); that.unassign_from_package($(this).data('li_id')); })
      ));
    }    
    ul.append($('<li/>').append($('<a/>')
      .html('Remove from Invoice')
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
    $.each(that.invoice.line_items, function(i, li) {
      if (!li.invoice_package_id || li.invoice_package_id == -1)
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
      .append($('<th/>').html('Unit Price' ))
      .append($('<th/>').html('Quantity'   ))
      .append($('<th/>').html('Subtotal'   ))
    );
    
    $.each(that.invoice.line_items, function(i, li) {
      if (li.invoice_package_id && li.invoice_package_id != -1) return true;
            
      var div = false;
      
      if (li.variant.downloadable)
      {
        div = $('<div/>').append('This item is downloadable.');
      }
      else
      {        
        div = $('<div/>').attr('id', 'assign_to_package_' + li.id)
          .append('Unpackaged! ')
          .append($('<a/>').data('line_item_id', li.id).attr('href', '#').html('Assign to package').click(function(e) {
            e.preventDefault();
            e.stopPropagation();
            that.assign_to_package_form($(this).data('line_item_id'));
          }));
      }
                                     
      var tr = $('<tr/>');
      tr.append($('<td/>').append(div));
      tr.append($('<td/>')
        .append(that.line_item_link(li))        
        .append(that.gift_options(li))            
        .append($('<div/>').attr('id', 'line_item_' + li.id + '_message'))
      );            
      tr.append($('<td/>').append($('<div/>').attr('id', 'lineitem_' + li.id + '_status')))      
      tr.append($('<td/>').attr('align', 'right').html(curr(li.unit_price)));    
      tr.append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'lineitem_' + li.id + '_quantity')));
      tr.append($('<td/>').attr('align', 'right').attr('id', 'li_' + li.id + '_subtotal').html(curr(li.subtotal)));
      table.append(tr);
    });
  },
  
  // Show the invoice summary
  summary_table: function(table)
  {    
    var that = this;
    if (that.invoice.line_items.length > 0 || that.invoice.invoice_packages.length > 0)
    {
      table.append($('<tr/>').append($('<th/>').attr('colspan', '6').html('&nbsp;')));
    }
    
    if (that.invoice.line_items.length > 0)
    {
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Subtotal'    )).append($('<td/>').attr('align', 'right').attr('id', 'subtotal').html(curr(that.invoice.subtotal))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').append('Tax '      ).append($('<a/>').attr('href', '#').html('(calculate)').click(function(e) { e.preventDefault(); that.calculate_tax();      }))).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'invoice_' + that.invoice.id + '_tax'))));                
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Shipping'    )).append($('<td/>').attr('align', 'right').attr('id', 'shipping').html(curr(that.invoice.shipping))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').append('Handling ' ).append($('<a/>').attr('href', '#').html('(calculate)').click(function(e) { e.preventDefault(); that.calculate_handling(); }))).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'invoice_' + that.invoice.id + '_handling'))));
      if (that.invoice.discounts)
      {
        $.each(that.invoice.discounts, function(i, d) {
          table.append($('<tr/>')
            .append($('<td/>').attr('colspan', '5').attr('align', 'right')
              .append($('<a/>').attr('href', '#').html('Remove').click(function(e) { that.remove_discount(d.id); }))
              .append(' "' + d.gift_card.code + '" Discount')
            )
            .append($('<td/>').attr('align', 'right').html(curr(d.amount)))
          );
        });
      }    
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Discount')).append($('<td/>').attr('align', 'right').append($('<div/>').attr('id', 'invoice_' + that.invoice.id + '_custom_discount'))));
      table.append($('<tr/>').append($('<td/>').attr('colspan', '5').attr('align', 'right').html('Total' )).append($('<td/>').attr('align', 'right').attr('id', 'total').html(curr(that.invoice.total))));
    }    
    else
    {
      table.append($('<tr/>').append($('<td/>').attr('colspan', '6')
        .append($('<p/>')
          .append('There are no items in this invoice. ')
          .append($('<a/>').attr('href','#').html('Add one!').click(function(e) {
            e.preventDefault();
            that.add_variant();              
          }))
        )
      ));            
    }
  },
  
  button_controls: function()
  {
    var that = this;
    var p = $('<p/>');
    p.append($('<input/>').attr('type', 'button').val('< Back').click(function() { window.location = '/admin/invoices'; })).append(' ');
    if (that.invoice.total > 0)
    {
      switch (that.invoice.financial_status)
      {
        case 'pending':
          p.append($('<input/>').attr('type', 'button').val('Send for Authorization').click(function() { that.send_for_authorization(); })).append(' ');
          break;
        case 'authorized':    
          p.append($('<input/>').attr('type', 'button').val('Capture Funds').click(function() { that.capture_funds(); })).append(' ');
          p.append($('<input/>').attr('type', 'button').val('Void'         ).click(function() { that.void_invoice();    })).append(' ');
          break;
        case 'captured':           
          p.append($('<input/>').attr('type', 'button').val('Refund'       ).click(function() { that.refund(); })).append(' ');
          break;
      }
    }
    //p.append($('<input/>').attr('type', 'button').val('Resend Confirmation' ).click(function() { that.resend_confirmation(); })).append(' ');
    p.append($('<input/>').attr('type', 'button').val('Add Item'            ).click(function() { that.add_variant();         })).append(' ');
    p.append($('<input/>').attr('type', 'button').val('Print Invoice'         ).click(function() { that.print_invoice();         })).append(' ');
    $('#controls').empty().append(p);
  },

  /****************************************************************************/
  
  add_variant: function(variant_id)
  {
    var that = this;
    if (!variant_id)
    {
      caboose_modal_url('/admin/invoices/' + this.invoice.id + '/line-items/new');
      return;
    }
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/line-items',
      type: 'post',
      data: { variant_id: variant_id },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();        
      }
    });
  },
  
  delete_invoice_package: function(invoice_package_id)
  {
    var that = this;
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/packages/' + invoice_package_id,
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
      url: '/admin/invoices/' + that.invoice.id + '/line-items/' + li_id,
      type: 'delete',      
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        else that.refresh();        
      }
    });    
  },
  
  void_invoice: function(confirm)
  {
    var that = this;
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to void this invoice? ")
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.void_invoice(true); }))
        .append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }
    $('#message').html("<p class='loading'>Voiding...</p>");
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/void',
      success: function(resp) {
        if (resp.error)   $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#message').empty(); that.refresh(); }
        if (resp.refresh) { $('#message').empty(); that.refresh(); }
      }
    });
  },
  
  capture_funds: function(confirm)
  {
    var that = this;    
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to charge $" + parseFloat(that.invoice.total).toFixed(2) + " to the customer? ")
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.capture_funds(true); }))
        .append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }
    $('#message').html("<p class='loading'>Capturing funds...</p>");
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/capture',
      success: function(resp) {
        if (resp.error)   $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#message').empty(); that.refresh(); }
        if (resp.refresh) { $('#message').empty(); that.refresh(); }
      }
    });
  },
  
  send_for_authorization: function(confirm)
  {
    var that = this;    
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to send this invoice to the customer for authorization? ")
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.send_for_authorization(true); }))
        .append(' ')                
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }
    $('#message').html("<p class='loading'>Sending for authorization...</p>");
    $.ajax({
      url: '/admin/invoices/' + that.invoice.id + '/send-for-authorization',
      success: function(resp) {
        if (resp.error)   { that.flash_error(resp.error); }
        if (resp.success) { that.refresh(function() { that.flash_success("An email has been sent successfully to the customer."); }); }        
      }
    });
  },

  calculate_tax: function()
  {
    var that = this;
    $.ajax({
      url: '/admin/invoices/' + that.invoice_id + '/calculate-tax',
      success: function(resp) { that.refresh_invoice(function() { $('#invoice_' + that.invoice.id + '_tax').val(that.invoice.tax); }); }
    });
  },
  
  calculate_handling: function()
  {
    var that = this;
    $.ajax({
      url: '/admin/invoices/' + that.invoice_id + '/calculate-handling',
      success: function(resp) { that.refresh_invoice(function() { $('#invoice_' + that.invoice.id + '_handling').val(that.invoice.handling); }); }
    });
  },
  
  calculate_shipping: function(invoice_package_id)
  {
    var that = this;
    $('#invoice_package_' + invoice_package_id + '_message').html("<p class='loading'>Calculating...</p>");
    var shipping_method_id = $('');
    $.ajax({
      url: '/admin/invoices/' + that.invoice_id + '/packages/' + invoice_package_id + '/calculate-shipping',
      success: function(resp) {
        if (resp.error)
          $('#invoice_package_' + invoice_package_id + '_message').html("<p class='note error'>" + resp.error + "</p>");
        else
        {
          that.refresh_invoice(function() { 
            $('#invoicepackage_' + invoice_package_id + '_total').val(resp.rate); 
          });
          $('#invoice_package_' + invoice_package_id + '_message').empty();
        }
      }
    });    
  },
  
  has_shippable_items: function()
  {
    var that = this;
    var needs_shipping = false;
    $.each(that.invoice.line_items, function(i, li) {      
      if (li.variant.downloadable == false)
        needs_shipping = true;
    });
    return needs_shipping;    
  },
  
  flash_success: function(str, length) { this.flash_message("<p class='note success'>" + str + "</p>", length); },
  flash_error:   function(str, length) { this.flash_message("<p class='note error'>" + str + "</p>", length); },    
  flash_message: function(str, length)
  {
    if (!length) length = 5000;
    $('#message').empty().append(str);
    setTimeout(function() { $('#message').slideUp(function() { $('#message').empty().show(); }); }, length);
  }
  
  //resend_confirmation: function(invoice_id)
  //{
  //  modal.autosize("<p class='loading'>Resending confirmation..</p>");
  //  $.ajax({
  //    type: 'post',
  //    url: '/admin/invoices/' + invoice_id + '/resend-confirmation',
  //    success: function(resp) {
  //      if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
  //      if (resp.success) modal.autosize("<p class='note success'>" + resp.success + "</p>");
  //    }
  //  });
  //},
  //      
  //
  //refund_invoice: function(invoice_id, confirm)
  //{
  //  if (!confirm)
  //  {    
  //    var p = $('<p/>').addClass('note confirm')
  //      .append("Are you sure you want to refund this invoice? ")
  //      .append($('<input/>').attr('type','button').val('Yes').click(function() { refund_invoice(invoice_id, true); }))
  //      .append(' ')
  //      .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); modal.autosize(); }));
  //    modal.autosize(p);
  //    return;
  //  }
  //  modal.autosize("<p class='loading'>Refunding...</p>");
  //  $.ajax({
  //    url: '/admin/invoices/' + invoice_id + '/refund',
  //    success: function(resp) {
  //      if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
  //      if (resp.success) modal.autosize("<p class='note success'>" + resp.success + "</p>");
  //      if (resp.refresh) window.location.reload(true);
  //    }
  //  });
  //},
  
};
