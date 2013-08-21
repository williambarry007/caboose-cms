
BoundText = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  width: false,
  save_attempts: 0,
 
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;    
    $('#'+this.el).wrap($('<div/>').attr('id', this.el + '_container').css('position', 'relative'));
    $('#'+this.el+'_container').empty();
    $('#'+this.el+'_container').append($('<input/>')
      .attr('id', this.el)
      .attr('type', 'text')
      .attr('placeholder', this.attribute.fixed_placeholder ? 'empty' : this.attribute.nice_name)
      .css('text-align', this.attribute.align)
      .val(this.attribute.value)
    );
    
    if (this.attribute.fixed_placeholder)      
      $('#'+this.el+'_container').append($('<div/>').attr('id', this.el + '_placeholder').addClass('placeholder').append($('<span/>').html(this.attribute.nice_name + ': ')));
    if (this.attribute.width)  $('#'+this.el).css('width' , this.attribute.width);
    if (this.attribute.fixed_placeholder)
    {
      var w = $('#'+this.el+'_placeholder').outerWidth();
      $('#'+this.el).attr('placeholder', 'empty').css('padding-left', '+=' + w).css('width', '-=' + w);
    }
    
    var this2 = this;
    $('#'+this.el).on('keyup', function(e) {
      if (e.keyCode == 27) this2.cancel(); // Escape 
      if (e.keyCode == 13) this2.save();   // Enter
      
      if ($('#'+this2.el).val() != this2.attribute.value_clean)
        $('#'+this2.el).addClass('dirty');
      else
        $('#'+this2.el).removeClass('dirty');
    });                             
    $('#'+this.el).on('blur', function() {
      if (this2.save_attempts < 1)
      {
        this2.save_attempts++;
        this2.save();
      }      
    });
  },
  
  save: function() {
    this.attribute.value = $('#'+this.el).val();
    if (this.attribute.value == this.attribute.value_clean)
      return;
    
    this.show_loader();        
    var this2 = this;
    this.model.save(this.attribute, function(resp) {
      this2.save_attempts = 0;
      if (resp.error)
      {
        this2.hide_loader();
        this2.error(resp.error);
      }
      else
      {
        this2.show_check(500);
        $('#'+this2.el).val(this2.attribute.value);
        $('#'+this2.el).removeClass('dirty');

        if (this2.binder.success)
          this2.binder.success(this2);
      }
    });
  },
  
  cancel: function() {    
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).val(this.attribute.value);
    $('#'+this.el).removeClass('dirty');
    
    if ($('#'+this.el+'_check').length)
      this.hide_check();
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
  }
  
});
