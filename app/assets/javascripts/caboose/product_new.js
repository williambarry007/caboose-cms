//
//var ProductController = function(params) { this.init(params); };
//
//ProductController.prototype = {
//  
//  product: false,
//  option_values: [[], [], []],
//      
//  init: function() {    
//    self.$price = self.$product.find('#product-price');
//    $("<span id='percent-off'></span").insertAfter(self.$price);
//    $("<span id='sale-price'></span").insertBefore(self.$price);
//    if (!self.$product.length) return false;
//  },
//  
//  refresh: function(after)
//  {    
//    var that = this;
//    $.ajax({
//      url: '/products/' + that.product.id + '/info',
//      type: 'get',
//      success: function(resp) {
//        that.product = resp.product;
//        that.option_values = [that.option1_values, that.option2_values, that.option3_values];    
//        that.render();        
//        that.set_variant(self.get_initial_variant());
//        that.set_options_from_variant(self.variant);
//      }
//    );    
//  },
//  
//  render: function() 
//  {   
//    var that = this;
//    that.render_images();
//    that.render_options();
//    $('#message').empty();    
//  },
//
//  initalize_zoom: function(image_url) 
//  {
//    var big_image = $("#product-images").children("figure").first();
//    big_image.data("zoom-image",image_url);
//    big_image.elevateZoom();
//  },
//  
//  render_images: function() 
//  {
//    var that = this;
//    var div = $('<div/>').append($('<figure/>').attr('id', 'main_image').click(function(e) {
//      window.location = $(e.target).css('background-image').match(/^url\("(.*)"\)$/)[1];    
//    }));
//    
//    if (that.product.images.length > 0)
//    {
//      var ul = $('<ul/>');
//      $.each(product.images, function(i, image) {                
//        ul.append(
//          $('<li/>').data('id', image.id).append(
//            $('<figure/>')
//              .data('url-large', image.urls.large)
//              .data('url-huge' , image.urls.huge)
//              .css('background-image', "url(" + image.urls.thumb + ")")
//              .click(function(e) {                                 
//                $('#main_image').css('background-image', 'url(' + $(this).data('url-large') + ')');
//                that.initalize_zoom($(this).data('url-huge'));                
//              })
//          )
//        );
//      });
//      div.append(ul);      
//    }
//    else
//    {
//      div.append($('<p/>').html("This product doesn't have any images yet."));
//    }
//    $('#product-images').empty().append(div);
//  },
//  
//  render_options: function() 
//  {
//    var that = this;
//    var div = $('<div/>');            
//        
//    if (that.product.options.length > 0)
//    {
//      $.each(that.product.options, function(i, option) {              
//        div.append($('<h3>').html(option));
//        var ul = $('<ul/>').attr('id', 'option' + (i + 1)).data('name', option);      
//        $.each(that.option_values[i], function(j, option_value) { 
//          ul.append($('<li/>')
//            .attr('id', 'option_' + i + '_' + j)
//            .data('i', i).data('j', j).data('value', option_value)
//            .html(option_value)
//            .click(function(e) { 
//              that.select_option($(this).data('i'), $(this).data('value')); 
//            })
//          );                                          
//        });                
//        div.append(ul);
//      });      
//    }
//    else
//    {
//      div.append($('<p/>').html("This product doesn't have any options."));      
//    }
//    $('#product-options').empty().append(div);            
//  },
//      
//  selected_options: false,
//    
//  select_option: function(option_index, value) 
//  {
//    var that = this;    
//    that.selected_options[option_index] = (that.selected_options[option_index] == value ? false : value);    
//    $('#product-options li').removeClass('available').removeClass('unavailable').removeClass('selected');
//                
//    if (that.product.options.length > 0)
//    {
//      $.each(that.product.options, function(i, option) {
//        $.each(that.option_values[i], function(j, option_value) {
//          var el = $('#option_' + i + '_' + j);
//          if (that.variant_is_available(i, option_value))
//          {
//            el.addClass('available');
//            if (that.selected_options[i] == option_value)
//              el.addClass('selected');
//          }
//          else
//          {
//            el.addClass('unavailable');
//          }
//        });
//      });
//    }
//    //self.set_variant(self.get_variant_from_options(self.get_current_options()));
//  },
//    
//  variant_is_available: function(option_index, option_value)
//  {
//    var that = this;
//    var exists = true;    
//    
//    var options_array = [];
//    $.each(that.product.options, function(i, option) {
//      if (that.selected_option[i] == false) // Any option will work
//      {
//        options_array[i] = that.option_values[i];
//      }
//      else if (i == option_index) // Only the given option_value will work
//      {
//        options_array[i] = [option_value];        
//      }
//      else // Only the previously selected option will work
//      {
//        options_array[i] = [that.selected_option[i]];        
//      }
//    });
//    
//    var found_it = false;
//    $.each(that.product.variants, function(i, v) {
//      var matches = true;
//      $.each(options_array, function(j, option_values) {
//        if (option_values.index_of(v['option'+j]) != -1)
//        {
//          matches = false;
//          return false;
//        }
//      });
//      if (matches)
//      {
//        found_it = true;
//        return false;
//      }
//    });    
//    return found_it;
//  },
//  
//  variant_for_options: function()
//  {
//    var that = this;
//    var exists = true;    
//    
//    var options_array = [];
//    $.each(that.product.options, function(i, option) {      
//      options_array[i] = that.selected_option[i];
//    });
//    
//    var matching_variant = false;
//    $.each(that.product.variants, function(i, v) {
//      var matches = true;
//      $.each(options_array, function(j, option_value) {
//        if (option_value != v['option'+j]) { matches = false; return false; }
//      });
//      if (matches) { matching_variant = v; return false; }
//    });    
//    return matching_variant;
//  },
//  
//  //
//  // Variant Methods
//  //
//  
//  initial_variant: function () 
//  {
//    var that = this;        
//    var available_variants = $.grep(that.product.variants, function(v) { return v.quantity_in_stock > 0; });
//    
//    if (!available_variants)           
//      $('#add-to-cart').after($('<p/>').addClass('message error').text('Out of Stock')).remove();
//    
//    variant = available_variants ? available_variants[0] : that.product.variants[0];
//    return variant;
//  },
//  
//  self.set_variant = function(variant) {
//    self.variant = variant;
//    Caboose.Store.Modules.Cart.set_variant(variant);
//    if (variant) self.set_image_from_variant(variant);
//    if (variant && self.$price.length) self.$price.empty().text('$' + parseFloat((variant.price * 100) / 100).toFixed(2));
//    if (variant && self.variant_on_sale(variant)) {
//      self.$price.addClass("on-sale");
//      var percent = 100 - ((variant.sale_price / variant.price) * 100).toFixed(0);
//      $("#percent-off").text("SALE! Save " + percent + "%");
//      $("#sale-price").text('$' + parseFloat((variant.sale_price * 100) / 100).toFixed(2));
//    }
//    else {
//      self.$price.removeClass("on-sale");
//      $("#percent-off").text('');
//      $("#sale-price").text('');
//    }
//  },
//
//  variant_on_sale: function(variant) 
//  {    
//    if (variant.sale_price != "" && variant.sale_price != 0) 
//    {
//      var d = new Date();
//      if (variant.date_sale_starts && d < variant.date_sale_starts) return false;
//      if (variant.date_sale_ends && d > variant.date_sale_ends)     return false;
//      return true;
//    }
//    return false;
//  },
//  
//  get_variant: function(variant_id) 
//  {    
//    for (var v in this.product.variants)      
//      if (v.id == variant_id)
//        return v;
//    return false;        
//  },
//  
//  //
//  // Option Methods
//  //
//  
//  self.get_option_attribute = function(option) 
//  {
//    optionName = _.isObject(option) ? option.name : option;    
//    if      (self.product.option1 == optionName) { return 'option1'; }
//    else if (self.product.option2 == optionName) { return 'option2'; }
//    else if (self.product.option3 == optionName) { return 'option3'; }
//  },
//  
//  self.get_current_options = function() 
//  {
//    var options = [];
//    
//    self.$options.children('ul').each(function(index, element) {
//      var $option = $(element);
//      
//      options.push({
//        name: $option.data('name'),
//        value: $option.children('.selected').first().data('value')
//      });
//    });
//    
//    return options;
//  },
//  
//  //
//  // Image Methods
//  //
//  
//  set_image_from_variant: function(variant) 
//  {    
//    if (!variant || !variant.images || variant.images.length == 0 || !variant.images[0]) return;
//    
//    $('#main_image').css('background-image', 'url(' + $(this).data('url-large') + ')');
//    that.initalize_zoom($(this).data('url-huge'));
//                
//    var $figure = self.$images.children('figure');   
//    if (variant.images && variant.images.length > 0 && variant.images[0]) {
//      $figure.css('background-image', 'url(' + variant.images[0].urls.large + ')');
//      self.initalize_zoom(variant.images[0].urls.huge);
//    } else if ($figure.css('background-image').toLowerCase() == 'none') {
//      $figure.css('background-image', 'url(' + _.first(self.product.images).urls.large + ')');
//      self.initalize_zoom(_.first(self.product.images).urls.huge);
//    }
//    
//  };
//  
//  return self;
//}).call(Caboose.Store);
//