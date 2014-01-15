
var all_model_binders = [];
var ModelBinder = function(params) { 
  this.init(params);
  all_model_binders[all_model_binders.length] = this;
};

ModelBinder.remove_from_all_model_binders = function(model_name, id) {
  var arr = [];
  $.each(all_model_binders, function(i, mb) {
   if (mb.model.name != model_name || mb.model.id != id)
     arr[arr.length] = mb;      
  });
  all_model_binders = arr;  
};

ModelBinder.tinymce_current_control = function() {
  var id = tinymce.activeEditor.id.toLowerCase();
  var control = false;
  $.each(all_model_binders, function(i, mb) {
    $.each(mb.controls, function(i, c) {        
      if (id == (mb.model.name + "_" + mb.model.id + "_" + c.attribute.name).toLowerCase())
      { control = c; return false; }
    });
  });
  return control;
};

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
      else if (attrib.type == 'richtext')          control = new BoundRichText(opts);
      else if (attrib.type == 'image')             control = new BoundImage(opts);
      this2.controls.push(control);    
    });
    
    if (this.on_load)
      this.on_load();
  },
  
  control_with_id: function(id)
  {
    attrib = false
    var this2 = this;
    $.each(this.controls, function(i, c) {        
      if (id == (this2.model.name + "_" + this2.model.id + "_" + c.attribute.name).toLowerCase())
      {        
        attrib = c.attribute; 
        return false;
      }
    });
    return attrib;
  },
  
  cancel: function()
  {
    $(this.controls).each(function(i, control) { 
      control.cancel(); 
    });    
  }
};
