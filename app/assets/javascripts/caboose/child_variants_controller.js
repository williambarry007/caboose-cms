 
var ChildVariantsController = function(params) { this.init(params); };

ChildVariantsController.prototype = {

  container: 'child_variants',
  product_id: false,
  variant_id: false,
  variant_children: false,
  authenticity_token: false,
    
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];    
    that.refresh_and_print();        
  },
  
  refresh: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/products/' + that.product_id + '/variants/' + that.variant_id + '/children/json',
      type: 'get'
      success: function(resp) {
        that.variant_children = resp.variant_children;
        if (after) after();        
      }       
    });    
  },
  
  print: function()
  {
    var that = this;
    
    if (!that.variant_children || that.variant_children.length == 0)
    {
      $(that.container).empty().append("This variant doesn't have any child variants.");
      return;
    }
    
    var div = $('<div/>');
    var tbody = $('<tbody/>');
    $.each(that.variant_children, function(i, vc) {
      tbody.append($('<tr/>')
        .append($('<td/>').append(vc.variant.product.name))        
        .append($('<td/>').append(vc.quantity))
      );        
    }); 
    div.append($('<table/>').addClass('data').append(tbody);
    $('#'+that.container).empty().append(div);
  }
  
      
  
};
