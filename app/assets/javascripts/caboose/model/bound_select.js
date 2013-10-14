
BoundSelect = BoundControl.extend({

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
         
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    if (this.attribute.fixed_placeholder)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.placeholder)
        .addClass('placeholder')
        .append($('<span/>')
          .html(this.attribute.nice_name + ': ')
        )
      );
    }
    $('#'+this.el+'_container').append($('<input/>')
      .attr('id', this.el)
      .attr('placeholder', this.attribute.empty_text)
      .on('focus', function() { this2.edit(); })
      .val(this.attribute.text.length > 0 ? this.attribute.text : this.attribute.empty_text)
    );
    if (this.attribute.width)
      $('#'+this.el).css('width', this.attribute.width);
    
    if (this.attribute.fixed_placeholder)
    {
      var w = $('#'+this.placeholder).outerWidth();
      $('#'+this.el)
        .css('padding-left', '+=' + w)
        .css('width', '-=' + w);
    }
      
    var this2 = this;
    this.attribute.populate_options(function() {
      var select = $('<select/>')
        .attr('id', this2.el + '_select')
        .addClass('fake')
        .css('width', $('#'+this2.el).outerWidth())
        .on('change', function() {
          $('#'+this2.el).val($('#'+this2.el+'_select').val());
          this2.save();                     
        });
        
      $.each(this2.attribute.options, function(i, option) {
        var opt = $('<option/>')
          .val(option.value)
          .html(option.text);
        if (option.value == this2.attribute.value)
          opt.attr('selected', 'true');
        select.append(opt);
      });
      $('#'+this2.el+'_container').append(select);
      $('#'+this2.el+'_select').css('width', $('#'+this2.el).outerWidth());      
    });
  },
  
  view: function() {
    
  },
    
  edit: function() {
    
  },
  
  save: function() {
    this.attribute.value = $('#'+this.el).val();
    var this2 = this;
    this.model.save(this.attribute, function(resp) {
      if (this2.attribute.text)
        $('#'+this2.el).val(this2.attribute.text);        
      $('#'+this2.el+'_check a').removeClass('loading');
      if (resp.error) this2.error(resp.error);
      else
      {
        if (this2.binder.success)
          this2.binder.success(this2);
        this2.view();
      }
    });
  },
  
  cancel: function() {
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).val(this.attribute.value);
    this.view();
  },

  error: function(str) {
    if (!$('#'+this.message).length)
      $('#'+this.el+'_container').prepend($('<div/>').attr('id', this.message));
    $('#'+this.message).html("<p class='note error'>" + str + "</p>");
  }

});
