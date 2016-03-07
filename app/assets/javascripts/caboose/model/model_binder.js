
var all_model_binders = [];
var ModelBinder = function(params) { 
  this.init(params);
  all_model_binders[all_model_binders.length] = this;
};

ModelBinder.tinymce_init = function() {
  alert('ModelBinder.tinymce_init');
};

ModelBinder.remove_from_all_model_binders = function(model_name, id) {
  var arr = [];
  $.each(all_model_binders, function(i, mb) {
   if (mb.model.name != model_name || mb.model.id != id)
     arr[arr.length] = mb;      
  });
  all_model_binders = arr;  
};

ModelBinder.tinymce_control = function(id) {  
  var control = false;
  $.each(all_model_binders, function(i, mb) {
    $.each(mb.controls, function(i, c) {        
      if (id == (mb.model.name + "_" + mb.model.id + "_" + c.attribute.name).toLowerCase())
      { control = c; return false; }
    });
  });
  return control;
};

ModelBinder.tinymce_current_control = function() {
  var id = tinymce.activeEditor.id.toLowerCase();
  return ModelBinder.tinymce_control(id);    
};

ModelBinder.find_control = function(model_name, model_id, attribute_name) {  
  var control = false;
  $.each(all_model_binders, function(i, mb) {
    if (mb.model.name == model_name && mb.model.id == model_id) {
      $.each(mb.controls, function(i, c) {        
        if (c.attribute.name == attribute_name) { control = c; return false; }
      });
    }
    if (control) return false;
  });
  return control;  
};

ModelBinder.repopulate_options_for_control = function(model_name, model_id, attribute_name) {    
  var control = ModelBinder.find_control(model_name, model_id, attribute_name);  
  if (control)
  {
    control.attribute.options = false;
    control.init({});
  }
};

//==============================================================================

ModelBinder.options = {};
ModelBinder.waiting_on_options = {};
ModelBinder.wait_for_options = function(url, after) {  
  if (ModelBinder.options[url])
  {
    after(ModelBinder.options[url]);      
  }
  else if (ModelBinder.waiting_on_options[url])
  {
    ModelBinder.waiting_on_options[url].push(after);
  }
  else
  {
    ModelBinder.waiting_on_options[url] = [after];      
    var that = this;
    $.ajax({
      url: url,
      type: 'get',
			success: function(resp) {
			  ModelBinder.options[url] = resp;			  
        $.each(ModelBinder.waiting_on_options[url], function(i, after2) {        
          after2(ModelBinder.options[url]);
        });
			}			
		});
  }    
};

//==============================================================================

ModelBinder.prototype = {
  model: false,
  controls: [],
  on_load: false,
  success: false,
  authenticity_token: false,
  options: {},
  
  init: function(params) {
    var that = this;    
    that.model = new Model({        
      name: params['name'],
      id: params['id'],
      attributes: [],
      attributes_clean: []
    });
    if (params['update_url'])         that.model.update_url = params['update_url'];
    if (params['success'])            that.success = params['success'];
    if (params['authenticity_token']) that.authenticity_token = params['authenticity_token'];
    if (params['on_load'])            that.on_load = params['on_load'];

    $.each(params['attributes'], function(i, attrib) {
      that.model.attributes[that.model.attributes.length] = new Attribute(attrib);
    });        
    $.each(that.model.attributes, function(i, attrib) {      
      var opts = {
        model:     that.model,
        attribute: attrib,
        binder:    that
      };
      var control = false;
      
      if (attrib.type == 'text')                   control = new BoundText(opts);
      else if (attrib.type == 'color')             control = new BoundColor(opts);
      else if (attrib.type == 'datetime')          control = new BoundDateTime(opts);
      else if (attrib.type == 'date-time')         control = new BoundDateTime(opts);
      else if (attrib.type == 'date_time')         control = new BoundDateTime(opts);
      else if (attrib.type == 'select')            control = new BoundSelect(opts);
      else if (attrib.type == 'checkbox')          control = new BoundCheckbox(opts);
      else if (attrib.type == 'checkbox-multiple') control = new BoundCheckboxMultiple(opts);
      else if (attrib.type == 'checkbox_multiple') control = new BoundCheckboxMultiple(opts);      
      else if (attrib.type == 'textarea')          control = new BoundTextarea(opts);
      else if (attrib.type == 'richtext')          control = new BoundRichText(opts);
      else if (attrib.type == 'image')             control = new BoundImage(opts);
      else if (attrib.type == 'file')              control = new BoundFile(opts);
      else
      {
        control_class = "";
        $.each(attrib.type.split('-'), function(j, word) { control_class += word.charAt(0).toUpperCase() + word.toLowerCase().slice(1); });
        control = eval("new Bound" + control_class + "(opts)"); 
      }      
      that.controls.push(control);    
    });
            
    if (that.on_load)
      that.on_load();
  },
  
  reinit: function(control_id)
  {
    console.log('Reinitializing ' + control_id + '...');
    var that = this;
    var c = that.control_with_id(control_id);
    console.log(c);
    if (c) c.init({});
  },
    
  control_with_id: function(id)
  {
    var control = false
    var that = this;
    $.each(this.controls, function(i, c) {
      if (id == (that.model.name + "_" + that.model.id + "_" + c.attribute.name).toLowerCase())
      {        
        control = c; 
        return false;
      }
    });
    return control;
  },
  
  cancel: function()
  {
    $(this.controls).each(function(i, control) { 
      control.cancel(); 
    });    
  }
};
