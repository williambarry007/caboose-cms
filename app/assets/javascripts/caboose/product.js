//
// Product
//

Caboose.Store.Modules.Product = (function() {
  var self = {
    templates: {
      images:  JST['caboose/product/images'],
      options: JST['caboose/product/options']
    }
  };
  
  //
  // Initialize
  //
  
  self.initialize = function() {
    self.$product = $('#product');
    self.$price = self.$product.find('#product-price');
    if (!self.$product.length) return false;

    $.get('/products/' + self.$product.data('id') + '/info', function(response) {
      self.product = response.product;
      self.option1_values = response.option1_values;
      self.option2_values = response.option2_values;
      self.option3_values = response.option3_values;
      self.render();
      self.bind_events();
      self.set_variant(self.get_initial_variant());
      self.set_options_from_variant(self.variant);
    });
    
  };
  
  //
  // Render
  //  
  self.render = function() {
    var render_functions = [];
    render_functions.push(self.render_images);
    render_functions.push(self.render_options);
    
    _.each(render_functions, function(render_function, index) {
      var finished = index == (render_functions.length - 1);
      
      render_function(function() {
        if (finished) self.$product.removeClass('loading');
      });
    });
  };

  self.initalize_zoom = function(image_url) {
    var big_image = $("#product-images").children("figure").first();
    big_image.data("zoom-image",image_url);
    big_image.elevateZoom();
  }
  
  self.render_images = function(callback) {
    self.$images = $('#product-images', self.$product);        
    if (!self.$images.length) return false;
    self.$images.empty().html(self.templates.images({ images: self.product.images }));
    if (callback) callback();
  };
  
  self.render_options = function(callback) {
    self.$options = $('#product-options', self.$options);
    if (!self.$options.length) return false;
    self.$options.empty().html(self.templates.options({ options: self.get_options_with_all_values() }));
    if (callback) callback();
  };
  
  //
  // Out of Stock
  //
  
  self.out_of_stock = function() {
    self.$product.find('#add-to-cart').after($('<p/>').addClass('message error').text('Out of Stock')).remove();
  };
  
  //
  // Events
  //
  
  self.bind_events = function() {
    self.$images.find('ul > li > figure').on('click', self.thumb_click_handler);
    self.$images.children('figure').on('click', self.image_click_handler);
    self.$options.find('ul').on('click', 'li', self.option_click_handler);
  };
  
  self.thumb_click_handler = function(event) {
    self.$images.children('figure').css('background-image', 'url(' + $(event.target).data('url-large') + ')');
    self.initalize_zoom($(event.target).data('url-large').replace('large','huge'));
  };
  
  self.image_click_handler = function(event) {
    window.location = $(event.target).css('background-image').match(/^url\("(.*)"\)$/)[1];
  };
  
  self.option_click_handler = function(event) {
    var $target_option = $(event.delegateTarget)
    var $target_value  = $(event.target);
    
    if ($target_value.hasClass('selected')) {
      $target_value.removeClass('selected');
      $target_value = $();
    } else {
      $target_value.addClass('selected').siblings().removeClass('selected');
      
      self.$options.find('ul').not($target_option).each(function(index, element) {
        var $currentOption = $(element)
          , $currentValue = $currentOption.children('.selected')
          , $otherOption = self.$options.find('ul').not($target_option.add($currentOption))
          , $otherValue = $otherOption.children('.selected')
          , options = [];
        
        if (!$currentValue.length) return true;
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        options.push({ name: $target_option.data('name'), value: $target_value.data('value') });
        
        if (!!!self.get_variant_from_options(options)) {
          $currentValue.removeClass('selected');
        } else if ($otherOption.length && $otherValue.length) {
          options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
          if (!!!self.get_variant_from_options(options)) $otherValue.removeClass('selected');
        }
      });
      
      $target_option.children().each(function(index, element) {
        var $currentOption = $target_option
          , $currentValue = $(element)
          , $otherOption = self.$options.find('ul').not($target_option).first()
          , $otherValue = $otherOption.children('.selected')
          , $otherOtherOption = self.$options.find('ul').not($target_option.add($otherOption))
          , $otherOtherValue = $otherOtherOption.children('.selected')
          , options = [];
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        if ($otherOption.length && $otherValue.length) options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
        if ($otherOtherOption.length && $otherOtherValue.length) options.push({ name: $otherOtherOption.data('name'), value: $otherOtherValue.data('value') });
        self.toggle_option_value($currentValue, !!self.get_variant_from_options(options));
      });
    }
    
    self.$options.find('ul').not($target_option).each(function(index, element) {
      var $currentOption = $(element);
      
      $currentOption.children().each(function(index, element) {
        var $currentValue = $(element)
          , $otherOption = self.$options.find('ul').not($target_option.add($currentOption))
          , $otherValue = $otherOption.children('.selected')
          , options = [];
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        if ($target_option.length && $target_value.length) options.push({ name: $target_option.data('name'), value: $target_value.data('value') });
        if ($otherOption.length && $otherValue.length) options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
        self.toggle_option_value($currentValue, !!self.get_variant_from_options(options));
      });
    });
    
    self.set_variant(self.get_variant_from_options(self.get_current_options()));
  };
  
  //
  // Option Methods
  //
  
  self.get_options_from_product = function() {
    return _.compact([
      self.product.option1 ? self.product.option1 : undefined,
      self.product.option2 ? self.product.option2 : undefined,
      self.product.option3 ? self.product.option3 : undefined
    ]);
  };
  
    
  self.get_options_from_variant = function(variant) {
    return _.compact([
      self.product.option1 ? { name: self.product.option1, value: variant.option1 } : undefined,
      self.product.option2 ? { name: self.product.option2, value: variant.option2 } : undefined,
      self.product.option3 ? { name: self.product.option3, value: variant.option3 } : undefined
    ]);
  };
  
  self.get_options_with_all_values = function() {
    var options = [];
    if (self.product.option1) options.push({ name: self.product.option1, values: self.option1_values });
    if (self.product.option2) options.push({ name: self.product.option2, values: self.option2_values });
    if (self.product.option3) options.push({ name: self.product.option3, values: self.option3_values });
    return options;          
  };
  
  self.get_option_attribute = function(option) {
    optionName = _.isObject(option) ? option.name : option;
    
    if (self.product.option1 == optionName) {
      return 'option1';
    } else if (self.product.option2 == optionName) {
      return 'option2';
    } else if (self.product.option3 == optionName) {
      return 'option3';
    }
  };
  
  self.get_current_options = function() {
    var options = [];
    
    self.$options.children('ul').each(function(index, element) {
      var $option = $(element);
      
      options.push({
        name: $option.data('name'),
        value: $option.children('.selected').first().data('value')
      });
    });
    
    return options;
  };
  
  self.toggle_option_value = function($value, on) {
    if (on) {
      $value.addClass('available').removeClass('unavailable');
    } else {
      $value.addClass('unavailable').removeClass('available selected');
    }
  };
  
  //
  // Variant Methods
  //
  
  self.get_initial_variant = function () {
    var variant = _.find(self.product.variants, function(variant) {
      return variant.quantity_in_stock > 0;
    });
    
    if (!variant) {
      variant = _.first(self.product.variants);
      self.out_of_stock();
    }
    
    return variant;
  };
  
  self.get_variant_from_options = function(options) {
    if (_.find(options, function(option) { return option.value == undefined })) return false;
    
    var attributes = _.object(_.map(options, function(option) {
      return [self.get_option_attribute(option.name), option.value.toString()]
    }));
    
    var variants = _.sortBy(_.where(self.product.variants, attributes), function(variant) { return variant.price });
    return _.find(variants, function(variant) { return variant.quantity_in_stock > 0 });
  };
  
  self.set_options_from_variant = function(variant) {
    if (variant.option1) $('#option1 li[data-value="' + variant.option1 + '"]', self.$options).click();
    if (variant.option1) $('#option2 li[data-value="' + variant.option2 + '"]', self.$options).click();
    if (variant.option1) $('#option3 li[data-value="' + variant.option3 + '"]', self.$options).click();
  };
  
  self.set_variant = function(variant) {
    self.variant = variant;
    Caboose.Store.Modules.Cart.set_variant(variant);
    if (variant) self.set_image_from_variant(variant);
    if (variant && self.$price.length) self.$price.empty().text('$' + parseFloat((variant.price * 100) / 100).toFixed(2));

  };

  self.variant_on_sale = function(variant) {
    if (variant.sale_price == "") {
      return false;
    }
    else {
      
    }
    d = DateTime.now.utc
    return false if self.date_sale_starts && d < self.date_sale_starts
    return false if self.date_sale_ends   && d > self.date_sale_ends
    return true
  
  }
  
  self.get_variant = function(id) {
    return _.find(self.product.variants, function(variant) { return variant.id == (id || self.variant.id) });
  };
  
  //
  // Image Methods
  //
  
  self.set_image_from_variant = function(variant) {    
    if (!variant || !variant.images || variant.images.length == 0 || !variant.images[0]) return;
    self.$product.trigger('variant:updated');
    
    var $figure = self.$images.children('figure');   
    if (variant.images && variant.images.length > 0 && variant.images[0]) {
      $figure.css('background-image', 'url(' + variant.images[0].urls.large + ')');
      self.initalize_zoom(variant.images[0].urls.huge);
    } else if ($figure.css('background-image').toLowerCase() == 'none') {
      $figure.css('background-image', 'url(' + _.first(self.product.images).urls.large + ')');
      self.initalize_zoom(_.first(self.product.images).urls.huge);
    }
    
  };
  
  return self;
}).call(Caboose.Store);

