
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
      .addClass('mb_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    if (this.attribute.fixed_placeholder == true)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.placeholder)
        .addClass('mb_placeholder')
        .append($('<span/>')
          .html(this.attribute.nice_name + ': ')
        )
      );
    }
    var this2 = this;
    $('#'+this.el+'_container').append($('<input/>')
      .attr('type', 'text')
      .attr('id', this.el)
      .addClass('mb_fake_option')
      .attr('placeholder', this.attribute.empty_text)
      .click(function() { this2.edit(); })
      .val(this.attribute.text && this.attribute.text.length > 0 ? this.attribute.text : this.attribute.empty_text)
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
    
    //this.update_options();
      
    //var this2 = this;
    //this.attribute.populate_options(function() {
    //  this2.print_options(this2);
    //});    
        
    this.attribute.populate_options(function() {
      var select = $('<select/>')
        .attr('id', this2.el + '_select')
        .addClass('mb_fake')
        .css('width', $('#'+this2.el).outerWidth())        
        .on('change', function() {                
          var v = $('#'+this2.el+'_select').val();
          if (this2.attribute.quick_add_url && v == 'quickadd')
          {                        
            caboose_modal_close_handler = function(new_id) {              
              this2.attribute.populate_options(function() {
                var select2 = $('#' + this2.el + '_select');
                select2.empty();
                if (this2.attribute.show_empty_option)  select.append($('<option/>').val('').html('-- Empty --'));
                if (this2.attribute.quick_add_url)      select.append($('<option/>').val('quickadd').html('-- ' + this2.attribute.quick_add_text + ' --'));
                $.each(this2.attribute.options, function(i, option) {
                  var opt = $('<option/>').val(option.value).html(option.text);
                  if (option.value == new_id)
                  {
                    this2.attribute.text = option.text;
                    $('#'+this2.el).val(this2.attribute.text);
                    opt.attr('selected', 'true');
                  }
                  select.append(opt);
                });
                $('#'+this2.el).val(new_id);
                this2.save();
              }, true);
            }
            if (typeof this2.attribute.quick_add_url == 'string')
              caboose_modal_url(this2.attribute.quick_add_url);
            else
              caboose_modal_url(this2.attribute.quick_add_url(this2.model));
          }
          else
          {
            $('#'+this2.el).val(v);                    
            this2.save();
          }
        });        
      // Make sure the existing value is in the list of options
      var exists = false;
      $.each(this2.attribute.options, function(i, option) {
        if (option.value == this2.attribute.value)
        {
          exists = true;
          return false;
        }
      });
      if (!exists && !(this2.attribute.show_empty_option && (this2.attribute.value == '' || this2.attribute.value == null)))
      {
        this2.attribute.options.unshift({ 
          value: this2.attribute.value,
          text: this2.attribute.text
        });
      }      
      if (this2.attribute.show_empty_option)      
        select.append($('<option/>').val('').html('-- Empty --'));
      if (this2.attribute.quick_add_url)      
        select.append($('<option/>').val('quickadd').html('-- ' + this2.attribute.quick_add_text + ' --'));
      $.each(this2.attribute.options, function(i, option) {
        var opt = $('<option/>')
          .val(option.value)
          .html(option.text);
        if (option.value == this2.attribute.value)
        {
          this2.attribute.text = option.text;
          $('#'+this2.el).val(this2.attribute.text);
          opt.attr('selected', 'true');
        }
        select.append(opt);
      });      
      $('#'+this2.el+'_container').append(select);
      $('#'+this2.el+'_select').css('width', $('#'+this2.el).outerWidth());            
    });
  },
             
  //update_options: function() {    
  //  var that = this;
  //  this.attribute.populate_options(function() {          
  //    var select = $('<select/>')
  //      .attr('id', that.el + '_select')
  //      .addClass('fake')
  //      .css('width', $('#'+that.el).outerWidth())
  //      .on('change', function() {
  //        $('#'+that.el).val($('#'+that.el+'_select').val());
  //        that.save();                     
  //      });
  //          
  //    $.each(that.attribute.options, function(i, option) {      
  //      var opt = $('<option/>')
  //        .val(option.value)
  //        .html(option.text);
  //      if (option.value == that.attribute.value)
  //        opt.attr('selected', 'true');
  //      select.append(opt);
  //    });
  //    
  //    if ($('#' + that.el + '_select').length) 
  //      $('#' + that.el + '_select').remove();
  //    
  //    $('#'+that.el+'_container').append(select);    
  //    $('#'+that.el+'_select').css('width', $('#'+that.el).outerWidth());
  //  });
  //},
  
  view: function() {
    
  },
    
  edit: function() {        
  },
  
  save: function() {
    this.attribute.value = $('#'+this.el).val();
    var i = $('#' + this.el + "_container option[value='" + this.attribute.value + "']").index();
    this.attribute.text = $('#' + this.el + " option").eq(i).text();
    if (this.attribute.text == '' && this.attribute.show_empty_option)
      this.attribute.text = '-- Empty --';
        
    var this2 = this;    
    this.model.save(this.attribute, function(resp) {      
      $(this2.attribute.options).each(function(i,opt) {
        if (opt.value == this2.attribute.value)
          this2.attribute.text = opt.text;        
      });      
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
