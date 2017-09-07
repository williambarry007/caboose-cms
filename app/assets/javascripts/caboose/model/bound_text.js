
BoundText = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  width: false,
  save_attempts: 0,
 
  init: function(params) {
    var that = this;
    for (var thing in params)
      that[thing] = params[thing];
    
    that.el = that.el ? that.el : that.model.name.toLowerCase() + '_' + that.model.id + '_' + that.attribute.name;
    var wrapper = $('<div/>').attr('id', that.el + '_container').addClass('mb_container').css('position', 'relative');
    if (that.attribute.wrapper_class)
      wrapper.addClass(that.attribute.wrapper_class);        
    $('#'+that.el).wrap(wrapper);      
    $('#'+that.el+'_container').empty();    
    $('#'+that.el+'_container').append($('<input/>')
      .attr('id', that.el)
      .attr('type', 'text')
      .attr('placeholder', that.attribute.fixed_placeholder ? 'empty' : that.attribute.nice_name)
      .css('text-align', that.attribute.align)
      .val(that.attribute.value)
    );

    if (that.attribute.fixed_placeholder)
    {
      $('#'+that.el+'_container').append($('<div/>').attr('id', that.el + '_placeholder').addClass('mb_placeholder').append($('<span/>').html(that.attribute.nice_name + ': ')));
      $('#'+that.el).css('background', 'transparent');
    }    

    // if (this.attribute.width)  $('#'+this.el).css('width' , this.attribute.width);    
    // if (this.attribute.fixed_placeholder && this.attribute.align != 'right')
    // {
    //   that.set_placeholder_padding();
    //   //setTimeout(function() {
    //   //  var w = $('#'+that.el+'_placeholder').outerWidth();
    //   //  $('#'+that.el).attr('placeholder', 'empty').css('padding-left', '+=' + w);//.css('width', '-=' + w);
    //   //  }, 200);            
    // }
    // var this2 = this;
    // $('#'+this.el).on('keyup', function(e) {
    //   if (e.keyCode == 27) this2.cancel(); // Escape 
    //   if (e.keyCode == 13) this2.save();   // Enter

    if (that.attribute.width)  $('#'+that.el).css('width', that.attribute.width);    
    if (that.attribute.fixed_placeholder && that.attribute.align != 'right')
      that.set_placeholder_padding();                  
                
    $('#'+that.el).on('keyup', function(e) {
      if (e.keyCode == 27) that.cancel(); // Escape 
      if (e.keyCode == 13) that.save();   // Enter

      
      if ($('#'+that.el).val() != that.attribute.value_clean)
        $('#'+that.el).addClass('mb_dirty');
      else
        $('#'+that.el).removeClass('mb_dirty');
    });                             
    $('#'+that.el).on('blur', function() { that.save(); });
    $('#'+that.el).on('change', function() { that.save(); });
  },
  
  set_placeholder_padding: function() {
    var that = this;
    var w = $('#'+that.el+'_placeholder').outerWidth();    
    if (w > 0)
      $('#'+that.el).css('padding-left', '+=' + w);
    else    
      setTimeout(function() { that.set_placeholder_padding(); }, 200);                    
  },
  
  save: function() 
  {    
    var that = this;
    if (that.save_attempts > 0)
      return;
    
    that.save_attempts++;          
    that.attribute.value = $('#'+that.el).val();
    if (that.attribute.value == that.attribute.value_clean)
    {
      that.save_attempts = 0;
      return;
    }
    
    that.show_loader();
    that.binder.save(that.attribute, function(resp) {
      that.save_attempts = 0;
      if (resp.error)
      {
        that.hide_loader();
        that.error(resp.error);
      }
      else
      {
        that.show_check(500);        
        $('#'+that.el).val(that.attribute.value);
        $('#'+that.el).removeClass('mb_dirty');

        if (that.binder.success)
          that.binder.success(that);
      }
    });
  },
  
  cancel: function() {
    if (this.attribute.before_cancel) this.attribute.before_cancel();    
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).val(this.attribute.value);
    $('#'+this.el).removeClass('mb_dirty');
    
    if ($('#'+this.el+'_check').length)
      this.hide_check();
    
    if (this.attribute.after_cancel) this.attribute.after_cancel();
  },
    
  error: function(str) {
    if (!$('#'+this.el+'_message').length)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.el + '_message')
        .css('width', $('#'+this.el).outerWidth())
      );
    }
    $('#'+this.el+'_message').hide();
    $('#'+this.el+'_message').html("<p class='note error'>" + str + "</p>");
    $('#'+this.el+'_message').slideDown();
    var this2 = this;
    setTimeout(function() { $('#'+this2.el+'_message').slideUp(function() { $(this).empty(); }); }, 3000);
  },
  
  set_value: function(v) {
    var that = this;
    $('#'+this.el).val(v);
    this.attribute.value = v;
    this.attribute.value_clean = v;
  }
  
});
