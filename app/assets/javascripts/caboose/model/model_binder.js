
var all_model_binders = [];
var ModelBinder = function(params) { 
  this.init(params);
  ModelBinder.add_to_all_model_binders(this);
};

ModelBinder.add_to_all_model_binders = function(mb) {
  var exists = false;  
  for (var i=0; i<all_model_binders.length; i++) {
    var m = all_model_binders[i].model;
    if (m.name == mb.model.name && parseInt(m.id) == parseInt(mb.model.id))
    {
      all_model_binders[i] = mb;             
      exists = true;
      break;
    }
  }
  if (!exists)   
    all_model_binders[all_model_binders.length] = mb;  
};

ModelBinder.remove_from_all_model_binders = function(model_name, id) {
  var arr = [];
  $.each(all_model_binders, function(i, mb) {
   if (mb.model.name != model_name || mb.model.id != id)
     arr[arr.length] = mb;      
  });
  all_model_binders = arr;  
};

ModelBinder.tinymce_init = function() {
  alert('ModelBinder.tinymce_init');
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
  for (var i=0; i<all_model_binders.length; i++) {
    var mb = all_model_binders[i];
    if (mb.model.name == model_name && mb.model.id == model_id) {
      for (var j=0; j<mb.controls.length; j++) {
        var c = mb.controls[j];                          
        if (c.attribute.name == attribute_name) {
          return c;
        }
      }
    }    
  }  
  return false;
};

//ModelBinder.print_all_model_binders = function() {
//  console.log("-----------------------------------------------------------------");
//  console.log("All model binders");
//  for (var i=0; i<all_model_binders.length; i++) {
//    var mb = all_model_binders[i];                                
//    console.log(mb.model.name + ' | ' + mb.model.id);                                                      
//  }
//  console.log("-----------------------------------------------------------------");  
//};

//ModelBinder.print_all_controls = function() {
//  
//  count = 0;
//  for (var i=0; i<all_model_binders.length; i++) { count += all_model_binders[i].controls.length; }
//  
//  console.log("-----------------------------------------------------------------");
//  console.log("All controls (" + count + ")");
//  for (var i=0; i<all_model_binders.length; i++) {
//    var mb = all_model_binders[i];              
//    for (var j=0; j<mb.controls.length; j++) {      
//      var c = mb.controls[j];              
//      console.log(mb.model.name + ' | ' + mb.model.id +  ' | ' + c.attribute.name); //c.model.name + ' | ' + c.model.id + ' | ' + c.attribute.name + ' | ' + c.attribute.options_url);                                                  
//    }
//  }
//  console.log("-----------------------------------------------------------------");
//};

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
  controls: false,
  on_load: false,
  success: false,
  authenticity_token: false,
  options: false,
  
  init: function(params) {
    var that = this;
    that.controls = [];
    that.options = {};
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
        attribute: attrib,
        model:     that.model,        
        binder:    that
      };
      //console.log(that.model.name + ' | ' + that.model.id + ' | ' + attrib.name);      
      var control = false;
      
      if (attrib.type == 'text')                   control = new BoundText(opts);
      else if (attrib.type == 'color')             control = new BoundColor(opts);
      else if (attrib.type == 'date')              control = new BoundDate(opts);
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
        //console.log("ModelBinder Error: unsupported attribute type \"" + attrib.type + "\"");
      }
      if (control)
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
  },
  
  save: function(attrib, after) {
    if (!attrib.update_url)
      attrib.update_url = this.model.update_url;
    if (attrib.before_update) attrib.before_update(this);
    attrib.save(after);      
    if (attrib.after_update) {
      attrib.after_update(this);
    }
  },

  repopulate_options_for_control: function(attribute_name) 
  { 
    for (var i=0; i<this.controls.length; i++)
    { 
      var c = this.controls[i];
      if (c.attribute.name == attribute_name)
      {
        c.attribute.options = false;
        c.init({});
      }      
    }
  }
};
