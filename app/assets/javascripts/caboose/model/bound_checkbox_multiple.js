
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
    $.each(that.attribute.options, function(i, option) {
      var checked = that.attribute.value.indexOf(option.value) > -1;
      tbody.append($('<tr/>')
        .append($('<td/>')
          .append($('<input/>')
            .attr('id', that.el + '_' + i)
            .attr('type', 'checkbox')
            .attr('checked', checked)
            .val(option.value)
            .css('position', 'relative')
            .on('change', function() { that.save($(this).val(), $(this).prop('checked')); })
          )
        )
        .append($('<td/>').append($('<label/>').attr('for', that.el + '_' + i).html(option.text)))
      );
    });
    $('#'+this.el+'_container').append($('<table/>').addClass('data').append(tbody));    
  },
    
  edit: function() {
    
  },
  
  save: function(value, checked) {
        
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
				  
				  that.binder.active_control = that;
				  if (that.binder.success)
				    that.binder.success(that);				  
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
