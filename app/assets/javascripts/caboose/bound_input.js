
var Model = function(params) {
  for (var thing in params)
    this[thing] = params[thing];
};

Model.prototype = {
  name: false,
  id: false,
  attributes: [],
  attributes_clean: [],
  update_url: false,
  
  save: function(attrib, after) {
    var this2 = this;
    $.ajax({
      url: this.update_url,
      type: 'put',
      data: attrib + '=' + this.attributes[attrib],
			success: function(resp) {			  
				if (resp.success)
				{
				  this2.attributes_clean[attrib] = this2.attributes[attrib];
				  if (resp.attributes && resp.attributes[attrib])
				  {
				    this2.attributes[attrib]       = resp.attributes[attrib];
				    this2.attributes_clean[attrib] = resp.attributes[attrib];
				  }
				}
				after(resp);
			},
			error: function() { 
			  after(false);
			}
		});
  }
};

/******************************************************************************/

var BoundControl = function(model, attribute, el) {
  this.init(model, attribute, el);
};

BoundControl.prototype = {
  el: false, 
  check: false,
  message: false,
  model: false,
  attribute: false,
  binder: false, 
  
  init: function(model, attribute, el) {    
    this.model = model;
    this.attribute = attribute;
    this.el = el ? el : model.name.toLowerCase() + '_' + model.id + '_' + attribute;
    this.check   = this.el + '_check';
    this.message = this.el + '_message';
         
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .css('position', 'relative')
    );
    
    var this2 = this;
    $('#'+this.el).on('focus', function() { this2.edit(); });
    //$('#'+this.el).keydown(function() {
    //  if (this2.model.attributes[attribute] != this2.model.attributes_clean[attribute])
    //    this2.edit();
    //});
  },
  
  view: function() {
    if ($('#'+this.check).length)   $('#'+this.check).remove();
    if ($('#'+this.message).length) $('#'+this.message).remove();    
    $('#'+this.el).val(this.model.attributes[this.attribute]);      
  },
  
  edit: function() {
    this.binder.cancel_active();
    this.binder.active_control = this;
    
    var w = $('#'+this.el).outerWidth();
    var h = $('#'+this.el).outerHeight();
    var this2 = this;    
    $('#'+this.el+'_container').prepend($('<div/>')
      .attr('id', this.el + '_check')
      .addClass('bound_input_check')
      .css('position', 'absolute')      
      .css('top', 0)
      .css('left', w-2)
      .css('width', h+2)
      .css('overflow', 'hidden')
      .append($('<a/>')
        .html('&#10003;')
        .css('width', h)
        .css('margin-left', -h)
        .attr('href', '#')
        .click(function(event) {
          event.preventDefault();
          this2.save();
        })
      )
    );
    $('#'+this.el+'_check a').animate({ 'margin-left': 0 }, 300);
  },
  
  save: function() {
    $('#'+this.el+'_check a').addClass('loading');
    this.model.attributes[this.attribute] = $('#'+this.el).val();
    
    var this2 = this;
    this.model.save(this.attribute, function(resp) {
      $('#'+this2.el+'_check a').removeClass('loading');
      if (resp.error) this2.error(resp.error);
      else
      {
        this2.binder.active_control = this2;
        //this2.view();
        //if ($('#'+this.check).length)   $('#'+this.check).remove();
        //if ($('#'+this.message).length) $('#'+this.message).remove();    
        //$('#'+this.el).val(this.model.attributes[this.attribute]);
        //$('#'+this2.el).focus();
      }
    });
  },
  
  cancel: function() {
    this.model.attributes[this.attribute] = this.model.attributes_clean[this.attribute];
    $('#'+this.el).val(this.model.attributes[this.attribute]);
    
    if ($('#'+this.el+'_check a').length)
    {
      var this2 = this;
      var h = $('#'+this.el).outerHeight();
      $('#'+this.el+'_check a').animate({ 'margin-left': -h }, 300, function() {
        this2.view();    
      });
    }
    else
      this.view();
  },
    
  error: function(str) {
    if (!$('#'+this.message).length)
      $('#'+this.el+'_container').prepend($('<div/>').attr('id', this.message));
    $('#'+this.message).html("<p class='note error'>" + str + "</p>");
  }
};

/******************************************************************************/

var ModelBinder = function(params) { this.init(params); };

ModelBinder.prototype = {
  model: false,
  controls: [],
  active_control: false,
  
  init: function(params) {
    this.model = new Model({        
      name:       params['name'],
      id:         params['id'],
      update_url: params['update_url'],
      attributes: {},
      attributes_clean: {}
    });
    
    var this2 = this;
    $.each(params['attributes'], function(i, attrib) {
      var el = (this2.model.name + '_' + this2.model.id + '_' + attrib).toLowerCase();
      this2.model.attributes[attrib]        = $('#'+el).val();
      this2.model.attributes_clean[attrib]  = $('#'+el).val();
      var control = new BoundControl(this2.model, attrib);
      control.binder = this2;
      this2.controls.push();    
    });
    
    $(document).keyup(function(e) {
      if (e.keyCode == 27) this2.cancel_active(); // Escape
      if (e.keyCode == 13) this2.save_active();   // Enter
    });
  },
  
  cancel_active: function() {
    if (!this.active_control)
      return;
    this.active_control.cancel();
    this.active_control = false;    
  },
  
  save_active: function() {
    if (!this.active_control)
      return;
    this.active_control.save();      
    this.active_control = false;    
  },
};
