
BoundCode = BoundControl.extend({

  width: false,
 
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
         
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      //.addClass('mb_container')
      //.css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    $('#'+this.el+'_container').append($('<textarea/>').attr('id', this.el).attr('placeholder', 'empty').val(this.attribute.value));
    //$('#'+this.el+'_container').append($('<div/>').attr('id', this.el + '_placeholder').addClass('mb_placeholder').append($('<span/>').html(this.attribute.nice_name + ': ')));
    //if (this.attribute.width)  $('#'+this.el).css('width'  , this.attribute.width);
    //if (this.attribute.height) $('#'+this.el).css('height' , this.attribute.height);
    //var h = $('#'+this.el+'_placeholder').outerHeight();
    //$('#'+this.el).attr('placeholder', 'empty').css('padding-top', '+=' + h).css('height', '-=' + h);
    
    var this2 = this;
    //$('#'+this.el).on('keyup', function(e) {
    //  if (e.keyCode == 27) this2.cancel(); // Escape 
    //  //if (e.keyCode == 13) this2.save();   // Enter
    //  
    //  if ($('#'+this2.el).val() != this2.attribute.value_clean)
    //  {
    //    this2.show_controls();
    //    $('#'+this2.el).addClass('mb_dirty');
    //  }
    //  else
    //    $('#'+this2.el).removeClass('mb_dirty');
    //});                             
    //$('#'+this.el).on('blur', function() { this2.save(); });
    
    var code_editor = CodeMirror.fromTextArea(document.getElementById(this.el), {
      lineNumbers: true,
      theme: "night",
      extraKeys: {
        //"F11": function(cm) { cm.setOption("fullScreen", !cm.getOption("fullScreen")); },
        "Esc": function(cm) { if (cm.getOption("fullScreen")) cm.setOption("fullScreen", false); }
      }
    });
  },
  
  show_controls: function() {
    if ($('#'+this.el+'_controls').length)
      return;    
    var w = $('#'+this.el).outerWidth();
    var this2 = this;
    $('#'+this.el+'_container').prepend($('<div/>')
      .attr('id', this.el + '_controls')
      .addClass('mb_bound_textarea_controls')
      .css('position', 'absolute')
      .css('top', 0)
      .css('left', w-148)
      .css('width', 148)
      .css('overflow', 'hidden')
      .append($('<div/>')
        .css('width', 148)
        .css('margin-left', 148)
        .append($('<a/>').html('Save'   ).addClass('mb_save'   ).css('width', 60).attr('href', '#').click(function(event) { event.preventDefault(); this2.save();   }))
        .append($('<a/>').html('Discard').addClass('mb_discard').css('width', 80).attr('href', '#').click(function(event) { event.preventDefault(); this2.cancel(); }))
      )
    );  
    $('#'+this.el+'_controls div').animate({ 'margin-left': 0 }, 300); 
  },
    
  hide_controls: function() {
    if (!$('#'+this.el+'_controls').length)
      return;
    var this2 = this;
    $('#'+this.el+'_controls div').animate({ 'margin-left': 100 }, 300, function() { 
      $('#'+this2.el+'_controls').remove(); 
    });
  },
  
  save: function() {

    //this.attribute.value = $('#'+this.el).val();    
    //if (this.attribute.value == this.attribute.value_clean)
    //  return;
    //
    //this.hide_controls();
    //this.show_loader();        
    //var this2 = this;
    //this.model.save(this.attribute, function(resp) {
    //  if (resp.error)
    //  {
    //    this2.hide_loader();
    //    this2.error(resp.error);
    //  }
    //  else
    //  {
    //    this2.show_check(500);
    //    $('#'+this2.el).val(this2.attribute.value);
    //    $('#'+this2.el).removeClass('mb_dirty');
    //
    //    if (this2.binder.success)
    //      this2.binder.success(this2);
    //  }
    //});
  },
  
  cancel: function() {
    
    //if ($('#'+this.el).val() != this.attribute.value_clean)
    //{
    //  if (confirm('This box has unsaved changes.  Hit OK to save changes, Cancel to discard.'))
    //  { 
    //    this.attribute.value       = $('#'+this.el).val();
    //    this.attribute.value_clean = $('#'+this.el).val();
    //    this.save();
    //  }
    //}    
    //this.attribute.value = this.attribute.value_clean;
    //$('#'+this.el).val(this.attribute.value);
    //$('#'+this.el).removeClass('mb_dirty');
    //
    //if ($('#'+this.el+'_check').length)
    //  this.hide_check();
  },
    
  error: function(str) {
    //if (!$('#'+this.el+'_message').length)
    //{
    //  $('#'+this.el+'_container').append($('<div/>')
    //    .attr('id', this.el + '_message')
    //    .css('width', $('#'+this.el).outerWidth())
    //  );
    //}
    //$('#'+this.el+'_message').hide();
    //$('#'+this.el+'_message').html("<p class='note error'>" + str + "</p>");
    //$('#'+this.el+'_message').slideDown();
    //var this2 = this;
    //setTimeout(function() { $('#'+this2.el+'_message').slideUp(function() { $(this).empty(); }); }, 3000);
  }
  
});
