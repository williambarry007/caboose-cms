
var BillingAddressController = function(params) { this.init(params); };

BillingAddressController.prototype = {

  cc: false,
  model_binder: false,
      
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];        
  },
  
  print: function()
  {
    var that = this;
    var ba = that.cc.order.billing_address;
          
    var div = $('<div/>').append($('<h3/>').html('Billing Address'));
    
    if (that.cc.is_empty_address(ba))
      div.append($('<p/>').append('[Empty]'));
    else
    {
      var name = ba.first_name + ' ' + ba.last_name;
      if (name.length == 0) name = '[Empty name]';
      var address = ba.address1.length > 0 ? ba.address1 : '[Empty address]'
      var city_state_zip = (ba.city.length > 0 ? ba.city : '[Empty city]') + ', ' + (ba.state.length > 0 ? ba.state : '[Empty state]') + ' ' + (ba.zip.length > 0 ? ba.zip : '[Empty zip]') 
      
                                  div.append($('<span/>').addClass('name'           ).html(name           )).append($('<br/>'));
      if (ba.company.length > 0)  div.append($('<span/>').addClass('company'        ).html(ba.company     )).append($('<br/>'));
                                  div.append($('<span/>').addClass('address1'       ).html(address        )).append($('<br/>'));
      if (ba.address2.length > 0) div.append($('<span/>').addClass('address2'       ).html(ba.address2    )).append($('<br/>'));
                                  div.append($('<span/>').addClass('city_state_zip' ).html(city_state_zip )).append($('<br/>'));
    }

    div.append($('<p/>').append($('<a/>').attr('href', '#').html('Edit').click(function(e) { e.preventDefault(); that.edit(); })));              
    $('#billing_address_container').empty().append(div);
  },
      
  edit: function()
  {
    var that = this;
    var ba = that.cc.order.billing_address;
    if (!ba.id) ba.id = 1;
    
    var div = $('<div/>')          
      .append($('<h3/>').html('Billing Address'))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_first_name' ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_last_name'  ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_company'    ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_address1'   ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_address2'   ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_city'       ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_state'      ))
      .append($('<div/>').attr('id', 'billingaddress_' + ba.id + '_zip'        ));
    $('#billing_address_container').empty().append(div);
    
    that.model_binder = new ModelBinder({
      name: 'BillingAddress',
      id: ba.id,
      update_url: '/checkout/billing-address',
      authenticity_token: that.cc.authenticity_token,
      attributes: [      
        { name: 'first_name'  , wrapper_class: 'first_name' , nice_name: 'First Name'  , type: 'text'     , value: ba.first_name , width:  '50%' , fixed_placeholder: false }, 
        { name: 'last_name'   , wrapper_class: 'last_name'  , nice_name: 'Last Name'   , type: 'text'     , value: ba.last_name  , width:  '50%' , fixed_placeholder: false }, 
        { name: 'company'     , wrapper_class: 'company'    , nice_name: 'Company'     , type: 'text'     , value: ba.company    , width: '100%' , fixed_placeholder: false }, 
        { name: 'address1'    , wrapper_class: 'address1'   , nice_name: 'Address 1'   , type: 'text'     , value: ba.address1   , width: '100%' , fixed_placeholder: false }, 
        { name: 'address2'    , wrapper_class: 'address2'   , nice_name: 'Address 2'   , type: 'text'     , value: ba.address2   , width: '100%' , fixed_placeholder: false }, 
        { name: 'city'        , wrapper_class: 'city'       , nice_name: 'City'        , type: 'text'     , value: ba.city       , width:  '25%' , fixed_placeholder: false },         
        { name: 'zip'         , wrapper_class: 'zip'        , nice_name: 'Zip'         , type: 'text'     , value: ba.zip        , width:  '25%' , fixed_placeholder: false },
        { name: 'state'       , wrapper_class: 'state'      , nice_name: 'State'       , type: 'select'   , value: ba.state      , width:  '25%' , fixed_placeholder: false , options_url: '/checkout/state-options' }                  
      ]            
    });            
  },
  
  ready: function()
  {
    var that = this;
    if (that.cc.is_empty_address(that.cc.order.billing_address)) return false;
    return true;        
  }
};
