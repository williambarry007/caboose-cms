
BoundCheckbox = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  message: false,
  placeholder: false,
 
  init: function(params) {
    
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    this.message = this.el + '_message';
    this.placeholder = this.el + '_placeholder';
    
    var this2 = this;
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .addClass('mb_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    if (this.attribute.fixed_placeholder)
    {            
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.placeholder)
        .addClass('mb_placeholder')
        .append($('<span/>').html(this.attribute.nice_name + (this.attribute.nice_name[this.attribute.nice_name.length-1] == '?' ? '' : ':') + ' '))
      );
    }
    var cb = $('<input/>')
      .attr('id', this.el)
      .attr('type', 'checkbox')      
      .attr('checked', this.attribute.value == 1)
      .on('change', function() {        
        this2.save(); 
      });    
    $('#'+this.el+'_container').append(cb);
    
    if (this.attribute.align == 'right')
      $('#'+this.el).css('left', this.attribute.width - 24)
    else if (this.attribute.align == 'center')
      $('#'+this.el).css('left', Math.floor($('#'+this.el+'_container').outerWidth()/2))
    else // left
    {
      this.set_placeholder_padding();
      //$('#'+this.el).css('left', $('#'+this.placeholder).outerWidth(true) + 10);
    }
    
    $('#'+this.el+'_container').append($('<input/>')
      .attr('type', 'text')
      .attr('id', this.el + '_background')
      .attr('disabled', true)
      //.css('background', '#fff')
      .addClass('mb_checkbox_background')
    );
    if (this.attribute.width)
      $('#'+this.el+'_background').css('width' , this.attribute.width);
  },
  
  set_placeholder_padding: function() {
    var that = this;
    var w = $('#'+that.placeholder).outerWidth(true);
    if (w > 0)
      $('#'+that.el).css('left', w + 10);                
    else            
      setTimeout(function() { that.set_placeholder_padding(); }, 200);                    
  },
  
  view: function() {
    
  },
    
  edit: function() {
    
  },
  
  save: function() {
    var that = this;    
    this.attribute.value = $('#'+this.el).prop('checked') ? 1 : 0;
            
    this.binder.save(this.attribute, function(resp) {
      $('#'+that.el+'_check a').removeClass('loading');
      if (resp.error) that.error(resp.error);
      else
      {
        if (that.binder.success)
          that.binder.success(that);
        that.view();
      }
    });
  },
  
  cancel: function() {
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).attr('checked', '' + this.attribute.value ? 'true' : 'false') 
    this.view();
  },

  error: function(str) {
    if (!$('#'+this.message).length)
      $('#'+this.el+'_container').prepend($('<div/>').attr('id', this.message));
    $('#'+this.message).html("<p class='note error'>" + str + "</p>");
  }

});
