
var ModelBinder = function(params) { this.init(params); };

ModelBinder.prototype = {
  model: false,
  controls: [],
  on_load: false,
  success: false,
  authenticity_token: false,
  
  init: function(params) {
    this.model = new Model({        
      name: params['name'],
      id: params['id'],
      attributes: [],
      attributes_clean: []
    });
    if (params['update_url'])         this.model.update_url = params['update_url'];
    if (params['success'])            this.success = params['success'];
    if (params['authenticity_token']) this.authenticity_token = params['authenticity_token'];
      
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
      if (attrib.type == 'text')                   control = new BoundText(opts);
      else if (attrib.type == 'select')            control = new BoundSelect(opts);
      else if (attrib.type == 'checkbox')          control = new BoundCheckbox(opts);
      else if (attrib.type == 'checkbox-multiple') control = new BoundCheckboxMultiple(opts);
      else if (attrib.type == 'textarea')          control = new BoundTextarea(opts);
      else if (attrib.type == 'image')             control = new BoundImage(opts);

      this2.controls.push();    
    });
    
    if (this.on_load)
      this.on_load();
  },
};
