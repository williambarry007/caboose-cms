 
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
      $('#'+that.container).empty()
        .append($('<div/>').attr('id', 'vc_message'))
        .append($('<p/>')
          .append("This variant doesn't have any child variants.")          
        );
    }
    else
    {    
      var div = $('<div/>');
      var tbody = $('<tbody/>');
      $.each(that.variant_children, function(i, vc) {
        tbody.append($('<tr/>')
          .append($('<td/>').append(vc.variant.full_title))        
          .append($('<td/>').append(vc.quantity))
        );        
      }); 
      div.append($('<table/>').addClass('data').append(tbody));
      $('#'+that.container).empty().append(div);        
    }
    $('#'+that.container)
      .append($('<div/>').attr('id', 'new_vc_container')        
        .append($('<a/>').attr('href', '#').append('Add Variant to Bundle').click(function(e) { e.preventDefault(); that.add_variant_child(); }))
      );    
    $('#'+that.container).show();
  },
  
  add_variant_child: function(variant_id)
  {
    var that = this;
    if (!variant_id)
    {      
      $('#new_vc_container').empty()
        .append($('<div/>').addClass('note warning')
          .append($('<div/>').attr('id', 'new_vc_message'))
          .append($('<p/>').append($('<input/>').attr('type', 'text').attr('placeholder', 'Product Name').keyup(function() { that.show_products($(this).val()); })))
          .append($('<div/>').attr('id', 'products'))
        );        
      return;
    }
    $('#new_vc_container').html("<p class='loading'>Adding variant...</p>");
    $.ajax({
      url: '/admin/products/' + that.product_id + '/variants/' + that.variant_id + '/children',
      type: 'post',
      data: { variant_id: variant_id },
      success: function(resp) {
        if (resp.error) $('#new_vc_container').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) that.refresh_and_print();        
      }
    });    
  },
  
  show_products: function(title)
  {
    var that = this;
    $.ajax({
      url: '/admin/products/stubs',
      type: 'get',
      data: { title: title },
      success: function(products) {
        if (products && products.length > 0)
        {
          var ul = $('<ul/>');
          $.each(products, function(i, p) {
            ul.append($('<li/>')
              .attr('id', 'product_id_' + p.id)
              .data('product_id', p.id)
              .data('variant_id', p.variant_id)            
              .append($('<a/>').attr('href', '#').html(p.title).click(function(e) {
                e.preventDefault();
                
                var li = $(e.target).parent();
                var product_id = li.data('product_id');
                var variant_id = li.data('variant_id');              
                
                if (variant_id && variant_id != null)
                  that.add_variant_child(variant_id);
                else              
                  that.show_variants(li, product_id);                                        
              }))
            );
          });
          $('#products').empty().append(ul);
        }
        else
        {
          $('#products').empty().append($('<p/>').html('No products met your search.'));
        }        
      } 
    });
  },

  show_variants: function(li, product_id)
  {
    var that = this;
    if (that.open_product_id && that.open_product_id == product_id)
    {
      $('#product_id_' + that.open_product_id).find('ul').remove();
      that.open_product_id = false;
      return;
    }
    if (that.open_product_id)  
    {
      $('#product_id_' + that.open_product_id).find('ul').remove();
      that.open_product_id = false;
    }  
    that.open_product_id = product_id;
    $.ajax({
      url: '/admin/products/' + product_id + '/variants/json',
      type: 'get',        
      success: function(resp) {
        var ul = $('<ul/>');
        $.each(resp.models, function(i, v) {
          var name = [];
          if (v.option1) name.push(v.option1);
          if (v.option2) name.push(v.option2);
          if (v.option3) name.push(v.option3);
          name = name.join(' / ');
          if (!name || name.length == 0) name = 'Default';
          ul.append($('<li/>')
            .data('variant_id', v.id)          
            .append($('<a/>').attr('href', '#').html(name).click(function(e) {
              e.preventDefault();
              variant_id = $(e.target).parent().data('variant_id');
              that.add_variant_child(variant_id);              
            }))
          );
        });
        li.append(ul);        
      }
    });  
  }
  
};
