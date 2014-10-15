//
// Product
//

Caboose.Store.Modules.Product = (function() {
  var self = {
    templates: {
      images: JST['caboose/product/images'],
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
      self.bindEvents();
      self.setVariant(self.getInitialVariant());
      self.setOptionsFromVariant(self.variant);
    });
  };
  
  //
  // Render
  //
  
  self.render = function() {
    var renderFunctions = [];
    renderFunctions.push(self.renderImages);
    renderFunctions.push(self.renderOptions);
    
    _.each(renderFunctions, function(renderFunction, index) {
      var finished = index == (renderFunctions.length - 1);
      
      renderFunction(function() {
        if (finished) self.$product.removeClass('loading');
      });
    });
  };
  
  self.renderImages = function(callback) {
    self.$images = $('#product-images', self.$product);
    if (!self.$images.length) return false;
    self.$images.empty().html(self.templates.images({ images: self.product.images }));
    if (callback) callback();
  };
  
  self.renderOptions = function(callback) {
    self.$options = $('#product-options', self.$options);
    if (!self.$options.length) return false;
    self.$options.empty().html(self.templates.options({ options: self.getOptionsWithAllValues() }));
    if (callback) callback();
  };
  
  //
  // Out of Stock
  //
  
  self.outOfStock = function() {
    self.$product.find('#add-to-cart').after($('<p/>').addClass('message error').text('Out of Stock')).remove();
  };
  
  //
  // Events
  //
  
  self.bindEvents = function() {
    self.$images.find('ul > li > figure').on('click', self.thumbClickHandler);
    self.$images.children('figure').on('click', self.imageClickHandler);
    self.$options.find('ul').on('click', 'li', self.optionClickHandler);
  };
  
  self.thumbClickHandler = function(event) {
    self.$images.children('figure').css('background-image', 'url(' + $(event.target).data('url-large') + ')');
  };
  
  self.imageClickHandler = function(event) {
    window.location = $(event.target).css('background-image').match(/^url\("(.*)"\)$/)[1];
  };
  
  self.optionClickHandler = function(event) {
    var $targetOption = $(event.delegateTarget)
      , $targetValue = $(event.target);
    
    if ($targetValue.hasClass('selected')) {
      $targetValue.removeClass('selected');
      $targetValue = $();
    } else {
      $targetValue.addClass('selected').siblings().removeClass('selected');
      
      self.$options.find('ul').not($targetOption).each(function(index, element) {
        var $currentOption = $(element)
          , $currentValue = $currentOption.children('.selected')
          , $otherOption = self.$options.find('ul').not($targetOption.add($currentOption))
          , $otherValue = $otherOption.children('.selected')
          , options = [];
        
        if (!$currentValue.length) return true;
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        options.push({ name: $targetOption.data('name'), value: $targetValue.data('value') });
        
        if (!!!self.getVariantFromOptions(options)) {
          $currentValue.removeClass('selected');
        } else if ($otherOption.length && $otherValue.length) {
          options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
          if (!!!self.getVariantFromOptions(options)) $otherValue.removeClass('selected');
        }
      });
      
      $targetOption.children().each(function(index, element) {
        var $currentOption = $targetOption
          , $currentValue = $(element)
          , $otherOption = self.$options.find('ul').not($targetOption).first()
          , $otherValue = $otherOption.children('.selected')
          , $otherOtherOption = self.$options.find('ul').not($targetOption.add($otherOption))
          , $otherOtherValue = $otherOtherOption.children('.selected')
          , options = [];
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        if ($otherOption.length && $otherValue.length) options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
        if ($otherOtherOption.length && $otherOtherValue.length) options.push({ name: $otherOtherOption.data('name'), value: $otherOtherValue.data('value') });
        self.toggleOptionValue($currentValue, !!self.getVariantFromOptions(options));
      });
    }
    
    self.$options.find('ul').not($targetOption).each(function(index, element) {
      var $currentOption = $(element);
      
      $currentOption.children().each(function(index, element) {
        var $currentValue = $(element)
          , $otherOption = self.$options.find('ul').not($targetOption.add($currentOption))
          , $otherValue = $otherOption.children('.selected')
          , options = [];
        
        options.push({ name: $currentOption.data('name'), value: $currentValue.data('value') });
        if ($targetOption.length && $targetValue.length) options.push({ name: $targetOption.data('name'), value: $targetValue.data('value') });
        if ($otherOption.length && $otherValue.length) options.push({ name: $otherOption.data('name'), value: $otherValue.data('value') });
        self.toggleOptionValue($currentValue, !!self.getVariantFromOptions(options));
      });
    });
    
    self.setVariant(self.getVariantFromOptions(self.getCurrentOptions()));
  };
  
  //
  // Option Methods
  //
  
  self.getOptionsFromProduct = function() {
    return _.compact([
      self.product.option1 ? self.product.option1 : undefined,
      self.product.option2 ? self.product.option2 : undefined,
      self.product.option3 ? self.product.option3 : undefined
    ]);
  };
  
    
  self.getOptionsFromVariant = function(variant) {
    return _.compact([
      self.product.option1 ? { name: self.product.option1, value: variant.option1 } : undefined,
      self.product.option2 ? { name: self.product.option2, value: variant.option2 } : undefined,
      self.product.option3 ? { name: self.product.option3, value: variant.option3 } : undefined
    ]);
  };
  
  self.getOptionsWithAllValues = function() {
    var options = [];
    if (self.product.option1) options.push({ name: self.product.option1, values: self.option1_values });
    if (self.product.option2) options.push({ name: self.product.option2, values: self.option2_values });
    if (self.product.option3) options.push({ name: self.product.option3, values: self.option3_values });
    return options;          
  };
  
  self.getOptionAttribute = function(option) {
    optionName = _.isObject(option) ? option.name : option;
    
    if (self.product.option1 == optionName) {
      return 'option1';
    } else if (self.product.option2 == optionName) {
      return 'option2';
    } else if (self.product.option3 == optionName) {
      return 'option3';
    }
  };
  
  self.getCurrentOptions = function() {
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
  
  self.toggleOptionValue = function($value, on) {
    if (on) {
      $value.addClass('available').removeClass('unavailable');
    } else {
      $value.addClass('unavailable').removeClass('available selected');
    }
  };
  
  //
  // Variant Methods
  //
  
  self.getInitialVariant = function () {
    var variant = _.find(self.product.variants, function(variant) {
      return variant.quantity_in_stock > 0;
    });
    
    if (!variant) {
      variant = _.first(self.product.variants);
      self.outOfStock();
    }
    
    return variant;
  };
  
  self.getVariantFromOptions = function(options) {
    if (_.find(options, function(option) { return option.value == undefined })) return false;
    
    var attributes = _.object(_.map(options, function(option) {
      return [self.getOptionAttribute(option.name), option.value.toString()]
    }));
    
    var variants = _.sortBy(_.where(self.product.variants, attributes), function(variant) { return variant.price });
    return _.find(variants, function(variant) { return variant.quantity_in_stock > 0 });
  };
  
  self.setOptionsFromVariant = function(variant) {
    if (variant.option1) $('#option1 li[data-value="' + variant.option1 + '"]', self.$options).click();
    if (variant.option1) $('#option2 li[data-value="' + variant.option2 + '"]', self.$options).click();
    if (variant.option1) $('#option3 li[data-value="' + variant.option3 + '"]', self.$options).click();
  };
  
  self.setVariant = function(variant) {
    self.variant = variant;
    Caboose.Store.Modules.Cart.setVariant(variant);
    if (variant) self.setImageFromVariant(variant);
    if (variant && self.$price.length) self.$price.empty().text('$' + parseFloat((variant.price * 100) / 100).toFixed(2));
  };
  
  self.getVariant = function(id) {
    return _.find(self.product.variants, function(variant) { return variant.id == (id || self.variant.id) });
  };
  
  //
  // Image Methods
  //
  
  self.setImageFromVariant = function(variant) {    
    if (!variant || !variant.images || variant.images.length == 0 || !variant.images[0]) return;
    self.$product.trigger('variant:updated');
    
    var $figure = self.$images.children('figure');   
    if (variant.images && variant.images.length > 0 && variant.images[0]) {
      $figure.css('background-image', 'url(' + variant.images[0].urls.large + ')');
    } else if ($figure.css('background-image').toLowerCase() == 'none') {
      $figure.css('background-image', 'url(' + _.first(self.product.images).urls.large + ')');
    }
  };
  
  return self;
}).call(Caboose.Store);

