
BoundCheckboxMultiple = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  message: false,
  placeholder: false,
  checkboxes: false,
 
  init: function(params) {
    
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    this.message = this.el + '_message';
    this.placeholder = this.el + '_placeholder';
    
    var this2 = this;
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    $('#'+this.el+'_container').append($('<div/>')
      .attr('id', this.placeholder)
      .addClass('placeholder')
      .append($('<span/>').html(this.attribute.nice_name + ': '))
    );
    $('#'+this.el+'_container').append($('<input/>')
      .attr('id', this.el + '_background')
      .attr('disabled', true)
      .css('background', '#fff')
    );
    if (this.attribute.width)
      $('#'+this.el+'_background').css('width' , this.attribute.width);
    
    var this2 = this;
    this.attribute.populate_options(function() {

      var tbody = $('<tbody/>');
      $.each(this2.attribute.options, function(i, option) {

        tbody.append($('<tr/>')
          .append($('<td/>')
            .attr('id', this2.el + '_' + i)
            .attr('type', 'checkbox')
            .attr('checked', this2.attribute.value[option.value])
            .on('change', function() {
              // this2.binder.cancel_active();
              // this2.binder.active_control = this;
              // this2.save(); 
            })
          )
          .append($('<label/>')
            .attr('for', this2.el + '_' + i)
            .html(option.text)
          )
        );
      });
      $('#'+this.el+'_container').append(
        $('<table/>').append(tbody)
      );
    });
  },
  
  view: function() {
    
  },
    
  edit: function() {
    
  },
  
  save: function() {
    
    this.attribute.value = $('#'+this.el).prop('checked') ? 1 : 0;
        
    var this2 = this;
    this.model.save(this.attribute, function(resp) {
      $('#'+this2.el+'_check a').removeClass('loading');
      if (resp.error) this2.error(resp.error);
      else
      {
        this2.binder.active_control = this2;
        if (this2.binder.success)
          this2.binder.success(this2);
        this2.view();
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
