 
var VariantChildrenController = function(params) { this.init(params); };

VariantChildrenController.prototype = {

  container: 'variant_children',
  product_id: false,
  variant_id: false,
  variant_children: false,
  authenticity_token: false,
  hide_on_init: false,
          
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i]; 
    if (that.hide_on_init)
      that.refresh_and_hide();
    else
      that.refresh_and_print();
  },
  
  hide: function()
  {
    var that = this;
    $('#'+that.container).hide();    
  },
  
  refresh_and_print: function()
  {
    var that = this;
    that.refresh(function() { that.print(); });
  },
  
  refresh_and_hide: function()
  {
    var that = this;
    that.refresh(function() {
      that.print();
      $('#'+that.container).hide();
    });
  },
  
  refresh: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/products/' + that.product_id + '/variants/' + that.variant_id + '/children/json',
      type: 'get',
      success: function(resp) {
        that.variant_children = resp.models;
        if (after) after();        
      }       
    });    
  },
  
  print: function()
  {
    var that = this;
    $('#'+that.container).show();
        
    if (!that.variant_children || that.variant_children.length == 0)
    {
      $('#'+that.container).empty().append($('<p/>').append("This variant doesn't have any child variants."));
      return;
    }
    
    var div = $('<div/>');
    var tbody = $('<tbody/>');
    $.each(that.variant_children, function(i, vc) {
      tbody.append($('<tr/>')
        .append($('<td/>').append(vc.variant.full_title))        
        .append($('<td/>').append(vc.quantity))
      );        
    }); 
    div.append($('<table/>').addClass('data').append(tbody));
    $('#'+that.container).empty()
      .append(div)
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Add Variant to Bundle').click(function(e) { }))
      );
    
    $('#'+that.container).show();
  }          
};
