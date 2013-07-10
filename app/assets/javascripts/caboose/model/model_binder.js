
var ModelBinder = function(params) { this.init(params); };

ModelBinder.prototype = {
  model: false,
  controls: [],
  //active_control: false,
  success: false,
  
  init: function(params) {
    this.model = new Model({        
      name: params['name'],
      id: params['id'],
      attributes: [],
      attributes_clean: []
    });
    if (params['update_url']) this.model.update_url = params['update_url'];
    if (params['success'])    this.success = params['success'];
      
    var m = this.model;
    $.each(params['attributes'], function(i, attrib) {
      m.attributes[m.attributes.length] = new Attribute(attrib);
    });
    //this.model.populate_options();

    var this2 = this;
    $.each(this.model.attributes, function(i, attrib) {
      var opts = {
        model: this2.model,
        attribute: attrib,
        binder: this2
      };    
      var control = false;
      if (attrib.type == 'text')          control = new BoundText(opts);
      else if (attrib.type == 'select')   control = new BoundSelect(opts);
      else if (attrib.type == 'checkbox') control = new BoundCheckbox(opts);
      else if (attrib.type == 'textarea') control = new BoundTextarea(opts);

      this2.controls.push();    
    });
    
    //$(document).keyup(function(e) {
    //  if (e.keyCode == 27) this2.cancel_active(); // Escape
    //  //if (e.keyCode == 13) this2.save_active();   // Enter
    //});
  },
  
  //cancel_active: function() {
  //  if (!this.active_control)
  //    return;
  //  this.active_control.cancel();
  //  this.active_control = false;    
  //},
  
  //save_active: function() {
  //  if (!this.active_control)
  //    return;
  //  this.active_control.save();      
  //  this.active_control = false;    
  //},
};
