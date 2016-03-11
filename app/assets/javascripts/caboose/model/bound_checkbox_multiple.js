
BoundCheckboxMultiple = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  message: false,
  placeholder: false,
  checkboxes: false,
 
  init: function(params) {
    var that = this;
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    this.message = this.el + '_message';
    this.placeholder = this.el + '_placeholder';
        
    var div = $('<div/>')
      .attr('id', this.el + '_container')
      .addClass('mb_container')
      .css('position', 'relative');
    if (this.attribute.height)
      div.css('height', '' + this.attribute.height + 'px').css('overflow-y', 'scroll');        
    $('#'+this.el).wrap(div);    
    $('#'+this.el+'_container').empty();        
    if (this.attribute.value == null || this.attribute.value == false)
      this.attribute.value = [];
    if (typeof(this.attribute.value) == 'string')    
      this.attribute.value = this.attribute.value.split('|');    
    
    if (this.attribute.options_url)      
    {
      ModelBinder.wait_for_options(this.attribute.options_url, function(options) {
        that.attribute.options = options; 
        that.cancel();
      });            
    }             
  },
  
  view: function() {
    var that = this;    
    var tbody = $('<tbody/>');
    
    if (this.attribute.show_check_all)
    {      
      var all_checked = true
      $.each(this.attribute.options, function(i, option) {        
        if (!that.attribute.value || that.attribute.value.indexOf(option.value) == -1)
        {
          all_checked = false;
          return;
        }
      });  
      var input = $('<input/>')
        .attr('id', that.el + '_all')
        .attr('type', 'checkbox')        
        .val('all')
        .css('position', 'relative')
        .on('change', function() {
          var checked = $(this).prop('checked');
          that.save('all', checked);
          $.each(that.attribute.options, function(i, option) {                        
            $('#' + that.el + '_' + i).prop('checked', checked);
          });          
        });
      if (all_checked)
        input.attr('checked', 'true');          
      tbody.append($('<tr/>')
        .append($('<td/>').append(input))
        .append($('<td/>').append($('<label/>').attr('for', that.el + '_all').html('Check All')))
      );      
    }
    $.each(that.attribute.options, function(i, option) {
      var checked = that.attribute.value != false && that.attribute.value != null && that.attribute.value.indexOf(option.value) > -1;
      tbody.append($('<tr/>')
        .append($('<td/>')
          .append($('<input/>')
            .attr('id', that.el + '_' + i)
            .attr('type', 'checkbox')
            .attr('checked', checked)
            .val(option.value)
            .css('position', 'relative')
            .on('change', function() {              
              that.save($(this).val(), $(this).prop('checked'));              
              if (that.attribute.show_check_all)
              {
                var all_checked = true;
                $.each(that.attribute.options, function(j, option) {                   
                  if ($('#' + that.el + '_' + j).prop('checked') == false) all_checked = false;
                });
                $('#' + that.el + '_all').prop('checked', all_checked);
              }            
            })            
          )
        )
        .append($('<td/>').append($('<label/>').attr('for', that.el + '_' + i).html(option.text)))
      );
    });
    $('#'+this.el+'_container').append($('<table/>').addClass('data').addClass('checkbox_multiple').append(tbody));    
  },
    
  edit: function() {
    
  },
  
  save: function(value, checked) {

    if (this.attribute.value == null || this.attribute.value == false)
      this.attribute.value = [];    
    if (typeof(this.attribute.value) == 'string')    
      this.attribute.value = this.attribute.value.split('|');
    
    var that = this;    
    var i = this.attribute.value.indexOf(value);
    if (checked && i == -1) this.attribute.value.push(value);
    if (!checked && i > -1) this.attribute.value.splice(i, 1);        
        
    if (this.attribute.before_update)
      this.attribute.before_update();    
    if (!this.attribute.update_url)
      this.attribute.update_url = this.model.update_url;

    var data = {};
    data[this.attribute.name] = [value,(checked ? 1 : 0)];
    
    
    $.ajax({
      url: this.attribute.update_url,
      type: 'put',
      data: data,        
			success: function(resp) {        			  
				if (resp.success)
				{
				  if (resp.attributes && resp.attributes[that.attribute.name])
				    for (var thing in resp.attributes[that.attribute.name])
				      that.attribute[thing] = resp.attributes[that.attribute.name][thing];				  
				  that.attribute.value_clean = that.attribute.value;
				  
				  b.active_control = that;
				  if (this2.binder.success)
				    this2.binder.success(that);				  
				}								
				else if (resp.error)
				  that.error(resp.error);    				
				if (that.attribute.after_update)
				  that.attribute.after_update();				
			},
			error: function() { 
			  if (after) after(false);
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
