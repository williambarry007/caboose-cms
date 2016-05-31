
BoundControl = Class.extend({
    
  el: false,         // The DOM element to which the object is bound
  model: false,      // The model to which the control is bound
  attribute: false,  // The attribute of the model
  binder: false,     // The model binder
    
  init:   function(params) {},  // Constructor  
  view:   function() {},        // Sets the control in a view state
  edit:   function() {},        // Sets the control in an edit state
  save:   function() {},        // Sends the value in the control to the model to be saved
  cancel: function() {},      // Cancels the edit
  error:  function(str) {},     // Shows an error

  //show_loader: function() {
  //  var w = $('#'+this.el).outerWidth();
  //  var h = 40; //$('#'+this.el).outerHeight();
  //  var this2 = this;
  //  
  //  if (!$('#'+this.el+'_check').length)
  //  {      
  //    $('#'+this.el+'_container').prepend($('<div/>')
  //      .attr('id', this.el + '_check')
  //      .addClass('mb_bound_input_check')
  //      .css('position', 'absolute')
  //      .css('top', 0)
  //      .css('right', w-h-1)
  //      .css('width', h+2)
  //      .css('overflow', 'hidden')
  //      .append($('<a/>')
  //        .addClass('loading')
  //        .html('&#10003;')
  //        .css('width', h)
  //        .css('margin-left', h)
  //        .attr('href', '#')
  //        .click(function(event) { event.preventDefault(); })
  //      )
  //    );
  //  }    
  //  $('#'+this.el+'_check a')
  //    .addClass('mb_loading')
  //    .css('margin-left', h);
  //  $('#'+this.el+'_check a').animate({ 'margin-left': 0 }, 300); 
  //},
  
  show_loader: function() {
    var w = $('#'+this.el).outerWidth();
    var h = $('#'+this.el).outerHeight();    
    var this2 = this;
    
    if (!$('#'+this.el+'_check').length)
    {      
      $('#'+this.el+'_container').prepend($('<div/>')
        .attr('id', this.el + '_check')
        .addClass('mb_bound_input_check')
        .css('position', 'absolute')
        .css('top', 0)
        .css('right', 0-h)
        .css('width', h)
        .css('overflow', 'hidden')
        .css('border', '0')
        .append($('<a/>')
          .addClass('loading')
          .html('&#10003;')
          .css('width', h)
          .css('height', h)
          .css('text-decoration', 'none')
          .css('border', '0')
          .attr('href', '#')
          .click(function(event) { event.preventDefault(); })
        )
      );
    }    
    $('#'+this.el+'_check a').addClass('loading');
    $('#'+this.el+'_check').animate({ 'right': -1 }, 300); 
  },
  
  hide_loader: function() {
    this.hide_check();
  },
  
  show_check: function(duration) {        
    $('#'+this.el+'_check a').removeClass('loading');
    if (duration)
    {
      var this2 = this;
      setTimeout(function() { this2.hide_check(); }, duration);
    }
  },
  
  //hide_check: function() {
  //  var w = $('#'+this.el).outerWidth();
  //  var h = 40;
  //  
  //  var this2 = this;
  //  $('#'+this.el+'_check a').animate({ 'margin-left': h }, 300, function() { 
  //    $('#'+this2.check).remove(); 
  //  });
  //},
  
  hide_check: function() {
    var that = this;    
    var h = $('#'+this.el).outerHeight();        
    $('#'+that.el+'_check').animate({ 'right': 0-h }, 300, function() { 
      $('#'+that.el+'_check').remove(); 
    });
  },
  
});
